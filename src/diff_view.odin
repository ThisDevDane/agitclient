/*
 *  @Name:     diff_view
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 19-02-2018 16:09:18 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 19-02-2018 16:43:39 UTC+1
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin";
import "core:mem.odin";

import imgui   "shared:libbrew/brew_imgui.odin";

import git "libgit2.odin";
import     "color.odin";

Context :: struct {
    label : string,
    patch : ^git.Patch,
    num_hunks : uint,
    wrap := false,
}

create_context :: proc(file_name : string, patch : ^git.Patch) -> ^Context {
    ctx := new(Context);
    ctx.patch = patch;
    ctx.num_hunks = git.patch_num_hunks(ctx.patch);
    ctx.label = fmt.aprintf("Diff: %s", file_name);
    return ctx;
}

free :: proc(ctx : ^Context) {
    _global.free(ctx.label);
    git.free(ctx.patch);
    _global.free(ctx);
}

window :: proc(ctx : ^Context, keep_open : ^bool) {
    imgui.set_next_window_size(imgui.Vec2{500, 600}, imgui.Set_Cond.Once);
    if imgui.begin(ctx.label, keep_open) {
        imgui.checkbox("Wrap?", &ctx.wrap);
        if ctx.patch != nil {
            if imgui.begin_child(str_id = "diff lines", extra_flags = imgui.Window_Flags.HorizontalScrollbar) {
                for i in 0..ctx.num_hunks {
                    hunk, hunk_lines, _ := git.patch_get_hunk(ctx.patch, i);
                    imgui.push_font(imgui.mono_font); defer imgui.pop_font();
                    for j in 0..hunk_lines {
                        line, _ := git.patch_get_line_in_hunk(ctx.patch, i, j);
                        if line == nil do continue;
                        origin := rune(line.origin);
                        pop := false;
                        line_idx := line.old_lineno;
                        
                        switch origin { 
                            case '-' : {
                                pop = true;
                                imgui.push_style_color(imgui.Color.Text, color.deep_orange600);
                                line_idx = line.old_lineno;
                            }
                            case '+' : {
                                pop = true;
                                imgui.push_style_color(imgui.Color.Text, color.light_greenA400);
                                line_idx = line.new_lineno;
                            }
                        }
                        
                        if ctx.wrap do imgui.text_wrapped("%d %r %s", line_idx, origin, string(mem.slice_ptr(line.content, int(line.content_len))));
                        else        do imgui.text("%d %r %s", line_idx, origin, string(mem.slice_ptr(line.content, int(line.content_len))));
                        
                        if pop do imgui.pop_style_color();
                    }
                    imgui.text_colored(color.grey600, "[...]");
                }
            } imgui.end_child();
        }
    }
    imgui.end();
}