/*
 *  @Name:     libgit2
 *
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 01:50:33
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 15-01-2018 00:53:09 UTC+1
 *
 *  @Description:
 *
 */

foreign import libgit "../external/libgit2.lib";
export "libgit2_types.odin";
import "core:fmt.odin";
import "core:mem.odin";
import "core:strings.odin";

////////////////////////////////////////////
//// git_*_free
////
free :: proc[git_commit_free, 
             git_repository_free, 
             git_index_free, 
             git_remote_free, 
             git_revwalk_free, 
             _signature_free, 
             git_signature_free,
             git_reference_free,
             git_status_list_free,
             git_branch_iterator_free,
             git_object_free];

////////////////////////////////////////////
//// git_libgit2
////
lib_init                    :: inline proc() -> Error_Code                                                                                                                                     { return git_libgit2_init(); }
lib_shutdown                :: inline proc() -> Error_Code                                                                                                                                     { return git_libgit2_shutdown(); }
lib_features                :: inline proc() -> Lib_Features                                                                                                                                   { return git_libgit2_features(); }
lib_version                 :: inline proc(major : ^i32, minor : ^i32, rev : ^i32)                                                                                                             { git_libgit2_version(major, minor, rev); }

////////////////////////////////////////////
//// git_repository
////
repository_init             :: proc[repository_init_, repository_init_ext];
repository_init_            :: inline proc(path : string, is_bare : bool) -> (^Repository, Error_Code)                                                                                         { return _repository_init(path, is_bare); }
repository_init_ext         :: inline proc(path : string, pots : ^Repository_Init_Options) -> (^Repository, Error_Code)                                                                        { return _repository_init_ext(path, pots); }
repository_open             :: inline proc(path : string, flags := Repository_Open_Flags.No_Search, ceiling_dirs := "") -> (^Repository, Error_Code)                                           { return _repository_open_ext(path, flags, ceiling_dirs);}
repository_head             :: inline proc(repo : ^Repository) -> (^Reference, Error_Code)                                                                                                     { return _repository_head(repo); }
repository_set_head         :: inline proc(repo : ^Repository, refname : string) -> Error_Code                                                                                                 { return _repository_set_head(repo, refname); }
repository_path             :: inline proc(repo : ^Repository) -> string                                                                                                                       { return _repository_path(repo); }
repository_index            :: inline proc(repo : ^Repository) -> (^Index, Error_Code)                                                                                                         { return _repository_index(repo); }
repository_set_index        :: inline proc(repo : ^Repository, index : ^Index)                                                                                                                 { git_repository_set_index(repo, index); }
is_repository               :: inline proc(path : string) -> bool                                                                                                                              { return _is_repository(path); } 

////////////////////////////////////////////
//// git_clone
////
clone                       :: inline proc(url : string, local_path : string, options : ^Clone_Options) -> (^Repository, Error_Code)                                                           { return _clone(url, local_path, options); }
clone_init_options          :: inline proc(version : u32) -> (Clone_Options, Error_Code)                                                                                                       { return _clone_init_options(version); }

////////////////////////////////////////////
//// git_remote
////
remote_lookup               :: inline proc(repo : ^Repository, name : string) -> (^Remote, Error_Code)                                                                                         { return _remote_lookup(repo, name); }
remote_list                 :: inline proc(repo : ^Repository) -> ([]string, Error_Code)                                                                                                       { return _remote_list(repo); }
// NOTE(Hoej): Not wrapped yet 
//remote_default_branch     :: inline proc(out : ^Buf, remote : ^Remote) -> Error_Code                                                                                                         {  }
remote_connect              :: inline proc(remote : ^Remote, direction : Direction, callbacks : ^Remote_Callbacks, proxy_opts : ^Proxy_Options, custom_headers : ^Str_Array) -> Error_Code     { return git_remote_connect(remote, direction, callbacks, proxy_opts, custom_headers); }
remote_disconnect           :: inline proc(remote : ^Remote)                                                                                                                                   { git_remote_disconnect(remote); }
remote_init_callbacks       :: inline proc() -> (Remote_Callbacks, Error_Code)                                                                                                                 { return _remote_init_callbacks(); }
remote_connected            :: inline proc(remote : ^Remote) -> Error_Code                                                                                                                     { return git_remote_connected(remote); }
remote_fetch                :: inline proc(remote : ^Remote, refspecs : []string, opts : ^Fetch_Options, reflog_message := "fetch") -> Error_Code                                              { return _remote_fetch(remote, refspecs, opts, reflog_message); }
remote_push                 :: inline proc(remote : ^Remote, refspecs : []string, opts : ^Push_Options) -> Error_Code                                                                          { return _remote_push(remote, refspecs, opts); }
remote_update_tips          :: inline proc(remote : ^Remote, callbacks : ^Remote_Callbacks, update_fetchhead : bool, download_tags : Remote_Autotag_Option_Flags, reflog_message := "fetch") -> Error_Code { return _remote_update_tips(remote, callbacks, update_fetchhead, download_tags, reflog_message); }
remote_name                 :: inline proc(remote : ^Remote) -> string                                                                                                                         { return _remote_name(remote); }

////////////////////////////////////////////
//// git_status
////
status_foreach              :: inline proc(repo : ^Repository, callback : Status_Cb, payload : rawptr) -> Error_Code                                                                           { return git_status_foreach(repo, callback, payload); }
status_foreach_ext          :: inline proc(repo : ^Repository, opts : ^Status_Options, callback : Status_Cb, payload : rawptr) -> Error_Code                                                   { return git_status_foreach_ext(repo, opts, callback, payload); }
status_list_new             :: inline proc(repo : ^Repository, opts : ^Status_Options) -> (^Status_List, Error_Code)                                                                           { return _status_list_new(repo, opts); }
status_list_entrycount      :: inline proc(list : ^Status_List) -> uint                                                                                                                        { return git_status_list_entrycount(list); }
status_byindex              :: inline proc(list : ^Status_List, idx : uint) -> ^Status_Entry                                                                                                   { return git_status_byindex(list, idx); }

////////////////////////////////////////////
//// git_commit
////
commit_create               :: inline proc(repo : ^Repository, update_ref : string, author, committer : ^Signature, message : string, tree : ^Tree, parents : ...^Commit) -> (Oid, Error_Code) { return _commit_create(repo, update_ref, author, committer, message, tree, ...parents) }
commit_lookup               :: inline proc(repo : ^Repository, id : ^Oid) -> (^Commit, Error_Code)                                                                                             { return _commit_lookup(repo, id); }
commit_parent_id            :: inline proc(commit : ^Commit, n : u32) -> ^Oid                                                                                                                  { return git_commit_parent_id(commit, n) }
commit_parentcount          :: inline proc(commit : ^Commit) -> Error_Code                                                                                                                     { return git_commit_parentcount(commit) } 
commit_message              :: inline proc(commit : ^Commit) -> string                                                                                                                         { return _commit_message(commit); }
commit_committer            :: inline proc(commit : ^Commit) -> Signature                                                                                                                      { return _commit_committer(commit); }
commit_author               :: inline proc(commit : ^Commit) -> Signature                                                                                                                      { return _commit_author(commit); }
commit_summary              :: inline proc(commit : ^Commit) -> string                                                                                                                         { return _commit_summary(commit); }
commit_raw_header           :: inline proc(commit : ^Commit) -> string                                                                                                                         { return _commit_raw_header(commit); }

////////////////////////////////////////////
//// git_signature
////
signature_now               :: inline proc(name : string, email : string) -> (Signature, Error_Code)                                                                                           { return _signature_now(name, email); }

////////////////////////////////////////////
//// git_branch
////
branch_create               :: inline proc(repo : ^Repository, branch_name : string, target : ^Commit, force : bool) -> (^Reference, Error_Code)                                               { return _branch_create(repo, branch_name, target, force); }
branch_name                 :: inline proc(ref : ^Reference) -> (string, Error_Code)                                                                                                           { return _branch_name(ref); }
branch_iterator_new         :: inline proc(repo : ^Repository, list_flags : Branch_Type) -> (^Branch_Iterator, Error_Code)                                                                     { return _branch_iterator_new(repo, list_flags); }
branch_next                 :: inline proc(iter : ^Branch_Iterator) -> (^Reference, Branch_Type, Error_Code)                                                                                   { return _branch_next(iter); }
branch_delete               :: inline proc(branch : ^Reference) -> Error_Code                                                                                                                  { return git_branch_delete(branch); }
branch_is_checked_out       :: inline proc(branch : ^Reference) -> bool                                                                                                                        { return git_branch_is_checked_out(branch) };
branch_upstream             :: inline proc(branch : ^Reference) -> (^Reference, Error_Code)                                                                                                    { return _branch_upstream(branch); }
branch_set_upstream         :: inline proc(branch : ^Reference, upstream_name : string) -> Error_Code                                                                                          { return _branch_set_upstream(branch, upstream_name); }

////////////////////////////////////////////
//// git_checkout
////
checkout_tree               :: inline proc(repo : ^Repository, treeish : ^Object, opts : ^Checkout_Options) -> Error_Code                                                                      { return git_checkout_tree(repo ,treeish, opts); }

////////////////////////////////////////////
//// git_stash
////
stash_save                  :: inline proc(repo : ^Repository, stasher : ^Signature, message : string, flags : Stash_Flags) -> (Oid, Error_Code)                                               { return _stash_save(repo, stasher, message, flags); }
stash_apply                 :: inline proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code                                                                     { return git_stash_apply(repo, index, options); }
stash_pop                   :: inline proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code                                                                     { return git_stash_pop(repo, index, options); }
stash_drop                  :: inline proc(repo : ^Repository, index : uint) -> Error_Code                                                                                                     { return git_stash_drop(repo, index); }
stash_foreach               :: inline proc(repo : ^Repository, callback : Stash_Cb, payload : rawptr, index : uint) -> Error_Code                                                              { return git_stash_foreach(repo, callback, payload, index); }

////////////////////////////////////////////
//// git_reference
////
reference_name_to_id        :: inline proc(repo : ^Repository, name : string) -> (Oid, Error_Code)                                                                                             { return _reference_name_to_id(repo, name); }
reference_symbolic_target   :: inline proc(ref : ^Reference) -> string                                                                                                                         { return _reference_symbolic_target(ref); }
reference_name              :: inline proc(ref : ^Reference) -> string                                                                                                                         { return _reference_name(ref); }
reference_peel              :: inline proc(ref : ^Reference, kind : Obj_Type) -> (^Object, Error_Code)                                                                                         { return _reference_peel(ref, kind); } 
reference_is_branch         :: inline proc(ref : ^Reference) -> bool                                                                                                                           { return git_reference_is_branch(ref); }

////////////////////////////////////////////
//// git_revwalk
////
revwalk_new                 :: inline proc(repo : ^Repository) -> (^Revwalk, Error_Code)                                                                                                       { return _revwalk_new(repo); }
revwalk_next                :: inline proc(walk : ^Revwalk) -> (Oid, Error_Code)                                                                                                               { return _revwalk_next(walk); }
revwalk_push_range          :: inline proc(walk : ^Revwalk, range : string) -> Error_Code                                                                                                      { return _revwalk_push_range(walk, range); }
revwalk_push_ref            :: inline proc(walk : ^Revwalk, refname : string) -> Error_Code                                                                                                    { return _revwalk_push_ref(walk, refname); }

////////////////////////////////////////////
//// git_index
////
index_new                   :: inline proc() -> (^Index, Error_Code)                                                                                                                           { return _index_new(); }
index_add                   :: proc[index_add_, index_add_bypath];  
index_add_                  :: inline proc(index : ^Index, entry : ^Index_Entry) -> Error_Code                                                                                                 { return git_index_add(index, entry); }
index_add_bypath            :: inline proc(index : ^Index, path : string) -> Error_Code                                                                                                        { return _index_add_bypath(index, path); }
index_remove                :: proc[index_remove_, index_remove_bypath];  
index_remove_               :: inline proc(index : ^Index, entry : ^Index_Entry) -> Error_Code                                                                                                 { return git_index_remove(index, entry); }
index_remove_bypath         :: inline proc(index : ^Index, path : string) -> Error_Code                                                                                                        { return _index_remove_bypath(index, path); }
index_entrycount            :: inline proc(index : ^Index) -> uint                                                                                                                             { return git_index_entrycount(index); }
index_get_byindex           :: inline proc(index : ^Index, n : uint) -> ^Index_Entry                                                                                                           { return git_index_get_byindex(index, n); }
index_write                 :: inline proc(index : ^Index) -> Error_Code                                                                                                                       { return git_index_write(index); }
index_write_tree            :: inline proc(index : ^Index) -> (Oid, Error_Code)                                                                                                                { return _index_write_tree(index); }

////////////////////////////////////////////
//// git_cred
////
cred_userpass_plaintext_new :: inline proc(username : string, password : string) -> (^Cred, Error_Code)                                                                                        { return _cred_userpass_plaintext_new(username, password); }
cred_has_username           :: inline proc(cred : ^Cred) -> bool                                                                                                                               { return git_cred_has_username(cred); }
cred_ssh_key_from_agent     :: inline proc(username : string) -> (^Cred, Error_Code)                                                                                                           { return _cred_ssh_key_from_agent(username); }

////////////////////////////////////////////
//// git_reset
////
reset_default               :: inline proc(repo : ^Repository, target : ^Object, pathspecs : []string) -> Error_Code                                                                           { return _reset_default(repo, target, pathspecs); };

////////////////////////////////////////////
//// git_revparse
////
revparse_single             :: inline proc(repo : ^Repository, spec : string) -> (^Object, Error_Code)                                                                                         { return _revparse_single(repo, spec); }

////////////////////////////////////////////
//// git_object
////
object_lookup               :: inline proc(repo : ^Repository, id : Oid, otype : Obj_Type) -> (^Object, Error_Code)                                                                            { return _object_lookup(repo, id, otype); }
object_type                 :: inline proc(obj : ^Object) -> Obj_Type                                                                                                                          { return git_object_type(obj); }

////////////////////////////////////////////
//// git_*_init_options
////
fetch_init_options          :: inline proc(version : u32 = FETCH_OPTIONS_VERSION)       -> (Fetch_Options, i32)                                                                                { return _fetch_init_options(version); }
stash_apply_init_options    :: inline proc(version : u32 = STASH_APPLY_OPTIONS_VERSION) -> (Stash_Apply_Options, i32)                                                                          { return _stash_apply_init_options(version); }
status_init_options         :: inline proc(version : u32 = STATUS_OPTIONS_VERSION)      -> (Status_Options, i32)                                                                               { return _status_init_options(version); }
checkout_init_options       :: inline proc(version : u32 = CHECKOUT_OPTIONS_VERSION)    -> (Checkout_Options, i32)                                                                             { return _checkout_init_options(version); }
push_init_options           :: inline proc(version : u32 = PUSH_OPTIONS_VERSION)        -> (Push_Options, i32)                                                                                 { return _push_init_options(version); }
proxy_init_options          :: inline proc(version : u32 = PROXY_OPTIONS_VERSION)       -> (Proxy_Options, i32)                                                                                { return _proxy_init_options(version); }

////////////////////////////////////////////
//// git_graph_*
////
graph_ahead_behind          :: inline proc(repo : ^Repository, local : Oid, upstream : Oid) -> (ahead : uint, behind : uint, err : Error_Code)                                                 { return _graph_ahead_behind(repo, local, upstream); }

////////////////////////////////////////////
//// git_err
////
err_last        :: proc() -> Error {
    err := giterr_last();
    if err == nil {
        return Error{"N/A", ErrorType.Unknown};
    }
    str := strings.to_odin_string(err.message);
    return Error{str, err.klass};
}


////////////////////////////////////////////
//// 
////    IMPLEMENTATION
////
////////////////////////////////////////////

///////////////////////// Odin UTIL /////////////////////////

Misc_Buf :: enum {
    One   = 0,
    Two   = 1,
    Three = 2,
    Four  = 3,
} 

_MISC_BUF_SIZE :: 4096;
@(thread_local) misc_bufs : [4][_MISC_BUF_SIZE]u8;

_make_misc_string :: proc(chosen_buf : Misc_Buf, fmt_: string, args: ...any) -> ^byte {
    buf := misc_bufs[chosen_buf][..];
    s := fmt.bprintf(buf, fmt_, ...args);
    buf[len(s)] = 0;
    return cast(^byte)&buf[0];
}

_str_array_to_slice :: proc(stra : ^Str_Array) -> []string {
    raw_strings := mem.slice_ptr(stra.strings, int(stra.count));
    res := make([]string, int(stra.count));
    for _, i in res {
        res[i] = strings.to_odin_string(raw_strings[i]);
    }
    return res;
}

_slice_to_str_array :: proc(slice : []string) -> Str_Array {
      cslice := make([]^u8, len(slice));
      for _, i in slice {
            cslice[i] = &(slice[i])[0];
      }
      return Str_Array{&cslice[0], uint(len(cslice))};
}

_free_str_array :: proc(stra : ^Str_Array) {
    raw_strings := mem.slice_ptr(stra.strings, int(stra.count));
    for _, i in raw_strings {
        _global.free(raw_strings[i]);
    }
}

///////////////////////// Odin Wrappers /////////////////////////

_repository_init :: proc(path : string, is_bare : bool = false) -> (^Repository, Error_Code) {
    repo : ^Repository = nil;
    err := git_repository_init(&repo, _make_misc_string(Misc_Buf.One, path), u32(is_bare));
    return repo, err;
}

_repository_init_ext :: proc(path : string, opts : ^Repository_Init_Options) -> (^Repository, Error_Code) {
    repo : ^Repository = nil;
    err := git_repository_init_ext(&repo, _make_misc_string(Misc_Buf.One, path), opts);
    return repo, err;
}

_repository_open_ext :: proc(path : string, flags : Repository_Open_Flags, ceiling_dirs : string) -> (^Repository, Error_Code) {
    repo : ^Repository = nil;
    err := git_repository_open_ext(&repo, _make_misc_string(Misc_Buf.One, path), flags, _make_misc_string(Misc_Buf.Two, ceiling_dirs));
    return repo, err;
}

_repository_head :: proc(repo : ^Repository) -> (^Reference, Error_Code) {
    ref : ^Reference = nil;
    err := git_repository_head(&ref, repo);
    return ref, err;
}

_repository_set_head :: proc(repo : ^Repository, refname : string) -> Error_Code {
    return git_repository_set_head(repo, _make_misc_string(Misc_Buf.One, "%s", refname));
}

_repository_path :: proc(repo : ^Repository) -> string {
    if path := git_repository_path(repo); path != nil {
        return strings.to_odin_string(path);
    }

    return "";
}

_is_repository  :: proc(path : string) -> bool {
    if git_repository_open_ext(nil, _make_misc_string(Misc_Buf.One, path), Repository_Open_Flags.No_Search, nil) == 0 {
        return true;
    } else {
        return false;
    }
}

_clone :: proc(url : string, local_path : string, options : ^Clone_Options) -> (^Repository, Error_Code) {
    repo : ^Repository = nil;
    err := git_clone(&repo, _make_misc_string(Misc_Buf.One, url), _make_misc_string(Misc_Buf.Two, local_path), options);
    return repo, err;
}

_clone_init_options :: proc(version : u32) -> (Clone_Options, Error_Code) {
    options: Clone_Options;
    err := git_clone_init_options(&options, version);
    return options, err;
}

_repository_index :: proc(repo : ^Repository) -> (^Index, Error_Code) {
    index : ^Index = nil;
    err := git_repository_index(&index, repo);
    return index, err;
}

_remote_lookup :: proc(repo : ^Repository, name : string = "origin") -> (^Remote, Error_Code) {
    rem : ^Remote = nil;
    err := git_remote_lookup(&rem, repo, _make_misc_string(Misc_Buf.One, name));
    return rem, err;
}

_remote_list   :: proc(repo : ^Repository) -> ([]string, Error_Code) {
    strs := Str_Array{};
    err := git_remote_list(&strs, repo);
    res := _str_array_to_slice(&strs);
    return res, err;
}

_remote_init_callbacks :: proc() -> (Remote_Callbacks, Error_Code) {
    cb := Remote_Callbacks{};
    err := git_remote_init_callbacks(&cb, 1);
    return cb, err;
}

_remote_fetch :: proc(remote : ^Remote, refspecs : []string, opts : ^Fetch_Options, reflog_message : string = nil) -> Error_Code {
    sa := Str_Array{};
    if refspecs != nil && len(refspecs) > 0 {
        sa = _slice_to_str_array(refspecs);
    }
    err := git_remote_fetch(remote, &sa, opts, _make_misc_string(Misc_Buf.One, reflog_message));
    _free_str_array(&sa);
    return err;
}

_remote_push :: proc(remote : ^Remote, refspecs : []string, opts : ^Push_Options) -> Error_Code {
    sa := Str_Array{};
    if refspecs != nil && len(refspecs) > 0 {
        sa = _slice_to_str_array(refspecs);
    }
    err := git_remote_push(remote, &sa, opts);
    _free_str_array(&sa);
    return err;
}

_remote_update_tips :: proc(remote : ^Remote, 
                            callbacks : ^Remote_Callbacks, 
                            update_fetchhead : bool, 
                            download_tags : Remote_Autotag_Option_Flags, 
                            reflog_message : string) -> Error_Code {
    return git_remote_update_tips(remote, 
                               callbacks, 
                               update_fetchhead, 
                               download_tags, 
                               _make_misc_string(Misc_Buf.One, reflog_message));
}

_remote_name :: proc(remote : ^Remote) -> string {
    c_str := git_remote_name(remote);
    return strings.to_odin_string(c_str);
}

_index_new :: proc() -> (^Index, Error_Code) {
    out : ^Index;
    err := git_index_new(&out);
    return out, err;
}

_index_add_bypath :: proc(index : ^Index, path : string) -> Error_Code {
    err := git_index_add_bypath(index, _make_misc_string(Misc_Buf.One, path));
    return err;
}

_index_remove_bypath :: proc(index : ^Index, path : string) -> Error_Code {
    err := git_index_remove_bypath(index, _make_misc_string(Misc_Buf.One, path));
    return err;
}

_index_write_tree :: proc(index : ^Index) -> (Oid, Error_Code) {
    id : Oid;
    err := git_index_write_tree(&id, index);
    return id, err;
}

_cred_userpass_plaintext_new :: proc(username : string, password : string) -> (^Cred, Error_Code) {
    cred : ^Cred = nil;
    err := git_cred_userpass_plaintext_new(&cred, _make_misc_string(Misc_Buf.One, username), _make_misc_string(Misc_Buf.Two, password));
    return cred, err;
}

_cred_ssh_key_from_agent :: proc(username : string) -> (^Cred, Error_Code) {
    cred : ^Cred = nil;
    err := git_cred_ssh_key_from_agent(&cred, _make_misc_string(Misc_Buf.One, username));
    return cred, err;
} 

_status_list_new :: proc(repo : ^Repository, opts : ^Status_Options) -> (^Status_List, Error_Code) {
    out : ^Status_List = nil;
    err := git_status_list_new(&out, repo, opts);
    return out, err;
}

_reference_name_to_id :: proc(repo : ^Repository, name : string) -> (Oid, Error_Code) {
    id := Oid{};
    err := git_reference_name_to_id(&id, repo, _make_misc_string(Misc_Buf.One, name));
    return id, err;
}

_reference_symbolic_target :: proc(ref : ^Reference) -> string {
    c_str := git_reference_symbolic_target(ref);
    return strings.to_odin_string(c_str);
}

_reference_name :: proc(ref : ^Reference) -> string {
    c_str := git_reference_name(ref);
    return strings.to_odin_string(c_str);
}

_reference_peel :: proc(ref : ^Reference, kind : Obj_Type) -> (^Object, Error_Code) {
    out : ^Object;
    err := git_reference_peel(&out, ref, kind);
    return out, err;
}

_commit_create :: proc(repo : ^Repository, update_ref : string, author, committer : ^Signature, message : string, tree : ^Tree, parents : ...^Commit) -> (Oid, Error_Code) {
    id : Oid;
    encoding := "UTF-8\x00";
    err := git_commit_create(&id, repo, _make_misc_string(Misc_Buf.One, update_ref), author._git_orig, committer._git_orig, &encoding[0], _make_misc_string(Misc_Buf.Two, message), tree, uint(len(parents)), &parents[0]);
    return id, err;
}

_commit_lookup :: proc(repo : ^Repository, id : ^Oid) -> (^Commit, Error_Code) {
    commit : ^Commit = nil;
    err := git_commit_lookup(&commit, repo, id);
    return commit, err;
}

_commit_committer :: proc(commit : ^Commit) -> Signature {
    gsig := git_commit_committer(commit);
    //NOTE(Hoej): YUCK!
    sig := Signature {
        gsig,
        strings.new_string(strings.to_odin_string(gsig.name)),
        strings.new_string(strings.to_odin_string(gsig.email)),
        gsig.time_when
    };

    return sig;
}

_commit_author :: proc(commit : ^Commit) -> Signature {
    gsig := git_commit_author(commit);
    //NOTE(Hoej): YUCK!
    sig := Signature {
        gsig,
        strings.new_string(strings.to_odin_string(gsig.name)),
        strings.new_string(strings.to_odin_string(gsig.email)),
        gsig.time_when
    };

    return sig;
}

_commit_message :: proc(commit : ^Commit) -> string {
    c_str := git_commit_message(commit);
    return strings.to_odin_string(c_str);
}

_commit_summary :: proc(commit : ^Commit) -> string {
    c_str := git_commit_summary(commit);
    return strings.to_odin_string(c_str);
}

_commit_raw_header :: proc(commit : ^Commit) -> string {
    ptr := git_commit_raw_header(commit);
    return strings.to_odin_string(ptr);
}

_branch_iterator_new :: proc(repo : ^Repository, list_flags : Branch_Type) -> (^Branch_Iterator, Error_Code) {
    iter : ^Branch_Iterator = nil;
    err := git_branch_iterator_new(&iter, repo, list_flags);
    return iter, err;
}

_branch_next :: proc(iter : ^Branch_Iterator) -> (^Reference, Branch_Type, Error_Code) {
    ref : ^Reference = nil;
    flags : Branch_Type;
    err := git_branch_next(&ref, &flags, iter);
    return ref, flags, err;
}

_branch_name :: proc(ref : ^Reference) -> (string, Error_Code) {
    c_str : ^byte;
    err := git_branch_name(&c_str, ref);
    return strings.to_odin_string(c_str), err;
}

_branch_create :: proc(repo : ^Repository, branch_name : string, target : ^Commit, force : bool = false) -> (^Reference, Error_Code) {
    ref : ^Reference = nil;
    err := git_branch_create(&ref, repo, _make_misc_string(Misc_Buf.One, branch_name), target, i32(force));
    return ref, err;
}

_branch_upstream :: proc(branch : ^Reference) -> (^Reference, Error_Code) {
    ref : ^Reference = nil;
    err := git_branch_upstream(&ref, branch);
    return ref, err;
}

_branch_set_upstream :: proc(branch : ^Reference, upstream_name : string) -> Error_Code {
    return git_branch_set_upstream(branch, _make_misc_string(Misc_Buf.One, upstream_name));
}

_revparse_single :: proc(repo : ^Repository, spec : string) -> (^Object, Error_Code) {
    obj : ^Object = nil;
    err := git_revparse_single(&obj, repo, _make_misc_string(Misc_Buf.One, spec));
    return obj, err;
}

_stash_save :: proc(repo : ^Repository, stasher : ^Signature, message : string, flags : Stash_Flags) -> (Oid, Error_Code) {
    out : Oid;
    err := git_stash_save(&out, repo, stasher._git_orig, _make_misc_string(Misc_Buf.One, message), flags);
    return out, err;
}

_signature_now :: proc(name, email : string) -> (Signature, Error_Code) {
    out : ^Git_Signature;
    err := git_signature_now(&out, _make_misc_string(Misc_Buf.One, name), _make_misc_string(Misc_Buf.Two, email));
    return Signature {
        _git_orig = out,
        name      = strings.new_string(strings.to_odin_string(out.name)),
        email     = strings.new_string(strings.to_odin_string(out.email)),
        time_when = out.time_when,
    }, err;
}

_signature_free :: proc(sig : ^Signature) {
    _global.free(sig.name);
    _global.free(sig.email);
    free(sig._git_orig);
}

_reset_default :: proc(repo : ^Repository, target : ^Object, pathspecs : []string) -> Error_Code {
      stra := _slice_to_str_array(pathspecs);
      return git_reset_default(repo, target, &stra);
}

_revwalk_new :: proc(repo : ^Repository) -> (^Revwalk, Error_Code) {
    ptr : ^Revwalk = nil;
    err := git_revwalk_new(&ptr, repo);
    return ptr, err;
}

_revwalk_next :: proc(walk : ^Revwalk) -> (Oid, Error_Code) {
    id : Oid;
    err := git_revwalk_next(&id, walk);
    return id, err;
}

_revwalk_push_range :: proc(walk : ^Revwalk, range : string) -> Error_Code {
    return git_revwalk_push_range(walk, _make_misc_string(Misc_Buf.One, range));
}

_revwalk_push_ref :: proc(walk : ^Revwalk, refname : string) -> Error_Code {
    return git_revwalk_push_ref(walk, _make_misc_string(Misc_Buf.One, refname));
}

_object_lookup :: proc(repo : ^Repository, id : Oid, otype : Obj_Type) -> (^Object, Error_Code) {
    object : ^Object;
    err := git_object_lookup(&object, repo, &id, otype);
    return object, err;
}

_fetch_init_options :: proc(version : u32) -> (Fetch_Options, i32) {
      result := Fetch_Options{};
      err := git_fetch_init_options(&result, version);
      return result, err;
}

_stash_apply_init_options :: proc(version : u32) -> (Stash_Apply_Options, i32) {
      result := Stash_Apply_Options{};
      err := git_stash_apply_init_options(&result, version);
      return result, err;
}

_status_init_options :: proc(version : u32) -> (Status_Options, i32) {
      result := Status_Options{};
      err := git_status_init_options(&result, version);
      return result, err;
}

_checkout_init_options :: proc(version : u32) -> (Checkout_Options, i32) {
      result := Checkout_Options{};
      err := git_checkout_init_options(&result, version);
      return result, err;
}

_push_init_options :: proc(version : u32) -> (Push_Options, i32) {
      result := Push_Options{};
      err := git_push_init_options(&result, version);
      return result, err;
}

_proxy_init_options :: proc(version : u32) -> (Proxy_Options, i32) {
      result := Proxy_Options{};
      err := git_proxy_init_options(&result, version);
      return result, err;
}

_graph_ahead_behind :: proc(repo : ^Repository, local : Oid, upstream : Oid) -> (ahead : uint, behind : uint, err : Error_Code) {
    ahead : uint = 0;
    behind : uint = 0;
    err := git_graph_ahead_behind(&ahead, &behind, repo, &local, &upstream);
    return ahead, behind, err;
}


@(default_calling_convention="stdcall")
foreign libgit {
    giterr_last :: proc() -> ^Git_Error ---;

    //libgit2    
    git_libgit2_init                :: proc() -> Error_Code ---;
    git_libgit2_shutdown            :: proc() -> Error_Code ---;
    git_libgit2_features            :: proc() -> Lib_Features ---;
    git_libgit2_version             :: proc(major : ^i32, minor : ^i32, rev : ^i32) ---;

    //Repository
    git_repository_init             :: proc(out : ^^Repository, path : ^byte, is_bare : u32) -> Error_Code ---;
    git_repository_init_ext         :: proc(out : ^^Repository, path : ^byte, pots : ^Repository_Init_Options) -> Error_Code ---;
    git_repository_free             :: proc(repo : ^Repository) ---;
    git_repository_open_ext         :: proc(out : ^^Repository, path : ^byte, flags : Repository_Open_Flags, ceiling_dirs : ^byte) -> Error_Code ---;
    git_repository_head             :: proc(out : ^^Reference, repo : ^Repository) -> Error_Code ---;
    git_repository_set_head         :: proc(repo : ^Repository, refname : ^byte) -> Error_Code ---;
    git_repository_path             :: proc(repo : ^Repository) -> ^u8 ---;
    git_repository_index            :: proc(out : ^^Index, repo : ^Repository) -> Error_Code ---;
    git_repository_set_index        :: proc(repo : ^Repository, index : ^Index) ---;
   
    //Clone
    git_clone                       :: proc(out : ^^Repository, url : ^byte, local_path : ^byte, options : ^Clone_Options) -> Error_Code ---;
    git_clone_init_options          :: proc(options : ^Clone_Options, version: u32) -> Error_Code ---;

    //Status
    git_status_foreach              :: proc(repo : ^Repository, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    git_status_foreach_ext          :: proc(repo : ^Repository, opts : ^Status_Options, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    git_status_list_new             :: proc(out : ^^Status_List, repo : ^Repository, opts : ^Status_Options) -> Error_Code ---;
    git_status_list_free            :: proc(list : ^Status_List) ---;
    git_status_list_entrycount      :: proc(statuslist: ^Status_List) -> uint ---;
    git_status_byindex              :: proc(statuslist : ^Status_List, idx : uint) -> ^Status_Entry ---;

    // Commits
    git_commit_create               :: proc(id : ^Oid, repo : ^Repository, update_ref : ^u8, author : ^Git_Signature, committer : ^Git_Signature, message_encoding : ^u8, message : ^u8, tree : ^Tree, parent_count : uint, parents : ^^Commit) -> Error_Code ---;
    git_commit_free                 :: proc(out: ^Commit) ---;
    git_commit_lookup               :: proc(out: ^^Commit, repo: ^Repository, id: ^Oid) -> Error_Code ---;
    git_commit_parentcount          :: proc(commit : ^Commit) -> Error_Code ---;
    git_commit_parent_id            :: proc(commit : ^Commit, n : u32) -> ^Oid ---;
    git_commit_message              :: proc(commit : ^Commit) -> ^u8 ---;
    git_commit_committer            :: proc(commit : ^Commit) -> ^Git_Signature ---;
    git_commit_author               :: proc(commit : ^Commit) -> ^Git_Signature ---;
    git_commit_summary              :: proc(commit : ^Commit) -> ^byte ---;
    git_commit_raw_header           :: proc(commit : ^Commit) -> ^byte ---;

    //Signature
    git_signature_now               :: proc(out : ^^Git_Signature, name, email : ^byte) -> Error_Code ---;
    git_signature_free              :: proc(sig : ^Git_Signature) ---;

    // Oid
    git_oid_from_str                :: proc(out: ^Oid, str: ^u8) -> Error_Code ---;

    //Remote
    git_remote_lookup               :: proc(out : ^^Remote, repo : ^Repository, name : ^byte) -> Error_Code ---;
    git_remote_list                 :: proc(out : ^Str_Array, repo : ^Repository) -> Error_Code ---;
    git_remote_default_branch       :: proc(out : ^Buf, remote : ^Remote) -> Error_Code ---;
    git_remote_connect              :: proc(remote : ^Remote, Direction : Direction, callbacks : ^Remote_Callbacks, proxy_opts : ^Proxy_Options, custom_headers : ^Str_Array) -> Error_Code ---;
    git_remote_disconnect           :: proc(remote : ^Remote) ---;
    git_remote_init_callbacks       :: proc(opts : ^Remote_Callbacks, version : u32 = REMOTE_CALLBACKS_VERSION) -> Error_Code ---;
    git_remote_connected            :: proc(remote : ^Remote) -> Error_Code ---;
    git_remote_fetch                :: proc(remote : ^Remote, refspecs : ^Str_Array, opts : ^Fetch_Options, reflog_message : ^byte) -> Error_Code ---;
    git_remote_free                 :: proc(remote : ^Remote) ---;
    git_remote_push                 :: proc(remote : ^Remote, refspecs : ^Str_Array, opts : ^Push_Options) -> Error_Code ---;
    git_remote_update_tips          :: proc(remote : ^Remote, callbacks : ^Remote_Callbacks, update_fetchhead : bool, download_tags : Remote_Autotag_Option_Flags, reflog_message : ^byte) -> Error_Code ---;
    git_remote_name                 :: proc(remote : ^Remote) -> ^byte ---;

    //Index
    git_index_new                   :: proc(out : ^^Index) -> Error_Code ---;
    git_index_free                  :: proc(index : ^Index) -> Error_Code ---;
    git_index_add                   :: proc(index : ^Index, entry : ^Index_Entry) -> Error_Code ---;
    git_index_add_bypath            :: proc(index : ^Index, path : ^byte) -> Error_Code ---;
    git_index_remove                :: proc(index : ^Index, entry : ^Index_Entry) -> Error_Code ---;
    git_index_remove_bypath         :: proc(index : ^Index, path : ^byte) -> Error_Code ---;
    git_index_entrycount            :: proc(index : ^Index) -> uint ---;
    git_index_get_byindex           :: proc(index : ^Index, n : uint) -> ^Index_Entry ---;
    git_index_write                 :: proc(index : ^Index) -> Error_Code ---;
    git_index_write_tree            :: proc(id : ^Oid, index : ^Index) -> Error_Code ---;

    //Cred
    git_cred_userpass_plaintext_new :: proc(out : ^^Cred, username : ^byte, password : ^byte) -> Error_Code ---;
    git_cred_has_username           :: proc(cred : ^Cred) -> bool ---;
    git_cred_ssh_key_from_agent     :: proc(out : ^^Cred, username : ^byte) -> Error_Code ---;

    //Reset
    git_reset_default               :: proc(repo : ^Repository, target : ^Object, pathspecs : ^Str_Array) -> Error_Code ---;

    //Reference
    git_reference_name_to_id        :: proc(out : ^Oid, repo : ^Repository, name : ^byte) -> Error_Code ---;
    git_reference_symbolic_target   :: proc(ref : ^Reference) -> ^byte ---;
    git_reference_name              :: proc(ref : ^Reference) -> ^byte ---;
    git_reference_peel              :: proc(out : ^^Object, ref : ^Reference, kind : Obj_Type) -> Error_Code ---;
    git_reference_free              :: proc(ref : ^Reference) ---;
    git_reference_is_branch         :: proc(ref : ^Reference) -> bool ---;

    //Object
    git_object_lookup               :: proc(object : ^^Object, repo : ^Repository, id : ^Oid, otype : Obj_Type) -> Error_Code ---;
    git_object_free                 :: proc(object : ^Object)          ---;
    git_object_type                 :: proc(obj : ^Object)    -> Obj_Type ---;

    //Branch
    git_branch_create               :: proc(out : ^^Reference, repo : ^Repository, branch_name : ^byte, target : ^Commit, force : i32) -> Error_Code ---;
    git_branch_name                 :: proc(out : ^^byte, ref : ^Reference) -> Error_Code ---;
    git_branch_iterator_new         :: proc(out : ^^Branch_Iterator, repo : ^Repository, list_flags : Branch_Type) -> Error_Code ---;
    git_branch_iterator_free        :: proc(iter : ^Branch_Iterator) ---;
    git_branch_next                 :: proc(out : ^^Reference, out_type : ^Branch_Type, iter : ^Branch_Iterator) -> Error_Code ---;
    git_branch_delete               :: proc(branch : ^Reference) -> Error_Code ---;
    git_branch_is_checked_out       :: proc(branch : ^Reference) -> bool ---;
    git_branch_upstream             :: proc(out : ^^Reference, branch : ^Reference) -> Error_Code ---;
    git_branch_set_upstream         :: proc(branch : ^Reference, upstream_name : ^byte) -> Error_Code ---;

    //Revparse
    git_revparse_single             :: proc(out : ^^Object, repo : ^Repository, spec : ^byte) -> Error_Code ---;

    //Checkout
    git_checkout_tree               :: proc(repo : ^Repository, treeish : ^Object, opts : ^Checkout_Options) -> Error_Code ---;

    // Stash
    git_stash_save                  :: proc(out : ^Oid, repo : ^Repository, stasher : ^Git_Signature, message : ^byte, flags : Stash_Flags) -> Error_Code ---;
    git_stash_apply                 :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    git_stash_pop                   :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    git_stash_drop                  :: proc(repo : ^Repository, index : uint) -> Error_Code ---;
    git_stash_foreach               :: proc(repo : ^Repository, callback : Stash_Cb, payload : rawptr, index : uint) -> Error_Code ---;

    //Revwalk
    git_revwalk_new                 :: proc(out : ^^Revwalk, repo : ^Repository) -> Error_Code ---;
    git_revwalk_next                :: proc(out : ^Oid, walk : ^Revwalk) -> Error_Code ---;
    git_revwalk_push_range          :: proc(walk : ^Revwalk, range : ^byte) -> Error_Code ---;
    git_revwalk_push_ref            :: proc(walk : ^Revwalk, refname : ^byte) -> Error_Code ---;
    git_revwalk_free                :: proc(walk : ^Revwalk) ---;

    //init_options
    git_fetch_init_options          :: proc(opts : ^Fetch_Options,       version : u32) -> i32 ---;
    git_stash_apply_init_options    :: proc(opts : ^Stash_Apply_Options, version : u32) -> i32 ---;
    git_status_init_options         :: proc(opts : ^Status_Options,      version : u32) -> i32 ---;
    git_checkout_init_options       :: proc(opts : ^Checkout_Options,    version : u32) -> i32 ---;
    git_push_init_options           :: proc(opts : ^Push_Options,        version : u32) -> i32 ---;
    git_proxy_init_options          :: proc(opts : ^Proxy_Options,       version : u32) -> i32 ---;

    //Graph
    git_graph_ahead_behind          :: proc(ahead : ^uint, behind : ^uint, repo : ^Repository, local : ^Oid, upstream : ^Oid) -> Error_Code ---;
}
