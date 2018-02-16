/*
 *  @Name:     file_explorer
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 28-01-2018 22:20:23 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 16-02-2018 05:21:30 UTC+1
 *  
 *  @Description:
 *  
 */
import "core:fmt.odin";
import "core:mem.odin";
import "core:strings.odin";

import       "shared:libbrew/sys/file.odin";
import       "shared:libbrew/sys/misc.odin";
import imgui "shared:libbrew/brew_imgui.odin";
import       "shared:libbrew/string_util.odin";

import icon "icon-fa.odin";

_misc_buf : [4096]u8;

Context :: struct {
    path            : string,
    show_hidden     := true,
    show_extension  := true,
    show_system     := false,
    files           : []file.DiskEntry,

    _writing_path   : bool,
    _path_buf       : [1024]byte,
    _input_buf      : [1024]byte,
    _selected       := -1,

    _selection_flag : Selection_Flag,
} 

Selection_Flag :: enum {
    Folder = 1 << 0,
    File   = 1 << 1,
}

new_context :: proc(path : string, flags := Selection_Flag.Folder | Selection_Flag.File) -> Context {
    ctx := Context{};
    ctx.path = path;
    ctx.files = file.get_all_entries_in_directory(path); 
    ctx._selection_flag = flags;
    fmt.bprint(ctx._path_buf[..], path);
    return ctx;
}

_make_misc_string :: proc(fmt_: string, args: ...any) -> string {
    s := fmt.bprintf(_misc_buf[..], fmt_, ...args);
    _misc_buf[len(s)] = 0;
    return s;
}

window :: proc(ctx : ^Context, show : ^bool) {
    if imgui.begin("File Explorer", show, imgui.Window_Flags.NoCollapse | imgui.Window_Flags.MenuBar) {
        defer imgui.end();

        if imgui.begin_menu_bar() {
            defer imgui.end_menu_bar();

            if imgui.begin_menu("Misc") {
                defer imgui.end_menu();
                imgui.checkbox("Show Hidden", &ctx.show_hidden);
                imgui.checkbox("Show Extension", &ctx.show_extension);
                imgui.checkbox("Show System", &ctx.show_system);
            }
        }

        if imgui.button(_make_misc_string("%r", icon.ARROW_UP)) {
            _go_up_one_folder(ctx);
        } 
        imgui.same_line();

        if ctx._writing_path {
            fail :: proc(ctx : ^Context) {
                mem.zero(&ctx._path_buf[0], len(ctx._path_buf));
                fmt.bprint(ctx._path_buf[..], ctx.path);
            }

            open :: proc(ctx : ^Context) {
                ctx._writing_path = false;
                str := string(ctx._path_buf[..]);
                if file.is_path_valid(str[..string_util.clen(str)]) {
                    _open_folder_path(ctx, str[..string_util.clen(str)]);
                } else {
                    fail(ctx);
                }
            }

            if imgui.input_text("##path", ctx._path_buf[..], imgui.Input_Text_Flags.EnterReturnsTrue) {
                open(ctx);
            }
            imgui.same_line();
            if imgui.button("Enter") {
                open(ctx);
            }
            imgui.same_line();
            if imgui.button("Cancel") {
                ctx._writing_path = false;
                fail(ctx);
            }
        } else {
            if imgui.selectable(string(ctx._path_buf[..])) {
                ctx._writing_path = true;
            }
        }

        if imgui.begin_child("##files", imgui.Vec2{0, -26}) {
            imgui.columns(count = 3, border = false);
            imgui.text_disabled("Name");
            imgui.next_column();
            imgui.text_disabled("Date Modified");
            imgui.next_column();
            imgui.text_disabled("Size");
            imgui.next_column();
            clipper := imgui.ListClipper{items_count = i32(len(ctx.files))};
            outer: for imgui.list_clipper_step(&clipper) {
                for i := clipper.display_start; i < clipper.display_end; i += 1 {
                    file := ctx.files[i];
                    if !ctx.show_hidden && file.hidden do continue;
                    if !ctx.show_system && file.system do continue;
                    str := _make_misc_string("%r %s", file.dir ? icon.FOLDER_O : icon.FILE, file.name);
                    if imgui.selectable(str, ctx._selected == int(i), imgui.Selectable_Flags.SpanAllColumns | 
                                                                      imgui.Selectable_Flags.AllowDoubleClick) {
                        if imgui.is_mouse_double_clicked(0) {
                            if file.dir {
                                _open_folder(ctx, file);
                                break outer;
                            }
                        } else {
                            select :: proc(ctx : ^Context, file : file.DiskEntry, idx : int) {
                                mem.zero(&ctx._input_buf[0], len(ctx._input_buf));
                                fmt.bprintf(ctx._input_buf[..], "%s", file.name);
                                ctx._selected = int(idx);
                            }

                            if (ctx._selection_flag & Selection_Flag.Folder == Selection_Flag.Folder) &&
                               (file.dir) {
                                select(ctx, file, int(i));
                            } else if (ctx._selection_flag & Selection_Flag.File == Selection_Flag.File) &&
                                      (!file.dir) {
                                select(ctx, file, int(i));
                            }
                        }
                    }
                    imgui.push_id(i);
                    defer imgui.pop_id();
                    if imgui.begin_popup_context_item("file_context", 1) {
                        defer imgui.end_popup();
                        if imgui.begin_menu("New") {
                            imgui.text_disabled("New File");
                            imgui.text_disabled("New Folder");
                            imgui.end_menu();
                        }
                    }
                    imgui.next_column();
                    imgui.text("%2d-%2d-%2d %2d:%2d", file.modified.day, 
                                                      file.modified.month, 
                                                      file.modified.year, 
                                                      file.modified.hour, 
                                                      file.modified.minute);
                    imgui.next_column();

                    kilobytes :: inline proc "contextless" (x : f32) -> f32 do return          (x) / 1024;
                    megabytes :: inline proc "contextless" (x : f32) -> f32 do return kilobytes(x) / 1024;
                    gigabytes :: inline proc "contextless" (x : f32) -> f32 do return megabytes(x) / 1024;
                    
                    if !file.dir {
                        kb := kilobytes(f32(file.size));
                        gb := gigabytes(f32(file.size));
                        mb := megabytes(f32(file.size));
                        if kb >= 1 {
                            if mb >= 1 {
                                if gb >= 1 {
                                    imgui.text("%.2f gb", gb);
                                } else {
                                    imgui.text("%.2f mb", mb);
                                }
                            } else {
                                imgui.text("%.0f kb", kb);
                            }
                        } else {
                            imgui.text_unformatted("1 kb");
                        }

                    }
                    imgui.next_column();
                }
            }
        }
        imgui.end_child();

        imgui.columns_reset();
        imgui.separator();
        imgui.text("%d items", len(ctx.files)); imgui.same_line();
        imgui.input_text(": File name", ctx._input_buf[..]); imgui.same_line();
        imgui.button("Open"); imgui.same_line(); // Call some callback with the file path
        imgui.button("Cancel"); imgui.same_line();
    }
}

_go_up_one_folder :: proc(ctx : ^Context) {
    path, found := string_util.to_second_last_rune(ctx.path, '\\');
    if found {
        _set_and_open(ctx, strings.new_string(path));
    }
}

_open_folder :: proc(ctx : ^Context, folder : file.DiskEntry) {
    _set_and_open(ctx, fmt.aprintf("%s%s\\", ctx.path, folder.name));
}

_open_folder_path :: proc(ctx : ^Context, path : string) {
    buf : [1024]byte;
    if(path[len(path)-1] != '\\') {
        path = fmt.bprintf(buf[..], "%s\\", path);
    }
    _set_and_open(ctx, strings.new_string(path));
}

_set_and_open :: proc(ctx : ^Context, path : string) {
    ctx.path = path;
    mem.zero(&ctx._path_buf[0], len(ctx._path_buf));
    fmt.bprint(ctx._path_buf[..], ctx.path);
    free(ctx.files);
    ctx.files = file.get_all_entries_in_directory(ctx.path);
}