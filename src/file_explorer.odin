/*
 *  @Name:     file_explorer
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 28-01-2018 22:20:23 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 07-02-2018 21:12:04 UTC+1
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
    path           : string,
    show_hidden    := true,
    show_extension := true,
    show_system    := false,
    files          : []file.DiskEntry,

    _writing_path  : bool,
    _path_buf      : [1024]byte,
    _input_buf     : [1024]byte,
    _selected      := -1,
} 

new_context :: proc(path : string) -> Context {
    ctx := Context{};
    ctx.path = path;
    ctx.files = file.get_all_entries_in_directory(path); 
    fmt.bprint(ctx._path_buf[..], path);
    return ctx;
}

_make_misc_string :: proc(fmt_: string, args: ...any) -> string {
    s := fmt.bprintf(_misc_buf[..], fmt_, ...args);
    _misc_buf[len(s)] = 0;
    return s;
}

_new_idx : i32 = -1;
_new_buf : [256]byte;

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

        imgui.button(_make_misc_string("%r", icon.ARROW_CIRCLE_LEFT)); imgui.same_line();
        imgui.button(_make_misc_string("%r", icon.ARROW_CIRCLE_RIGHT)); imgui.same_line();
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
        imgui.begin_child("##files_header", imgui.Vec2{0, 26});
        {
            imgui.columns(count = 3, border = false);
            imgui.text("Name");
            imgui.next_column();
            imgui.text("Date Modified");
            imgui.next_column();
            imgui.text("Size");
            imgui.next_column();
            imgui.columns_reset();
        }
        imgui.end_child();

        if imgui.begin_child("##files", imgui.Vec2{0, -26}) {

            imgui.columns(count = 3, border = false);
            defer imgui.end_child();
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
                            mem.zero(&ctx._input_buf[0], len(ctx._input_buf));
                            fmt.bprintf(ctx._input_buf[..], "%s", file.name);
                            ctx._selected = int(i);
                        }
                    }
                    imgui.push_id(i);
                    defer imgui.pop_id();
                    if imgui.begin_popup_context_item("file_context", 1) {
                        defer imgui.end_popup();
                        if imgui.begin_menu("New") {
                            if imgui.selectable("New File") {
                                fmt.bprintf(_new_buf[..], "new file");
                                _new_idx = i;
                            }
                            
                            if imgui.selectable("New Folder") {
                                fmt.bprintf(_new_buf[..], "new folder");
                                _new_idx = i;
                            }
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
                        if kb >= 1 {
                            if gb >= 1 {
                                imgui.text("%.2f gb", gb);
                            } else {
                                imgui.text("%.0f kb", kb);
                            }
                        } else {
                            imgui.text("%d b", file.size);
                        }

                    }
                    imgui.next_column();

                    if _new_idx == i {
                        if imgui.input_text("##new_input", _new_buf[..], imgui.Input_Text_Flags.EnterReturnsTrue) {
                            mem.zero(&_new_buf[0], len(_new_buf));
                            _new_idx = -1;
                        }
                        imgui.next_column();
                        if imgui.button("Cancel") {
                            mem.zero(&_new_buf[0], len(_new_buf));
                            _new_idx = -1;
                        }
                        imgui.next_column();
                        imgui.next_column();
                    }
                }
            }
        }
        imgui.columns_reset();
        imgui.separator();
        imgui.text("%d items", len(ctx.files)); imgui.same_line();
        imgui.input_text(": File name", ctx._input_buf[..]); imgui.same_line();
        imgui.button("Open"); imgui.same_line();
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