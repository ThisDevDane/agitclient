/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 14-12-2017 02:48:51 GMT+1
 *  
 *  @Description:
 *      Entry point for A Git Client.
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
    if len(args) >= 2 { 
        username = args[0];
        password = args[1];
    } else {
        console.log_error("You forgot to supply username AND password");
    }
}

credentials_callback :: proc "stdcall" (cred : ^^git.Cred,  url : ^byte,  
                              username_from_url : ^byte, allowed_types : git.Cred_Type, payload : rawptr) -> i32 {
    test_val :: proc(test : git.Cred_Type, value : git.Cred_Type) -> bool {
        return test & value == test;
    }
    if test_val(git.Cred_Type.Userpass_Plaintext, allowed_types) {
        new_cred, err := git.cred_userpass_plaintext_new(username, password);
        if err != 0 {
            return 1;
        }
        cred^ = new_cred;
    } else {
        return -1;            
    }

    return 0;
}

log_if_err :: proc(err : i32, loc := #caller_location) -> bool {
    if err != 0 {
        gerr := git.err_last();
        console.logf_error("LibGit2 Error: %v | %v | %s (%s:%d)", err, 
                                                                  gerr.klass, 
                                                                  gerr.message, 
                                                                  string_util.remove_path_from_file(loc.file_path), 
                                                                  loc.line);
        return true;
    } else {
        return false;
    }
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

    repo: ^git.Repository;

    message            : msg.Msg;
    wnd_width          := 1280;
    wnd_height         := 720;
    shift_down         := false;
    new_frame_state    := imgui.FrameState{};
    lm_down            := false;
    rm_down            := false;
    time_data          := misc.create_time_data();
    mpos_x             := 0;
    mpos_y             := 0;
    draw_log           := false;
    draw_history       := false;
    draw_console       := true;
    draw_demo_window   := false;

    lib_ver_major      : i32;
    lib_ver_minor      : i32;
    lib_ver_rev        : i32;

    statuses           : ^git.Status_List;

    path_buf           : [255+1]byte;

    open_repo_name     : string;

    commit             : ^git.Commit;
    commit_hash_buf    : [1024]byte;
    commit_message     : string;
    commit_sig         : git.Signature;
    branch_c           : ^byte;

    git.lib_init();
    feature_set :: proc(test : git.Lib_Features, value : git.Lib_Features) -> bool {
        return test & value == test;
    }
    lib_features := git.lib_features();
    console.log("LibGit2 build config;");
    console.logf("\tLibGit2 is %s", 
                 feature_set(git.Lib_Features.Threads, lib_features) ? "thread-safe." : "not thread-safe");
    console.logf("\tHttps is %s", 
             feature_set(git.Lib_Features.Https, lib_features) ? "supported." : "not supported");
    console.logf("\tSSH is %s", 
             feature_set(git.Lib_Features.Ssh, lib_features) ? "supported." : "not supported");
    console.logf("\tNsec is %s", 
             feature_set(git.Lib_Features.Nsec, lib_features) ? "supported." : "not supported");
    
    git.lib_version(&lib_ver_major, &lib_ver_minor, &lib_ver_rev);
    lib_ver_string := fmt.aprintf("libgit2 v%d.%d.%d", 
                                  lib_ver_major, lib_ver_minor, lib_ver_rev);

    main_loop: for {
        new_frame_state.mouse_wheel = 0;
        
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

                case msg.MsgMouseWheel : {
                    new_frame_state.mouse_wheel = msg.distance;
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
                    imgui.checkbox("Show Console", &draw_console);
                    imgui.checkbox("Show Demo Window", &draw_demo_window);
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
                defer imgui.end();
                
                if repo == nil {
                    imgui.input_text("Repo Path;", path_buf[..]);
                    if imgui.button("Open") {
                        path := strings.to_odin_string(&path_buf[0]);
                        if git.is_repository(path) {
                            new_repo, err := git.repository_open(path);
                            if !log_if_err(err) {
                                repo = new_repo;
                                open_repo_name = strings.new_string(path); 
                                oid, ok := git.reference_name_to_id(repo, "HEAD");
                                if !log_if_err(ok) {
                                    if commit != nil {
                                        git.commit_free(commit);
                                    }
                                    ok = git.commit_lookup(&commit, repo, &oid);
                                    if !log_if_err(ok) {
                                        message_c := git.commit_message(commit);
                                        commit_message = strings.to_odin_string(message_c);
                                        commit_sig = git.commit_committer(commit);
                                    }
                                }
                                ref : ^git.Reference;
                                ref, ok = git.repository_head(repo);
                                if !log_if_err(ok) {
                                    git.git_branch_name(&branch_c, ref);
                                }

                            }
                        } else {
                            console.logf_error("%s is not a repo", path);
                        }
                    }
                } else {
                    imgui.text("Repo: %s", open_repo_name); imgui.same_line();
                    if imgui.button("Close Repo") {
                        git.repository_free(repo);
                        repo = nil;
                    } else {
                        if imgui.button("Fetch" ) {
                            remote, ok := git.remote_lookup(repo, "origin");
                            remote_cb, _  := git.remote_init_callbacks();
                            remote_cb.credentials = credentials_callback;
                            ok = git.remote_connect(remote, git.Direction.Fetch, &remote_cb, nil, nil);
                            if !log_if_err(ok) {
                                console.logf("Origin Connected: %t", cast(bool)git.remote_connected(remote));
                                fetch_opt := git.Fetch_Options{};
                                fetch_cb, _  := git.remote_init_callbacks();
                                fetch_opt.version = 1;
                                fetch_opt.proxy_opts.version = 1;
                                fetch_opt.callbacks = remote_cb;

                                ok = git.remote_fetch(remote, nil, &fetch_opt);
                                if !log_if_err(ok) {
                                    console.log("Fetch complete...");
                                }
                            }

                            git.remote_free(remote);
                        }

                        imgui.input_text("Commit Hash;", commit_hash_buf[..]);
                        if imgui.button("Lookup") {
                            if repo != nil {
                                oid_str := cast(string)commit_hash_buf[..];
                                oid: git.Oid;
                                ok: = git.oid_from_str(&oid, &oid_str[0]);
                                log_if_err(ok);
                                if ok == 0 {
                                    if commit != nil {
                                        git.commit_free(commit);
                                    }



                                    ok = git.commit_lookup(&commit, repo, &oid);
                                    log_if_err(ok);

                                    if ok == 0 {
                                        message_c := git.commit_message(commit);
                                        commit_message = strings.to_odin_string(message_c);
                                        commit_sig = git.commit_committer(commit);
                                    }
                                }
                            }
                            else {
                                console.log("You haven't fetched a repo yet!");
                            }
                        }

                        imgui.text("Branch: %s",         strings.to_odin_string(branch_c));
                        imgui.text("Commiter: %s",       commit_sig.name);
                        imgui.text("Commiter Email: %s", commit_sig.email);
                        imgui.text("Message: %s",        commit_message);

                        imgui.separator();

                        if imgui.button("Status") {
                            if statuses != nil {
                                git.status_list_free(statuses);
                            }
                            options : git.Status_Options;
                            git.status_init_options(&options, 1);
                            err : i32;
                            statuses, err = git.status_list_new(repo, &options); 
                            log_if_err(err);
                        }
                        

                        if statuses != nil {
                            count := git.status_list_entrycount(statuses);

                            imgui.text("Changes to be committed:");
                            if imgui.begin_child("Staged", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 2, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{0, 1, 0, 1});
                                for i: uint = 0; i < count; i += 1 {
                                    if entry := git.status_byindex(statuses, i); entry != nil {
                                        if entry.head_to_index != nil {
                                            if entry.head_to_index.old_file.path != nil {
                                                imgui.set_column_width(-1, 100);
                                                imgui.text("%v", entry.head_to_index.status);
                                                imgui.next_column();
                                                imgui.text(strings.to_odin_string(entry.head_to_index.old_file.path));
                                                imgui.next_column();
                                            }
                                        }
                                    } else {
                                        console.logf_error("entry nil: index %d", i);
                                    }
                                }
                                imgui.pop_style_color();
                            }
                            imgui.end_child();

                            imgui.text("Changes not staged for commit:");
                            if imgui.begin_child("NotStaged", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 2, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});
                                for i: uint = 0; i < count; i += 1 {
                                    if entry := git.status_byindex(statuses, i); entry != nil {
                                        if entry.index_to_workdir != nil {
                                            if entry.index_to_workdir.old_file.path != nil {
                                                imgui.set_column_width(-1, 100);
                                                imgui.text("%v", entry.index_to_workdir.status);
                                                imgui.next_column();
                                                imgui.text(strings.to_odin_string(entry.index_to_workdir.old_file.path));
                                                imgui.next_column();
                                            }
                                        }
                                    } else {
                                        console.logf_error("entry nil: index %d", i);
                                    }
                                }
                                imgui.pop_style_color();
                            }
                            imgui.end_child();
                        }
                    }
                }
            }

            if draw_console {
                console.draw_console(&draw_console, &draw_log, &draw_history);
            }
            if draw_log {
                console.draw_log(&draw_log);
            }
            if draw_history {
                console.draw_history(&draw_history);
            }

            if draw_demo_window {
                imgui.show_test_window(&draw_demo_window);
            }
        }
        imgui.render_proc(dear_state, wnd_width, wnd_height);
        
        window.swap_buffers(wnd_handle);
    }

    git.lib_shutdown();
}
