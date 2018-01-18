/*
 *  @Name:     libgit2_foreign
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-12-2017 23:52:55 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 07-01-2018 17:58:30 UTC-5
 *  
 *  @Description:
 *  
 */

foreign import libgit "../external/libgit2.lib";

export "libgit2_types.odin"

@(default_calling_convention="stdcall")
foreign libgit {
    @(link_name="giterr_last") giterr_last :: proc() -> ^Git_Error ---;

    // libgit2
    git_libgit2_init                :: proc() -> Error_Code ---;
    git_libgit2_shutdown            :: proc() -> Error_Code ---;
    git_libgit2_features            :: proc() -> Lib_Features ---;
    git_libgit2_version             :: proc(major : ^i32, minor : ^i32, rev : ^i32) ---;

    // Repository
    git_repository_init             :: proc(out : ^^Repository, path : ^byte, is_bare : u32) -> Error_Code ---;
    git_repository_init_ext         :: proc(out : ^^Repository, path : ^byte, pots : ^Repository_Init_Options) -> Error_Code ---;
    git_repository_free             :: proc(repo : ^Repository) ---;
    git_repository_open_ext         :: proc(out : ^^Repository, path : ^byte, flags : Repository_Open_Flags, ceiling_dirs : ^byte) -> Error_Code ---;
    git_repository_head             :: proc(out : ^^Reference, repo : ^Repository) -> Error_Code ---;
    git_repository_set_head         :: proc(repo : ^Repository, refname : ^byte) -> Error_Code ---;
    git_repository_path             :: proc(repo : ^Repository) -> ^u8 ---;
    git_repository_index            :: proc(out : ^^Index, repo : ^Repository) -> Error_Code ---;
    git_repository_set_index        :: proc(repo : ^Repository, index : ^Index) ---;

    // Clone
    git_clone                       :: proc(out : ^^Repository, url : ^byte, local_path : ^byte, options : ^Clone_Options) -> Error_Code ---;
    git_clone_init_options          :: proc(options : ^Clone_Options, version: u32) -> Error_Code ---;

    // Status
    git_status_foreach              :: proc(repo : ^Repository, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    git_status_foreach_ext          :: proc(repo : ^Repository, opts : ^Status_Options, callback : Status_Cb, payload : rawptr) -> Error_Code ---;
    git_status_list_new             :: proc(out : ^^Status_List, repo : ^Repository, opts : ^Status_Options) -> Error_Code ---;
    git_status_list_free            :: proc(list : ^Status_List) ---;
    git_status_list_entrycount      :: proc(statuslist: ^Status_List) -> uint ---;
    git_status_byindex              :: proc(statuslist : ^Status_List, idx : uint) -> ^Status_Entry ---;

    // Commits
    git_commit_create               :: proc(id : ^Oid, repo : ^Repository, update_ref : ^u8, author : ^Git_Signature, committer : ^Git_Signature, message_encoding : ^u8, message : ^u8, tree : ^Tree, parent_count : uint, parents : ^^Commit) -> Error_Code ---;
    git_commit_free                 :: proc(out : ^Commit) ---;
    git_commit_lookup               :: proc(out : ^^Commit, repo : ^Repository, id : ^Oid) -> Error_Code ---;
    git_commit_parent               :: proc(out : ^^Commit, commit : ^Commit, n : u32) -> i32 ---;
    git_commit_parentcount          :: proc(commit : ^Commit) -> Error_Code ---;
    git_commit_parent_id            :: proc(commit : ^Commit, n : u32) -> ^Oid ---;
    git_commit_message              :: proc(commit : ^Commit) -> ^u8 ---;
    git_commit_committer            :: proc(commit : ^Commit) -> ^Git_Signature ---;
    git_commit_author               :: proc(commit : ^Commit) -> ^Git_Signature ---;
    git_commit_summary              :: proc(commit : ^Commit) -> ^byte ---;
    git_commit_raw_header           :: proc(commit : ^Commit) -> ^byte ---;
    git_commit_tree                 :: proc(tree_out : ^^Tree, commit : ^Commit) -> i32 ---;

    // Signature
    git_signature_now               :: proc(out : ^^Git_Signature, name, email : ^byte) -> Error_Code ---;
    git_signature_free              :: proc(sig : ^Git_Signature) ---;

    // Oid
    git_oid_from_str                :: proc(out: ^Oid, str: ^u8) -> Error_Code ---;

    // Remote
    git_remote_lookup               :: proc(out : ^^Remote, repo : ^Repository, name : ^byte) -> Error_Code ---;
    git_remote_list                 :: proc(out : ^Str_Array, repo : ^Repository) -> Error_Code ---;
    git_remote_default_branch       :: proc(out : ^Buf, remote : ^Remote) -> Error_Code ---;
    git_remote_connect              :: proc(remote : ^Remote, Direction : Direction, callbacks : ^Remote_Callbacks, proxy_opts : ^Proxy_Options, custom_headers : ^Str_Array) -> Error_Code ---;
    git_remote_disconnect           :: proc(remote : ^Remote) ---;
    git_remote_init_callbacks       :: proc(opts : ^Remote_Callbacks, version : u32 = REMOTE_CALLBACKS_VERSION) -> Error_Code ---;
    git_remote_connected            :: proc(remote : ^Remote) -> Error_Code ---;
    git_remote_fetch                :: proc(remote : ^Remote, refspecs : ^Str_Array, opts : ^Fetch_Options, reflog_message : ^byte) -> Error_Code ---;
    git_remote_free                 :: proc(remote : ^Remote) ---;

    // Index
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

    // Cred
    git_cred_userpass_plaintext_new :: proc(out : ^^Cred, username : ^byte, password : ^byte) -> Error_Code ---;
    git_cred_has_username           :: proc(cred : ^Cred) -> bool ---;
    git_cred_ssh_key_from_agent     :: proc(out : ^^Cred, username : ^byte) -> Error_Code ---;

    // Reset
    git_reset_default               :: proc(repo : ^Repository, target : ^Object, pathspecs : ^Str_Array) -> Error_Code ---;

    // Reference
    git_reference_name_to_id        :: proc(out : ^Oid, repo : ^Repository, name : ^byte) -> Error_Code ---;
    git_reference_symbolic_target   :: proc(ref : ^Reference) -> ^byte ---;
    git_reference_name              :: proc(ref : ^Reference) -> ^byte ---;
    git_reference_peel              :: proc(out : ^^Object, ref : ^Reference, kind : Obj_Type) -> Error_Code ---;
    git_reference_free              :: proc(ref : ^Reference) ---;
    git_reference_is_branch         :: proc(ref : ^Reference) -> bool ---;

    // Object
    git_object_lookup               :: proc(object : ^^Object, repo : ^Repository, id : ^Oid, otype : Obj_Type) -> Error_Code ---;
    git_object_free                 :: proc(object : ^Object)          ---;
    git_object_type                 :: proc(obj : ^Object)    -> Obj_Type ---;

    // Diff
    // git_diff_blob_to_buffer                    :: proc() ---;
    // git_diff_blobs                             :: proc() ---;
    // git_diff_buffers                           :: proc() ---;
    // git_diff_commit_as_email                   :: proc() ---;
    // git_diff_find_init_options                 :: proc() ---;
    git_diff_find_similar                      :: proc(diff : ^Diff, options : ^Diff_Find_Options) -> i32 ---; // 0 on success, -1 on failure
    git_diff_foreach                           :: proc(diff : ^Diff, file_cb : Diff_File_Cb, binary_cb : Diff_Binary_Cb, hunk_cb : Diff_Hunk_Cb, line_cb : Diff_Line_Cb, payload : rawptr) -> Error_Code ---;
    // git_diff_format_email                      :: proc() ---;
    // git_diff_format_email_init_options         :: proc() ---;
    git_diff_free                              :: proc(diff : ^Diff) ---;
    // git_diff_from_buffer                       :: proc() ---;
    // git_diff_get_delta                         :: proc() ---;
    // git_diff_get_perfdata                      :: proc() ---;
    // git_diff_get_stats                         :: proc() ---;
    // git_diff_index_to_index                    :: proc() ---;
    git_diff_index_to_workdir                  :: proc(diff : ^^Diff, repo : ^Repository, index : ^Index, opts : ^Diff_Options) -> Error_Code ---;
    // git_diff_init_options                      :: proc() ---;
    // git_diff_is_sorted_icase                   :: proc() ---;
    // git_diff_merge                             :: proc() ---;
    // git_diff_num_deltas                        :: proc() ---;
    // git_diff_num_deltas_of_type                :: proc() ---;
    git_diff_print                             :: proc(diff: ^Diff, format: Diff_Format, print_cb: Diff_Line_Cb, payload: rawptr) -> Error_Code ---; // Sometimes returns an error code?: "0 on success, non-zero callback return value, or error code"
    // git_diff_print_callback__to_buf            :: proc() ---;
    // git_diff_print_callback__to_file_handle    :: proc() ---;
    // git_diff_stats_deletions                   :: proc() ---;
    // git_diff_stats_files_changed               :: proc() ---;
    // git_diff_stats_free                        :: proc() ---;
    // git_diff_stats_insertions                  :: proc() ---;
    // git_diff_stats_to_buf                      :: proc() ---;
    // git_diff_status_char                       :: proc() ---;
    // git_diff_to_buf                            :: proc() ---;
    // git_diff_tree_to_index                     :: proc() ---;
    git_diff_tree_to_index                     :: proc(diff : ^^Diff, repo : ^Repository, old_tree : ^Tree, index : ^Index, opts : ^Diff_Options) -> Error_Code ---;
    git_diff_tree_to_tree                      :: proc(diff : ^^Diff, repo : ^Repository, old_tree, new_tree : ^Tree, opts : ^Diff_Options) -> Error_Code ---;
    // git_diff_tree_to_workdir                   :: proc() ---;
    git_diff_tree_to_workdir_with_index        :: proc(diff : ^^Diff, repo : ^Repository, old_tree : ^Tree, opts : ^Diff_Options) -> Error_Code ---;
    
    // Patch
    git_patch_free                  :: proc(patch : ^Patch) ---;
    git_patch_from_diff             :: proc(out : ^^Patch, diff : ^Diff, idx : uint) -> i32 ---;

    // Tree
    git_tree_lookup                 :: proc(out : ^^Tree, repo : ^Repository, id : ^Oid) -> i32 ---;

    // Branch
    git_branch_create               :: proc(out : ^^Reference, repo : ^Repository, branch_name : ^byte, target : ^Commit, force : i32) -> Error_Code ---;
    git_branch_name                 :: proc(out : ^^byte, ref : ^Reference) -> Error_Code ---;
    git_branch_iterator_new         :: proc(out : ^^Branch_Iterator, repo : ^Repository, list_flags : Branch_Type) -> Error_Code ---;
    git_branch_iterator_free        :: proc(iter : ^Branch_Iterator) ---;
    git_branch_next                 :: proc(out : ^^Reference, out_type : ^Branch_Type, iter : ^Branch_Iterator) -> Error_Code ---;
    git_branch_delete               :: proc(branch : ^Reference) -> Error_Code ---;
    git_branch_is_checked_out       :: proc(branch : ^Reference) -> bool ---;

    // Revparse
    git_revparse_single             :: proc(out : ^^Object, repo : ^Repository, spec : ^byte) -> Error_Code ---;

    // Checkout
    git_checkout_tree               :: proc(repo : ^Repository, treeish : ^Object, opts : ^Checkout_Options) -> Error_Code ---;

    // Stash
    git_stash_save                  :: proc(out : ^Oid, repo : ^Repository, stasher : ^Git_Signature, message : ^byte, flags : Stash_Flags) -> Error_Code ---;
    git_stash_apply                 :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    git_stash_pop                   :: proc(repo : ^Repository, index : uint, options : ^Stash_Apply_Options) -> Error_Code ---;
    git_stash_drop                  :: proc(repo : ^Repository, index : uint) -> Error_Code ---;
    git_stash_foreach               :: proc(repo : ^Repository, callback : Stash_Cb, payload : rawptr, index : uint) -> Error_Code ---;

    // Revwalk
    git_revwalk_new                 :: proc(out : ^^Revwalk, repo : ^Repository) -> Error_Code ---;
    git_revwalk_next                :: proc(out : ^Oid, walk : ^Revwalk) -> Error_Code ---;
    git_revwalk_push_range          :: proc(walk : ^Revwalk, range : ^byte) -> Error_Code ---;
    git_revwalk_push_ref            :: proc(walk : ^Revwalk, refname : ^byte) -> Error_Code ---;
    git_revwalk_free                :: proc(walk : ^Revwalk) ---;

    // init_options
    git_fetch_init_options          :: proc(opts : ^Fetch_Options,       version : u32) -> i32 ---;
    git_stash_apply_init_options    :: proc(opts : ^Stash_Apply_Options, version : u32) -> i32 ---;
    git_status_init_options         :: proc(opts : ^Status_Options,      version : u32) -> i32 ---;
    git_checkout_init_options       :: proc(opts : ^Checkout_Options,    version : u32) -> i32 ---;
}
