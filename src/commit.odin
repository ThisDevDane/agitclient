package main;

import "core:fmt";
import "core:strings";

import     "shared:odin-imgui";
import git "shared:odin-libgit2";

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

commit_free :: proc(commit : ^Commit) {
    if commit.git_commit == nil do return;
    git.free(commit.git_commit);
    commit.git_commit = nil;
}