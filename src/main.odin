/*
 *  @Name:     main
 *
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 00:59:20
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 21-12-2017 22:27:53 UTC+1
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
import       "shared:libbrew/time_util.odin";
import imgui "shared:libbrew/brew_imgui.odin";
import       "shared:libbrew/gl.odin";

import git     "libgit2.odin";
import console "console.odin";
using import _ "debug.odin";
import         "cel.odin";
import pat     "path.odin";

Log_Item :: struct {
    commit : Commit,
    time   : misc.Datetime,
}

Git_Log :: struct {
    items : [dynamic]Log_Item,
    count : int,
}

Commit :: struct {
    git_commit : ^git.Commit,
    author     : git.Signature,
    committer  : git.Signature,
    summary    : string,
    message    : string,
}

Branch :: struct {
    ref           : ^git.Reference,
    name          : string,
    btype         : git.Branch_Type,
    current_commit : Commit,
}

Branch_Collection :: struct {
    name     : string,
    branches : [dynamic]Branch,
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

SETTINGS_FILE :: "settings.cel";

Settings :: struct {
    username : string,
    password : string,

    name  : string,
    email : string,
}

settings := init_settings();

init_settings :: proc(username := "username", password := "password", name := "Jane Doe", email := "j.doe@example.com") -> Settings {
    return Settings {
        strings.new_string(username),
        strings.new_string(password),
        strings.new_string(name),
        strings.new_string(email),
    };
}

free_settings :: proc(settings : ^Settings) {
    free(settings.username);
    free(settings.password);
    free(settings.name);
    free(settings.email);
}

save_settings :: proc() {
    if cel.marshal_file(SETTINGS_FILE, settings) {
        console.log("settings saved.");
    } else {
        console.log_error("save_settings failed");
    }
}

load_settings :: proc() {
    tmp := settings;
    if cel.unmarshal_file(SETTINGS_FILE, settings) {
        free_settings(&tmp);
        console.log("settings loaded.");
    } else {
        settings = tmp;
        console.log_error("load_settings failed");
    }
}

save_settings_cmd :: proc(args : []string) {
    save_settings();
}

load_settings_cmd :: proc(args : []string) {
    load_settings();
}

set_user :: proc(args : []string) {
    if len(args) == 2 {
        free(settings.username);
        free(settings.password);

        settings.username = strings.new_string(args[0]);
        settings.password = strings.new_string(args[1]);

        save_settings();
    } else {
        console.log_error("You forgot to supply username AND password");
    }
}

set_signature :: proc(args : []string) {
    if len(args) == 2 {
        free(settings.name);
        free(settings.email);

        settings.name  = strings.new_string(args[0]);
        settings.email = strings.new_string(args[1]);

        save_settings();
    } else if len(args) == 3 {
        free(settings.name);
        free(settings.email);
        
        settings.name  = fmt.aprintf("%s %s", args[0], args[1]);
        settings.email = strings.new_string(args[2]);

        save_settings();
    } else {
        console.log_error("set_signature takes either two names and an email or one name and an email.");
    }
}

credentials_callback :: proc "stdcall" (cred : ^^git.Cred,  url : ^byte,
                              username_from_url : ^byte, allowed_types : git.Cred_Type, payload : rawptr) -> i32 {
    test_val :: proc(test : git.Cred_Type, value : git.Cred_Type) -> bool {
        return test & value == test;
    }
    if test_val(git.Cred_Type.Userpass_Plaintext, allowed_types) {
        new_cred, err := git.cred_userpass_plaintext_new(settings.username, settings.password);
        if err != 0 {
            return 1;
        }
        cred^ = new_cred;
    } else {
        return -1;
    }

    return 0;
}

get_all_branches :: proc(repo : ^git.Repository, btype : git.Branch_Type) -> []Branch_Collection {
    GIT_ITEROVER :: -31;
    result : [dynamic]Branch_Collection;
    iter, err := git.branch_iterator_new(repo, btype);
    over : i32 = 0;
    for over != GIT_ITEROVER {
        ref, btype, over := git.branch_next(iter);
        if over == GIT_ITEROVER do break;
        if !log_if_err(over) {
            name, suc := git.branch_name(ref);
            refname := git.reference_name(ref);
            oid, ok := git.reference_name_to_id(repo, refname);
            commit := get_commit(repo, oid);

            col_name, found := string_util.get_upto_first_from_file(name, '/');
            if !found {
                col_name = "";
            }
            col_found := false;
            for col, i in result {
                if col.name == col_name {
                    b := Branch {
                        ref,
                        name,
                        btype,
                        commit,
                    };
                    append(&result[i].branches, b);
                    col_found = true;
                }
            }

            if !col_found {
                col := Branch_Collection{};
                col.name = col_name;
                b := Branch {
                    ref,
                    name,
                    btype,
                    commit,
                };
                append(&col.branches, b);
                append(&result, col);
            }
        }
    }

    git.branch_iterator_free(iter);
    return result[..];
}

get_commit :: proc(repo : ^git.Repository, oid : git.Oid) -> Commit {
    result : Commit;
    err : i32;
    result.git_commit, err = git.commit_lookup(repo, &oid);
    if !log_if_err(err) {
        result.message  = git.commit_message(result.git_commit);
        result.summary  = git.commit_summary(result.git_commit);
        result.committer = git.commit_committer(result.git_commit);
        result.author   = git.commit_author(result.git_commit);
    }

    return result;
}

checkout_branch :: proc(repo : ^git.Repository, b : Branch) -> bool {
    obj, err := git.revparse_single(repo, b.name);
    if !log_if_err(err) {
        opts := git.Checkout_Options{};
        opts.version = 1;
        opts.disable_filters = 1; //NOTE(Hoej): User option later
        opts.checkout_strategy = git.Checkout_Strategy_Flags.Safe;
        err = git.checkout_tree(repo, obj, &opts);
        refname := git.reference_name(b.ref);
        if !log_if_err(err) {
            err = git.repository_set_head(repo, refname);
            if !log_if_err(err) {
                return true;
            } else {
                return false;
            }
        }
    }

    return false;
}

create_branch :: proc[create_branch_name, create_branch_branch];

create_branch_branch :: proc(repo : ^git.Repository, b : Branch, force := false) -> Branch {
    if b.btype == git.Branch_Type.Remote {
        b.name = string_util.remove_first_from_file(b.name, '/');
    }

    ref, err := git.branch_create(repo, b.name, b.current_commit.git_commit, force);
    if !log_if_err(err) {
        name, suc := git.branch_name(ref);
        refname := git.reference_name(ref);
        oid, ok := git.reference_name_to_id(repo, refname);
        commit := get_commit(repo, oid);
        b := Branch {
            ref,
            name,
            git.Branch_Type.Local,
            commit,
        };

        return b;
    }

    return Branch{};
}

create_branch_name :: proc(repo : ^git.Repository, name : string, target : Commit, force := false) -> Branch {
    ref, err := git.branch_create(repo, name, target.git_commit, force);
    if !log_if_err(err) {
        name, suc := git.branch_name(ref);
        refname := git.reference_name(ref);
        oid, ok := git.reference_name_to_id(repo, refname);
        commit := get_commit(repo, oid);
        b := Branch {
            ref,
            name,
            git.Branch_Type.Local,
            commit,
        };

        return b;
    }

    return Branch{};
}

free_commit :: proc(commit : ^Commit) {
    if commit.git_commit == nil do return;
    git.commit_free(commit.git_commit);
    commit.git_commit = nil;
}

Status :: struct {
    list             : ^git.Status_List,
    staged           : [dynamic]^git.Status_Entry,
    unstaged         : [dynamic]^git.Status_Entry,
    untracked        : [dynamic]^git.Status_Entry,
}

update_status :: proc(repo : ^git.Repository, status : ^Status) {
    if status.list == nil {
        options : git.Status_Options;
        git.status_init_options(&options, 1);
        options.flags = git.Status_Opt_Flags.Include_Untracked | git.Status_Opt_Flags.Recurse_Untracked_Dirs;
        err : i32;
        status.list, err = git.status_list_new(repo, &options);
        log_if_err(err);
    }

    assert(status.list != nil);

    count := git.status_list_entrycount(status.list);

    for i: uint = 0; i < count; i += 1 {
        if entry := git.status_byindex(status.list, i); entry != nil {
            if entry.head_to_index != nil {
                append(&status.staged, entry);
            }

            if entry.index_to_workdir != nil {
                if entry.index_to_workdir.status == git.Delta.Untracked {
                    repo_path := git.repository_path(repo);
                    rel_path  := strings.to_odin_string(entry.index_to_workdir.new_file.path);
                    
                    // @todo(bpunsky): optimize with a buffer
                    path := fmt.aprintf("%s/../%s", repo_path, rel_path);
                    defer free(path);
                    
                    if pat.is_file(path) {
                        append(&status.untracked, entry);
                    }
                } else { 
                    append(&status.unstaged, entry);
                }
            }
        }
    }
}

free_status :: proc(status : ^Status) {
    if status.list == nil do return;

    git.status_list_free(status.list);
    clear(&status.staged);
    clear(&status.unstaged);
    clear(&status.untracked);

    status.list = nil;
}

agc_style :: proc() {
    style := imgui.get_style();

    style.window_padding        = imgui.Vec2{6, 6};
    style.window_rounding       = 0;
    style.child_window_rounding = 2;
    style.frame_padding         = imgui.Vec2{4 ,2};
    style.frame_rounding        = 2;
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
    style.colors[imgui.Color.ChildWindowBg]         = imgui.Vec4{0.20, 0.20, 0.20, 1.00};
    style.colors[imgui.Color.PopupBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.96};
    style.colors[imgui.Color.Border]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.colors[imgui.Color.BorderShadow]          = imgui.Vec4{0.00, 0.00, 0.00, 0.04};
    style.colors[imgui.Color.FrameBg]               = imgui.Vec4{0.00, 0.00, 0.00, 0.29};
    style.colors[imgui.Color.TitleBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.98};
    style.colors[imgui.Color.TitleBgCollapsed]      = imgui.Vec4{0.12, 0.12, 0.12, 0.49};
    style.colors[imgui.Color.TitleBgActive]         = imgui.Vec4{0.33, 0.33, 0.33, 0.98};
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

main :: proc() {
    console.log("Program start...");
    console.add_default_commands();
    console.add_command("set_user", set_user);
    console.add_command("set_signature", set_signature);
    console.add_command("save_settings", save_settings_cmd);
    console.add_command("load_settings", load_settings_cmd);

    app_handle := misc.get_app_handle();
    wnd_handle := window.create_window(app_handle, "A Git Client", false, 1280, 720);
    gl_ctx     := wgl.create_gl_context(wnd_handle, 3, 3);

    gl.load_functions(set_proc, load_lib, free_lib);

    dear_state := new(imgui.State);
    imgui.init(dear_state, wnd_handle, agc_style);
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

    current_branch     : Branch;
    commit_hash_buf    : [1024]byte;

    create_branch_name  : [1024]byte;
    checkout_new_branch := true;

    local_branches     : []Branch_Collection;
    remote_branches    : []Branch_Collection;

    close_repo         := false;
    git_log            := Git_Log{};

    status             :  Status;
    show_status_window := true;

    status_refresh_timer := time_util.create_timer(1, true);

    to_stage           : [dynamic]^git.Status_Entry;
    to_unstage         : [dynamic]^git.Status_Entry;

    summary_buf        : [512+1]byte;
    message_buf        : [4096+1]byte;

    username_buf       : [1024]byte;
    password_buf       : [1024]byte;
    
    name_buf           : [1024]byte;
    email_buf          : [1024]byte;

    test : string;

    load_settings();
    save_settings();
    defer save_settings();

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

    _settings := debug_get_settings();
    _settings.print_location = true;
    debug_set_settings(_settings);

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
            open_set_signature := false;
            open_set_user      := false;

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
                    
                    if imgui.menu_item("Set Signature") {
                        open_set_signature = true;
                    }

                    if imgui.menu_item("Set User") {
                        open_set_user = true;
                    }
                    
                    imgui.end_menu();
                }
                if imgui.begin_menu("Help") {
                    imgui.menu_item(label = "A Git Client v0.0.0a", enabled = false);
                    imgui.menu_item(label = lib_ver_string, enabled = false);
                    imgui.end_menu();
                }
            }

            if open_set_signature {
                fmt.bprintf(name_buf[..], settings.name);
                fmt.bprintf(email_buf[..], settings.email);
                imgui.open_popup("set_signature_modal");
            }

            if open_set_user {
                fmt.bprintf(username_buf[..], settings.username);
                fmt.bprintf(password_buf[..], settings.password);
                imgui.open_popup("set_user_modal");
            }

            if imgui.begin_popup_modal("set_signature_modal", nil, imgui.WindowFlags.AlwaysAutoResize) {
                defer imgui.end_popup();
                imgui.input_text("Name", name_buf[..]);
                imgui.input_text("Email", email_buf[..]);
                imgui.separator();
                if imgui.button("Save", imgui.Vec2{135, 0}) {
                    { // Save settings
                        name := strings.to_odin_string(&name_buf[0]);
                        settings.name = strings.new_string(name);
                        email := strings.to_odin_string(&email_buf[0]);
                        settings.email = strings.new_string(email);
                        save_settings();
                    }
                    name_buf = [1024]u8{};
                    email_buf = [1024]u8{};
                    imgui.close_current_popup();
                }
                imgui.same_line();
                if imgui.button("Cancel", imgui.Vec2{135, 0}) {
                    name_buf = [1024]u8{};
                    email_buf = [1024]u8{};
                    imgui.close_current_popup();
                }
            } 

            if imgui.begin_popup_modal("set_user_modal",      nil, imgui.WindowFlags.AlwaysAutoResize) {
                defer imgui.end_popup();
                imgui.input_text("Username", username_buf[..]);
                imgui.input_text("Password", password_buf[..], imgui.InputTextFlags.Password);
                imgui.separator();
                if imgui.button("Save", imgui.Vec2{135, 0}) {
                    { // Save settings
                        username := strings.to_odin_string(&username_buf[0]);
                        settings.username = strings.new_string(username);
                        password := strings.to_odin_string(&password_buf[0]);
                        settings.password = strings.new_string(password);
                        save_settings();
                    }
                    username_buf = [1024]u8{};
                    password_buf = [1024]u8{};
                    imgui.close_current_popup();
                }
                imgui.same_line();
                if imgui.button("Cancel", imgui.Vec2{135, 0}) {
                    username_buf = [1024]u8{};
                    password_buf = [1024]u8{};
                    imgui.close_current_popup();
                }
            }

            imgui.set_next_window_pos(imgui.Vec2{160, 18});
            imgui.set_next_window_size(imgui.Vec2{500, f32(wnd_height-18)});
            if imgui.begin("Repo", nil, imgui.WindowFlags.NoResize |
                                        imgui.WindowFlags.NoMove |
                                        imgui.WindowFlags.NoCollapse |
                                        imgui.WindowFlags.NoBringToFrontOnFocus) {
                defer imgui.end();
                if repo == nil {
                    ok := imgui.input_text("Repo Path;", path_buf[..], imgui.InputTextFlags.EnterReturnsTrue);
                    if imgui.button("Open") || ok {
                        path := strings.to_odin_string(&path_buf[0]);
                        if git.is_repository(path) {
                            new_repo, err := git.repository_open(path);
                            if !log_if_err(err) {
                                repo = new_repo;
                                open_repo_name = strings.new_string(path);
                                oid, ok := git.reference_name_to_id(repo, "HEAD");
                                if !log_if_err(ok) {
                                    free_commit(&current_branch.current_commit);
                                    current_branch.current_commit = get_commit(repo, oid);
                                }

                                ref, err := git.repository_head(repo);
                                if !log_if_err(err) {
                                    bname, err := git.branch_name(ref);
                                    refname := git.reference_name(ref);
                                    oid, ok := git.reference_name_to_id(repo, refname);
                                    commit := get_commit(repo, oid);
                                    current_branch = Branch{
                                        ref,
                                        bname,
                                        git.Branch_Type.Local,
                                        commit,
                                    };
                                }

                                local_branches = get_all_branches(repo, git.Branch_Type.Local);
                                remote_branches = get_all_branches(repo, git.Branch_Type.Remote);

                                options : git.Status_Options;
                                git.status_init_options(&options, 1);
                                options.flags = git.Status_Opt_Flags.Include_Untracked;
                                statuses, err = git.status_list_new(repo, &options);
                                log_if_err(err);
                            }

                        } else {
                            console.logf_error("%s is not a repo", path);
                        }
                    }
                } else {
                    imgui.text("Repo: %s", open_repo_name); imgui.same_line();
                    if imgui.button("Close Repo") {
                        close_repo = true;
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

                        /*imgui.input_text("Commit Hash;", commit_hash_buf[..]);
                        if imgui.button("Lookup") {
                            if repo != nil {
                                oid_str := cast(string)commit_hash_buf[..];
                                oid: git.Oid;
                                ok := git.oid_from_str(&oid, &oid_str[0]);
                                if !log_if_err(ok) {
                                    free_commit(&current_branch.current_commit);
                                    current_branch.current_commit = get_commit(repo, oid);
                                }
                            }
                            else {
                                console.log_error("You haven't opened a repo yet!");
                            }
                        }*/

                        imgui.separator();

                        if imgui.button("Status") {
                            if show_status_window {
                                show_status_window = false;
                                free_status(&status);
                            } else {
                                show_status_window = true;
                                time_util.reset(&status_refresh_timer);
                                update_status(repo, &status);
                            }
                        }

                        if show_status_window {
                            if time_util.query(&status_refresh_timer, dt) {
                                free_status(&status);
                                update_status(repo, &status);
                            }

                            imgui.text("Staged files:");
                            if imgui.begin_child("Staged", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 3, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{0, 1, 0, 1});

                                for entry, i in status.staged {
                                    imgui.set_column_width(-1, 60);
                                    imgui.push_id(i);
                                    if imgui.button("unstage") do append(&to_unstage, entry);
                                    imgui.pop_id();
                                    imgui.next_column();
                                    imgui.set_column_width(-1, 100);
                                    imgui.text("%v", entry.head_to_index.status);
                                    imgui.next_column();
                                    imgui.text(strings.to_odin_string(entry.head_to_index.new_file.path));
                                    imgui.next_column();
                                }

                                imgui.pop_style_color();
                            }
                            imgui.end_child();

                            imgui.text("Unstaged files:");
                            if imgui.begin_child("Unstaged", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 3, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});

                                for entry, i in status.unstaged {
                                    imgui.set_column_width(-1, 60);
                                    imgui.push_id(i);
                                    if imgui.button("stage") do append(&to_stage, entry);
                                    imgui.pop_id();
                                    imgui.next_column();
                                    imgui.set_column_width(-1, 100);
                                    imgui.text("%v", entry.index_to_workdir.status);
                                    imgui.next_column();
                                    imgui.text(strings.to_odin_string(entry.index_to_workdir.new_file.path));
                                    imgui.next_column();
                                }

                                imgui.pop_style_color();
                            }
                            imgui.end_child();

                            imgui.text("Untracked files:");
                            if imgui.begin_child("Untracked", imgui.Vec2{0, 100}) {
                                imgui.columns(count = 3, border = false);
                                imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});

                                for entry, i in status.untracked {
                                    imgui.set_column_width(-1, 60);
                                    imgui.push_id(i);
                                    if imgui.button("stage") do append(&to_stage, entry);
                                    imgui.pop_id();
                                    imgui.next_column();
                                    imgui.set_column_width(-1, 100);
                                    imgui.text("%v", entry.index_to_workdir.status);
                                    imgui.next_column();
                                    imgui.text(strings.to_odin_string(entry.index_to_workdir.new_file.path));
                                    imgui.next_column();
                                }

                                imgui.pop_style_color();
                            }
                            imgui.end_child();

                            if len(to_stage) > 0 || len(to_unstage) > 0 {
                                time_util.fill(&status_refresh_timer);

                                if index, err := git.repository_index(repo); !log_if_err(err) {
                                    for entry in to_stage {
                                        err := git.index_add_bypath(index, strings.to_odin_string(entry.index_to_workdir.new_file.path));
                                        log_if_err(err);
                                    }

                                    for entry in to_unstage {
                                        if head, err := git.repository_head(repo); !log_if_err(err) {
                                            defer git.reference_free(head);

                                            if head_commit, err := git.reference_peel(head, git.Otype.Commit); !log_if_err(err) {
                                                defer git.object_free(head_commit);
                                                path := entry.head_to_index.new_file.path;
                                                stra := git.Str_Array{&path, 1};
                                                err = git.reset_default(repo, head_commit, &stra);
                                                log_if_err(err);
                                            }
                                        }
                                    }

                                    err = git.index_write(index);
                                    log_if_err(err);
                                }
                            }

                            clear(&to_stage);
                            clear(&to_unstage);

                            imgui.separator();

                            imgui.text("Commit Message:");
                            imgui.input_text          ("Summary", summary_buf[..]);
                            imgui.input_text_multiline("Message", message_buf[..], imgui.Vec2{0, 100});

                            if imgui.button("Commit") {
                                // @note(bpunsky): do the commit!
                                commit_msg := fmt.aprintf("%s\r\n%s", strings.to_odin_string(&summary_buf[0]), strings.to_odin_string(&message_buf[0]));
                                defer free(commit_msg);

                                committer, _ := git.signature_now(settings.name, settings.email);
                                author       := committer;

                                // @note(bpunsky): copied from above, should probably be a switch to reload HEAD or something
                                if ref, err := git.repository_head(repo); !log_if_err(err) {
                                    refname := git.reference_name(ref);
                                    oid, ok := git.reference_name_to_id(repo, refname);
                                    commit := get_commit(repo, oid);

                                    if index, err := git.repository_index(repo); !log_if_err(err) {
                                        if tree_id, err := git.index_write_tree(index); !log_if_err(err) {
                                            if tree, err := git.object_lookup(repo, tree_id, git.Otype.Tree); !log_if_err(err) {
                                                if id, err := git.commit_create(repo, "HEAD", &author, &committer, commit_msg,
                                                                                cast(^git.Tree) tree, commit.git_commit); !log_if_err(err) {
                                                    // @note(bpunsky): copied again!
                                                    if ref, err := git.repository_head(repo); !log_if_err(err) {
                                                        bname, err := git.branch_name(ref);
                                                        refname := git.reference_name(ref);
                                                        oid, ok := git.reference_name_to_id(repo, refname);
                                                        commit := get_commit(repo, oid);
                                                        current_branch = Branch{
                                                            ref,
                                                            bname,
                                                            git.Branch_Type.Local,
                                                            commit,
                                                        };
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            imgui.same_line();

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
                                opts : git.Stash_Apply_Options;
                                git.stash_apply_init_options(&opts, 1);
                                git.stash_pop(repo, 0, &opts);
                            }
                        }
                    }

                    update_branches := false;
                    open_create_modal := false;
                    imgui.set_next_window_pos(imgui.Vec2{0, 18});
                    imgui.set_next_window_size(imgui.Vec2{160, f32(wnd_height-18)});
                    if imgui.begin("Branches", nil, imgui.WindowFlags.NoResize |
                                                    imgui.WindowFlags.NoMove |
                                                    imgui.WindowFlags.NoCollapse |
                                                    imgui.WindowFlags.MenuBar |
                                                    imgui.WindowFlags.NoBringToFrontOnFocus) {
                        defer imgui.end();
                        if imgui.begin_menu_bar() {
                            defer imgui.end_menu_bar();
                            if imgui.begin_menu("Misc") {
                                defer imgui.end_menu();
                                if imgui.menu_item("Update") {
                                    update_branches = true;
                                }

                                if imgui.menu_item("Create branch") {
                                    open_create_modal = true;
                                }
                            }
                        }


                        if open_create_modal {
                            imgui.open_popup("Create Branch###create_branch_modal");
                        }

                        if imgui.begin_popup_modal("Create Branch###create_branch_modal", nil, imgui.WindowFlags.AlwaysAutoResize) {
                            defer imgui.end_popup();
                            imgui.text("Branch name:"); imgui.same_line();
                            imgui.input_text("", create_branch_name[..]);
                            imgui.checkbox("Checkout new branch?", &checkout_new_branch);
                            imgui.separator();
                            if imgui.button("Create", imgui.Vec2{160, 0}) {
                                branch_name_str := cast(string)create_branch_name[..];
                                b := create_branch(repo, branch_name_str, current_branch.current_commit);
                                if checkout_new_branch {
                                    checkout_branch(repo, b);
                                }
                                update_branches = true;
                                create_branch_name = [1024]u8{};
                                imgui.close_current_popup();
                            }
                            imgui.same_line();
                            if imgui.button("Cancel", imgui.Vec2{160, 0}) {
                                create_branch_name = [1024]u8{};
                                imgui.close_current_popup();
                            }
                        }

                        pos := imgui.get_window_pos();
                        size := imgui.get_window_size();

                        print_branches :: proc(repo : ^git.Repository, branches : []Branch, update_branches : ^bool, curb : ^Branch) {
                            branch_to_delete: Branch;
                            for b in branches {
                                is_current_branch := git.reference_is_branch(b.ref) && git.branch_is_checked_out(b.ref);
                                imgui.selectable(b.name, is_current_branch);
                                if imgui.is_item_clicked(0) && imgui.is_mouse_double_clicked(0) {
                                    if checkout_branch(repo, b) {
                                        update_branches^ = true;
                                        curb^ = b;
                                    }
                                }
                                imgui.push_id(b.name);
                                defer imgui.pop_id();


                                if !is_current_branch {
                                    if imgui.begin_popup_context_item("branch_context", 1) {
                                        defer imgui.end_popup();
                                        if imgui.selectable("Checkout") {
                                            if checkout_branch(repo, b) {
                                                update_branches^ = true;
                                                curb^ = b;
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
                        imgui.set_next_tree_node_open(true, imgui.SetCond.Once);
                        if imgui.tree_node("Local Branches:") {
                            defer imgui.tree_pop();
                            imgui.push_style_color(imgui.Color.Text, imgui.Vec4{0, 1, 0, 1});
                            for col in local_branches {
                                if col.name == "" {
                                    print_branches(repo, col.branches[..], &update_branches, &current_branch);
                                } else {
                                    imgui.set_next_tree_node_open(true, imgui.SetCond.Once);
                                    if imgui.tree_node(col.name) {
                                        defer imgui.tree_pop();
                                        imgui.indent(5);
                                        print_branches(repo, col.branches[..], &update_branches, &current_branch);
                                        imgui.unindent(5);
                                    }
                                }
                            }
                            imgui.pop_style_color();
                        }

                        imgui.set_next_tree_node_open(true, imgui.SetCond.Once);
                        if imgui.tree_node("Remote Branches:") {
                            defer imgui.tree_pop();
                            imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});
                            for col in remote_branches[..] {
                                if col.name == "origin" {
                                    imgui.set_next_tree_node_open(true, imgui.SetCond.Once);
                                }
                                if imgui.tree_node(col.name) {
                                    defer imgui.tree_pop();
                                    imgui.indent(5);
                                    for b in col.branches {
                                        if b.name == "origin/HEAD" do continue;
                                        imgui.selectable(b.name);
                                        imgui.push_id(git.reference_name(b.ref));
                                        defer imgui.pop_id();
                                        if imgui.begin_popup_context_item("branch_context", 1) {
                                            defer imgui.end_popup();
                                            if imgui.selectable("Checkout") {
                                                branch := create_branch(repo, b);
                                                if checkout_branch(repo, branch) {
                                                    update_branches = true;
                                                    current_branch = branch;
                                                }
                                            }
                                        }
                                    }
                                    imgui.unindent(5);
                                }
                            }
                            imgui.pop_style_color();
                        }
                    }

                    if update_branches {
                        local_branches = get_all_branches(repo, git.Branch_Type.Local);
                        remote_branches = get_all_branches(repo, git.Branch_Type.Remote);
                    }
                    commit_count := 0;
                    if imgui.begin("Log") {
                        defer imgui.end();
                        if imgui.begin_child("gitlog", imgui.Vec2{0, -25}) {
                            defer imgui.end_child();
                            for item in git_log.items {
                                imgui.text_colored(imgui.Vec4{0.60, 0.60, 0.60, 1.00}, "%v <%v> | %d/%d/%d %2d:%2d:%2d UTC%s%d",
                                           item.commit.author.name,
                                           item.commit.author.email,
                                           item.time.day,
                                           item.time.month,
                                           item.time.year,
                                           item.time.hour,
                                           item.time.minute,
                                           item.time.second,
                                           item.commit.author.time_when.offset < 0 ? "" : "+",
                                           item.commit.author.time_when.offset/60);

                                imgui.indent();
                                imgui.selectable(item.commit.summary);
                                if imgui.is_item_hovered() {
                                    imgui.begin_tooltip();
                                    imgui.text(item.commit.message);
                                    imgui.end_tooltip();
                                }
                                imgui.unindent();
                                imgui.separator();
                            }
                        }

                        imgui.separator();
                        imgui.text_colored(imgui.Vec4{1, 1, 1, 0.2}, "Commits: %d", git_log.count); imgui.same_line();
                        if imgui.button("Update") {
                            clear(&git_log.items);
                            git_log.count = 0;
                            GIT_ITEROVER :: -31;
                            walker, err := git.revwalk_new(repo);
                            if !log_if_err(err) {
                                err = git.revwalk_push_ref(walker, git.reference_name(current_branch.ref));
                                log_if_err(err);
                            }

                            for {
                                id, err := git.revwalk_next(walker);
                                if err == GIT_ITEROVER {
                                    break;
                                }
                                commit_count += 1;
                                commit := get_commit(repo, id);
                                time := misc.unix_to_datetime(int(commit.author.time_when.time + i64(commit.author.time_when.offset) * 60));

                                item := Log_Item{
                                    commit,
                                    time,
                                };

                                append(&git_log.items, item);
                                git_log.count += 1;
                            }
                            git.revwalk_free(walker);
                        }
                    }
                }
            }

            if close_repo {
                //FIXME(Hoej): Runtime crash for some reason??
                /*for col in local_branches {
                    free(col.branches);
                }

                for col in remote_branches {
                    free(col.branches);
                }
                free(local_branches);
                free(remote_branches);*/
                git.repository_free(repo);
                repo = nil;
                close_repo = false;
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
