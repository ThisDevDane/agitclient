package main;

import "core:strings";
import "core:runtime";

import cel "shared:odin-cel";
import console "shared:libbrew/console";

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

settings_instance := init_settings();

init_settings :: proc(username := "username", password := "password", name := "Jane Doe", email := "j.doe@example.com") -> Settings {
    return Settings {
        username = strings.new_string(username),
        password = strings.new_string(password),
        name = strings.new_string(name),
        email = strings.new_string(email),
    };
}

settings_free :: proc(settings : ^Settings) {
    runtime.delete(settings.username);
    runtime.delete(settings.password);
    runtime.delete(settings.name);
    runtime.delete(settings.email);
}

save :: proc() {
    if cel.marshal_file(SETTINGS_FILE, settings_instance) {
        console.log("settings saved.");
    } else {
        console.log_error("save_settings failed");
    }
}

load :: proc() {
    tmp := settings_instance;
    if cel.unmarshal_file(SETTINGS_FILE, settings_instance) {
        runtime.free(&tmp);
        console.log("settings loaded.");
    } else {
        settings_instance = tmp;
        console.log_error("load_settings failed");
    }
}

save_settings_cmd :: proc(args : []string) {
    save();
}

load_settings_cmd :: proc(args : []string) {
    load();
}
