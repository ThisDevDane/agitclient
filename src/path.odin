package main;

import "core:mem"
import "core:strings"
import "core:unicode/utf8"
import win32 "core:sys/win32"

foreign import "system:kernel32.lib"
foreign kernel32 {
    GetLongPathNameA :: proc "std" (short, long: cstring, len: u32) -> u32 ---;
    GetShortPathNameA :: proc "std" (long, short: cstring, len: u32) -> u32 ---;
    GetFullPathNameA :: proc "std" (filename: cstring, buffer_length: u32, buffer: cstring, file_part: ^cstring) -> u32 ---;
    GetCurrentDirectoryA :: proc "std" (buffer_length: u32, buffer: ^u8) -> u32 ---;
}

long :: proc(path: string) -> string {
    

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetLongPathNameA(c_path, nil, 0);

    if length > 0 {
        buf := make([]u8, length-1);

        GetLongPathNameA(c_path, cstring(&buf[0]), length);

        return cast(string) buf[:length-1];
    }

    return "";
}

short :: proc(path: string) -> string {
    

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetShortPathNameA(c_path, nil, 0);

    if length > 0 {
        buf := make([]u8, length-1);

        GetShortPathNameA(c_path, cstring(&buf[0]), length);

        return cast(string) buf[:length-1];
    }

    return "";
}

full :: proc(path: string) -> string {
    

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetFullPathNameA(c_path, 0, nil, nil);

    if length > 0 {
        buf := make([]u8, length);

        GetFullPathNameA(c_path, length, cstring(&buf[0]), nil);

        return cast(string) buf[:length-1];
    }

    return "";
}

current :: proc() -> string {
    

    length := GetCurrentDirectoryA(0, nil);

    if length > 0 {
        buf := make([]u8, length);

        GetCurrentDirectoryA(length, &buf[0]);

        return cast(string) buf[:length-1];
    }

    return "";
}

// @todo: should I allocate?
ext :: proc(path: string, new := false) -> string {
    dot   := -1;
    slash := -1;
    
    for char, i in path do switch char {
        case '.':  dot   = i; 
        case '/':  slash = i;
        case '\\': slash = i;
    }

    if dot != -1 && (slash == -1 || slash < dot) do return new ? strings.new_string(path[dot+1:]) : path[dot+1:];

    return "";
}

// @todo: should I allocate?
name :: proc(path: string, new := false) -> string {
    dot   := -1;
    slash := -1;

    for char, i in path do switch char {
        case '.':  dot   = i;
        case '/':  slash = i;
        case '\\': slash = i;
    }

    if slash != -1 {
        if slash < dot do return path[slash+1:dot];
        return new ? strings.new_string(path[slash+1:]) : path[slash+1:];
    } else {
        if dot != -1 do return path[:dot];
        return new ? strings.new_string(path) : path;
    }

    return "";
}

is_dir :: proc(path: string) -> bool {
    c_path := strings.new_cstring(path);
    defer delete(c_path);

    return 0 < (win32.get_file_attributes_a(c_path) & win32.FILE_ATTRIBUTE_DIRECTORY);
}

is_file :: proc(path: string) -> bool {
    return !is_dir(path);
}

dir :: proc(path: string, new := false) -> string {
    slash := -1;

    if is_file(path) {
        for char, i in path do switch char {
            case '/':  slash = i;
            case '\\': slash = i;
        }

        if slash != -1 do return new ? strings.new_string(path[:slash]) : path[:slash];

        return "";
    }

    return new ? strings.new_string(path) : path;
}

dir_new :: proc(path: string) -> string {
    return strings.new_string(dir(path));
}

relative_between :: proc(from, to: string) -> string {
    full_from, full_to := full(from), full(to);

    dots   := 0;
    common := 0;

    for char, i in full_from {
        if char2, bytes := utf8.decode_rune(cast([]u8) full_to[i:]); bytes > 0 {
            if ((char == '\\' || char == '/') && (char2 != '\\' && char2 != '/')) || char != char2 {
                common = i;
                break;
            }
        } else {
            break;
        }
    }

    if common <= 0 do return "";

    for char, i in full_from[common+1:] {
        if char == '/' || char == '\\' do dots += 1;
    }

    if is_dir(full_from) do dots += 1;

    buf := make([]u8, dots*3 + (len(full_to)-common));

    dot   := '.';
    slash := '\\';

    i := 0;
    for in 0..dots {
        mem.copy(&buf[i], &dot,   1); i += 1;
        mem.copy(&buf[i], &dot,   1); i += 1;
        mem.copy(&buf[i], &slash, 1); i += 1;
    }

    mem.copy(&buf[i], &full_to[common], len(full_to)-common);

    return cast(string) buf[:];
}

relative_current :: proc(to: string) -> string {
    tmp := current();
    defer delete(tmp);

    return relative(tmp, to);
}

relative :: proc[relative_between, relative_current];
