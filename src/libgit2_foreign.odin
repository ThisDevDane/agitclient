/*
 *  @Name:     libgit2_foreign
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-12-2017 23:52:55 UTC-5
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 21-01-2018 22:18:51 UTC+1
 *  
 *  @Description:
 *  
 */

foreign import libgit "../external/libgit2.lib";

using import "libgit2_types.odin"

@(link_prefix="git_", default_calling_convention="stdcall")
foreign libgit {
    @(link_name="giterr_last") err_last :: proc() -> ^Git_Error ---;

    // libgit2
    libgit2_init                :: proc() -> Error_Code ---;
    libgit2_shutdown            :: proc() -> Error_Code ---;
    libgit2_features            :: proc() -> Lib_Features ---;
    libgit2_version             :: proc(major : ^i32, minor : ^i32, rev : ^i32) ---;

    // Repository
    repository_init             :: proc(out : ^^Repository, path : ^byte, is_bare : u32) -> Error_Code ---;
    repository_init_ext         :: proc(out : ^^Repository, path : ^byte, pots : ^Repository_Init_Options) -> Error_Code ---;
    repository_free             :: proc(repo : ^Repository) ---;
    repository_open_ext         :: proc(out : ^^Repository, path : ^byte, flags : Repository_Open_Flags, ceiling_dirs : ^byte) -> Error_Code ---;
    repository_head             :: proc(out : ^^Reference, repo : ^Repository) -> Error_Code ---;
    repository_set_head         :: proc(repo : ^Repository, refname : ^byte) -> Error_Code ---;
    repository_path             :: proc(repo : ^Repository) -> ^u8 ---;
    repository_index            :: proc(out : ^^Index, repo : ^Repository) -> Error_Code ---;
    repository_set_index        :: proc(repo : ^Repository, index : ^Index) ---;

    // Clone
    clone                       :: proc(out : ^^Repository, url : ^byte, local_path : ^byte, options : ^Clone_Options) -> Error_Code ---;
    clone_init_options          :: proc(options : ^Clone_Options, version: u32) -> Error_Code ---;

    // Status
    status_foreach              :: proc(repo : ^Repository, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    status_foreach_ext          :: proc(repo : ^Repository, opts : ^Status_Options, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    status_list_new             :: proc(out : ^^Status_List, repo : ^Repository, opts : ^Status_Options) -> Error_Code ---;
    status_list_free            :: proc(list : ^Status_List) ---;
    status_list_entrycount      :: proc(statuslist: ^Status_List) -> uint ---;
    status_byindex              :: proc(statuslist : ^Status_List, idx : uint) -> ^Status_Entry ---;

    // Commits
    commit_create               :: proc(id : ^Oid, repo : ^Repository, update_ref : ^u8, author : ^Git_Signature, committer : ^Git_Signature, message_encoding : ^u8, message : ^u8, tree : ^Tree, parent_count : uint, parents : ^^Commit) -> Error_Code ---;
    commit_free                 :: proc(out : ^Commit) ---;
    commit_lookup               :: proc(out : ^^Commit, repo : ^Repository, id : ^Oid) -> Error_Code ---;
    commit_parent               :: proc(out : ^^Commit, commit : ^Commit, n : u32) -> i32 ---;
    commit_parentcount          :: proc(commit : ^Commit) -> Error_Code ---;
    commit_parent_id            :: proc(commit : ^Commit, n : u32) -> ^Oid ---;
    commit_message              :: proc(commit : ^Commit) -> ^u8 ---;
    commit_committer            :: proc(commit : ^Commit) -> ^Git_Signature ---;
    commit_author               :: proc(commit : ^Commit) -> ^Git_Signature ---;
    commit_summary              :: proc(commit : ^Commit) -> ^byte ---;
    commit_raw_header           :: proc(commit : ^Commit) -> ^byte ---;
    commit_tree                 :: proc(tree_out : ^^Tree, commit : ^Commit) -> i32 ---;

    // Signature
    signature_now               :: proc(out : ^^Git_Signature, name, email : ^byte) -> Error_Code ---;
    signature_free              :: proc(sig : ^Git_Signature) ---;

    // Oid
    oid_from_str                :: proc(out: ^Oid, str: ^u8) -> Error_Code ---;

    // Remote
    remote_lookup               :: proc(out : ^^Remote, repo : ^Repository, name : ^byte) -> Error_Code ---;
    remote_list                 :: proc(out : ^Str_Array, repo : ^Repository) -> Error_Code ---;
    remote_default_branch       :: proc(out : ^Buf, remote : ^Remote) -> Error_Code ---;
    remote_connect              :: proc(remote : ^Remote, Direction : Direction, callbacks : ^Remote_Callbacks, proxy_opts : ^Proxy_Options, custom_headers : ^Str_Array) -> Error_Code ---;
    remote_disconnect           :: proc(remote : ^Remote) ---;
    remote_init_callbacks       :: proc(opts : ^Remote_Callbacks, version : u32 = REMOTE_CALLBACKS_VERSION) -> Error_Code ---;
    remote_connected            :: proc(remote : ^Remote) -> b32 ---;
    remote_fetch                :: proc(remote : ^Remote, refspecs : ^Str_Array, opts : ^Fetch_Options, reflog_message : ^byte) -> Error_Code ---;
    remote_free                 :: proc(remote : ^Remote) ---;
    remote_push                 :: proc(remote : ^Remote, refspecs : ^Str_Array, opts : ^Push_Options) -> Error_Code ---;
    remote_update_tips          :: proc(remote : ^Remote, callbacks : ^Remote_Callbacks, update_fetchhead : b32, download_tags : Remote_Autotag_Option_Flags, reflog_message : ^byte) -> Error_Code ---;
    remote_name                 :: proc(remote : ^Remote) -> ^byte ---;

    // Index
    index_new                   :: proc(out : ^^Index) -> Error_Code ---;
    index_free                  :: proc(index : ^Index) -> Error_Code ---;
    index_add                   :: proc(index : ^Index, entry : ^Index_Entry) -> Error_Code ---;
    index_add_bypath            :: proc(index : ^Index, path : ^byte) -> Error_Code ---;
    index_remove                :: proc(index : ^Index, entry : ^Index_Entry) -> Error_Code ---;
    index_remove_bypath         :: proc(index : ^Index, path : ^byte) -> Error_Code ---;
    index_entrycount            :: proc(index : ^Index) -> uint ---;
    index_get_byindex           :: proc(index : ^Index, n : uint) -> ^Index_Entry ---;
    index_write                 :: proc(index : ^Index) -> Error_Code ---;
    index_write_tree            :: proc(id : ^Oid, index : ^Index) -> Error_Code ---;

    // Cred
    cred_userpass_plaintext_new :: proc(out : ^^Cred, username : ^byte, password : ^byte) -> Error_Code ---;
    cred_has_username           :: proc(cred : ^Cred) -> b32 ---;
    cred_ssh_key_from_agent     :: proc(out : ^^Cred, username : ^byte) -> Error_Code ---;

    // Reset
    reset_default               :: proc(repo : ^Repository, target : ^Object, pathspecs : ^Str_Array) -> Error_Code ---;

    // Reference
    reference_name_to_id        :: proc(out : ^Oid, repo : ^Repository, name : ^byte) -> Error_Code ---;
    reference_symbolic_target   :: proc(ref : ^Reference) -> ^byte ---;
    reference_name              :: proc(ref : ^Reference) -> ^byte ---;
    reference_peel              :: proc(out : ^^Object, ref : ^Reference, kind : Obj_Type) -> Error_Code ---;
    reference_free              :: proc(ref : ^Reference) ---;
    reference_is_branch         :: proc(ref : ^Reference) -> b32 ---;

    // Object
    object_lookup               :: proc(object : ^^Object, repo : ^Repository, id : ^Oid, otype : Obj_Type) -> Error_Code ---;
    object_free                 :: proc(object : ^Object)          ---;
    object_type                 :: proc(obj : ^Object)    -> Obj_Type ---;

    // Diff
    // diff_blob_to_buffer                    :: proc() ---;
    // diff_blobs                             :: proc() ---;
    // diff_buffers                           :: proc() ---;
    // diff_commit_as_email                   :: proc() ---;
    // diff_find_init_options                 :: proc() ---;
    diff_find_similar                      :: proc(diff : ^Diff, options : ^Diff_Find_Options) -> i32 ---; // 0 on success, -1 on failure
    diff_foreach                           :: proc(diff : ^Diff, file_cb : Diff_File_Cb, binary_cb : Diff_Binary_Cb, hunk_cb : Diff_Hunk_Cb, line_cb : Diff_Line_Cb, payload : rawptr) -> Error_Code ---;
    // diff_format_email                      :: proc() ---;
    // diff_format_email_init_options         :: proc() ---;
    diff_free                              :: proc(diff : ^Diff) ---;
    // diff_from_buffer                       :: proc() ---;
    // diff_get_delta                         :: proc() ---;
    // diff_get_perfdata                      :: proc() ---;
    // diff_get_stats                         :: proc() ---;
    // diff_index_to_index                    :: proc() ---;
    diff_index_to_workdir                  :: proc(diff : ^^Diff, repo : ^Repository, index : ^Index, opts : ^Diff_Options) -> Error_Code ---;
    // diff_init_options                      :: proc() ---;
    // diff_is_sorted_icase                   :: proc() ---;
    // diff_merge                             :: proc() ---;
    // diff_num_deltas                        :: proc() ---;
    // diff_num_deltas_of_type                :: proc() ---;
    diff_print                             :: proc(diff: ^Diff, format: Diff_Format, print_cb: Diff_Line_Cb, payload: rawptr) -> Error_Code ---; // Sometimes returns an error code?: "0 on success, non-zero callback return value, or error code"
    // diff_print_callback__to_buf            :: proc() ---;
    // diff_print_callback__to_file_handle    :: proc() ---;
    // diff_stats_deletions                   :: proc() ---;
    // diff_stats_files_changed               :: proc() ---;
    // diff_stats_free                        :: proc() ---;
    // diff_stats_insertions                  :: proc() ---;
    // diff_stats_to_buf                      :: proc() ---;
    // diff_status_char                       :: proc() ---;
    // diff_to_buf                            :: proc() ---;
    // diff_tree_to_index                     :: proc() ---;
    diff_tree_to_index                     :: proc(diff : ^^Diff, repo : ^Repository, old_tree : ^Tree, index : ^Index, opts : ^Diff_Options) -> Error_Code ---;
    diff_tree_to_tree                      :: proc(diff : ^^Diff, repo : ^Repository, old_tree, new_tree : ^Tree, opts : ^Diff_Options) -> Error_Code ---;
    // diff_tree_to_workdir                   :: proc() ---;
    diff_tree_to_workdir_with_index        :: proc(diff : ^^Diff, repo : ^Repository, old_tree : ^Tree, opts : ^Diff_Options) -> Error_Code ---;
    
    // Patch
    patch_free                  :: proc(patch : ^Patch) ---;
    patch_from_diff             :: proc(out : ^^Patch, diff : ^Diff, idx : uint) -> i32 ---;

    // Tree
    tree_lookup                 :: proc(out : ^^Tree, repo : ^Repository, id : ^Oid) -> i32 ---;

    // Branch
    branch_create               :: proc(out : ^^Reference, repo : ^Repository, branch_name : ^byte, target : ^Commit, force : i32) -> Error_Code ---;
    branch_name                 :: proc(out : ^^byte, ref : ^Reference) -> Error_Code ---;
    branch_iterator_new         :: proc(out : ^^Branch_Iterator, repo : ^Repository, list_flags : Branch_Type) -> Error_Code ---;
    branch_iterator_free        :: proc(iter : ^Branch_Iterator) ---;
    branch_next                 :: proc(out : ^^Reference, out_type : ^Branch_Type, iter : ^Branch_Iterator) -> Error_Code ---;
    branch_delete               :: proc(branch : ^Reference) -> Error_Code ---;
    branch_is_checked_out       :: proc(branch : ^Reference) -> b32 ---;
    branch_upstream             :: proc(out : ^^Reference, branch : ^Reference) -> Error_Code ---;
    branch_set_upstream         :: proc(branch : ^Reference, upstream_name : ^byte) -> Error_Code ---;

    // Revparse
    revparse_single             :: proc(out : ^^Object, repo : ^Repository, spec : ^byte) -> Error_Code ---;

    // Checkout
    checkout_tree               :: proc(repo : ^Repository, treeish : ^Object, opts : ^Checkout_Options) -> Error_Code ---;

    // Stash
    stash_save                  :: proc(out : ^Oid, repo : ^Repository, stasher : ^Git_Signature, message : ^byte, flags : Stash_Flags) -> Error_Code ---;
    stash_apply                 :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    stash_pop                   :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    stash_drop                  :: proc(repo : ^Repository, index : uint) -> Error_Code ---;
    stash_foreach               :: proc(repo : ^Repository, callback : Stash_Cb, payload : rawptr, index : uint) -> Error_Code ---;

    // Revwalk
    revwalk_new                 :: proc(out : ^^Revwalk, repo : ^Repository) -> Error_Code ---;
    revwalk_next                :: proc(out : ^Oid, walk : ^Revwalk) -> Error_Code ---;
    revwalk_push_range          :: proc(walk : ^Revwalk, range : ^byte) -> Error_Code ---;
    revwalk_push_ref            :: proc(walk : ^Revwalk, refname : ^byte) -> Error_Code ---;
    revwalk_free                :: proc(walk : ^Revwalk) ---;

    // init_options
    fetch_init_options          :: proc(opts : ^Fetch_Options,       version : u32) -> i32 ---;
    stash_apply_init_options    :: proc(opts : ^Stash_Apply_Options, version : u32) -> i32 ---;
    status_init_options         :: proc(opts : ^Status_Options,      version : u32) -> i32 ---;
    checkout_init_options       :: proc(opts : ^Checkout_Options,    version : u32) -> i32 ---;

    push_init_options           :: proc(opts : ^Push_Options,        version : u32) -> i32 ---;
    proxy_init_options          :: proc(opts : ^Proxy_Options,       version : u32) -> i32 ---;

    //Graph
    graph_ahead_behind          :: proc(ahead : ^uint, behind : ^uint, repo : ^Repository, local : ^Oid, upstream : ^Oid) -> Error_Code ---;
}
