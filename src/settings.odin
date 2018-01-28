import "core:strings.odin";

import "shared:libbrew/cel.odin";
import "console.odin";

SETTINGS_FILE :: "settings.cel";

Settings :: struct {
    username      : string,
    password      : string,
    name          : string,
    email         : string,

    use_ssh_agent : bool,

    recent_repos  : [dynamic]string,

    //Stuff for persistence over multiple runs
    auto_checkout_new_branch : bool,
    auto_setup_remote_branch : bool,
}

instance := init_settings();

init_settings :: proc(username := "username", password := "password", name := "Jane Doe", email := "j.doe@example.com") -> Settings {
    return Settings {
        username = strings.new_string(username),
        password = strings.new_string(password),
        name = strings.new_string(name),
        email = strings.new_string(email),
    };
}

free :: proc(settings : ^Settings) {
    _global.free(settings.username);
    _global.free(settings.password);
    _global.free(settings.name);
    _global.free(settings.email);
}

save :: proc() {
    if cel.marshal_file(SETTINGS_FILE, instance) {
        console.log("settings saved.");
    } else {
        console.log_error("save_settings failed");
    }
}

load :: proc() {
    tmp := instance;
    if cel.unmarshal_file(SETTINGS_FILE, instance) {
        free(&tmp);
        console.log("settings loaded.");
    } else {
        instance = tmp;
        console.log_error("load_settings failed");
    }
}

save_settings_cmd :: proc(args : []string) {
    save();
}

load_settings_cmd :: proc(args : []string) {
    load();
}
