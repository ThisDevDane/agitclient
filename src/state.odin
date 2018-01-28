import misc  "shared:libbrew/win/misc.odin";
import       "shared:libbrew/win/window.odin";
import       "shared:libbrew/win/msg.odin";
import wgl   "shared:libbrew/win/opengl.odin";

import imgui "shared:libbrew/brew_imgui.odin";
import       "shared:libbrew/time_util.odin";

import git "libgit2.odin";
import     "log.odin";
import brnch "branch.odin";
import git_status "status.odin";

State :: struct {
    running              := false,

    dt                   :  f64,

    app_handle           :  misc.AppHandle,
    wnd_handle           :  window.WndHandle,
    gl_ctx               :  wgl.GlContext,

    dear_state           :  ^imgui.State,

    message              :  msg.Msg,
    wnd_width            := 1280,
    wnd_height           := 720,
    shift_down           := false,
    new_frame_state      := imgui.FrameState{},
    lm_down              := false,
    rm_down              := false,
    time_data            :  misc.TimeData,
    mpos_x               := 0,
    mpos_y               := 0,
    draw_log             := false,
    draw_history         := false,
    draw_console         := true,
    draw_demo_window     := false,

    lib_ver_major        :  i32,
    lib_ver_minor        :  i32,
    lib_ver_rev          :  i32,
    lib_ver_string       :  string,

    path_buf             :  [255+1]byte,

    commit_hash_buf      :  [1024]byte,

    create_branch_name   :  [1024]byte,

    close_repo           := false,
    git_log              := log.Log{},

    status               :  git_status.Status,
    show_status_window   := true,

    username_buf         :  [1024]byte,
    password_buf         :  [1024]byte,

    name_buf             :  [1024]byte,
    email_buf            :  [1024]byte,

    clone_repo_url       :  [1024]byte,
    clone_repo_path      :  [1024]byte,

    open_recent          := false,
    recent_repo          :  string,

    credentials_cb       : git.Cred_Acquire_Cb,

    repo                 : ^git.Repository,
    open_repo_name       : string,

    statuses             : ^git.Status_List,

    current_branch       : brnch.Branch,

    local_branches       : []brnch.Branch_Collection,
    remote_branches      : []brnch.Branch_Collection,

    summary_buf : [512+1]byte,
    message_buf : [4096+1]byte,
}