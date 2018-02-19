using import _ "debug.odin";

import "core:strings.odin";
import "core:fmt.odin";

import       "shared:libbrew/time_util.odin";
import imgui "shared:libbrew/brew_imgui.odin";

import git "libgit2.odin";
import pat "path.odin";
import     "color.odin";

Status :: struct {
    list      : ^git.Status_List,
    staged    : [dynamic]^git.Status_Entry,
    unstaged  : [dynamic]^git.Status_Entry,
    untracked : [dynamic]^git.Status_Entry,
}

update :: proc(repo : ^git.Repository, status : ^Status) {
    if status.list == nil {
        options, _ := git.status_init_options();
        options.flags = git.Status_Opt_Flags.Include_Untracked | git.Status_Opt_Flags.Recurse_Untracked_Dirs;
        err : git.Error_Code;
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
                    defer _global.free(path);

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

free :: proc(status : ^Status) {
    if status.list == nil do return;

    git.free(status.list);
    clear(&status.staged);
    clear(&status.unstaged);
    clear(&status.untracked);

    status.list = nil;
}

status_refresh_timer : time_util.Timer;
to_stage             :  [dynamic]^git.Status_Entry;
to_unstage           :  [dynamic]^git.Status_Entry;
show_status_window   := true;

window :: proc(dt : f64, status : ^Status, repo : ^git.Repository) {
    if imgui.button("Status") {
        if show_status_window {
            show_status_window = false;
            free(status);
        } else {
            show_status_window = true;
            time_util.reset(&status_refresh_timer);
            update(repo, status);
        }
    }

    if time_util.query(&status_refresh_timer, dt) {
        free(status);
        update(repo, status);
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
            imgui.text("%v", entry.head_to_index.status);
            imgui.next_column();
            imgui.text(strings.to_odin_string(entry.head_to_index.new_file.path));
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
            imgui.same_line(); imgui.button("diff");
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
    if imgui.begin_child("Untracked", imgui.Vec2{0, 150}) {
        imgui.columns(count = 3, border = false);
        imgui.push_style_color(imgui.Color.Text, color.alizarin);

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
                err := git.index_add(index, strings.to_odin_string(entry.index_to_workdir.new_file.path));
                log_if_err(err);
            }

            for entry in to_unstage {
                if head, err := git.repository_head(repo); !log_if_err(err) {
                    defer git.free(head);

                    if head_commit, err := git.reference_peel(head, git.Obj_Type.Commit); !log_if_err(err) {
                        defer git.free(head_commit);
                        path := strings.to_odin_string(entry.head_to_index.new_file.path);
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
    }

    clear(&to_stage);
    clear(&to_unstage);
}