/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 12-12-2017 22:44:08
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

import git     "libgit2.odin";
import console "console.odin";

set_proc :: inline proc(lib_ : rawptr, p: rawptr, name: string) {
    lib := misc.LibHandle(lib_);
    res := wgl.get_proc_address(name);
    if res == nil {
        res = misc.get_proc_address(lib, name);
    }   
    if res == nil {
        console.log("Couldn't load:", name);
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
    console.log(strings.to_odin_string(path), status_flags);

    return 0;
}

username : string;
password : string;

set_user :: proc(args : []string) {
    username = args[0];
    password = args[1];
}

credentials_callback :: proc "stdcall" (cred : ^^git.Cred,  url : ^byte,  
                              username_from_url : ^byte, allowed_types : git.Cred_Type, payload : rawptr) -> i32 {
    test_val :: proc(test : git.Cred_Type, value : git.Cred_Type) -> bool {
        return test & value == test;
    }
    //console.log(test_val(git.Cred_Type.Userpass_Plaintext, allowed_types));
    //console.log(test_val(git.Cred_Type.Ssh_Key,            allowed_types));
    //console.log(test_val(git.Cred_Type.Ssh_Custom,         allowed_types));
    //console.log(test_val(git.Cred_Type.Default,            allowed_types));
    //console.log(test_val(git.Cred_Type.Ssh_Interactive,    allowed_types));
    //console.log(test_val(git.Cred_Type.Username,           allowed_types));
    //console.log(test_val(git.Cred_Type.Ssh_Memory,         allowed_types));
    new_cred, err := git.cred_userpass_plaintext_new(username, password);
    cred^ = new_cred;
    //console.log("----------------");
    return 0;
}


main :: proc() {
    console.log("Program start...");
    console.add_default_commands();
    console.add_command("set_user", set_user);
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
    draw_log        := false;     

    lib_ver_major   : i32;
    lib_ver_minor   : i32;
    lib_ver_rev     : i32;

    path_buf        : [255+1]byte;

    git.lib_init();
    lib_features := git.lib_features();
    feature_set :: proc(test : git.Lib_Features, value : git.Lib_Features) -> bool {
        return test & value == test;
    }
    git.lib_version(&lib_ver_major, &lib_ver_minor, &lib_ver_rev);
    lib_ver_string := fmt.aprintf("libgit2 v%d.%d.%d", 
                                  lib_ver_major, lib_ver_minor, lib_ver_rev);
 
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
        new_frame_state.deltatime     = f32(dt);
        new_frame_state.mouse_x       = mpos_x;
        new_frame_state.mouse_y       = mpos_y;
        new_frame_state.window_width  = wnd_width;
        new_frame_state.window_height = wnd_height;
        new_frame_state.left_mouse    = lm_down;
        new_frame_state.right_mouse   = rm_down;

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

            if imgui.begin("TEST") {
                imgui.input_text("Repo Path;", path_buf[..]);
                if imgui.button("Fetch") {
                    repo, err := git.repository_open(strings.to_odin_string(&path_buf[0]));
                    if err != 0 {
                        console.log(err);
                        gerr := git.err_last();
                        console.logf_error("Libgit Error: %v/%v %s\n", err, gerr.klass, gerr.message);
                    } else {

                    }

                    remote, ok := git.remote_lookup(repo, "origin");
                    remote_cb, _  := git.remote_init_callbacks();
                    remote_cb.credentials = credentials_callback;
                    ok = git.remote_connect(remote, git.Direction.Fetch, &remote_cb, nil, nil);
                    if ok != 0 {
                        gerr := git.err_last();
                        console.logf_error("Libgit Error: %v/%v %s\n", ok, gerr.klass, gerr.message);
                    } else {
                        console.logf("Origin Connected: %t", cast(bool)git.remote_connected(remote));
                    }

                    fetch_opt := git.Fetch_Options{};
                    fetch_cb, _  := git.remote_init_callbacks();
                    fetch_opt.version = 1;
                    fetch_opt.proxy_opts.version = 1;
                    fetch_opt.callbacks = remote_cb;

                    ok = git.remote_fetch(remote, nil, &fetch_opt, nil);
                    if ok != 0 {
                        gerr := git.err_last();
                        console.logf_error("Libgit Error: %d/%v %s\n", ok, gerr.klass, gerr.message);
                    } else {
                        console.log("Fetch complete...");
                    }
                    
                    git.status_foreach(repo, status_callback, nil);

                    git.remote_free(remote);
                    git.repository_free(repo);
                }
                imgui.end();
            }

            if imgui.begin("foo") {
                defer imgui.end();
            }

            console.draw_console(nil, &draw_log);
            if draw_log {
                console.draw_log(&draw_log);
            }
            imgui.show_test_window();
        }
        imgui.render_proc(dear_state, wnd_width, wnd_height);
        
        window.swap_buffers(wnd_handle);
    }

    git.lib_shutdown();
}