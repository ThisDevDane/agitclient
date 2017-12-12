/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 12-12-2017 06:13:02
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin";
import "core:strings.odin";
import "core:os.odin";

import       "shared:libbrew/win/window.odin";
import       "shared:libbrew/win/msg.odin";
import misc  "shared:libbrew/win/misc.odin";
import input "shared:libbrew/win/keys.odin";
import wgl   "shared:libbrew/win/opengl.odin";

import       "shared:libbrew/string_util.odin";
import imgui "shared:libbrew/brew_imgui.odin";
import       "shared:libbrew/gl.odin";

import git   "libgit2.odin";

set_proc :: inline proc(lib_ : rawptr, p: rawptr, name: string) {
    lib := misc.LibHandle(lib_);
    res := wgl.get_proc_address(name);
    if res == nil {
        res = misc.get_proc_address(lib, name);
    }   
    if res == nil {
        fmt.println("Couldn't load:", name);
    }

    (^rawptr)(p)^ = rawptr(res);
}

load_lib :: proc(str : string) -> rawptr {
    return rawptr(misc.load_library(str));
}

free_lib :: proc(lib : rawptr) {
    misc.free_library(misc.LibHandle(lib));
}

status_callback :: proc "stdcall" (path : ^byte, status_flags : git.Status_Flags, payload : rawptr) -> i32 {
    fmt.println(strings.to_odin_string(path), status_flags);

    return 0;
}

main :: proc() {
    fmt.println("Program start...");
    app_handle := misc.get_app_handle();
    wnd_handle := window.create_window(app_handle, "A Git Client", false, 1280, 720);
    gl_ctx     := wgl.create_gl_context(wnd_handle, 3, 3);

    gl.load_functions(set_proc, load_lib, free_lib);

    dear_state := new(imgui.State);
    imgui.init(dear_state, wnd_handle);
    wgl.swap_interval(-1);
    gl.clear_color(0.10, 0.10, 0.10, 1);


    message         : msg.Msg;
    wnd_width       := 1280;
    wnd_height      := 720;
    shift_down      := false;
    new_frame_state := imgui.FrameState{};
    lm_down         := false;
    rm_down         := false;
    time_data       := misc.create_time_data();
    mpos_x          := 0;
    mpos_y          := 0;     

    lib_ver_major   : i32;
    lib_ver_minor   : i32;
    lib_ver_rev     : i32;

    git.lib_init();
    lib_features := git.lib_features();
    feature_set :: proc(test : git.Lib_Features, value : git.Lib_Features) -> bool {
        return test & value == test;
    }
    git.lib_version(&lib_ver_major, &lib_ver_minor, &lib_ver_rev);
    lib_ver_string := fmt.aprintf("libgit2 v%d.%d.%d", 
                                  lib_ver_major, lib_ver_minor, lib_ver_rev);
 
    repo, err := git.repository_open("E:/Odin/");
    if err != 0 {
        gerr := git.err_last();
        fmt.printf("Libgit Error: %d/%v %s\n", err, gerr.klass, gerr.message);
    }

    git.status_foreach(repo, status_callback, nil);

    main_loop: for {
        for msg.poll_message(&message) {
            switch msg in message {
                case msg.MsgQuitMessage : {
                    break main_loop;
                }

                case msg.MsgChar : {
                    imgui.gui_io_add_input_character(u16(msg.char));
                }

                case msg.MsgKey : {
                    switch msg.key {
                        case input.VirtualKey.Escape : {
                            if msg.down == true && shift_down {
                                break main_loop;
                            }
                        }

                        case input.VirtualKey.Lshift : {
                            shift_down = msg.down;
                        }
                    }
                }

                case msg.MsgMouseButton : {
                    switch msg.key {
                        case input.VirtualKey.LMouse : {
                            lm_down = msg.down;
                        }

                        case input.VirtualKey.RMouse : {
                            rm_down = msg.down;
                        }
                    }
                }

                case msg.MsgWindowFocus : {
                    new_frame_state.window_focus = msg.enter_focus;
                }

                case msg.MsgMouseMove : {
                    mpos_x = msg.x;
                    mpos_y = msg.y;
                }

                case msg.MsgSizeChange : {
                    wnd_width = msg.width;
                    wnd_height = msg.height;
                    gl.viewport(0, 0, i32(wnd_width), i32(wnd_height));
                    gl.scissor (0, 0, i32(wnd_width), i32(wnd_height));
                }
            }
        }

        dt := misc.time(&time_data);
        new_frame_state.deltatime = f32(dt);
        new_frame_state.mouse_x = mpos_x;
        new_frame_state.mouse_y = mpos_y;
        new_frame_state.window_width = wnd_width;
        new_frame_state.window_height = wnd_height;
        new_frame_state.left_mouse = lm_down;
        new_frame_state.right_mouse = rm_down;

        gl.clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);
        imgui.begin_new_frame(&new_frame_state);
        { //RENDER
            imgui.begin_main_menu_bar();
            {
                if imgui.begin_menu("Menu") {
                    if imgui.menu_item("Close", "Shift+ESC") {
                        break main_loop;
                    }
                    imgui.end_menu();
                }
                if imgui.begin_menu("Preferences") {
                    imgui.end_menu();
                }
                if imgui.begin_menu("Help") {
                    imgui.menu_item(label = "A Git Client v0.0.0a", enabled = false);
                    imgui.menu_item(label = lib_ver_string, enabled = false);
                    imgui.end_menu();
                }
            }
            imgui.end_main_menu_bar();
            
            imgui.show_test_window();
        }
        imgui.render_proc(dear_state, wnd_width, wnd_height);
        
        window.swap_buffers(wnd_handle);
    }

    git.lib_shutdown();
}