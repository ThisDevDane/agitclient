/*
 *  @Name:     status
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 13-02-2018 14:26:12 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 22-02-2018 14:22:37 UTC+1
 *  
 *  @Description:
 *  
 */

using import _ "debug.odin";

import "core:thread.odin";
import "core:sync.odin";
import "core:strings.odin";
import "core:fmt.odin";
import win32 "core:sys/windows.odin";

import         "shared:libbrew/sys/misc.odin";
import         "shared:libbrew/time_util.odin";
import         "shared:libbrew/string_util.odin";
import imgui   "shared:libbrew/brew_imgui.odin";
import console "shared:libbrew/imgui_console.odin";

import git "libgit2.odin";
import pat "path.odin";
import     "color.odin";
import     "diff_view.odin";

Status :: struct {
    staged    : [dynamic]Status_Entry,
    unstaged  : [dynamic]Status_Entry,
    untracked : [dynamic]Status_Entry,

    diff      : ^git.Diff,

    _notify_thread : ^thread.Thread,
}

Status_Delta :: enum u32 {
    Unmodified =  0,
    Added      =  1,
    Deleted    =  2,
    Modified   =  3,
    Renamed    =  4,
    Copied     =  5,
    Ignored    =  6,
    Untracked  =  7,
    Typechange =  8,
    Unreadable =  9,
    Conflicted = 10,
}

Status_Entry :: struct {
    path   : string
    status : Status_Delta,
    _git   : ^git.Status_Entry,
}

//TODO(Hoej): Move this out of global.
mutex_setup := false;
update_mutex : sync.Mutex;
do_update := false;

update :: proc(repo : ^git.Repository, status : ^Status) {
    console.log("(Status) Updating...");

    clear(&status.staged);
    clear(&status.unstaged);
    clear(&status.untracked);

    options, _ := git.status_init_options();
    options.flags = git.Status_Opt_Flags.Include_Untracked | git.Status_Opt_Flags.Recurse_Untracked_Dirs;
    status_list, err := git.status_list_new(repo, &options);
    log_if_err(err);

    assert(status_list != nil);

    count := git.status_list_entrycount(status_list);

    for i: uint = 0; i < count; i += 1 {
        if entry := git.status_byindex(status_list, i); entry != nil {
            if entry.head_to_index != nil {
                append(&status.staged, Status_Entry{
                    strings.to_odin_string(entry.head_to_index.new_file.path), 
                    Status_Delta(entry.head_to_index.status),
                    entry});
            }

            if entry.index_to_workdir != nil {
                if entry.index_to_workdir.status == git.Delta.Untracked {
                    append(&status.untracked, Status_Entry{
                        strings.to_odin_string(entry.index_to_workdir.new_file.path), 
                        Status_Delta(entry.index_to_workdir.status),
                        entry});

                    //NOTE(Hoej): What was all this for???
                        /*repo_path := git.repository_path(repo);
                        rel_path  := strings.to_odin_string(entry.index_to_workdir.new_file.path);

                        // @todo(bpunsky): optimize with a buffer
                        path := fmt.aprintf("%s/../%s", repo_path, rel_path);
                        defer _global.free(path);

                        if pat.is_file(path) {
                            append(&status.untracked, entry);
                        }*/
                } else {
                    append(&status.unstaged, Status_Entry{
                        strings.to_odin_string(entry.index_to_workdir.new_file.path), 
                        Status_Delta(entry.index_to_workdir.status),
                        entry});
                }
            }
        }
    }

    //ROBUSTNESS(Hoej): Error checking
    git.free(status.diff);
    opt, _ := git.diff_init_options();
    status.diff, _ = git.diff_index_to_workdir(repo, nil, &opt);

    //NOTE(Hoej): Set up notficication thread
    //ROBUSTNESS(Hoej): Error checking
    if !mutex_setup {
        sync.mutex_init(&update_mutex);
        mutex_setup = true;
    }

    if status._notify_thread == nil {
        c_str := misc.odin_to_wchar_string(git.repository_workdir(repo));
        dirh := win32.create_file_w(c_str, win32.FILE_GENERIC_READ, win32.FILE_SHARE_READ | win32.FILE_SHARE_DELETE | win32.FILE_SHARE_WRITE, nil, 
                                    win32.OPEN_EXISTING, win32.FILE_FLAG_BACKUP_SEMANTICS, nil);
        if dirh == win32.INVALID_HANDLE {
            return;
        }
    
        _payload :: struct {
            dir_handle : win32.Handle,
            buf        : rawptr,
            buf_len    : u32,
            mtx        : ^sync.Mutex,
            repo       : ^git.Repository,
        }
    
        p := new(_payload);
        p.dir_handle = dirh;
        p.buf_len = size_of(win32.File_Notify_Information) * 32;
        p.buf = alloc(int(p.buf_len));
        p.mtx = &update_mutex;
        p.repo = repo;
    
        _proc :: proc(thread : ^thread.Thread) -> int {
            next_entry :: proc(c : ^win32.File_Notify_Information) -> ^win32.File_Notify_Information {
                if c.next_entry_offset == 0 {
                    return nil;
                } else {
                    return cast(^win32.File_Notify_Information)(cast(^byte)c + c.next_entry_offset);
                }
            }

            using p := cast(^_payload)thread.data;
            for {
                out : u32; //NOTE(Hoej): read_directory_changes_w crashes without this. Even though the param is optional.
                ok := win32.read_directory_changes_w(dir_handle, buf, buf_len, true,
                                                     win32.FILE_NOTIFY_CHANGE_LAST_WRITE | 
                                                     win32.FILE_NOTIFY_CHANGE_FILE_NAME | 
                                                     win32.FILE_NOTIFY_CHANGE_CREATION | 
                                                     win32.FILE_NOTIFY_CHANGE_DIR_NAME, 
                                                     &out, nil, nil);
                
                if ok {
                    c := cast(^win32.File_Notify_Information)buf;
                    for c != nil {
                        dos_name := misc.wchar_to_odin_string(&c.file_name[0], i32(c.file_name_length / size_of(u16))); defer _global.free(dos_name);
                        name := string_util.replace(dos_name, '\\', '/'); defer _global.free(name);
                        if ignored, _ := git.ignore_path_is_ignored(repo, name); ignored {
                            c = next_entry(c);
                            continue;
                        }

                        switch c.action {
                            case win32.FILE_ACTION_ADDED : {
                                console.logf("(Thread %d) %s was added.", 
                                             thread.specific.win32_thread_id, 
                                             name);
                            }
                            case win32.FILE_ACTION_REMOVED : {
                                console.logf("(Thread %d) %s was removed.", 
                                             thread.specific.win32_thread_id, 
                                             name);
                            }
                            case win32.FILE_ACTION_MODIFIED : {
                                console.logf("(Thread %d) %s was modified.", 
                                             thread.specific.win32_thread_id, 
                                             name);
                            }
                            case win32.FILE_ACTION_RENAMED_OLD_NAME : {
                                console.logf("(Thread %d) %s was renamed (old).", 
                                             thread.specific.win32_thread_id, 
                                             name);
                            }
                            case win32.FILE_ACTION_RENAMED_NEW_NAME : {
                                console.logf("(Thread %d) %s was renamed (new).", 
                                             thread.specific.win32_thread_id, 
                                             name);
                            }
                        }

                        sync.mutex_lock(mtx);
                        {
                            do_update = true;
                        }
                        sync.mutex_unlock(mtx);
    
                        c = next_entry(c);
                    }
    
                } else {
                    return -1;
                }
            }
    
            return 0;
        }
    
        status._notify_thread = thread.create(_proc);
        status._notify_thread.data = p;
        console.logf("(Thread %d) Beginning to watch repo at %s", status._notify_thread.specific.win32_thread_id, git.repository_workdir(repo));
        thread.start(status._notify_thread);
    }
}

free :: proc(status : ^Status) {
    clear(&status.staged);
    clear(&status.unstaged);
    clear(&status.untracked);

    git.free(status.diff);
    status.diff = nil;

    if mutex_setup do sync.mutex_lock(&update_mutex);
    if status._notify_thread != nil {
        thread.terminate(status._notify_thread, 0);
        thread.destroy(status._notify_thread);
        status._notify_thread = nil;
    }
    if mutex_setup do sync.mutex_unlock(&update_mutex);
}

to_stage             :  [dynamic]Status_Entry;
to_unstage           :  [dynamic]Status_Entry;
show_status_window   := true;

window :: proc(dt : f64, status : ^Status, repo : ^git.Repository, diff_ctx : ^^diff_view.Context) {
    if imgui.button("Status") {
        if show_status_window {
            show_status_window = false;
            free(status);
        } else {
            show_status_window = true;
            update(repo, status);
        }
    }

    if sync.mutex_try_lock(&update_mutex) {
        if do_update {
            update(repo, status);
            do_update = false;
        }
        sync.mutex_unlock(&update_mutex);
    }

    imgui.text("Staged files:");
    if imgui.begin_child("Staged", imgui.Vec2{0, 150}) {
        imgui.columns(count = 3, border = false);
        imgui.push_style_color(imgui.Color.Text, color.light_greenA400);

        for entry, i in status.staged {
            imgui.set_column_width(-1, 60);
            imgui.push_id(i);
            if imgui.button("unstage") do append(&to_unstage, entry);
            imgui.pop_id();
            imgui.next_column();
            imgui.set_column_width(-1, 100);
            imgui.text("%v", entry.status);
            imgui.next_column();
            imgui.selectable(entry.path);
            imgui.next_column();
        }

        imgui.pop_style_color();
    }
    imgui.end_child();

    imgui.text("Unstaged files:");
    if imgui.begin_child("Unstaged", imgui.Vec2{0, 150}) {
        imgui.columns(count = 3, border = false);
        imgui.push_style_color(imgui.Color.Text, color.deep_orange600);

        for entry, i in status.unstaged {
            imgui.set_column_width(width = 80);
            imgui.push_id(i); defer imgui.pop_id();

            if imgui.button("stage") do append(&to_stage, entry);
            imgui.same_line(); 
            if imgui.button("diff")  do open_diff(repo, status.diff, entry._git, diff_ctx);
            
            imgui.next_column();
            imgui.set_column_width(-1, 100);
            imgui.text("%v", entry.status);
            imgui.next_column();
            imgui.selectable(entry.path);
            imgui.next_column();
        }

        imgui.pop_style_color();
    }
    imgui.end_child();

    imgui.text("Untracked files:");
    if imgui.begin_child("Untracked", imgui.Vec2{0, 150}) {
        imgui.columns(count = 3, border = false);
        imgui.push_style_color(imgui.Color.Text, color.alizarin);

        for entry, i in status.untracked {
            imgui.set_column_width(-1, 60);
            imgui.push_id(i); defer imgui.pop_id();

            if imgui.button("stage") do append(&to_stage, entry);

            imgui.next_column();
            imgui.set_column_width(-1, 100);
            imgui.text("%v", entry.status);
            imgui.next_column();
            imgui.selectable(entry.path);
            imgui.next_column();
        }

        imgui.pop_style_color();
    }
    imgui.end_child();

    if len(to_stage) > 0 || len(to_unstage) > 0 {
        if index, err := git.repository_index(repo); !log_if_err(err) {
            for entry in to_stage {
                err := git.index_add(index, entry.path);
                log_if_err(err);
            }

            for entry in to_unstage {
                if head, err := git.repository_head(repo); !log_if_err(err) {
                    defer git.free(head);

                    if head_commit, err := git.reference_peel(head, git.Obj_Type.Commit); !log_if_err(err) {
                        defer git.free(head_commit);
                        path := entry.path;
                        strs := [?]string{
                            path,
                        };
                        err = git.reset_default(repo, head_commit, strs[..]);
                        log_if_err(err);
                    }
                }
            }

            err = git.index_write(index);
            log_if_err(err);
        }

        update(repo, status);
    }

    clear(&to_stage);
    clear(&to_unstage);
}

open_diff :: proc(repo : ^git.Repository, diff : ^git.Diff, entry : ^git.Status_Entry, diff_ctx : ^^diff_view.Context) {
    patch := find_patch(repo, diff, entry);
    ctx := diff_ctx^;
    if ctx != nil do diff_view.free(ctx);
    ctx = diff_view.create_context(strings.to_odin_string(entry.index_to_workdir.new_file.path), patch);
    diff_ctx^ = ctx;
}

find_patch :: proc(repo : ^git.Repository, diff : ^git.Diff, entry : ^git.Status_Entry) -> ^git.Patch {
    //Find common delta by old_file oid, new_file might be null
    num_deltas := git.diff_num_deltas(diff);
    di := -1;
    for i in 0..int(num_deltas) {
        d := git.diff_get_delta(diff, uint(i));
        if git.oid_equal(&d.old_file.id, &entry.index_to_workdir.old_file.id) {
            di = i;
            break;
        }
    }

    if di == -1 {
        console.log_error("Could not find matching delta, wtf?");
        return nil;
    }

    //Create Patch
    patch, _ := git.patch_from_diff(diff, uint(di));
    return patch;
}