/*
 *  @Name:     main
 *
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 05-03-2018 10:41:08 UTC+1
 *
 *  @Description:
 *      Entry point for A Git Client.
 */

import "core:fmt.odin";
import "core:strings.odin";
import "core:os.odin";
import "core:mem.odin";
import "core:thread.odin";
import "core:sync.odin";
import win32 "core:sys/windows.odin";

import       "shared:libbrew/sys/window.odin";
import       "shared:libbrew/sys/msg.odin";
import misc  "shared:libbrew/sys/misc.odin";
import input "shared:libbrew/sys/keys.odin";
import wgl   "shared:libbrew/sys/opengl.odin";

import         "shared:libbrew/string_util.odin";
import         "shared:libbrew/time_util.odin";
import imgui   "shared:libbrew/brew_imgui.odin";
import         "shared:libbrew/gl.odin";
import         "shared:libbrew/leakcheck.odin";
import         "shared:libbrew/cel.odin";
import         "shared:libbrew/dyna_util.odin";
import console "shared:libbrew/imgui_console.odin";

import git        "libgit2.odin";
using import _    "debug.odin";
import pat        "path.odin";
import            "color.odin";
import            "log.odin";
import com        "commit.odin";
import brnch      "branch.odin";
import            "settings.odin";
import            "diff_view.odin";
using import _    "state.odin";
import git_status "status.odin";
import explorer   "file_explorer.odin"

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

set_user :: proc(args : []string) {
    if len(args) == 2 {
        free(settings.instance.username);
        free(settings.instance.password);

        settings.instance.username = strings.new_string(args[0]);
        settings.instance.password = strings.new_string(args[1]);

        settings.save();
    } else {
        console.log_error("You forgot to supply username AND password");
    }
}

set_signature :: proc(args : []string) {
    if len(args) == 2 {
        free(settings.instance.name);
        free(settings.instance.email);

        settings.instance.name  = strings.new_string(args[0]);
        settings.instance.email = strings.new_string(args[1]);

        settings.save();
    } else if len(args) == 3 {
        free(settings.instance.name);
        free(settings.instance.email);

        settings.instance.name  = fmt.aprintf("%s %s", args[0], args[1]);
        settings.instance.email = strings.new_string(args[2]);

        settings.save();
    } else {
        console.log_error("set_signature takes either two names and an email or one name and an email.");
    }
}

credentials_callback :: proc "stdcall" (cred : ^^git.Cred,  url : ^byte, username_from_url : ^byte, allowed_types : git.Cred_Type, payload : rawptr) -> i32 {
    ERR :: -1;
    FAILED :: 1;
    SUCCESS :: 0;
    test_val :: proc(test : git.Cred_Type, value : git.Cred_Type) -> bool {
        return test & value == test;
    }
    if test_val(git.Cred_Type.Userpass_Plaintext, allowed_types) {
        new_cred, err := git.cred_userpass_plaintext_new(settings.instance.username, settings.instance.password);
        if err != 0 {
            return FAILED;
        }
        cred^ = new_cred;
    } else if test_val(git.Cred_Type.Ssh_Key, allowed_types) {
        if settings.instance.use_ssh_agent {
            new_cred, err := git.cred_ssh_key_from_agent(string(cstring(username_from_url)));
            if err != git.Error_Code.Ok {
                return FAILED;
            }
            cred^ = new_cred;
        } else {
            return FAILED;   
        }
    } else {
        return ERR;
    }

    return SUCCESS;
}

agc_style :: proc() {
    style := imgui.get_style();

    style.window_padding        = imgui.Vec2{6, 6};
    style.window_rounding       = 0;
    style.child_rounding        = 2;
    style.frame_padding         = imgui.Vec2{4 ,2};
    style.frame_rounding        = 2;
    style.frame_border_size     = 1;
    style.item_spacing          = imgui.Vec2{8, 4};
    style.item_inner_spacing    = imgui.Vec2{4, 4};
    style.touch_extra_padding   = imgui.Vec2{0, 0};
    style.indent_spacing        = 20;
    style.scrollbar_size        = 12;
    style.scrollbar_rounding    = 9;
    style.grab_min_size         = 9;
    style.grab_rounding         = 1;
    style.window_title_align    = imgui.Vec2{0.48, 0.5};
    style.button_text_align     = imgui.Vec2{0.5, 0.5};

    style.colors[imgui.Color.Text]                  = imgui.Vec4{1.00, 1.00, 1.00, 1.00};
    style.colors[imgui.Color.TextDisabled]          = imgui.Vec4{0.63, 0.63, 0.63, 1.00};
    style.colors[imgui.Color.WindowBg]              = imgui.Vec4{0.23, 0.23, 0.23, 0.98};
    style.colors[imgui.Color.ChildBg]               = imgui.Vec4{0.20, 0.20, 0.20, 1.00};
    style.colors[imgui.Color.PopupBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.96};
    style.colors[imgui.Color.Border]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.colors[imgui.Color.BorderShadow]          = imgui.Vec4{0.00, 0.00, 0.00, 0.04};
    style.colors[imgui.Color.FrameBg]               = imgui.Vec4{0.00, 0.00, 0.00, 0.29};
    style.colors[imgui.Color.TitleBg]               = imgui.Vec4{32.0/255.00, 32.0/255.00, 32.0/255.00, 1};
    style.colors[imgui.Color.TitleBgCollapsed]      = imgui.Vec4{0.12, 0.12, 0.12, 0.49};
    style.colors[imgui.Color.TitleBgActive]         = imgui.Vec4{32.0/255.00, 32.0/255.00, 32.0/255.00, 1};
    style.colors[imgui.Color.MenuBarBg]             = imgui.Vec4{0.11, 0.11, 0.11, 0.42};
    style.colors[imgui.Color.ScrollbarBg]           = imgui.Vec4{0.00, 0.00, 0.00, 0.08};
    style.colors[imgui.Color.ScrollbarGrab]         = imgui.Vec4{0.27, 0.27, 0.27, 1.00};
    style.colors[imgui.Color.ScrollbarGrabHovered]  = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.Color.CheckMark]             = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.colors[imgui.Color.SliderGrab]            = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.colors[imgui.Color.Button]                = imgui.Vec4{0.42, 0.42, 0.42, 0.60};
    style.colors[imgui.Color.ButtonHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.Color.Header]                = imgui.Vec4{0.31, 0.31, 0.31, 0.98};
    style.colors[imgui.Color.HeaderHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.Color.HeaderActive]          = imgui.Vec4{0.80, 0.50, 0.50, 1.00};
    style.colors[imgui.Color.TextSelectedBg]        = imgui.Vec4{0.65, 0.35, 0.35, 0.26};
    style.colors[imgui.Color.ModalWindowDarkening]  = imgui.Vec4{0.20, 0.20, 0.20, 0.35};
}

open_repo :: proc(new_repo: ^git.Repository, using state : ^State) {
    if repo != nil {
        panic("CLOSE REPO BEFORE OPENING A NEW ONE");
    }

    // @todo(josh): does the return value of `repository_path` need to be freed?
    repo_path := git.repository_path(new_repo);

    // @todo(bpunsky): optimize with a buffer
    path := fmt.aprintf("%s/..", repo_path);
    defer free(path);

    full_path := pat.full(path);
    defer free(full_path);

    found := false;

    for s, i in settings.instance.recent_repos {
        if s == full_path {
            found = true;
            dyna_util.remove_ordered(&settings.instance.recent_repos, i);
            dyna_util.append_front(&settings.instance.recent_repos, strings.new_string(full_path));
            break;
        }
    }

    if !found {
        dyna_util.append_front(&settings.instance.recent_repos, strings.new_string(full_path));
    }

    repo = new_repo;
    open_repo_name = strings.new_string(full_path);
    oid, ok := git.reference_name_to_id(repo, "HEAD");
    if !log_if_err(ok) {
        com.free(&current_branch.current_commit);
        current_branch.current_commit = com.from_oid(repo, oid);
    }

    ref, err := git.repository_head(repo);
    if !log_if_err(err) {
        bname, err := git.branch_name(ref);
        refname := git.reference_name(ref);
        oid, ok := git.reference_name_to_id(repo, refname);
        commit := com.from_oid(repo, oid);
        upstream, _ := git.branch_upstream(ref);
        ahead, behind : uint;
        if upstream != nil {
            uid, _          := git.reference_name_to_id(repo, git.reference_name(upstream));
            ahead, behind, _ = git.graph_ahead_behind(repo, oid, uid);
        } 

        current_branch = brnch.Branch{
            ref,
            upstream,
            bname,
            git.Branch_Type.Local,
            commit,
            ahead,
            behind,
        };
    }

    local_branches = brnch.all_branches_from_repo(repo, git.Branch_Type.Local);
    remote_branches = brnch.all_branches_from_repo(repo, git.Branch_Type.Remote);

    options, _ := git.status_init_options();
    options.flags = git.Status_Opt_Flags.Include_Untracked;
    statuses, err = git.status_list_new(repo, &options);
    log_if_err(err);

    log.update(&git_log, repo, current_branch.ref);
    git_status.free(&status);
    git_status.update(repo, &status);

    //NOTE(Hoej): libgit2 only ignores .git not the files inside it... *sigh*
    git.ignore_add_rule(repo, ".git\\*");
}

init :: proc(using state : ^State) {
    time_data = misc.create_time_data();

    app_handle = misc.get_app_handle();
    wnd_handle = window.create_window(app_handle, "A Git Client", 1280, 720);
    gl_ctx     = wgl.create_gl_context(wnd_handle, 3, 3);

    gl.load_functions(set_proc, load_lib, free_lib);

    dear_state = new(imgui.State);
    imgui.init(dear_state, wnd_handle, agc_style, true);
    wgl.swap_interval(-1);
    gl.clear_color(0.10, 0.10, 0.10, 1);

    git.lib_version(&lib_ver_major, &lib_ver_minor, &lib_ver_rev);
    lib_ver_string = fmt.aprintf("libgit2 v%d.%d.%d",
                                  lib_ver_major, lib_ver_minor, lib_ver_rev);

    //git_status.status_refresh_timer = time_util.create_timer(2.5, true);
}

begin_frame :: proc(using state : ^State) {
    debug_reset();

    new_frame_state.mouse_wheel = 0;

    for msg.poll_message(&message) {
        switch msg in message {
            case msg.MsgQuitMessage : {
                running = false;
            }

            case msg.MsgChar : {
                imgui.gui_io_add_input_character(u16(msg.char));
            }

            case msg.MsgKey : {
                switch msg.key {
                    case input.VirtualKey.Escape : {
                        if msg.down && shift_down {
                            running = false;
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

    dt = misc.time(&time_data);
    new_frame_state.deltatime     = f32(dt);
    new_frame_state.mouse_x       = mpos_x;
    new_frame_state.mouse_y       = mpos_y;
    new_frame_state.window_width  = wnd_width;
    new_frame_state.window_height = wnd_height;
    new_frame_state.left_mouse    = lm_down;
    new_frame_state.right_mouse   = rm_down;

    gl.clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);
    imgui.begin_new_frame(&new_frame_state);
}

end_frame :: proc(using state : ^State) {
    io := imgui.get_io();
    if io.want_capture_mouse do set_cursor();
    imgui.render_proc(dear_state, true, wnd_width, wnd_height);
    window.swap_buffers(wnd_handle);
}

main_menu :: proc(using state : ^State) {
    open_set_signature := false;
    open_clone_menu    := false;
    open_set_user      := false;

    if imgui.begin_main_menu_bar() {
        defer imgui.end_main_menu_bar();

        if imgui.begin_menu("Menu") {
            defer imgui.end_menu();
            if imgui.menu_item("Clone...") {
                open_clone_menu = true;
            }

            if imgui.begin_menu("Recent Repos:", len(settings.instance.recent_repos) > 0) {
                defer imgui.end_menu();

                for s in settings.instance.recent_repos {
                    if imgui.menu_item(s) {
                        open_recent = true;
                        recent_repo = s;
                    }
                }
            }
            
            imgui.separator();
            if imgui.menu_item("Close", "Shift+ESC") {
                running = false;
            }
        }
        if imgui.begin_menu("Preferences") {
            defer imgui.end_menu();
            imgui.checkbox("Show Console", &draw_console);
            imgui.checkbox("Show Demo Window", &draw_demo_window);
            if imgui.checkbox("Use SSH Agent", &settings.instance.use_ssh_agent) {
                settings.save();
            }

            if imgui.menu_item("Set Signature") {
                open_set_signature = true;
            }

            if imgui.menu_item("Set User") {
                open_set_user = true;
            }

        }
        if imgui.begin_menu("Help") {
            defer imgui.end_menu();
            imgui.menu_item(label = "A Git Client v0.0.0a", enabled = false);
            imgui.menu_item(label = lib_ver_string, enabled = false);
        }
    }

    if open_set_signature {
        if len(settings.instance.username) > 0 do fmt.bprintf(name_buf[..], settings.instance.name);
                                 else do mem.zero(&name_buf[0], len(name_buf));
        if len(settings.instance.password) > 0 do fmt.bprintf(email_buf[..], settings.instance.email);
                                 else do mem.zero(&email_buf[0], len(email_buf));
        imgui.open_popup("Set Signature##modal");
    }

    if open_set_user {
        if len(settings.instance.username) > 0 do fmt.bprintf(username_buf[..], settings.instance.username);
                                 else do mem.zero(&username_buf[0], len(username_buf));
        if len(settings.instance.password) > 0 do fmt.bprintf(password_buf[..], settings.instance.password);
                                 else do mem.zero(&password_buf[0], len(password_buf));
        imgui.open_popup("Set User##modal");
    }

    if open_clone_menu {
        mem.zero(&clone_repo_url[0], len(clone_repo_url));
        mem.zero(&clone_repo_path[0], len(clone_repo_path));
        imgui.open_popup("Clone Repo##modal");
    }

    if imgui.begin_popup_modal("Clone Repo##modal", nil, imgui.Window_Flags.AlwaysAutoResize) {
        defer imgui.end_popup();
        imgui.input_text("URL", clone_repo_url[..]);
        imgui.input_text("Destination path", clone_repo_path[..]);
        
        if imgui.button("Clone", imgui.Vec2{160, 30}) {
            options, err := git.clone_init_options(1);
            if !log_if_err(err) {
                repo, err2 := git.clone(cast(string)clone_repo_url[..], cast(string)clone_repo_path[..], &options);
                if !log_if_err(err2) {
                    open_repo(repo, state);
                }
            }

            imgui.close_current_popup();
        }
        
        imgui.same_line();
        if imgui.button("Cancel", imgui.Vec2{160, 30}) {
            mem.zero(&clone_repo_url[0],  len(clone_repo_url));
            mem.zero(&clone_repo_path[0], len(clone_repo_path));
            imgui.close_current_popup();
        }
    }

    if imgui.begin_popup_modal("Set Signature##modal", nil, imgui.Window_Flags.AlwaysAutoResize) {
        defer imgui.end_popup();
        imgui.input_text("Name", name_buf[..]);
        imgui.input_text("Email", email_buf[..]);
        imgui.separator();
        if imgui.button("Save", imgui.Vec2{135, 30}) {
            { // Save settings
                name := string(cstring(&name_buf[0]));
                settings.instance.name = strings.new_string(name);
                email := string(cstring(&email_buf[0]));
                settings.instance.email = strings.new_string(email);
                settings.save();
            }
            mem.zero(&name_buf[0], len(name_buf));
            mem.zero(&email_buf[0], len(email_buf));
            imgui.close_current_popup();
        }
        imgui.same_line();
        if imgui.button("Cancel", imgui.Vec2{135, 30}) {
            mem.zero(&name_buf[0], len(name_buf));
            mem.zero(&email_buf[0], len(email_buf));
            imgui.close_current_popup();
        }
    }

    if imgui.begin_popup_modal("Set User##modal",      nil, imgui.Window_Flags.AlwaysAutoResize) {
        defer imgui.end_popup();
        imgui.input_text("Username", username_buf[..]);
        imgui.input_text("Password", password_buf[..], imgui.Input_Text_Flags.Password);
        imgui.separator();
        if imgui.button("Save", imgui.Vec2{135, 30}) {
            { // Save settings
                username := string(cstring(&username_buf[0]));
                settings.instance.username = strings.new_string(username);
                password := string(cstring(&password_buf[0]));
                settings.instance.password = strings.new_string(password);
                settings.save();
            }
            mem.zero(&username_buf[0], len(username_buf));
            mem.zero(&password_buf[0], len(password_buf));
            imgui.close_current_popup();
        }
        imgui.same_line();
        if imgui.button("Cancel", imgui.Vec2{135, 30}) {
            mem.zero(&username_buf[0], len(username_buf));
            mem.zero(&password_buf[0], len(password_buf));
            imgui.close_current_popup();
        }
    }
}

do_async_fetch :: proc(repo : ^git.Repository) {
    console.log("Starting Fetch...");
    _payload :: struct {
        repo : ^git.Repository,
    }
    p := new(_payload);
    p.repo = repo;

    Fetch_Thread_Proc :: proc(thread : ^thread.Thread) -> int {
        using p := cast(^_payload)thread.data;
        remote, ok := git.remote_lookup(repo, "origin");
        remote_cb, _  := git.remote_init_callbacks();
        remote_cb.credentials = credentials_callback;
        ok = git.remote_connect(remote, git.Direction.Fetch, &remote_cb, nil, nil);
        if !log_if_err(ok) {
            console.logf("Connected to %s", git.remote_name(remote));
            fetch_opt, _ := git.fetch_init_options();
            fetch_opt.callbacks = remote_cb;

            ok = git.remote_fetch(remote, nil, &fetch_opt);
            if !log_if_err(ok) {
                console.log("Fetch complete...");
            }
            git.free(remote);
        }
        free(p);
        return int(ok);
    }

    fetch_thread := thread.create(Fetch_Thread_Proc);
    fetch_thread.data = p;
    thread.start(fetch_thread);
}

do_async_push :: proc(repo : ^git.Repository, branches_to_push : []brnch.Branch) {
    console.log("Starting Push...");
    _payload :: struct {
        repo : ^git.Repository,
        branches : []brnch.Branch,
    }
    p := new(_payload);
    p.repo = repo;
    p.branches = branches_to_push;

    Push_Thread_Proc :: proc(thread : ^thread.Thread) -> int {
        using p := cast(^_payload)thread.data;
        remote, _ := git.remote_lookup(repo, "origin");
        remote_cb, _  := git.remote_init_callbacks();
        remote_cb.credentials = credentials_callback;
        ok := git.remote_connect(remote, git.Direction.Push, &remote_cb, nil, nil);
        if !log_if_err(ok) {
            console.logf("Connected to %s", git.remote_name(remote));
            refspec : [dynamic]string; defer free(refspec);
            for b in branches {
                refname := git.reference_name(b.ref);
                spec := fmt.aprintf("%s:%s", refname, refname);
                append(&refspec, spec);
            }

            opts, _ := git.push_init_options();
            remote_cb.push_transfer_progress = push_transfer_progress;
            remote_cb.payload = &tpayload;
            opts.callbacks = remote_cb;
            opts.pb_parallelism = 0;


            err := git.remote_push(remote, refspec[..], &opts);
            if !log_if_err(err) {
                console.log("Push Complete...");
            }
            git.free(remote);
            tpayload.done = true;
            free(p);
            return int(err);
        } else {
            free(p);
            return int(ok);
        }
    }
    
    push_thread := thread.create(Push_Thread_Proc);
    push_thread.data = p;
    thread.start(push_thread);
}

repo_window :: proc(using state : ^State) {
    open_push_transfer := false;

    imgui.set_next_window_pos(imgui.Vec2{250, 18});
    imgui.set_next_window_size(imgui.Vec2{410, f32(wnd_height-18)});
    if imgui.begin("Repo", nil, imgui.Window_Flags.NoResize |
                                imgui.Window_Flags.NoMove |
                                imgui.Window_Flags.NoCollapse |
                                imgui.Window_Flags.NoBringToFrontOnFocus) {
        defer imgui.end();
        if repo == nil {
            ok := imgui.input_text("Repo Path;", path_buf[..], imgui.Input_Text_Flags.EnterReturnsTrue);
            if imgui.button("Open") || ok || open_recent {
                path := string(cstring(&path_buf[0]));

                if open_recent {
                    path = recent_repo;
                }

                if git.is_repository(path) {
                    new_repo, err := git.repository_open(path);
                    if !log_if_err(err) {
                        open_repo(new_repo, state);
                    }
                } else {
                    console.logf_error("%s is not a repo", path);
                }

                open_recent = false;
            }
        } else {
            imgui.text("Repo: %s", open_repo_name); imgui.same_line();
            if imgui.button("Close Repo") {
                close_repo = true;
            } else {
                bname := git.reference_name(current_branch.ref);
                bid, _ := git.reference_name_to_id(repo, bname);

                if current_branch.upstream_ref != nil {
                    uname := git.reference_name(current_branch.upstream_ref);
                    uid, _ := git.reference_name_to_id(repo, uname);
                    
                    ahead, behind, _ := git.graph_ahead_behind(repo, bid, uid);
                    imgui.text("%d commits ahead upstream.", ahead);
                    imgui.text("%d commits behind upstream.", behind);

                    if ahead > 0 {
                        if imgui.button("Push") {
                            open_push_transfer = true;
                            do_async_push(repo, []brnch.Branch{current_branch});
                        }

                        imgui.same_line();
                    }
                }

                if imgui.button("Fetch" ) {
                    do_async_fetch(repo);
                }

                imgui.separator();

                git_status.window(dt, &status, repo, &state.diff_ctx);

                imgui.separator();
                commit_window(state);

                if imgui.button("Stash") {
                    // TODO(josh): Get the stashers real name and email
                    if sig, err := git.signature_now(current_branch.current_commit.committer.name,
                                                     current_branch.current_commit.committer.email); !log_if_err(err) {
                        // TODO(josh): Stash messages
                        // TODO(josh): Stash options
                        _, err = git.stash_save(repo, &sig, "temp message", git.Stash_Flags.Default);
                        log_if_err(err);
                    }
                }

                imgui.same_line();

                if imgui.button("Pop") {
                    opts, _ := git.stash_apply_init_options();
                    git.stash_pop(repo, 0, &opts);
                }
            }  
        }
    }

    if open_push_transfer {
        imgui.open_popup("Pushing...##push_transfer");
    }

    if imgui.begin_popup("Pushing...##push_transfer", /*nil, imgui.Window_Flags.AlwaysAutoResize*/) {
        defer imgui.end_popup();
        sync.mutex_lock(&push_lock);
        if(tpayload.done) {
            tpayload = TransferPayload{};
            imgui.close_current_popup();
        }
        size := imgui.Vec2{0,0};
        imgui.progress_bar(f32(tpayload.current)/f32(tpayload.total), &size);
        imgui.text("Sent: %d bytes", tpayload.bytes);
        sync.mutex_unlock(&push_lock);
    }

    if close_repo {
        git.free(repo);
        repo = nil;
        close_repo = false;
    }
}

commit_window :: proc(using state : ^State) {
    if len(status.staged) > 0 {
        imgui.text("Commit Message:");
        imgui.input_text          ("Summary", summary_buf[..]);
        imgui.input_text_multiline("Message", message_buf[..], imgui.Vec2{0, 100});

        if imgui.button("Commit") {
            // @note(bpunsky): do the commit!
            commit_msg := fmt.aprintf("%s\r\n%s", string(cstring(&summary_buf[0])), string(cstring(&message_buf[0])));
            defer _global.free(commit_msg);

            committer, _ := git.signature_now(settings.instance.name, settings.instance.email);
            author       := committer;

            // @note(bpunsky): copied from above, should probably be a switch to reload HEAD or something
            // NOTE(Hoej): When wouldn't you want the HEAD to advance when creating a new commit? You would go
            //             from being on a branch to being in a detached HEAD?
            if ref, err := git.repository_head(repo); !log_if_err(err) {
                refname := git.reference_name(ref);
                oid, ok := git.reference_name_to_id(repo, refname);
                commit := com.from_oid(repo, oid);

                if index, err := git.repository_index(repo); !log_if_err(err) {

                    if tree_id, err := git.index_write_tree(index); !log_if_err(err) {

                        if tree, err := git.object_lookup(repo, tree_id, git.Obj_Type.Tree); !log_if_err(err) {

                            if id, err := git.commit_create(repo, "HEAD", &author, &committer, commit_msg,
                                                            cast(^git.Tree) tree, commit.git_commit); !log_if_err(err) {
                                // @note(bpunsky): copied again!
                                if ref, err := git.repository_head(repo); !log_if_err(err) {
                                    bname, err := git.branch_name(ref);
                                    refname := git.reference_name(ref);
                                    oid, ok := git.reference_name_to_id(repo, refname);
                                    commit := com.from_oid(repo, oid);
                                    upstream, _ := git.branch_upstream(ref);
                                    current_branch = brnch.Branch{
                                        ref,
                                        upstream,
                                        bname,
                                        git.Branch_Type.Local,
                                        commit,
                                        0,
                                        0,
                                    };
                                }
                            }
                        }
                    }
                }
            }

            //NOTE(Hoej): Should probably be a mem.set
            summary_buf = [512+1]u8{};
            message_buf = [4096+1]u8{};
        }
        imgui.same_line();
    }
}

TransferPayload :: struct {
    current : uint, 
    total : uint, 
    bytes : uint,
    done := false,
}

tpayload := TransferPayload{};
push_lock : sync.Mutex;

push_transfer_progress :: proc "stdcall"(current : u32, total : u32, bytes : uint, payload : rawptr) -> i32 {
    sync.mutex_lock(&push_lock);
    {
        tp := (^TransferPayload)(payload);
        console.logf("Push Progress: %d/%d %d bytes", current, total, bytes);
        tp.current = uint(current); 
        tp.total = uint(total); 
        tp.bytes = bytes;
    }
    sync.mutex_unlock(&push_lock);
    return 0;
}

//////FIXME: SO BAD, FIX PL0X
MAKEINTRESOURCEA :: inline proc(i : u16) -> ^u8 {
    return (^u8)(rawptr(uintptr(int(u16(i)))));
}

set_cursor :: proc() {
    cur := imgui.get_mouse_cursor();
    using imgui;
    switch cur {
        case Mouse_Cursor.Arrow      : win32.set_cursor(window.IDC_ARROW);
        case Mouse_Cursor.TextInput  : win32.set_cursor(window.IDC_IBEAM);
        case Mouse_Cursor.ResizeNS   : win32.set_cursor(window.IDC_SIZENS);
        case Mouse_Cursor.ResizeEW   : win32.set_cursor(window.IDC_SIZEWE);
        case Mouse_Cursor.ResizeNESW : win32.set_cursor(window.IDC_SIZENESW);
        case Mouse_Cursor.ResizeNWSE : win32.set_cursor(window.IDC_SIZENWSE);
    }
}
///////

main :: proc() {
    settings.load();
    settings.save();
    defer settings.save();

    console.log("Program start...");
    console.add_default_commands();
    console.add_command("set_user", set_user);
    console.add_command("set_signature", set_signature);
    console.add_command("save_settings", settings.save_settings_cmd);
    console.add_command("load_settings", settings.load_settings_cmd);

    sync.mutex_init(&push_lock);

    state := State{};
    init(&state);

    git.lib_init();
    feature_set :: proc(test : git.Lib_Features, value : git.Lib_Features) -> bool {
        return test & value == test;
    }
    lib_features := git.lib_features();
    console.log("LibGit2 build config;");
    console.logf("\tLibGit2 is %s",
                 feature_set(git.Lib_Features.Threads, lib_features) ? "thread-safe." : "not thread-safe");
    console.logf("\tHttps is %s",
             feature_set(git.Lib_Features.Https, lib_features)       ? "supported."   : "not supported");
    console.logf("\tSSH is %s",
             feature_set(git.Lib_Features.Ssh, lib_features)         ? "supported."   : "not supported");
    console.logf("\tNsec is %s",
             feature_set(git.Lib_Features.Nsec, lib_features)        ? "supported."   : "not supported");

    _settings := debug_get_settings();
    _settings.print_location = true;
    debug_set_settings(_settings);

    state.credentials_cb = credentials_callback;

    state.running = true;

    for state.running {
        begin_frame(&state);
        main_menu(&state);

        repo_window(&state);
        brnch.window(&settings.instance, state.wnd_height,
                     state.repo, state.create_branch_name[..],
                     &state.current_branch, state.credentials_cb,
                     &state.local_branches, &state.remote_branches);
        log.window(&state.git_log, state.repo, state.current_branch.ref);

        if state.diff_ctx != nil {
            keep_open := true;
            diff_view.window(state.diff_ctx, &keep_open);
            if !keep_open {
                diff_view.free(state.diff_ctx);
                state.diff_ctx = nil;
            }
        }

        if state.draw_console {
            console.draw_console(&state.draw_console, &state.draw_log, &state.draw_history);
        }

        if state.draw_log {
            console.draw_log(&state.draw_log);
        }
        
        if state.draw_history {
            console.draw_history(&state.draw_history);
        }

        if state.draw_demo_window {
            imgui.show_demo_window(&state.draw_demo_window);
        }

        end_frame(&state);
    }

    git.lib_shutdown();
}
