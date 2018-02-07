import imgui "shared:libbrew/brew_imgui.odin";

import misc  "shared:libbrew/sys/misc.odin";

//import   "commit.odin";
import git "libgit2.odin";
import     "color.odin";
import com "commit.odin";
using import _ "debug.odin";

Item :: struct {
    commit : com.Commit,
    time   : misc.Datetime,
}

Log :: struct {
    items : [dynamic]Item,
    count : int,
}

window :: proc(log : ^Log, repo : ^git.Repository, bref : ^git.Reference) {
    commit_count := 0;
    if imgui.begin("Log", nil, imgui.Window_Flags.NoCollapse) {
        defer imgui.end();
        if imgui.begin_child("gitlog", imgui.Vec2{0, -25}) {
            defer imgui.end_child();

            clipper := imgui.ListClipper{items_count = i32(len(log.items))};
            for imgui.list_clipper_step(&clipper) {
                for i := clipper.display_start; i < clipper.display_end; i += 1 {
                    item := log.items[i];
                    imgui.selectable(item.commit.summary);
                    if imgui.is_item_hovered() {
                        imgui.set_next_window_size(imgui.Vec2{350, 0});
                        imgui.begin_tooltip();
                        imgui.text_colored(color.lightgray, 
                                           "Time: %d/%d/%d %d:%d:%d UTC%s%d",
                                           item.time.day,
                                           item.time.month,
                                           item.time.year,
                                           item.time.hour,
                                           item.time.minute,
                                           item.time.second,
                                           item.commit.author.time_when.offset < 0 ? "" : "+",
                                           item.commit.author.time_when.offset/60);
                        imgui.text_wrapped(item.commit.message);
                        imgui.end_tooltip();
                    }
                    imgui.same_line();
                    imgui.text_colored(color.lightgray, "%s <%s>", item.commit.author.name, 
                                                                   item.commit.author.email);
                }
            }
        }

        imgui.separator();
        imgui.text_colored(color.alpha(color.white, 0.2), "Commits: %d", log.count); imgui.same_line();
        if imgui.button("Update") {
            update(log, repo, bref);
        }
    }
}

update :: proc(log : ^Log, repo : ^git.Repository, bref : ^git.Reference) {
    clear(&log.items);
    log.count = 0;
    GIT_ITEROVER :: -31;
    walker, err := git.revwalk_new(repo);
    if !log_if_err(err) {
        err = git.revwalk_push_ref(walker, git.reference_name(bref));
        log_if_err(err);
    }

    for {
        id, err := git.revwalk_next(walker);
        if err == GIT_ITEROVER {
            break;
        }
        //commit_count += 1;
        commit := com.from_oid(repo, id);
        time := misc.unix_to_datetime(int(commit.author.time_when.time + i64(commit.author.time_when.offset) * 60));

        item := Item{
            commit,
            time,
        };

        append(&log.items, item);
        log.count += 1;
    }
    git.free(walker);
}