/*
 *  @Name:     libgit2_types
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 29-12-2017 16:05:30 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 05-03-2018 10:48:01 UTC+1
 *
 *  @Description:
 *  
 */

GIT_OID_RAWSZ :: 20;
GIT_OID_HEXSZ :: GIT_OID_RAWSZ * 2;

//Opaque Structs
Repository       :: struct {};
Remote           :: struct {};
Tree             :: struct {};
Index            :: struct {};
Transport        :: struct {};
Commit           :: struct {};
Reference        :: struct {};
Object           :: struct {};
Revwalk          :: struct {};
Branch_Iterator  :: struct {};
Status_List      :: struct {};
Diff             :: struct {};
Patch            :: struct {};

Oid :: struct {
    id : [GIT_OID_RAWSZ]byte, // raw binary formatted id
}

Git_Signature :: struct {
    name      : cstring, //Full name of the author
    email     : cstring, //Email of the author
    time_when : Time,  //Time when the action happened
}

Signature :: struct {
    _git_orig : ^Git_Signature,
    name      : string,
    email     : string,
    time_when : Time,
}

Repository_Init_Options :: struct {
    version       : u32,
    flags         : u32,
    mode          : Repository_Init_Mode,
    workdir_path  : cstring,
    description   : cstring,
    template_path : cstring,
    initial_head  : cstring,
    origin_url    : cstring,
}

Git_Error :: struct {
    message : cstring,
    klass   : ErrorType,
}

Error :: struct {
    message : string,
    klass   : ErrorType,
}

Str_Array :: struct {
    strings : ^cstring,
    count   : uint,
}

Buf :: struct {
    ptr   : cstring,
    asize : uint,
    size  : uint,
}

Checkout_Perfdata :: struct {
    mkdir_calls : u32,
    stat_calls  : u32,
    chmod_calls : u32,
}

Cred :: struct {
    credtype : Cred_Type,
    free : proc "c" (cred : ^Cred),
}

Cert :: struct {
    type_ : Cert_Type,
}

Time :: struct {
    time   : i64,  //time in seconds from epoch
    offset : i32,  //timezone offset, in minutes
    sign   : byte, //indicator for questionable '-0000' offsets in signature
}

Index_Time :: struct {
    seconds : i32,
    nanoseconds : u32, // nsec should not be stored as time_t compatible
}

Index_Entry :: struct {
    ctime          : Index_Time,
    mtime          : Index_Time,
    dev            : u32,
    ino            : u32,
    mode           : u32,
    uid            : u32,
    gid            : u32,
    file_size      : u32,
    id             : Oid,
    flags          : Index_Entry_Flag,
    flags_extended : Index_Entry_Extended_Flag,
    path           : string,
}

Stash_Apply_Options :: struct {
    version          : u32,
    flags            : Stash_Apply_Flags,
    checkout_options : Checkout_Options, // Options to use when writing files to the working directory.
    progress_cb      : Stash_Apply_Progress_Cb, // Optional callback to notify the consumer of application progress.
    progress_payload : rawptr,
}

Clone_Options :: struct {
    version : u32,
    /**
     * These options are passed to the checkout step. To disable
     * checkout, set the `checkout_strategy` to
     * `GIT_CHECKOUT_NONE`.
     */
    checkout_opts : Checkout_Options,
    /**
     * Options which control the fetch, including callbacks.
     *
     * The callbacks are used for reporting fetch progress, and for acquiring
     * credentials in the event they are needed.
     */
    fetch_opts : Fetch_Options,
    /**
     * Set to zero (false) to create a standard repo, or non-zero
     * for a bare repo
     */
    bare : i32,
    local : Clone_Local_Flags, //Whether to use a fetch or copy the object database.
    /**
     * The name of the branch to checkout. NULL means use the
     * remote's default branch.
     */
    checkout_branch : ^byte,
    /**
     * A callback used to create the new repository into which to
     * clone. If NULL, the 'bare' field will be used to determine
     * whether to create a bare repository.
     */
    repository_cb : Repository_Create_Cb,
    /**
     * An opaque payload to pass to the git_repository creation callback.
     * This parameter is ignored unless repository_cb is non-NULL.
     */
    repository_cb_payload : rawptr,
    /**
     * A callback used to create the git_remote, prior to its being
     * used to perform the clone operation. See the documentation for
     * git_remote_create_cb for details. This parameter may be NULL,
     * indicating that git_clone should provide default behavior.
     */
    remote_cb : Remote_Create_Cb,
    /**
     * An opaque payload to pass to the git_remote creation callback.
     * This parameter is ignored unless remote_cb is non-NULL.
     */
    remote_cb_payload : rawptr,
}

Checkout_Options :: struct {
    version           : u32,
    checkout_strategy : Checkout_Strategy_Flags, // default will be a dry run
    disable_filters   : i32,                     // don't apply filters like CRLF conversion
    dir_mode          : u32,                     // default is 0755
    file_mode         : u32,                     // default is 0644 or 0755 as dictated by blob
    file_open_flags   : i32,                     // default is O_CREAT | O_TRUNC | O_WRONLY
    notify_flags      : u32,                     // see `git_checkout_notify_t` above
    notify_cb         : Checkout_Notify_Cb,
    notify_payload    : rawptr,
                                                 // Optional callback to notify the consumer of checkout progress.
    progress_cb       : Checkout_Progress_Cb,
    progress_payload  : rawptr,
    /*  When not zeroed out, array of fnmatch patterns specifying which
     *  paths should be taken into account, otherwise all files.  Use
     *  GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH to treat as simple list.
     */
    paths             : Str_Array,
    /** The expected content of the working directory; defaults to HEAD.
     *  If the working directory does not match this baseline information,
     *  that will produce a checkout conflict.
     */
    baseline          : ^Tree,
    /** Like `baseline` above, though expressed as an index.  This
     *  option overrides `baseline`.
     */
    baseline_index    : ^Index,                  // expected content of workdir, expressed as an index.
    target_directory  : ^byte,                   // alternative checkout path to workdir
    ancestor_label    : ^byte,                   // the name of the common ancestor side of conflicts
    our_label         : ^byte,                   // the name of the "our" side of conflicts
    their_label       : ^byte,                   // the name of the "their" side of conflicts
    perfdata_cb       : Checkout_Perfdata_Cb,    // Optional callback to notify the consumer of performance data
    perfdata_payload  : rawptr,
}

Fetch_Options :: struct {
    version : i32,
    /**
     * Callbacks to use for this fetch operation
     */
    callbacks : Remote_Callbacks,
    /**
     * Whether to perform a prune after the fetch
     */
    prune : Fetch_Prune_Flags,
    /**
     * Whether to write the results to FETCH_HEAD. Defaults to
     * on. Leave this default in order to behave like git.
     */
    update_fetchhead : i32,
    /**
     * Determines how to behave regarding tags on the remote, such
     * as auto-downloading tags for objects we're downloading or
     * downloading all of them.
     *
     * The default is to auto-follow tags.
     */
    download_tags : Remote_Autotag_Option_Flags,
    /**
     * Proxy options to use, by default no proxy is used.
     */
    proxy_opts : Proxy_Options,
    /**
     * Extra headers for this fetch operation
     */
    custom_headers : Str_Array,
}


/*
    Controls the behavior of a git_push object.
*/
Push_Options :: struct {
    version : u32,

    /*
      If the transport being used to push to the remote requires the creation
      of a pack file, this controls the number of worker threads used by
      the packbuilder when creating that pack file to be sent to the remote.
     
      If set to 0, the packbuilder will auto-detect the number of threads
      to create. The default value is 1.
     */
    pb_parallelism : u32,

    /*
      Callbacks to use for this push operation
     */
    callbacks : Remote_Callbacks,

    /*
     Proxy options to use, by default no proxy is used.
    */
    proxy_opts : Proxy_Options,

    /*
      Extra headers for this push operation
     */
    custom_headers : Str_Array,
}

Remote_Callbacks :: struct {
    version : u32,
    /**
     * Textual progress from the remote. Text send over the
     * progress side-band will be passed to this function (this is
     * the 'counting objects' output).
     */
    sideband_progress : Transport_Message_Cb,
    /**
     * Completion is called when different parts of the download
     * process are done (currently unused).
     */
    completion : proc "stdcall" (type_ : Remote_Completion_Type, data : rawptr),
    /**
     * This will be called if the remote host requires
     * authentication in order to connect to it.
     *
     * Returning GIT_PASSTHROUGH will make libgit2 behave as
     * though this field isn't set.
     */
    credentials : Cred_Acquire_Cb,
    /**
     * If cert verification fails, this will be called to let the
     * user make the final decision of whether to allow the
     * connection to proceed. Returns 1 to allow the connection, 0
     * to disallow it or a negative value to indicate an error.
     */
    certificate_check : Transport_Certificate_Check_Cb,
    /**
     * During the download of new data, this will be regularly
     * called with the current count of progress done by the
     * indexer.
     */
    transfer_progress : Transfer_Progress_Cb,
    /**
     * Each time a reference is updated locally, this function
     * will be called with information about it.
     */
    update_tips : proc "stdcall" (refname : ^byte, a : ^Oid, b : ^Oid, data : rawptr) -> i32,
    /**
     * Function to call with progress information during pack
     * building. Be aware that this is called inline with pack
     * building operations, so performance may be affected.
     */
    pack_progress : Packbuilder_Progress_Cb,
    /**
     * Function to call with progress information during the
     * upload portion of a push. Be aware that this is called
     * inline with pack building operations, so performance may be
     * affected.
     */
    push_transfer_progress : Push_Transfer_Progress_Cb,
    /**
     * See documentation of git_push_update_reference_cb
     */
    push_update_reference : proc "stdcall" (refname : ^byte, status : ^byte, data : rawptr) -> i32,
    /**
     * Called once between the negotiation step and the upload. It
     * provides information about what updates will be performed.
     */
    push_negotiation : Push_Negotiation_Cb,
    /**
     * Create the transport to use for this operation. Leave NULL
     * to auto-detect.
     */
    transport : Transport_Cb,
    /**
     * This will be passed to each of the callbacks in this struct
     * as the last parameter.
     */
    payload : rawptr,
}

Transfer_Progress :: struct {
    total_objects    : u32,
    indexed_objects  : u32,
    received_objects : u32,
    local_objects    : u32,
    total_deltas     : u32,
    indexed_deltas   : u32,
    received_bytes   : uint,
}

Push_Update :: struct {
    /**
     * The source name of the reference
     */
    src_refname : ^byte,
    /**
     * The name of the reference to update on the server
     */
    dst_refname : ^byte,
    /**
     * The current target of the reference
     */
    src : Oid,
    /**
     * The new target for the reference
     */
    dst : Oid,
}

Proxy_Options :: struct {
    version : u32,
    /**
     * The type of proxy to use, by URL, auto-detect.
     */
    type_ : Proxy_Flags,
    /**
     * The URL of the proxy.
     */
    url : ^byte,
    /**
     * This will be called if the remote host requires
     * authentication in order to connect to it.
     *
     * Returning GIT_PASSTHROUGH will make libgit2 behave as
     * though this field isn't set.
     */
    credentials : Cred_Acquire_Cb,
    /**
     * If cert verification fails, this will be called to let the
     * user make the final decision of whether to allow the
     * connection to proceed. Returns 1 to allow the connection, 0
     * to disallow it or a negative value to indicate an error.
     */
    certificate_check : Transport_Certificate_Check_Cb,
    /**
     * Payload to be provided to the credentials and certificate
     * check callbacks.
     */
    payload : rawptr,
}

Submodule_Ignore :: enum i32 {
    Unspecified  = -1, /**< use the submodule's configuration */

    None         = 1,  /**< any change or untracked == dirty */
    Untracked    = 2,  /**< dirty if tracked files change */
    Dirty        = 3,  /**< only dirty if HEAD moved */
    All          = 4,  /**< never dirty */
}

Diff_Format :: enum u32 {
    Patch        = 1, /**< full git diff */
    Patch_Header = 2, /**< just the file headers of patch */
    Raw          = 3, /**< like git diff --raw */
    Name_Only    = 4, /**< like git diff --name-only */
    Name_Status  = 5, /**< like git diff --name-status */
}

Diff_Notify_Cb   :: #type proc(diff_so_far : ^Diff, delta_to_add : ^Diff_Delta, matched_pathspec : ^byte, payload : rawptr) -> i32;
Diff_Progress_Cb :: #type proc(diff_so_far : ^Diff, old_path : ^byte, new_path : ^byte, payload : rawptr) -> i32;
Diff_Line_Cb     :: #type proc(delta : ^Diff_Delta, hunk : ^Diff_Hunk, line : ^Diff_Line, payload : rawptr) -> i32;
Diff_File_Cb     :: #type proc(delta : ^Diff_Delta, progress : f32, payload : rawptr) -> i32;
Diff_Binary_Cb   :: #type proc(delta : ^Diff_Delta, binary : ^Diff_Binary, payload : rawptr) -> i32;
Diff_Hunk_Cb     :: #type proc(delta : ^Diff_Delta, hunk : ^Diff_Hunk, payload : rawptr) -> i32;

GIT_DIFF_HUNK_HEADER_SIZE :: 128;

Diff_Hunk :: struct {
    old_start:  i32,     /**< Starting line number in old_file */
    old_lines:  i32,     /**< Number of lines in old_file */
    new_start:  i32,     /**< Starting line number in new_file */
    new_lines:  i32,     /**< Number of lines in new_file */
    header_len: uint,    /**< Number of bytes in header text */
    header:     [GIT_DIFF_HUNK_HEADER_SIZE]byte,   /**< Header text, NUL-byte terminated */
}

Diff_Line :: struct {
    origin:         byte,  /**< A git_diff_line_t value */
    old_lineno:     i32,   /**< Line number in old file or -1 for added line */
    new_lineno:     i32,   /**< Line number in new file or -1 for deleted line */
    num_lines:      i32,   /**< Number of newline characters in content */
    content_len:    uint,  /**< Number of bytes of data */
    content_offset: i64,   /**< Offset in the original file to the content */ // git_off_t
    content:        ^byte, /**< Pointer to diff text, not NUL-byte terminated */
}

Diff_Options :: struct {
    version: u32,      /**< version for the struct */
    flags:   u32,      /**< defaults to GIT_DIFF_NORMAL */

    /* options controlling which files are in the diff */

    ignore_submodules: Submodule_Ignore, /**< submodule ignore rule */
    pathspec:          Str_Array,        /**< defaults to include all paths */
    notify_cb:         Diff_Notify_Cb,
    progress_cb:       Diff_Progress_Cb,
    payload:           rawptr,

    /* options controlling how to diff text is generated */

    context_lines:   u32,   /**< defaults to 3 */
    interhunk_lines: u32,   /**< defaults to 0 */
    id_abbrev:       u16,   /**< default 'core.abbrev' or 7 if unset */
    max_size:        i64,   /**< defaults to 512MB */
    old_prefix:      ^byte, /**< defaults to "a" */
    new_prefix:      ^byte, /**< defaults to "b" */
}

Filemode :: enum u32 {
    Unreadable     = 0000000,
    Tree           = 0040000,
    Blob           = 0100644,
    BlobExecutable = 0100755,
    Link           = 0120000,
    Commit         = 0160000,
}

Diff_File :: struct {
    id        : Oid,
    path      : cstring,
    size      : i64, //NOTE(Hoej): Changes with platform, i64 on Windows
    flags     : Diff_Flags,
    mode      : u16,
    id_abbrev : u16,
}

Diff_Find_Options :: struct {
    version                       : u32,
    flags                         : u32,
    rename_threshold              : u16,
    rename_from_rewrite_threshold : u16,
    copy_threshold                : u16,
    break_rewrite_threshold       : u16,
    rename_limit                  : uint,
    metric                        : ^Diff_Similarity_Metric,
}

Diff_Similarity_Metric :: struct {
    file_signature    : #type proc(out : ^rawptr, file : ^Diff_File, fullpath : ^u8, payload : rawptr) -> i32,
    buffer_signature  : #type proc(out : ^rawptr, file : ^Diff_File, buf : ^u8, buflen : uint, payload : rawptr) -> i32,
    free_signature    : #type proc(sig : rawptr, payload : rawptr),
    similarity        : #type proc(score : ^i32, siga, sigb : rawptr, payload : rawptr),
    payload           : rawptr,
}

Diff_Binary_T :: enum i32 {
    None,
    Literal,
    Delta,
}

Diff_Binary_File :: struct {
    typ         : Diff_Binary_T,
    data        : ^u8,
    datalen     : uint,
    inflatedlen : uint,
}

Diff_Binary :: struct {
    contains_data : u32,
    old_file      : Diff_Binary_File,
    new_file      : Diff_Binary_File,
}

Status_Options :: struct {
    version  : u32,
    show     : Status_Show_Flags,
    flags    : Status_Opt_Flags,
    pathspec : Str_Array,
}

Status_Entry :: struct {
    status           : Status_Flags,
    head_to_index    : ^Diff_Delta,
    index_to_workdir : ^Diff_Delta,
}

Diff_Delta :: struct {
    status     : Delta,
    flags      : Diff_Flags,
    similarity : u16,
    nfiles     : u16,
    old_file   : Diff_File,
    new_file   : Diff_File,
}

Error_Code :: enum i32 {
    Ok               =  0,  // No error
    Generic_Error    = -1,  // Generic error
    Not_Found        = -3,  // Requested object could not be found
    Exists           = -4,  // Object exists preventing operation
    Ambiguous        = -5,  // More than one object matches
    Bufs             = -6,  // Output buffer too short to hold data
    User             = -7,  // User generated error, never generated by libgit2.
    Bare_Repo        = -8,  // Operation not allowed on bare repository
    Unborn_Branch    = -9,  // HEAD refers to branch with no commits
    Unmerged         = -10, // Merge in progress prevented operation
    Non_Fast_Forward = -11, // Reference was not fast-forwardable
    Invalid_Spec     = -12, // Name/ref spec was not in a valid format
    Conflict         = -13, // Checkout conflicts prevented operation
    Locked           = -14, // Lock file prevented operation
    Modified         = -15, // Reference value does not match expected
    Auth             = -16, // Authentication error
    Certificate      = -17, // Server certificate is invalid
    Applied          = -18, // Patch/merge has already been applied
    Peel             = -19, // The requested peel operation is not possible
    Eof              = -20, // Unexpected EOF
    Invalid          = -21, // Invalid operation or input
    Uncommitted      = -22, // Uncommitted changes in index prevented operation
    Directory        = -23, // The operation is not valid for a directory
    Merge_Conflict   = -24, // A merge conflict exists and cannot continue
    Passthrough      = -30, // Internal only
    Iter_Over        = -31, // Signals end of iteration with iterator
    Retry            = -32, // Internal only
    Mismatch         = -33, // Hashsum mismatch in object
}
 
Obj_Type :: enum i32 {
    Any       = -2, // Object can be any of the following
    Bad       = -1, // Object is invalid.
    _Ext1     = 0,  // Reserved for future use.
    Commit    = 1,  // A commit object.
    Tree      = 2,  // A tree (directory listing) object.
    Blob      = 3,  // A file revision object.
    Tag       = 4,  // An annotated tag object.
    _Ext2     = 5,  // Reserved for future use.
    Ofs_Delta = 6,  // A delta, base is given by an offset.
    Ref_Delta = 7,  // A delta, base is given by object id.
}

Cred_Type :: enum u32 {
    Userpass_Plaintext = (1 << 0), // git_cred_userpass_plaintext
    Ssh_Key = (1 << 1),            // git_cred_ssh_key
    Ssh_Custom = (1 << 2),         // git_cred_ssh_custom
    Default = (1 << 3),            // git_cred_default
    Ssh_Interactive = (1 << 4),    // git_cred_ssh_interactive
    Username = (1 << 5),           // Username-only information. 
                                   // If the SSH transport does not know which username to use, 
                                   // it will ask via this credential type.
    Ssh_Memory = (1 << 6),         // Credentials read from memory. Only available for libssh2+OpenSSL for now.
}

Repository_Init_Flags :: enum u32 {
    Bare              = (1 << 0), //Create a bare repository with no working directory
    No_Reinit         = (1 << 1), //Return an GIT_EEXISTS error if the repo_path appears to already be an git repository

    No_Dotgit_Dir     = (1 << 2), //Normally a "/.git/" will be appended to the repo
                                  //path for non-bare repos (if it is not already there), but
                                  //passing this flag prevents that behavior.

    Mkdir             = (1 << 3), //Make the repo_path (and workdir_path) as needed.  Init is
                                  //always willing to create the ".git" directory even without this
                                  //flag.  This flag tells init to create the trailing component of
                                  //the repo and workdir paths as needed.

    Mkpath            = (1 << 4), //Recursively make all components of the repo and workdir paths as necessary.

    External_Template = (1 << 5), //libgit2 normally uses internal templates to
                                  //initialize a new repo.  This flags enables external templates,
                                  //looking the "template_path" from the options if set, or the
                                  //`init.templatedir` global config if not, or falling back on
                                  //"/usr/share/git-core/templates" if it exists.

    Relative_Gitlink  = (1 << 6), //If an alternate workdir is specified, use relative paths for the gitdir and core.worktree.
}

Repository_Init_Mode :: enum u32 {
    Shared_Umask = 0,       //Use permissions configured by umask - the default.
    Shared_Group = 0002775, //Use "--shared=group" behavior, chmod'ing the new repo to be group writable and "g+sx" for sticky group assignment.
    Shared_All   = 0002777, //Use "--shared=all" behavior, adding world readability. Anything else - Set to custom value.
}

Index_Entry_Flag :: enum u16 {
    Extended = 0x4000,
    Valid    = 0x8000,
}

Index_Entry_Extended_Flag :: enum u16 {
    Intent_To_Add     = (1 << 13),
    Skip_Worktree     = (1 << 14),
    Extended2         = (1 << 15), // Reserved
    Extended_Flags    = (Intent_To_Add | Skip_Worktree),
    Update            = (1 << 0),
    Remove            = (1 << 1),
    Upto_Date         = (1 << 2),
    Added             = (1 << 3),
    Hashed            = (1 << 4),
    Unhashed          = (1 << 5),
    WtRemove          = (1 << 6), // Eemove in work directory
    Conflicted        = (1 << 7),
    Unpacked          = (1 << 8),
    New_Skip_Worktree = (1 << 9),
}

Stash_Apply_Flags :: enum i32 {
    Default         = 0 << 0,
    /* Try to reinstate not only the working tree's changes,
     * but also the index's changes.
     */
    Reinstate_Index = 1 << 0,
}

Stash_Flags :: enum u32 {
    Default           = 0 << 0, // No option, default
    /**
     * All changes already added to the index are left intact in
     * the working directory
     */
    Keep_Index        = 1 << 0,
    /**
     * All untracked files are also stashed and then cleaned up
     * from the working directory
     */
    Include_Untracked = 1 << 1,
    /**
     * All ignored files are also stashed and then cleaned up from
     * the working directory
     */
    Include_Ignored   = 1 << 2,
}

Stash_Apply_Progress :: enum i32 {
    None = 0,
    Loading_Stash,      // Loading the stashed data from the object database.
    Analyze_Index,      // The stored index is being analyzed.
    Analyze_Modified,   // The modified files are being analyzed.
    Analyze_Untracked,  // The untracked and ignored files are being analyzed.
    Checkout_Untracked, // The untracked files are being written to disk.
    Checkout_Modified,  // The modified files are being written to disk.
    Done,               // The stash was applied successfully.
}

Checkout_Strategy_Flags :: enum u32 {
    /* default is a dry run, no actual updates */
    None = 0, 
    /* Allow safe updates that cannot overwrite uncommitted data */
    Safe = (1 << 0),
    /* Allow all updates to force working directory to look like index */
    Force = (1 << 1),
    /* Allow checkout to recreate missing files */
    Recreate_Missing = (1 << 2),
    /* Allow checkout to make safe updates even if conflicts are found */
    Allow_Conflicts = (1 << 4),
    /* Remove untracked files not in index (that are not ignored) */
    Remove_Untracked = (1 << 5),
    /* Remove ignored files not in index */
    Remove_Ignored = (1 << 6),
    /* Only update existing files, don't create new ones */
    Update_Only = (1 << 7),
    /*
     * Normally checkout updates index entries as it goes; this stops that.
     * Implies `DontWriteIndex`.
     */
    Dont_Update_Index = (1 << 8),
    /* Don't refresh index/config/etc before doing checkout */
    No_Refresh = (1 << 9),
    /* Allow checkout to skip unmerged files */
    Skip_Unmerged = (1 << 10),
    /* For unmerged files, checkout stage 2 from index */
    Use_Ours = (1 << 11),
    /* For unmerged files, checkout stage 3 from index */
    Use_Theirs = (1 << 12),
    /* Treat pathspec as simple list of exact match file paths */
    Disable_Pathspec_Match = (1 << 13),
    /* Ignore directories in use, they will be left empty */
    Skip_Locked_Directories = (1 << 18),
    /* Don't overwrite ignored files that exist in the checkout target */
    Dont_Overwrite_Ignored = (1 << 19),
    /* Write normal merge files for conflicts */
    Conflict_Style_Merge = (1 << 20),
    /* Include common ancestor data in diff3 format files for conflicts */
    Conflict_Style_Diff3 = (1 << 21),
    /* Don't overwrite existing files or folders */
    Dont_Remove_Existing = (1 << 22),
    /* Normally checkout writes the index upon completion; this prevents that. */
    Dont_Write_Index = (1 << 23),
}

/*
 * Type of host certificate structure that is passed to the check callback
 */
Cert_Type :: enum i32 {
    /*
     * No information about the certificate is available. This may
     * happen when using curl.
     */
    None,
    /*
     * The `data` argument to the callback will be a pointer to
     * the DER-encoded data.
     */
    X509,
    /*
     * The `data` argument to the callback will be a pointer to a
     * `git_cert_hostkey` structure.
     */
    Hostkey_Libssh2,
    /*
     * The `data` argument to the callback will be a pointer to a
     * `git_strarray` with `name:content` strings containing
     * information about the certificate. This is used when using
     * curl.
     */
    Str_array,
}

Fetch_Prune_Flags :: enum i32 {
    Prune_Unspecified, // Use the setting from the configuration.
    Prune,             // Force pruning on.
    No_Prune,          // Force pruning off.
}

Remote_Autotag_Option_Flags :: enum i32 {
    Unspecified = 0, // Use the setting from the configuration.
    Auto,            // Ask the server for tags pointing to objects we're already downloading.
    None,            // Don't ask for any tags beyond the refspecs.
    All,             // Ask for the all the tags.
}

Clone_Local_Flags :: enum i32 {
    /*
     * Auto-detect (default), libgit2 will bypass the git-aware
     * transport for local paths, but use a normal fetch for
     * `file://` urls.
     */
    LOCAL_AUTO,
    /*
     * Bypass the git-aware transport even for a `file://` url.
     */
    LOCAL,
    /*
     * Do no bypass the git-aware transport
     */
    NO_LOCAL,
    /*
     * Bypass the git-aware transport, but do not try to use
     * hardlinks.
     */
    LOCAL_NO_LINKS,
}

Proxy_Flags :: enum i32 {
    /*
     * Do not attempt to connect through a proxy
     *
     * If built against libcurl, it itself may attempt to connect
     * to a proxy if the environment variables specify it.
     */
    None,
    /*
     * Try to auto-detect the proxy from the git configuration.
     */
    Auto,
    /*
     * Connect via the URL given in the options
     */
    Specified,
}

Remote_Completion_Type :: enum i32 {
    Download,
    Indexing,
    Error,
}

Checkout_Notify_Flags :: enum u32 {
    None      = 0,
    Conflict  = (1 << 0),
    Dirty     = (1 << 1),
    Updated   = (1 << 2),
    Untracked = (1 << 3),
    Ignored   = (1 << 4),

    All       = 0x0FFFF,
}

ErrorType :: enum i32 {
    Unknown = -1,
    None = 0,
    Nomemory,
    Os,
    Invalid,
    Reference,
    Zlib,
    Repository,
    Config,
    Regex,
    Odb,
    Index,
    Object,
    Net,
    Tag,
    Tree,
    Indexer,
    Ssl,
    Submodule,
    Thread,
    Stash,
    Checkout,
    Fetchhead,
    Merge,
    Ssh,
    Filter,
    Revert,
    Callback,
    Cherrypick,
    Describe,
    Rebase,
    Filesystem,
    Patch,
    Worktree,
    Sha1
}

Lib_Features :: enum i32 {
  /*
   * If set, libgit2 was built thread-aware and can be safely used from multiple
   * threads.
   */
    Threads = (1 << 0),
  /*
   * If set, libgit2 was built with and linked against a TLS implementation.
   * Custom TLS streams may still be added by the user to support HTTPS
   * regardless of this.
   */
    Https   = (1 << 1),
  /*
   * If set, libgit2 was built with and linked against libssh2. A custom
   * transport may still be added by the user to support libssh2 regardless of
   * this.
   */
    Ssh     = (1 << 2),
  /*
   * If set, libgit2 was built with support for sub-second resolution in file
   * modification times.
   */
    Nsec    = (1 << 3),
}

Repository_Open_Flags :: enum u32 {
    No_Search = (1 << 0),
    Cross_Fs  = (1 << 1),
    Bare      = (1 << 2),
    No_Dotgit = (1 << 3),
    From_Env  = (1 << 4),
}

Status_Flags :: enum u32 {
    Current = 0,

    IndexNew        = (1 << 0),
    IndexModified   = (1 << 1),
    IndexDeleted    = (1 << 2),
    IndexRenamed    = (1 << 3),
    IndexTypechange = (1 << 4),

    WtNew           = (1 << 7),
    WtModified      = (1 << 8),
    WtDeleted       = (1 << 9),
    WtTypechange    = (1 << 10),
    WtRenamed       = (1 << 11),
    WtUnreadable    = (1 << 12),

    Ignored         = (1 << 14),
    Conflicted      = (1 << 15),
}

Direction :: enum i32 {
    Fetch = 0,
    Push  = 1
}

Status_Show_Flags :: enum u32 {
    IndexAndWorkdir = 0,
    IndexOnly       = 1,
    WorkdirOnly     = 2,
}

Delta :: enum u32 {
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

Diff_Flags :: enum u32 {
    Binary     = (1 << 0),
    Not_Binary = (1 << 1),
    Valid_Id   = (1 << 2),
    Exists     = (1 << 3),
}

/**
 * Flags to control status callbacks
 *
 * - GIT_STATUS_OPT_INCLUDE_UNTRACKED says that callbacks should be made
 *   on untracked files.  These will only be made if the workdir files are
 *   included in the status "show" option.
 * - GIT_STATUS_OPT_INCLUDE_IGNORED says that ignored files get callbacks.
 *   Again, these callbacks will only be made if the workdir files are
 *   included in the status "show" option.
 * - GIT_STATUS_OPT_INCLUDE_UNMODIFIED indicates that callback should be
 *   made even on unmodified files.
 * - GIT_STATUS_OPT_EXCLUDE_SUBMODULES indicates that submodules should be
 *   skipped.  This only applies if there are no pending typechanges to
 *   the submodule (either from or to another type).
 * - GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS indicates that all files in
 *   untracked directories should be included.  Normally if an entire
 *   directory is new, then just the top-level directory is included (with
 *   a trailing slash on the entry name).  This flag says to include all
 *   of the individual files in the directory instead.
 * - GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH indicates that the given path
 *   should be treated as a literal path, and not as a pathspec pattern.
 * - GIT_STATUS_OPT_RECURSE_IGNORED_DIRS indicates that the contents of
 *   ignored directories should be included in the status.  This is like
 *   doing `git ls-files -o -i --exclude-standard` with core git.
 * - GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX indicates that rename detection
 *   should be processed between the head and the index and enables
 *   the GIT_STATUS_INDEX_RENAMED as a possible status flag.
 * - GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR indicates that rename
 *   detection should be run between the index and the working directory
 *   and enabled GIT_STATUS_WT_RENAMED as a possible status flag.
 * - GIT_STATUS_OPT_SORT_CASE_SENSITIVELY overrides the native case
 *   sensitivity for the file system and forces the output to be in
 *   case-sensitive order
 * - GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY overrides the native case
 *   sensitivity for the file system and forces the output to be in
 *   case-insensitive order
 * - GIT_STATUS_OPT_RENAMES_FROM_REWRITES indicates that rename detection
 *   should include rewritten files
 * - GIT_STATUS_OPT_NO_REFRESH bypasses the default status behavior of
 *   doing a "soft" index reload (i.e. reloading the index data if the
 *   file on disk has been modified outside libgit2).
 * - GIT_STATUS_OPT_UPDATE_INDEX tells libgit2 to refresh the stat cache
 *   in the index for files that are unchanged but have out of date stat
 *   information in the index.  It will result in less work being done on
 *   subsequent calls to get status.  This is mutually exclusive with the
 *   NO_REFRESH option.
 *
 * Calling `git_status_foreach()` is like calling the extended version
 * with: GIT_STATUS_OPT_INCLUDE_IGNORED, GIT_STATUS_OPT_INCLUDE_UNTRACKED,
 * and GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS.  Those options are bundled
 * together as `GIT_STATUS_OPT_DEFAULTS` if you want them as a baseline.
 */

Status_Opt_Flags :: enum u32 {
    Include_Untracked               = (1 <<  0),
    Include_Ignored                 = (1 <<  1),
    Include_Unmodified              = (1 <<  2),
    Exclude_Submodules              = (1 <<  3),
    Recurse_Untracked_Dirs          = (1 <<  4),
    Disable_Pathspec_Match          = (1 <<  5),
    Recurse_Ignored_Dirs            = (1 <<  6),
    Renames_Head_To_Index           = (1 <<  7),
    Renames_Index_To_Workdir        = (1 <<  8),
    Sort_Case_Sensitively           = (1 <<  9),
    Sort_Case_Insensitively         = (1 << 10),
    Renames_From_Rewrites           = (1 << 11),
    No_Refresh                      = (1 << 12),
    Update_Index                    = (1 << 13),
    Include_Unreadable              = (1 << 14),
    Include_Unreadable_As_Untracked = (1 << 15),
    Defaults                        = Include_Ignored       |
                                      Include_Untracked     |
                                      Recurse_Untracked_Dirs,
}

Branch_Type :: enum i32 {
    Local = 1,
    Remote = 2,
    All = Local | Remote,
}

Status_Cb                      :: #type proc "stdcall"(path : ^byte, status_flags : Status_Flags, payload : rawptr) -> Error_Code;
Stash_Cb                       :: #type proc "stdcall"(index: uint, message: ^byte, stash_id: Oid, payload: rawptr) -> i32;
Stash_Apply_Progress_Cb        :: #type proc "stdcall"(progress: Stash_Apply_Progress, payload: rawptr) -> i32;
Repository_Create_Cb           :: #type proc "stdcall"(out : ^^Repository, path : ^byte, bare : i32, payload : rawptr) -> i32;
Remote_Create_Cb               :: #type proc "stdcall"(out : ^^Remote, repo : ^Repository, name : ^byte, url : ^byte, payload : rawptr) -> i32;
Checkout_Notify_Cb             :: #type proc "stdcall"(why : Checkout_Notify_Flags, path : ^byte, baseline : ^Diff_File, target : ^Diff_File, workdir : ^Diff_File, payload : rawptr) -> i32;
Checkout_Progress_Cb           :: #type proc "stdcall"(path : ^byte, completed_steps : uint, total_steps : uint, payload : rawptr);
Checkout_Perfdata_Cb           :: #type proc "stdcall"(perfdata : ^Checkout_Perfdata, payload : rawptr);
Transport_Message_Cb           :: #type proc "stdcall"(str : ^byte, len : i32, payload : rawptr) -> i32;
Transport_Certificate_Check_Cb :: #type proc "stdcall"(cert : ^Cert, valid : i32, host : ^byte, payload : rawptr) -> i32;
Cred_Acquire_Cb                :: #type proc "stdcall"(cred : ^^Cred,  url : ^byte,  username_from_url : ^byte, allowed_types : Cred_Type, payload : rawptr) -> i32;
Transfer_Progress_Cb           :: #type proc "stdcall"(stats : Transfer_Progress, payload : rawptr) -> i32;
Packbuilder_Progress_Cb        :: #type proc "stdcall"(stage : i32, current : u32, total : u32, payload : rawptr) -> i32;
Push_Transfer_Progress_Cb      :: #type proc "stdcall"(current : u32, total : u32, bytes : uint, payload : rawptr) -> i32;
Push_Negotiation_Cb            :: #type proc "stdcall"(updates : ^^Push_Update, len : uint, payload : rawptr) -> i32;
Transport_Cb                   :: #type proc "stdcall"(out : ^^Transport, owner : ^Remote, param : rawptr) -> i32;

//NOTE(Hoej): These are down here cause a user shouldn't really use these normally
REMOTE_CALLBACKS_VERSION    :: 1;
FETCH_OPTIONS_VERSION       :: 1;
STASH_APPLY_OPTIONS_VERSION :: 1;
STATUS_OPTIONS_VERSION      :: 1;
CHECKOUT_OPTIONS_VERSION    :: 1;
PUSH_OPTIONS_VERSION        :: 1;
PROXY_OPTIONS_VERSION       :: 1;
DIFF_OPTIONS_VERSION        :: 1;