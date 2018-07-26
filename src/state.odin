package main;

import "core:fmt";

import       "shared:libbrew/gl";
import sys   "shared:libbrew/sys";
import       "shared:libbrew/imgui";
import util  "shared:libbrew/util";
import git   "shared:odin-libgit2";

State :: struct {
    running            : bool,

    dt                 : f64,

    app_handle         : sys.AppHandle,
    wnd_handle         : sys.WndHandle,
    gl_ctx             : sys.Gl_Context,

    dear_state         : ^brew_imgui.State,

    message            : sys.Msg,
    wnd_width          : int,
    wnd_height         : int,
    shift_down         : bool,
    new_frame_state    : brew_imgui.FrameState,
    lm_down            : bool,
    rm_down            : bool,
    time_data          : sys.TimeData,
    mpos_x             : int,
    mpos_y             : int,
    draw_log           : bool,
    draw_history       : bool,
    draw_console       : bool,
    draw_demo_window   : bool,

    lib_ver_major      : i32,
    lib_ver_minor      : i32,
    lib_ver_rev        : i32,
    lib_ver_string     : string,

    close_repo         : bool,
    git_log            : Log,

    status             : Status,
    show_status_window : bool,


    open_recent        : bool,
    recent_repo        : string,

    credentials_cb     : git.Cred_Acquire_Cb,

    repo               : ^git.Repository,
    open_repo_name     : string,

    statuses           : ^git.Status_List,

    current_branch     : Branch,

    local_branches     : []Branch_Collection,
    remote_branches    : []Branch_Collection,

    diff_ctx           : ^DiffCtx,

    //NOTE(Hoej): See comment on State_Buffers for this.
    using buffers      : ^State_Buffers
}

//NOTE(Hoej): The reason the buffers are split into a seperate struct is because
// of a LLVM bug. The compile times skyrocket of these are inside the State struct.
// Until the Odin developers put a fix into the ir-gen, this is the workaround.
//                                                  - Hoej 2018 Jul 26
State_Buffers :: struct {
    username_buf       : [128+1]byte,
    password_buf       : [128+1]byte,

    name_buf           : [1024]byte,
    email_buf          : [255+1]byte,

    clone_repo_url     : [1024]byte,
    clone_repo_path    : [1024]byte,
    path_buf           : [255+1]byte,

    commit_hash_buf    : [1024]byte,

    create_branch_name : [1024]byte,
    summary_buf        : [512+1]byte,
    message_buf        : [1024+1]byte,
}

State_ctor :: proc() -> State {
    result : State;
    using result;
    diff_ctx     = nil;

    wnd_width    = 1280;
    wnd_height   = 720;
    draw_console = true;
    show_status_window  = true;

    time_data = sys.create_time_data();

    app_handle = sys.get_app_handle();
    wnd_handle = sys.create_window(app_handle, "A Git Client", 1280, 720);
    gl_ctx     = sys.create_gl_context(wnd_handle, 3, 3);

    gl.load_functions(set_proc, load_lib, free_lib);

    dear_state = new(brew_imgui.State);
    brew_imgui.init(dear_state, wnd_handle, agc_style, true);
    
    git.lib_version(&lib_ver_major, &lib_ver_minor, &lib_ver_rev);
    lib_ver_string = fmt.aprintf("libgit2 v%d.%d.%d",
                                  lib_ver_major, lib_ver_minor, lib_ver_rev);

    result.buffers = new(State_Buffers);

    return result;
}