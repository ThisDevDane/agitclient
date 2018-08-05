package main;

import "core:fmt"

import util    "shared:libbrew/util";
import git     "shared:odin-libgit2"
import console "shared:libbrew/console"

/////////////////Debuggification/////////////////////

Debug_Settings :: struct {
    print_location  : bool,
    print_iteration : bool,
    print_procedure : bool,
}

Debug_State :: struct {
    settings  : Debug_Settings,
    iteration : int, 
}

_STACK_SIZE :: 1024;

_state_stack := [_STACK_SIZE]Debug_State{};
_index := 0;
_state := &_state_stack[_index];

debug_reset :: proc() {
    _index = 0;
    _state = &_state_stack[_index];
    _state.iteration = 0;
}

debug_pop :: proc() -> Debug_State {
    assert(_index > 0);
    tmp := _state^;
    _index -= 1;
    _state = &_state_stack[_index];
    return tmp;
}

debug_push :: proc(state := Debug_State{}) {
    assert(_index >= 0);
    _index += 1;
    _state = &_state_stack[_index];
    _state^ = state;
}

debug_get_settings :: proc() -> Debug_Settings {
    return _state.settings;
}

debug_set_settings :: proc(settings : Debug_Settings) {
    _state.settings = settings;
}

debug_format :: proc(format : string, args : ..any, loc := #caller_location) {
    buf := fmt.String_Buffer{};
    defer delete(buf);

    space := false;

    if _state.settings.print_iteration {
        if space do fmt.sbprint(&buf, " ");
        fmt.sbprintf(&buf, "#%d", _state.iteration);
        space = true;
    }

    if _state.settings.print_location {
        if space do fmt.sbprint(&buf, " ");
        fmt.sbprintf(&buf, "%s:(%d,%d)", util.remove_path_from_file(loc.file_path), loc.line, loc.column);
        space = true;
    }

    if _state.settings.print_procedure {
        fmt.sbprintf(&buf, "@%s", loc.procedure);
        space = true;
    }

    fmt.sbprint(&buf, "> ");
    fmt.sbprintf(&buf, format, ..args);

    console.logf_error("%s\r\n", fmt.to_string(buf));

    _state.iteration += 1;
}

debug_no_args :: inline proc(loc := #caller_location) do debug_format(format="", args=[]any{}, loc=loc);

debug :: proc[debug_format, debug_no_args];


/////////////////AGC Specific//////////////////////

log_if_err :: proc(err : git.Error_Code, loc := #caller_location) -> bool {
    if err != git.Error_Code.Ok {
        gerr := git.err_last();
        if gerr.klass != git.ErrorType.Unknown {
            console.logf_error("LibGit2 Error: %v | %v | %s (%s:%d)", err, 
                                                                      gerr.klass, 
                                                                      gerr.message, 
                                                                      util.remove_path_from_file(loc.file_path), 
                                                                      loc.line);
        } else {
            console.logf_error("LibGit2 Error: %v | (%s:%d)", err,
                                                              util.remove_path_from_file(loc.file_path), 
                                                              loc.line);
        }
        
        return true;
    } else {
        return false;
    }
}
