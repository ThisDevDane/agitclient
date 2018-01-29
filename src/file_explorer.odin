/*
 *  @Name:     file_explorer
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 28-01-2018 22:20:23 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 29-01-2018 03:19:29 UTC+1
 *  
 *  @Description:
 *  
 */
import "core:fmt.odin";
import "core:mem.odin";
import "core:strings.odin";

import win32 "core:sys/windows.odin";

import       "shared:libbrew/win/file.odin";
import       "shared:libbrew/win/misc.odin";
import imgui "shared:libbrew/brew_imgui.odin";
import       "shared:libbrew/string_util.odin";

import icon "icon-fa.odin";

FileEntry :: struct {
    name     : string,
    modified : misc.Datetime,
    type_    : string,
    dir      : bool,
    size     : int,
}



_misc_buf : [4096]u8;

Context :: struct {
    path           : string,
    show_hidden    : bool,
    show_extension : bool,
    files          : []FileEntry,

    _writing_path  : bool,
    _path_buf      : [1024]byte,
    _input_buf     : [1024]byte,
    _selected      := -1,
} 

new_context :: proc(path : string) -> Context {
    ctx := Context{};
    ctx.path = path;
    ctx.files = _get_files(path); 
    fmt.bprint(ctx._path_buf[..], path);
    return ctx;
}

_make_misc_string :: proc(fmt_: string, args: ...any) -> string {
    s := fmt.bprintf(_misc_buf[..], fmt_, ...args);
    _misc_buf[len(s)] = 0;
    return s;
}

window :: proc(ctx : ^Context, show : ^bool) {
    if imgui.begin("File Explorer", show, imgui.Window_Flags.NoCollapse) {
        defer imgui.end();

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
                if file.does_file_or_dir_exists(str[..string_util.clen(str)]) {
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
            for file, i in ctx.files {
                str := _make_misc_string("%r %s", file.dir ? icon.FOLDER_O : icon.FILE, file.name);
                if imgui.selectable(str, ctx._selected == i, imgui.Selectable_Flags.SpanAllColumns | 
                                                         imgui.Selectable_Flags.AllowDoubleClick) {
                    if imgui.is_mouse_double_clicked(0) {
                        if file.dir do _open_folder(ctx, file);
                    } else {
                        mem.zero(&ctx._input_buf[0], len(ctx._input_buf));
                        fmt.bprintf(ctx._input_buf[..], "%s", file.name);
                        ctx._selected = i;
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
                imgui.text("%d-%d-%d %d:%d", file.modified.day, 
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
        ctx.path = strings.new_string(path);
        mem.zero(&ctx._path_buf[0], len(ctx._path_buf));
        fmt.bprint(ctx._path_buf[..], ctx.path);
        free(ctx.files);
        ctx.files = _get_files(ctx.path);
    }
}

_open_folder :: proc(ctx : ^Context, folder : FileEntry) {
    ctx.path = fmt.aprintf("%s%s\\", ctx.path, folder.name);
    mem.zero(&ctx._path_buf[0], len(ctx._path_buf));
    fmt.bprint(ctx._path_buf[..], ctx.path);
    free(ctx.files);
    ctx.files = _get_files(ctx.path);
}

_open_folder_path :: proc(ctx : ^Context, path : string) {
    buf : [1024]byte;
    if(path[len(path)-1] != '\\') {
        path = fmt.bprintf(buf[..], "%s\\", path);
    }
    ctx.path = strings.new_string(path);
    mem.zero(&ctx._path_buf[0], len(ctx._path_buf));
    fmt.bprint(ctx._path_buf[..], ctx.path);
    free(ctx.files);
    ctx.files = _get_files(ctx.path);
}

_get_files :: proc(path : string) -> []FileEntry {
    buf : [1024]byte;
    if(path[len(path)-1] != '*') {
        path = fmt.bprintf(buf[..], "%s*", path);
    }
    find_data := win32.Find_Data{};
    file_handle := win32.find_first_file_a(&path[0], &find_data);

    result := make([]FileEntry, _count_files(file_handle, &find_data));

    file_handle = win32.find_first_file_a(&path[0], &find_data);
    i := 0;
    if file_handle != win32.INVALID_HANDLE {
        if !_skip_dot(find_data.file_name[..]) {
            result[i] = _make_file_from_find_data(find_data);
            i += 1;
        }
        for win32.find_next_file_a(file_handle, &find_data) == true {
            if _skip_dot(find_data.file_name[..]) {
                continue;
            }

            result[i] = _make_file_from_find_data(find_data);
            i += 1;
        }
    }
    fmt.println(i);

    win32.find_close(file_handle); 

    return result;
}

_make_file_from_find_data :: proc(data : win32.Find_Data) -> FileEntry {
    result := FileEntry{};
    tmp := strings.to_odin_string(&data.file_name[0]);
    tmp = tmp[..string_util.clen(tmp)];
    result.name = strings.new_string(tmp);
    result.modified = misc.filetime_to_datetime(data.last_write_time);
    result.size = int(data.file_size_low) | int(data.file_size_high) << 32;
    if data.file_attributes & win32.FILE_ATTRIBUTE_DIRECTORY == win32.FILE_ATTRIBUTE_DIRECTORY {
        result.dir = true;
    }
    return result;
}

_count_files :: proc(handle : win32.Handle, find_data : ^win32.Find_Data) -> int {
    count := 0;
    if handle != win32.INVALID_HANDLE {
        if !_skip_dot(find_data.file_name[..]) {
            count += 1;
        }
        for win32.find_next_file_a(handle, find_data) {
            if _skip_dot(find_data.file_name[..]) {
                continue;
            }
            count += 1;
        }
    }

    return count;
}

_skip_dot :: proc(c_str : []u8) -> bool {
    len := string_util.get_c_string_length(&c_str[0]);
    f := string(c_str[..len]);

    return f == "." || f == ".."; 
}