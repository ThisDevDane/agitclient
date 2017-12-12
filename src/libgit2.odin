/*
 *  @Name:     libgit2
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 12-12-2017 01:50:33
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 12-12-2017 07:16:33
 *  
 *  @Description:
 *  
 */

foreign import libgit "../external/git2.lib";

import "core:fmt.odin";
import "core:mem.odin";
import "core:strings.odin";

GIT_OID_RAWSZ :: 20;

Repository :: struct #ordered {};
Remote     :: struct #ordered {};
Tree       :: struct #ordered {};
Index      :: struct #ordered {};
Transport  :: struct #ordered {};

Oid :: struct #ordered {
    /** raw binary formatted id */
    id : [GIT_OID_RAWSZ]byte,
}

Repository_Init_Options :: struct #ordered {
    version       : u32,
    flags         : u32,
    mode          : Repository_Init_Mode,
    workdir_path  : ^byte,
    description   : ^byte,
    template_path : ^byte,
    initial_head  : ^byte,
    origin_url    : ^byte,
}

Git_Error :: struct #ordered {
    message : ^byte,
    klass   : ErrorType,
}

Error :: struct {
    message : string,
    klass   : ErrorType,
}

Str_Array :: struct #ordered {
    strings : ^^byte,
    count   : uint,
}

Checkout_Perfdata :: struct #ordered {
    mkdir_calls : u32,
    stat_calls  : u32,
    chmod_calls : u32,
}

Cred :: struct #ordered {
    credtype : Cred_Type,
    free : proc "c" (cred : ^Cred),
}

Cred_Type :: enum u32 {
    /* git_cred_userpass_plaintext */
    Userpass_Plaintext = (1 << 0),

    /* git_cred_ssh_key */
    Ssh_Key = (1 << 1),

    /* git_cred_ssh_custom */
    Ssh_Custom = (1 << 2),

    /* git_cred_default */
    Default = (1 << 3),

    /* git_cred_ssh_interactive */
    Ssh_Interactive = (1 << 4),

    /**
     * Username-only information
     *
     * If the SSH transport does not know which username to use,
     * it will ask via this credential type.
     */
    Username = (1 << 5),

    /**
     * Credentials read from memory.
     *
     * Only available for libssh2+OpenSSL for now.
     */
    Ssh_Memory = (1 << 6),
}

Cert :: struct #ordered {
    type_ : Cert_Type,
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

Clone_Options :: struct #ordered {
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

    /**
     * Whether to use a fetch or copy the object database.
     */
    local : Clone_Local_Flags,

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
    repository_cb : proc "stdcall" (out : ^^Repository, path : ^byte, bare : i32, payload : rawptr) -> i32,

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
    remote_cb : proc "stdcall" (out : ^^Remote, repo : ^Repository, name : ^byte, url : ^byte, payload : rawptr) -> i32,

    /**
     * An opaque payload to pass to the git_remote creation callback.
     * This parameter is ignored unless remote_cb is non-NULL.
     */
    remote_cb_payload : rawptr,
}

Checkout_Options :: struct #ordered {
    version           : u32,

    checkout_strategy : u32, // default will be a dry run

    disable_filters   : i32, // don't apply filters like CRLF conversion
    dir_mode          : u32, // default is 0755
    file_mode         : u32, // default is 0644 or 0755 as dictated by blob
    file_open_flags   : i32, // default is O_CREAT | O_TRUNC | O_WRONLY

    notify_flags      : u32, // see `git_checkout_notify_t` above
    notify_cb         : proc "stdcall" (why : Checkout_Notify_Flags, path : ^byte, baseline : ^Diff_File, target : ^Diff_File, workdir : ^Diff_File, payload : rawptr) -> i32,
    notify_payload    : rawptr,

    // Optional callback to notify the consumer of checkout progress.
    progress_cb       : proc "stdcall" (path : ^byte, completed_steps : uint, total_steps : uint, payload : rawptr),
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
    baseline_index    : ^Index, /**< expected content of workdir, expressed as an index. */

    target_directory  : ^byte, /**< alternative checkout path to workdir */

    ancestor_label    : ^byte, /**< the name of the common ancestor side of conflicts */
    our_label         : ^byte, /**< the name of the "our" side of conflicts */
    their_label       : ^byte, /**< the name of the "their" side of conflicts */

    /** Optional callback to notify the consumer of performance data. */
    perfdata_cb       : proc "stdcall" (perfdata : ^Checkout_Perfdata, payload : rawptr),
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

Remote_Callbacks :: struct #ordered {
    version : u32,
    /**
     * Textual progress from the remote. Text send over the
     * progress side-band will be passed to this function (this is
     * the 'counting objects' output).
     */
    sideband_progress : proc "stdcall" (str : ^byte, len : i32, payload : rawptr) -> i32,

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
    credentials : proc "stdcall" (cred : ^^Cred,  url : ^byte,  username_from_url : ^byte, allowed_types : u32, payload : rawptr) -> i32,

    /**
     * If cert verification fails, this will be called to let the
     * user make the final decision of whether to allow the
     * connection to proceed. Returns 1 to allow the connection, 0
     * to disallow it or a negative value to indicate an error.
     */
    certificate_check : proc "stdcall" (cert : ^Cert, valid : i32, host : ^byte, payload : rawptr) -> i32,

    /**
     * During the download of new data, this will be regularly
     * called with the current count of progress done by the
     * indexer.
     */
    transfer_progress : proc "stdcall" (stats : Transfer_Progress, payload : rawptr) -> i32,

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
    pack_progress : proc "stdcall" (stage : i32, current : u32, total : u32, payload : rawptr) -> i32,

    /**
     * Function to call with progress information during the
     * upload portion of a push. Be aware that this is called
     * inline with pack building operations, so performance may be
     * affected.
     */
    push_transfer_progress : proc "stdcall" (current : u32, total : u32, bytes : uint, payload : rawptr) -> i32,

    /**
     * See documentation of git_push_update_reference_cb
     */
    push_update_reference : proc "stdcall" (refname : ^byte, status : ^byte, data : rawptr) -> i32,

    /**
     * Called once between the negotiation step and the upload. It
     * provides information about what updates will be performed.
     */
    push_negotiation : proc "stdcall" (updates : ^^Push_Update, len : uint, payload : rawptr) -> i32,

    /**
     * Create the transport to use for this operation. Leave NULL
     * to auto-detect.
     */
    transport : proc "stdcall" (out : ^^Transport, owner : ^Remote, param : rawptr) -> i32,

    /**
     * This will be passed to each of the callbacks in this struct
     * as the last parameter.
     */
    payload : rawptr,
}

Transfer_Progress :: struct #ordered {
    total_objects    : u32,
    indexed_objects  : u32,
    received_objects : u32,
    local_objects    : u32,
    total_deltas     : u32,
    indexed_deltas   : u32,
    received_bytes   : uint,
}

Push_Update :: struct #ordered {
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

/**
 * Type of host certificate structure that is passed to the check callback
 */
Cert_Type :: enum i32 {
    /**
     * No information about the certificate is available. This may
     * happen when using curl.
     */
    None,
        /**
         * The `data` argument to the callback will be a pointer to
         * the DER-encoded data.
         */
    X509,
        /**
         * The `data` argument to the callback will be a pointer to a
         * `git_cert_hostkey` structure.
         */
    Hostkey_Libssh2,
    /**
     * The `data` argument to the callback will be a pointer to a
     * `git_strarray` with `name:content` strings containing
     * information about the certificate. This is used when using
     * curl.
     */
    Str_array,
}  

Fetch_Prune_Flags :: enum i32 {
    /**
     * Use the setting from the configuration
     */
    Prune_Unspecified,
    /**
     * Force pruning on
     */
    Prune,
    /**
     * Force pruning off
     */
    No_Prune,
}

Remote_Autotag_Option_Flags :: enum i32 {
    /**
     * Use the setting from the configuration.
     */
    Unspecified = 0,
    /**
     * Ask the server for tags pointing to objects we're already
     * downloading.
     */
    Auto,
    /**
     * Don't ask for any tags beyond the refspecs.
     */
    None,
    /**
     * Ask for the all the tags.
     */
    All,
}


Clone_Local_Flags :: enum i32 {
    /**
     * Auto-detect (default), libgit2 will bypass the git-aware
     * transport for local paths, but use a normal fetch for
     * `file://` urls.
     */
    LOCAL_AUTO,
    /**
     * Bypass the git-aware transport even for a `file://` url.
     */
    LOCAL,
    /**
     * Do no bypass the git-aware transport
     */
    NO_LOCAL,
    /**
     * Bypass the git-aware transport, but do not try to use
     * hardlinks.
     */
    LOCAL_NO_LINKS,
}

Proxy_Options :: struct #ordered {
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
    credentials : proc "stdcall" (cred : ^^Cred, url : ^byte, username_from_url : ^byte, allowed_types : u32, payload : rawptr) -> i32,

    /**
     * If cert verification fails, this will be called to let the
     * user make the final decision of whether to allow the
     * connection to proceed. Returns 1 to allow the connection, 0
     * to disallow it or a negative value to indicate an error.
     */
    certificate_check : proc "stdcall" (cert : ^Cred, valid : i32, host : ^byte, paylod : rawptr),

    /**
     * Payload to be provided to the credentials and certificate
     * check callbacks.
     */
    payload : rawptr,
}

Diff_File :: struct #ordered {
    id        : Oid,
    path      : ^byte,
    size      : i64, //NOTE(Hoej): Changes with platform, i64 on Windows
    flags     : u32,
    mode      : u16,
    id_abbrev : u16,
}

Proxy_Flags :: enum i32 {
    /**
     * Do not attempt to connect through a proxy
     *
     * If built against libcurl, it itself may attempt to connect
     * to a proxy if the environment variables specify it.
     */
    None,
    /**
     * Try to auto-detect the proxy from the git configuration.
     */
    Auto,
    /**
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
  /**
   * If set, libgit2 was built thread-aware and can be safely used from multiple
   * threads.
   */
    THREADS = (1 << 0),
  /**
   * If set, libgit2 was built with and linked against a TLS implementation.
   * Custom TLS streams may still be added by the user to support HTTPS
   * regardless of this.
   */
    HTTPS   = (1 << 1),
  /**
   * If set, libgit2 was built with and linked against libssh2. A custom
   * transport may still be added by the user to support libssh2 regardless of
   * this.
   */
    SSH     = (1 << 2),
  /**
   * If set, libgit2 was built with support for sub-second resolution in file
   * modification times.
   */
    NSEC    = (1 << 3),
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


///////////////////////// Odin UTIL /////////////////////////

_PATH_BUF_SIZE :: 4096;
_URL_BUF_SIZE  :: 4096;
_MISC_BUF_SIZE :: 4096;

@(thread_local) _path_buf : [_PATH_BUF_SIZE]u8;
@(thread_local) _url_buf  : [_URL_BUF_SIZE]u8;
@(thread_local) _misc_buf : [_MISC_BUF_SIZE]u8;
_make_path_string :: proc(fmt_: string, args: ...any) -> ^byte {
    s := fmt.bprintf(_path_buf[..], fmt_, ...args);
    _path_buf[len(s)] = 0;
    return cast(^byte)&_path_buf[0];
}
_make_url_string :: proc(fmt_: string, args: ...any) -> ^byte {
    s := fmt.bprintf(_url_buf[..], fmt_, ...args);
    _url_buf[len(s)] = 0;
    return cast(^byte)&_url_buf[0];
}
_make_misc_string :: proc(fmt_: string, args: ...any) -> ^byte {
    s := fmt.bprintf(_misc_buf[..], fmt_, ...args);
    _misc_buf[len(s)] = 0;
    return cast(^byte)&_misc_buf[0];
}

status_cb :: #type proc "stdcall" (path : ^byte, status_flags : Status_Flags, payload : rawptr) -> i32;

@(default_calling_convention="stdcall")
foreign libgit {
    @(link_name = "git_libgit2_init")     lib_init     :: proc() -> i32 ---;
    @(link_name = "git_libgit2_shutdown") lib_shutdown :: proc() -> i32 ---;
    @(link_name = "git_libgit2_features") lib_features :: proc() -> Lib_Features ---;
    @(link_name = "git_libgit2_version")  lib_version  :: proc(major : ^i32, minor : ^i32, rev : ^i32) ---;

    giterr_last :: proc() -> ^Git_Error ---;

    git_repository_init :: proc(out : ^^Repository, path : ^byte, is_bare : u32) -> i32 ---;
    git_repository_init_ext :: proc(out : ^^Repository, path : ^byte, pots : ^Repository_Init_Options) -> i32 ---;
    @(link_name = "git_repository_free") repository_free :: proc(repo : ^Repository) ---;

    git_clone :: proc(out : ^^Repository, url : ^byte, local_path : ^byte, options : ^Clone_Options) -> i32 ---;

    git_repository_open :: proc(out : ^^Repository, path : ^byte) -> i32 ---;
    git_repository_open_ext :: proc(out : ^^Repository, path : ^byte, flags : Repository_Open_Flags, ceiling_dirs : ^byte) -> i32 ---;

    @(link_name = "git_status_foreach") status_foreach :: proc(repo : ^Repository, callback : status_cb, payload : rawptr) -> i32 ---;

    git_remote_lookup :: proc(out : ^^Remote, repo : ^Repository, name : ^byte) -> i32 ---;
    git_remote_list   :: proc(out : ^Str_Array, repo : ^Repository) -> i32 ---;
}

err_last        :: proc() -> Error {
    err := giterr_last();
    str := strings.to_odin_string(err.message);
    return Error{str, err.klass};
}

repository_init :: proc(path : string, is_bare : bool = false) -> (^Repository, i32) {
    repo : ^Repository = nil;
    err := git_repository_init(&repo, _make_path_string(path), u32(is_bare));
    return repo, err;
}

repository_init :: proc(path : string, opts : ^Repository_Init_Options) -> (^Repository, i32) {
    repo : ^Repository = nil;
    err := git_repository_init_ext(&repo, _make_path_string(path), opts);
    return repo, err;
}

clone           :: proc(url : string, local_path : string, options : ^Clone_Options) -> (^Repository, i32) {
    repo : ^Repository = nil;
    err := git_clone(&repo, _make_url_string(url), _make_path_string(local_path), options);
    return repo, err;
}

repository_open :: proc(path : string) -> (^Repository, i32) {
    repo : ^Repository = nil;
    err := git_repository_open(&repo, _make_path_string(path));
    return repo, err;
}

repository_open :: proc(path : string, flags : Repository_Open_Flags, ceiling_dirs : string) -> (^Repository, i32) {
    repo : ^Repository = nil;
    err := git_repository_open_ext(&repo, _make_path_string(path), flags, _make_misc_string(ceiling_dirs));
    return repo, err;
}

is_repository  :: proc(path : string) -> bool {
    if git_repository_open_ext(nil, _make_path_string(path), Repository_Open_Flags.No_Search, nil) != 0 {
        return true;
    } else {
        return false;
    }
}

remote_lookup :: proc(repo : ^Repository, name : string = "origin") -> (^Remote, i32) {
    rem : ^Remote = nil;
    err := git_remote_lookup(&rem, repo, _make_misc_string(name));
    return rem, err;
}

remote_list   :: proc(repo : ^Repository) -> ([]string, i32) {
    strs := Str_Array{};
    err := git_remote_list(&strs, repo);
    raw_strings := mem.slice_ptr(strs.strings, int(strs.count));
    res := make([]string, int(strs.count));
    for _, i in res {
        res[i] = strings.to_odin_string(raw_strings[i]);
    }

    return res, err;
}