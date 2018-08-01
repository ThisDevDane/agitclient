package main;

import "core:fmt";
import "core:mem";

import util  "shared:libbrew/util";
import "shared:odin-imgui";

import git "shared:odin-libgit2";

Branch :: struct {
    ref           : ^git.Reference,
    upstream_ref  : ^git.Reference,

    name          : string,
    btype         : git.Branch_Type,
    current_commit : Commit,

    ahead : uint,
    behind : uint,
}

Branch_Collection :: struct {
    name     : string,
    branches : [dynamic]Branch,
}

all_branches_from_repo :: proc(repo : ^git.Repository, btype : git.Branch_Type) -> []Branch_Collection {
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
            commit := from_oid(repo, oid);

            upstream_ref, _ := git.branch_upstream(ref);
            ahead, behind : uint;
            if upstream_ref != nil {
                uid, _          := git.reference_name_to_id(repo, git.reference_name(upstream_ref));
                ahead, behind, _ = git.graph_ahead_behind(repo, oid, uid);
            } else {
                ahead = 0; 
                behind = 0;
            }

            col_name, found := util.get_upto_first_from_file(name, '/');
            if !found {
                col_name = "";
            }
            col_found := false;
            for col, i in result {
                if col.name == col_name {
                    b := Branch {
                        ref,
                        upstream_ref,
                        name,
                        btype,
                        commit,
                        ahead,
                        behind,
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
                    upstream_ref,
                    name,
                    btype,
                    commit,
                    ahead,
                    behind,
                };
                append(&col.branches, b);
                append(&result, col);
            }
        }
    }

    git.free(iter);
    return result[:];
}

checkout_branch :: proc(repo : ^git.Repository, b : Branch) -> bool {
    obj, err := git.revparse_single(repo, b.name);
    if !log_if_err(err) {
        opts, _ := git.checkout_init_options();
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

create_branch :: proc[create_from_name, create_from_branch];

create_from_branch :: proc(repo : ^git.Repository, b : Branch, force := false) -> Branch {
    if b.btype == git.Branch_Type.Remote {
        b.name = util.remove_first_from_file(b.name, '/');
    }

    ref, err := git.branch_create(repo, b.name, b.current_commit.git_commit, force);
    if !log_if_err(err) {
        name, suc := git.branch_name(ref);
        refname := git.reference_name(ref);
        oid, ok := git.reference_name_to_id(repo, refname);
        commit := from_oid(repo, oid);
        b := Branch {
            ref,
            nil,
            name,
            git.Branch_Type.Local,
            commit,
            0,
            0
        };

        return b;
    }

    return Branch{};
}

create_from_name :: proc(repo : ^git.Repository, name : string, target : Commit, force := false) -> Branch {
    ref, err := git.branch_create(repo, name, target.git_commit, force);
    if !log_if_err(err) {
        name, suc := git.branch_name(ref);
        refname := git.reference_name(ref);
        oid, ok := git.reference_name_to_id(repo, refname);
        commit := from_oid(repo, oid);
        b := Branch {
            ref,
            nil,
            name,
            git.Branch_Type.Local,
            commit,
            0,
            0,
        };

        return b;
    }

    return Branch{};
}

branch_window :: proc(settings : ^Settings, wnd_height : int, 
               repo : ^git.Repository, create_branch_name : []byte, 
               current_branch : ^Branch, credentials_cb : git.Cred_Acquire_Cb,
               local_branches : ^[]Branch_Collection, remote_branches : ^[]Branch_Collection) {
    update_branches := false;
    open_create_modal := false;
    half_height := (wnd_height - 18) / 2;
    widget_width :: 250;
    imgui.set_next_window_pos(imgui.Vec2{0, 18});
    imgui.set_next_window_size(imgui.Vec2{widget_width, f32(half_height)});
    buf : [1024]byte;
    label := fmt.bprintf(buf[:], "%r %s", BARS, "Local Branches");
    if imgui.begin(label, nil, imgui.Window_Flags.NoResize   |
                                    imgui.Window_Flags.NoMove     |
                                    imgui.Window_Flags.NoCollapse |
                                    imgui.Window_Flags.MenuBar    |
                                    imgui.Window_Flags.NoBringToFrontOnFocus) {
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
        if repo == nil {
            return;
        }

        if open_create_modal {
            mem.zero(&create_branch_name[0], len(create_branch_name));
            imgui.open_popup("Create Branch###create_branch_modal");
        }

        if imgui.begin_popup_modal("Create Branch###create_branch_modal", nil, imgui.Window_Flags.AlwaysAutoResize) {
            defer imgui.end_popup();
            imgui.text("Branch name:"); imgui.same_line();
            imgui.input_text("", create_branch_name[:]);
            imgui.checkbox("Checkout new branch?", &settings.auto_checkout_new_branch);
            imgui.checkbox("Setup on remote?", &settings.auto_setup_remote_branch);
            imgui.separator();
            if imgui.button("Create", imgui.Vec2{160, 0}) {
                branch_name_str := cast(string)create_branch_name[:];
                b := create_branch(repo, branch_name_str, current_branch.current_commit);
                
                if settings.auto_setup_remote_branch {
                    remote, _ := git.remote_lookup(repo, "origin");
                    defer git.free(remote);
                    remote_cb, _  := git.remote_init_callbacks();
                    remote_cb.credentials = credentials_cb;

                    ok := git.remote_connect(remote, git.Direction.Push, &remote_cb, nil, nil);
                    if !log_if_err(ok) {
                        refname := git.reference_name(b.ref);
                        opts, _ := git.push_init_options();
                        opts.callbacks = remote_cb;
                        opts.pb_parallelism = 0;

                        refspec := []string{
                            fmt.aprintf("%s:%s", refname, refname),
                        };

                        err := git.remote_push(remote, refspec, &opts);
                        if !log_if_err(err) {
                            git.branch_set_upstream(b.ref, fmt.aprintf("%s/%s", git.remote_name(remote), branch_name_str));
                        }
                    }
                }
                
                if settings.auto_checkout_new_branch {
                    checkout_branch(repo, b);
                }


                update_branches = true;
                imgui.close_current_popup();
            }
            imgui.same_line();
            if imgui.button("Cancel", imgui.Vec2{160, 0}) {
                imgui.close_current_popup();
            }
        }

        pos := imgui.get_window_pos();
        size := imgui.get_window_size();

        imgui.set_next_tree_node_open(true, imgui.Set_Cond.Once);
        for col in local_branches {
            if col.name == "" {
                print_branches(repo, col.branches[:], &update_branches, current_branch);
            } else {
                imgui.set_next_tree_node_open(true, imgui.Set_Cond.Once);
                if imgui.tree_node(col.name) {
                    defer imgui.tree_pop();
                    imgui.indent(5);
                    print_branches(repo, col.branches[:], &update_branches, current_branch);
                    imgui.unindent(5);
                }
            }
        }
    }

    imgui.set_next_window_pos(imgui.Vec2{0, f32(18+half_height)});
    imgui.set_next_window_size(imgui.Vec2{widget_width, f32(half_height)});
    label = fmt.bprintf(buf[:], "%r %s", CLOUD, "Remote Branches");
    if imgui.begin(label, nil, imgui.Window_Flags.NoResize   |
                                    imgui.Window_Flags.NoMove     |
                                    imgui.Window_Flags.NoCollapse |
                                    imgui.Window_Flags.NoBringToFrontOnFocus) {
        defer imgui.end();
        imgui.set_next_tree_node_open(true, imgui.Set_Cond.Once);
        //imgui.push_style_color(imgui.Color.Text, color.deep_orange600);
        for col in remote_branches[:] {
            if col.name == "origin" {
                imgui.set_next_tree_node_open(true, imgui.Set_Cond.Once);
            }
            label = fmt.bprintf(buf[:], "%r %s", CLOUD_UPLOAD, col.name);
            if imgui.tree_node(label) {
                defer imgui.tree_pop();
                imgui.indent(5);
                for b in col.branches {
                    if b.name == "origin/HEAD" do continue;
                    label = fmt.bprintf(buf[:], "%r %s", RANDOM, b.name);
                    imgui.selectable(label);
                    imgui.push_id(git.reference_name(b.ref));
                    defer imgui.pop_id();
                    if imgui.begin_popup_context_item("branch_context", 1) {
                        defer imgui.end_popup();
                        imgui.push_style_color(imgui.Color.Text, white);
                        defer imgui.pop_style_color();
                        label = fmt.bprintf(buf[:], "%r Checkout", CHECK);
                        if imgui.selectable(label) {
                            branch := create_branch(repo, b);
                            if checkout_branch(repo, branch) {
                                update_branches = true;
                                current_branch^ = branch;
                            }
                        }
                        imgui.text_disabled("%r Push", CLOUD_UPLOAD);
                        imgui.text_disabled("%r Pull", CLOUD_DOWNLOAD);
                        imgui.text_disabled("%r Delete", TIMES);
                    }
                }
                imgui.unindent(5);
            }
        }
        //imgui.pop_style_color();
    }

    if update_branches {
        local_branches^ = all_branches_from_repo(repo, git.Branch_Type.Local);
        remote_branches^ = all_branches_from_repo(repo, git.Branch_Type.Remote);
    }
}

print_branches :: proc(repo : ^git.Repository, branches : []Branch, update_branches : ^bool, curb : ^Branch) {
    branch_to_delete: Branch;
    imgui.indent();
    defer imgui.unindent();
    for b in branches {
        is_current_branch := git.reference_is_branch(b.ref) && git.branch_is_checked_out(b.ref);
        buf : [1024]byte;
        name := fmt.bprintf(buf[:], "%r %s | %r %d %r %d", RANDOM, b.name, ARROW_UP, b.ahead, ARROW_DOWN, b.behind);
        if is_current_branch do imgui.push_style_color(imgui.Color.Text, light_greenA400); 
        imgui.selectable(name, is_current_branch);
        if is_current_branch do imgui.pop_style_color();
        if imgui.is_item_clicked(0) && imgui.is_mouse_double_clicked(0) {
            if checkout_branch(repo, b) {
                update_branches^ = true;
                curb^ = b;
            }
        }
        imgui.push_id(b.name);
        defer imgui.pop_id();


        if imgui.begin_popup_context_item("branch_context", 1) {
            defer imgui.end_popup();
            imgui.push_style_color(imgui.Color.Text, white);
            defer imgui.pop_style_color();
            label := fmt.bprintf(buf[:], "%r Checkout", CHECK);
            if !is_current_branch {
                if imgui.selectable(label) {
                    if checkout_branch(repo, b) {
                        update_branches^ = true;
                        curb^ = b;
                    }
                }
            } else {
                imgui.text_disabled(label);
            }

            imgui.text_disabled("%r Push", CLOUD_UPLOAD);
            imgui.text_disabled("%r Pull", CLOUD_DOWNLOAD);

            if !is_current_branch {
                label := fmt.bprintf(buf[:], "%r Delete", TIMES);
                if imgui.selectable(label) {
                    branch_to_delete = b;
                }
            } else {
                imgui.text_disabled("%r Delete", TIMES);
            }
        }
    }

    if branch_to_delete.ref != nil {
        update_branches^ = true;
        git.branch_delete(branch_to_delete.ref);
    }
}