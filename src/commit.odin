using import _ "debug.odin";
import "core:fmt.odin";
import "core:strings.odin";

import imgui "shared:libbrew/brew_imgui.odin";

import git "libgit2.odin";
import "settings.odin";

Commit :: struct {
    git_commit : ^git.Commit,
    author     : git.Signature,
    committer  : git.Signature,
    summary    : string,
    message    : string,
}

from_oid :: proc(repo : ^git.Repository, oid : git.Oid) -> Commit {
    result : Commit;
    err : git.Error_Code;
    result.git_commit, err = git.commit_lookup(repo, &oid);
    if !log_if_err(err) {
        result.message  = git.commit_message(result.git_commit);
        result.summary  = git.commit_summary(result.git_commit);
        result.committer = git.commit_committer(result.git_commit);
        result.author   = git.commit_author(result.git_commit);
    }

    return result;
}

free :: proc(commit : ^Commit) {
    if commit.git_commit == nil do return;
    git.free(commit.git_commit);
    commit.git_commit = nil;
}