/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 12-12-2017 01:38:47
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin";

import       "mantle:libbrew/win/window.odin";
import       "mantle:libbrew/win/msg.odin";
import       "mantle:libbrew/win/file.odin";
import misc  "mantle:libbrew/win/misc.odin";
import input "mantle:libbrew/win/keys.odin";
import wgl   "mantle:libbrew/win/opengl.odin";

import       "mantle:libbrew/string_util.odin";
import imgui "mantle:libbrew/brew_imgui.odin";
import       "mantle:libbrew/gl.odin";

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

    main_loop: 
    for {
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
                    imgui.end_menu();
                }
            }
            imgui.end_main_menu_bar();
            
            imgui.show_test_window();
        }
        imgui.render_proc(dear_state, wnd_width, wnd_height);
        
        window.swap_buffers(wnd_handle);
    }
}