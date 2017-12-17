/*
 *  @Name:     main
 *
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Joshua Manton
 *  @Last Time: 16-12-2017 18:18:02 UTC-8
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
using import _ "debug.odin";

Commit :: struct {
    git_commit : ^git.Commit,
    author     : git.Signature,
    commiter   : git.Signature,
    message    : string,
}

Branch :: struct {
    ref   : ^git.Reference,
    name  : string,
    btype : git.Branch_Flags,
}

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

get_all_branches :: proc(repo : ^git.Repository, btype : git.Branch_Flags) -> []Branch {
    GIT_ITEROVER :: -31;
    result : [dynamic]Branch;
    iter, err := git.branch_iterator_new(repo, btype);
    over : i32 = 0;
    for over != GIT_ITEROVER {
        ref, btype, over := git.branch_next(iter);
        if over == GIT_ITEROVER do break;
        if !log_if_err(over) {
            name, suc := git.branch_name(ref);
            b := Branch {
                ref,
                name,
                btype,
            };
            append(&result, b);
        }
    }

    git.branch_iterator_free(iter);
    return result[..];
}

get_commit :: proc(repo : ^git.Repository, oid : git.Oid) -> Commit {
    result : Commit;

    err := git.commit_lookup(&result.git_commit, repo, &oid);
    if !log_if_err(err) {
        c_str := git.commit_message(result.git_commit);
        result.message = strings.to_odin_string(c_str);
        result.commiter = git.commit_committer(result.git_commit);
        result.author = git.commit_author(result.git_commit);
    }

    return result;
}

free_commit :: proc(commit : ^Commit) {
    if commit.git_commit == nil do return;
    git.commit_free(commit.git_commit);
    commit.git_commit = nil;
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

    current_commit     : Commit;
    commit_hash_buf    : [1024]byte;

    branch_name        : string;
    create_branch_name : [1024]byte;

    local_branches     : []Branch;
    remote_branches    : []Branch;

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

    settings := debug_get_settings();
    settings.print_location = true;
    debug_set_settings(settings);

    main_loop: for {
        debug_reset();

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
            if imgui.begin_main_menu_bar() {
                defer imgui.end_main_menu_bar();

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
                                    free_commit(&current_commit);
                                    current_commit = get_commit(repo, oid);
                                }
                                ref : ^git.Reference;
                                ref, ok = git.repository_head(repo);
                                if !log_if_err(ok) {
                                    branch_name, err = git.branch_name(ref);
                                }

                                local_branches = get_all_branches(repo, git.Branch_Flags.Local);
                                remote_branches = get_all_branches(repo, git.Branch_Flags.Remote);

                            }

                        } else {
                            console.logf_error("%s is not a repo", path);
                        }
                    }
                } else {
                    imgui.text("Repo: %s", open_repo_name); imgui.same_line();
                    if imgui.button("Close Repo") {
                        free(local_branches);
                        free(remote_branches);
                        local_branches = nil;
                        remote_branches = nil;
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

                                if !log_if_err(ok) {
                                    free_commit(&current_commit);
                                    current_commit = get_commit(repo, oid);
                                }
                            }
                            else {
                                console.log("You haven't fetched a repo yet!");
                            }
                        }

                        imgui.text("Branch: %s",         branch_name);
                        imgui.text("Commiter: %s",       current_commit.commiter.name);
                        imgui.text("Commiter Email: %s", current_commit.commiter.email);
                        imgui.text("Author: %s",         current_commit.author.name);
                        imgui.text("Author Email: %s",   current_commit.author.email);
                        imgui.text("Message: %s",        current_commit.message);

                        imgui.separator();

                        if imgui.button("Status") {
                            if statuses != nil {
                                git.status_list_free(statuses);
                                statuses = nil;
                            } else {
                                options : git.Status_Options;
                                git.status_init_options(&options, 1);
                                options.flags = git.Status_Opt_Flags.Include_Untracked;
                                err : i32;
                                statuses, err = git.status_list_new(repo, &options);
                                log_if_err(err);
                            }
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
                                        if entry.index_to_workdir != nil && entry.index_to_workdir.status != git.Delta.Untracked {
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

                            imgui.text("Untracked files:");
                            if imgui.begin_child("Untracked", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 2, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});
                                for i: uint = 0; i < count; i += 1 {
                                    if entry := git.status_byindex(statuses, i); entry != nil {
                                        if entry.index_to_workdir != nil && entry.index_to_workdir.status == git.Delta.Untracked {
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

                    update_branches := false;
                    if imgui.begin("Branches") {
                        defer imgui.end();

                        checkout_branch :: proc(repo: ^git.Repository, reference: ^git.Reference) -> bool {
                            branch_name, err := git.branch_name(reference);
                            if !log_if_err(err) {
                                obj, err := git.revparse_single(repo, branch_name);
                                if !log_if_err(err) {
                                    opts := git.Checkout_Options{};
                                    opts.version = 1;
                                    opts.checkout_strategy = git.Checkout_Strategy_Flags.Safe;
                                    err = git.checkout_tree(repo, obj, &opts);
                                    refname := git.reference_name(reference);
                                    if !log_if_err(err) {
                                        err = git.repository_set_head(repo, refname);
                                        if !log_if_err(err) {
                                            // TODO(josh): free the current b.ref?
                                            return true;
                                        }
                                    }
                                }
                            }

                            return false;
                        }

                        print_branches :: proc(repo : ^git.Repository, branches : []Branch, update_branches : ^bool) {
                            branch_to_delete: Branch;
                            for b in branches {
                                imgui.selectable(b.name);
                                imgui.push_id(b.name);
                                defer imgui.pop_id();

                                is_current_branch := git.reference_is_branch(b.ref) && git.branch_is_checked_out(b.ref);

                                if imgui.begin_popup_context_item("branch_context", 1) {
                                    defer imgui.end_popup();
                                    if !is_current_branch {
                                        if imgui.selectable("Checkout") {
                                            if checkout_branch(repo, b.ref) {
                                                update_branches^ = true;
                                            }
                                        }

                                        if imgui.selectable("Delete") {
                                            branch_to_delete = b;
                                        }
                                    }
                                }

                                if is_current_branch {
                                    imgui.same_line();
                                    imgui.text("(current)");
                                }
                            }

                            if branch_to_delete.ref != nil {
                                update_branches^ = true;
                                git.branch_delete(branch_to_delete.ref);
                            }
                        }

                        imgui.input_text("", create_branch_name[..]);
                        imgui.same_line();
                        if imgui.button("Create branch") {
                            branch_name_str := cast(string)create_branch_name[..];

                            // NOTE(josh): The docs say that `reference` needs to be freed by the user, but I'm not sure when. :thinking:
                            reference: ^git.Reference;
                            err := git.branch_create(&reference, repo, branch_name_str, current_commit.git_commit, 0);
                            if !log_if_err(err) {
                                if checkout_branch(repo, reference) {
                                    update_branches = true;
                                }
                            }

                            create_branch_name = [1024]u8{};
                        }

                        imgui.text("Local Branches:");
                        imgui.indent();
                        imgui.push_style_color(imgui.Color.Text, imgui.Vec4{0, 1, 0, 1});
                        print_branches(repo, local_branches, &update_branches);
                        imgui.pop_style_color();
                        imgui.unindent();

                        imgui.text("Remote Branches:");
                        imgui.indent();
                        imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});
                        for b in remote_branches {
                            imgui.text(b.name);
                        }
                        imgui.pop_style_color();
                        imgui.unindent();
                    }

                    if update_branches {
                        local_branches = get_all_branches(repo, git.Branch_Flags.Local);
                        remote_branches = get_all_branches(repo, git.Branch_Flags.Remote);
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
