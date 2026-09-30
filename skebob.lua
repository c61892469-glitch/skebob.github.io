
local pui = require("gamesense/pui")
local base64 = require("gamesense/base64")
local csgo_weapons = require("gamesense/csgo_weapons")
local vector = require("vector")
local ffi = require("ffi")
local gs_entity = require("gamesense/entity")

local function vtable_bind(module, interface, index, type)
    local ptr = ffi.cast("void***", client.create_interface(module, interface))
    local this = ptr[0]
    local fn = ffi.cast(type, this[index])
    return function(...)
        return fn(this, ...)
    end
end

local script_info = {
    name = "skebob.vip",
    version = "v1",
    build = "VIP",
    level = 2,
    username = _USER_NAME or "active user"
}

pui.macros.gray = "\0073d3d3dff"
pui.macros.exploit = "\7abab61ff"
pui.macros.sub = " \0077d7d7dff\226\134\170\r "
pui.macros.separation = string.rep("\226\148\128", 20)

local groups = {
    aa = {
        angles = pui.group("AA", "Anti-aimbot angles"),
        fake_lag = pui.group("AA", "Fake lag"),
        other = pui.group("AA", "Other")
    }
}

local refs = {
    rage = {
        aimbot = {
            enabled = { pui.reference("rage", "aimbot", "enabled") },
            target_selection = pui.reference("rage", "aimbot", "target selection"),
            target_hitbox = pui.reference("rage", "aimbot", "target hitbox"),
            mp_scale = pui.reference("rage", "aimbot", "multi-point scale"),
            minimum_damage = pui.reference("rage", "aimbot", "minimum damage"),
            minimum_damage_override = { pui.reference("rage", "aimbot", "minimum damage override") },
            minimum_hitchance = pui.reference("rage", "aimbot", "minimum hit chance"),
            double_tap = { pui.reference("rage", "aimbot", "double tap") },
            double_tap_limit = pui.reference("rage", "aimbot", "double tap fake lag limit"),
            force_body = pui.reference("rage", "aimbot", "force body aim"),
            force_safe = pui.reference("rage", "aimbot", "force safe point"),
            auto_scope = pui.reference("rage", "aimbot", "automatic scope")
        },
        other = {
            quick_peek = { pui.reference("rage", "other", "quick peek assist") },
            quick_peek_assist_mode = { pui.reference("rage", "other", "quick peek assist mode") },
            quick_peek_assist_distance = pui.reference("rage", "other", "quick peek assist distance"),
            fake_duck = pui.reference("rage", "other", "duck peek assist"),
            log_spread = pui.reference("rage", "other", "log misses due to spread")
        },
        ps = { pui.reference("misc", "miscellaneous", "ping spike") },
        log_hit = pui.reference("misc", "miscellaneous", "log damage dealt"),
        log_purchases = pui.reference("misc", "miscellaneous", "log weapon purchases")
    },
    aa = {
        angles = {
            enabled = pui.reference("aa", "anti-aimbot angles", "enabled"),
            pitch = { pui.reference("aa", "anti-aimbot angles", "pitch") },
            yaw = { pui.reference("aa", "anti-aimbot angles", "yaw") },
            yaw_base = pui.reference("aa", "anti-aimbot angles", "yaw base"),
            yaw_jitter = { pui.reference("aa", "anti-aimbot angles", "yaw jitter") },
            body_yaw = { pui.reference("aa", "anti-aimbot angles", "body yaw") },
            fs_body_yaw = pui.reference("aa", "anti-aimbot angles", "freestanding body yaw"),
            edge_yaw = pui.reference("aa", "anti-aimbot angles", "edge yaw"),
            freestanding = { pui.reference("aa", "anti-aimbot angles", "freestanding") },
            roll = pui.reference("aa", "anti-aimbot angles", "roll")
        },
        fakelag = {
            enabled = pui.reference("aa", "fake lag", "enabled"),
            amount = pui.reference("aa", "fake lag", "amount"),
            variance = pui.reference("aa", "fake lag", "variance"),
            limit = pui.reference("aa", "fake lag", "limit")
        },
        other = {
            on_shot_anti_aim = { pui.reference("aa", "other", "on shot anti-aim") },
            slow_motion = { pui.reference("aa", "other", "slow motion") },
            fake_peek = { pui.reference("aa", "other", "fake peek") },
            leg_movement = pui.reference("aa", "other", "leg movement")
        }
    },
    visuals = {
        scope = pui.reference("visuals", "effects", "remove scope overlay"),
        thirdperson = pui.reference("visuals", "effects", "force third person (alive)")
    },
    misc = {
        miscellaneous = {
            override_zoom_fov = pui.reference("misc", "miscellaneous", "override zoom fov"),
            clan_tag_spammer = pui.reference("misc", "miscellaneous", "clan tag spammer"),
            draw_console_output = pui.reference("misc", "miscellaneous", "draw console output")
        },
        settings = {
            menu_color = pui.reference("misc", "settings", "menu color"),
            anti_untrusted = pui.reference("misc", "settings", "anti-untrusted")
        },
        movement = {
            air_strafe = pui.reference("misc", "movement", "air strafe"),
            air_strafe_dir = pui.reference("misc", "movement", "air strafe direction")
        }
    },
    player_list = {
        players = pui.reference("players", "players", "player list"),
        force_body = pui.reference("players", "adjustments", "force body yaw"),
        force_body_value = pui.reference("players", "adjustments", "force body yaw value"),
        reset = pui.reference("players", "players", "reset all")
    }
}

local function safe_override_tbl(tbl)
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            if v.override then
                pcall(function()
                    v:override()
                    v:set_enabled(true)
                    if v.hotkey then v.hotkey:set_enabled(true) end
                end)
            else
                safe_override_tbl(v)
            end
        end
    end
end

client.delay_call(0, function()
    safe_override_tbl(refs)
end)

local text_cache = {}
local function cached_measure(flags, text)
    local key = tostring(flags) .. "|" .. tostring(text)
    if not text_cache[key] then
        text_cache[key] = renderer.measure_text(flags, text)
    end
    return text_cache[key]
end

local utils = {}

function utils.rgba_to_hex(r, g, b, a)
    g = g or r
    b = b or r
    a = a or r
    return string.format("%.2x%.2x%.2x%.2x", r, g, b, a)
end

function utils.lerp_color(c1, c2, t)
    return {
        r = c1.r + (c2.r - c1.r) * t,
        g = c1.g + (c2.g - c1.g) * t,
        b = c1.b + (c2.b - c1.b) * t,
        a = c1.a + (c2.a - c1.a) * t
    }
end

function utils.clamp(v, min_val, max_val)
    return math.max(math.min(v, max_val), min_val)
end

function utils.normalize(v, min_val, max_val)
    local range = max_val - min_val
    if range == 0 then return min_val end
    while v < min_val do
        v = v + range
    end
    while v > max_val do
        v = v - range
    end
    return v
end

function utils.normalize_yaw(yaw)
    yaw = ((yaw % 360) + 360) % 360
    return (yaw > 180) and (yaw - 360) or yaw
end

local function smooth_lerp(current, target, speed)
    speed = speed or 0.5
    return current + (target - current) * math.max(0, math.min(1, speed))
end

local function table_contains(tbl, value)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

local hotkey_manager = {}
do
    local hotkey_modes = { [0] = "Always on", [1] = "On hotkey", [2] = "Toggle", [3] = "Off hotkey" }
    local saved_states = {}
    local forced_states = {}

    local function get_hotkey_state(item)
        local mode, key = item:get_hotkey()
        return { hotkey_modes[mode] or "Off hotkey", key }
    end

    local function restore_hotkey(item, id)
        if forced_states[id] and saved_states[id] then
            item:set_hotkey(table.unpack(saved_states[id]))
            saved_states[id] = nil
            forced_states[id] = false
        end
    end

    local function force_hotkey(item, id)
        if not forced_states[id] then
            saved_states[id] = get_hotkey_state(item)
            item:set_hotkey("Always on")
            forced_states[id] = true
        end
    end

    function hotkey_manager.update(item, id, should_force)
        if not item or not id then return end
        if should_force then
            force_hotkey(item, id)
        else
            restore_hotkey(item, id)
        end
    end

    function hotkey_manager.force(item, id)
        if item and id then force_hotkey(item, id) end
    end

    function hotkey_manager.restore(item, id)
        if item and id then restore_hotkey(item, id) end
    end
end

local player_states = {
    "Standing", "Moving", "Walking", "Crouching",
    "Sneaking", "In air", "In air-crouch",
    "Freestanding", "Fake lag"
}

local ui = {}

function ui.lock_feature(item, default_value, required_level)
    if script_info.level < (required_level or 2) then
        local callback = function(val)
            client.delay_call(0.1, function()
                val:set(default_value or false)
            end)
        end
        item:set_callback(callback, true)
        item:set_enabled(false)
    end
    return item
end

do
    ui.space = groups.aa.angles:label("\nspace")

    local title = string.format("\226\139\134\226\156\180\239\184\142\203\154\239\189\161\226\139\134 \11%s %s\r \7ce9f9fff[%s]",
        script_info.name:lower(), script_info.version, script_info.build:lower())
    ui.toggle = groups.aa.angles:checkbox(title)

        local function on_toggle_change(item)
        local aa = refs.aa.angles
        if item:get() then
            aa.yaw[2]:depend({ aa.yaw[1], 666 }, { aa.yaw[2], 666 })
            aa.pitch[2]:depend({ aa.pitch[1], 666 }, { aa.pitch[2], 666 })
            aa.yaw_jitter[1]:depend({ aa.yaw[1], 666 }, { aa.yaw[2], 666 })
            aa.yaw_jitter[2]:depend({ aa.yaw[1], 666 }, { aa.yaw[2], 666 }, { aa.yaw_jitter[1], 666 }, { aa.yaw_jitter[2], 666 })
            aa.body_yaw[2]:depend({ aa.body_yaw[1], 666 })
            aa.fs_body_yaw:depend({ aa.body_yaw[1], 666 })
        end
    end

    ui.toggle:set_callback(on_toggle_change, true)

        pui.traverse({ refs.aa, ui.space }, function(item)
        item:depend({ ui.toggle, false })
        if item.hotkey then
            item.hotkey:depend({ ui.toggle, false })
        end
    end)
end

ui.tabs = {}
ui.tabs.main = groups.aa.angles:combobox("\nTab", {
    "Home",
    "Settings",
    "Anti-aimbot angles"
})

pui.traverse(ui.tabs, function(item)
    item:depend({ ui.toggle, true })
end)

local config_system

ui.configuration = {}
do
    ui.configuration.space = groups.aa.angles:label("\nspace")
    ui.configuration.cant_export_reason1 = groups.aa.fake_lag:label("You can't export your config because it")
    ui.configuration.cant_export_reason1_1 = groups.aa.fake_lag:label("only contains \11your personal settings")
    ui.configuration.cant_export_reason1_2 = groups.aa.fake_lag:label("and \11keybinds\r.")
    ui.configuration.cant_export_reason2 = groups.aa.other:label("Configs do not include \11shareable content\r.")
    ui.configuration.cant_export_reason3 = groups.aa.other:label("There is no benefit in sharing your")
    ui.configuration.cant_export_reason3_1 = groups.aa.other:label("config with others.")
    ui.configuration.cant_export_reason4 = groups.aa.other:label("Anti-aimbot angles config only stores your")
    ui.configuration.cant_export_reason4_1 = groups.aa.other:label("\11personal functions and binds\r.")

        local db_key = "skebobvip_configs"
    local saved_data = database.read(db_key) or {}
    local config_meta = { list = {}, id = 1 }

        local function encode_config(data)
        local payload = base64.encode(json.stringify(data))
        return table.concat({ "skebobvip", payload, "skebobvip" }, "::")
    end

    local function decode_config(str)
        local payload = str:match("skebobvip::(.+)::skebobvip")
        if not payload then
            print("Invalid config format")
            return nil
        end
        local decoded = base64.decode(payload)
        return json.parse(decoded)
    end

        local config_mgr = {}

    function config_mgr:export(name)
        return { name = (name or "Untitled"), code = config_system:save() }
    end

    function config_mgr:import(data)
        local cfg = decode_config(data)
        if not cfg then return nil end
        config_system:load(cfg.code)
        return cfg
    end

    function config_mgr:get_configs()
        local out = {}
        for i, v in ipairs(saved_data) do
            out[i] = v.name
        end
        return out
    end

    function config_mgr:get(id)
        return saved_data[id]
    end

    function config_mgr:delete(id)
        table.remove(saved_data, id)
    end

    function config_mgr:create(name, code)
        table.insert(saved_data, { name = name, code = code })
    end

    function config_mgr:save(id, code)
        if saved_data[id] then
            saved_data[id].code = code
        end
    end

    function config_mgr:create_from_encoded_data(data)
        local cfg = decode_config(data)
        if not cfg then
            error("Invalid config data.")
            return
        end
                local base_name = cfg.name
        local final_name = base_name
        local suffix = 0
        local function name_exists(n)
            for _, v in ipairs(saved_data) do
                if v.name == n then return true end
            end
            return false
        end
        while name_exists(final_name) do
            suffix = suffix + 1
            final_name = base_name .. "(" .. suffix .. ")"
        end
        cfg.name = final_name
        self:create(cfg.name, data)
    end

        local function get_cfg_name()
        local name = ui.configuration.name:get():gsub(" ", "")
        if name == "" then return true, "Config" end
        return true, name
    end

    local function validate_config_id(id)
        if #config_mgr:get_configs() <= 0 then
            print("No configs available.")
            return false, nil
        end
        local cfg = config_mgr:get(id)
        if not cfg then
            print("Config not found.")
            return false, nil
        end
        return true, cfg
    end

    local function do_load()
        local ok, cfg = validate_config_id(config_meta.id)
        if not ok or not cfg then
            print("Config is invalid.")
            return
        end
        config_mgr:import(cfg.code)
        client.exec("play ambient\\tones\\elev1")
    end

    local function do_save()
        local ok, name = get_cfg_name()
        if not ok then return end
        local code = config_mgr:export(name)
        local existing = config_mgr:get(config_meta.id)
        if not existing or name ~= existing.name then
            config_mgr:create(name, encode_config(code))
            client.exec("play ambient\\tones\\elev1")
        else
            config_mgr:save(config_meta.id, encode_config(code))
            client.exec("play ambient\\tones\\elev1")
        end
        database.write(db_key, saved_data)
    end

    local function do_delete()
        local ok, cfg = validate_config_id(config_meta.id)
        if not ok or not cfg then return end
        config_mgr:delete(config_meta.id)
        database.write(db_key, saved_data)
        client.exec("play ambient\\tones\\elev1")
    end

    local function do_export()
        local ok, name = get_cfg_name()
        if not ok then return end
        clipboard.set(encode_config(config_mgr:export(name)))
        print("Copied to clipboard.")
    end

    local function do_import()
        local data = clipboard.get()
        if not data then
            print("Clipboard is empty.")
            return
        end
        local ok = pcall(config_mgr.create_from_encoded_data, config_mgr, data)
        print((ok and "Config imported successfully.") or "Invalid config data.")
        if ok then database.write(db_key, saved_data) end
    end

    ui.configuration.list = groups.aa.angles:listbox("\nConfig list",
        ((#config_mgr:get_configs() > 0) and config_mgr:get_configs()) or { "Empty" })
    ui.configuration.name = groups.aa.angles:textbox("\nConfig name")
    ui.configuration.save = groups.aa.angles:button("Save", do_save)
    ui.configuration.load = groups.aa.angles:button("Load", do_load)
    ui.configuration.delete = groups.aa.angles:button("Delete", do_delete)
    ui.configuration.export = groups.aa.angles:button("Export", do_export)
    ui.configuration.import = groups.aa.angles:button("Import", do_import)

    ui.configuration.list:set_callback(function(item)
        local cfg = config_mgr:get(item:get() + 1) or config_mgr:get(config_meta.id)
        if cfg == nil then
            ui.configuration.name:set("")
            return
        end
        ui.configuration.name:set(cfg.name)
    end)

    client.set_event_callback("paint_ui", function()
        if not pui.is_menu_open() then return end
        local configs = config_mgr:get_configs()
        if #configs ~= #config_meta.list then
            config_meta.list = configs
            if #configs == 0 then
                ui.configuration.list:update({ "Empty" })
                ui.configuration.list.value = 1
                config_meta.id = 1
                return
            else
                ui.configuration.list:update(configs)
                return
            end
        end
        if ui.configuration.list.value == nil then
            ui.configuration.list.value = 1
        end
        local id = (ui.configuration.list.value or 1) + 1
        if id ~= config_meta.id then
            config_meta.id = id
        end
    end)

    pui.traverse(ui.configuration, function(item)
        item:depend({ ui.toggle, true }, { ui.tabs.main, "Home" })
    end)

    pui.traverse({ ui.configuration.export, ui.configuration.import }, function(item)
        item:depend({ ui.toggle, true }, { ui.tabs.main, "Home" })
    end)
end

ui.information = {}
do
    ui.information.name = groups.aa.fake_lag:label(
        string.format("Welcome back, \11%s\r!", script_info.username))
    ui.information.build = groups.aa.fake_lag:label(
        string.format("You're using \11%s\r build of %s \11%s\r.", script_info.build, script_info.name, script_info.version))
    ui.information.space = groups.aa.fake_lag:label("\nspace")
    ui.information.changelog = groups.aa.fake_lag:label("Changelog:")
    ui.information.log = groups.aa.fake_lag:label("[\1118/12/25\r] - Added peek bot, resolver,")
    ui.information.log_2 = groups.aa.fake_lag:label("and other rage functions.")

    pui.traverse(ui.information, function(item)
        item:depend({ ui.toggle, true }, { ui.tabs.main, "Settings" })
    end)
end

ui.statistics = {}
do
    ui.statistics.label = groups.aa.other:label("\11\238\139\188\r  Statistics")
    ui.statistics.separation = groups.aa.other:label("\12<gray>\12<seperation>")
    ui.statistics.hours_played = groups.aa.other:label("\12<gray>Hours played \226\151\166: \110")
    ui.statistics.times_loaded = groups.aa.other:label("\12<gray>Times loaded \226\151\166: \110")
    ui.statistics.enemies_killed = groups.aa.other:label("\12<gray>Enemies killed \226\151\166: \110")
    ui.statistics.hitrate = groups.aa.other:label("\12<gray>Hitrate \226\151\166: \110%")
    ui.statistics.gingerbread_earned = groups.aa.other:label("\12<gray>Gingerbread earned \226\151\166: \110")

    pui.traverse(ui.statistics, function(item)
        item:depend({ ui.toggle, true }, { ui.tabs.main, "Settings" })
    end)
end

ui.settings = {}
ui.settings.r_space = groups.aa.angles:label("\nspace")
ui.settings.r_label = groups.aa.angles:label("\11\238\132\174\r  Ragebot")
ui.settings.r_separation = groups.aa.angles:label("\12<gray>\12<seperation>")
ui.settings.resolver = groups.aa.angles:checkbox("\11\226\128\167\226\130\138\203\154 \226\152\129\239\184\143\226\139\133\226\153\161\240\147\130\131 \224\163\170 \214\180\214\182\214\184\226\152\190.\r  Resolver")
ui.settings.predict = groups.aa.angles:checkbox("CVar manipulation")
ui.settings.aimbot_helper = groups.aa.angles:checkbox("Aimbot helper")
ui.settings.aimbot_helper:set_enabled(true)
ui.settings.aimbot_helper_label = groups.aa.angles:label("Will \11prefer/force\r body aim and")
ui.settings.aimbot_helper_label_2 = groups.aa.angles:label("safe points if needed automatically.")
ui.settings.aimbot_helper_label:depend(ui.settings.aimbot_helper)
ui.settings.aimbot_helper_label_2:depend(ui.settings.aimbot_helper)
ui.settings.jump_scout = groups.aa.angles:checkbox("Jump scout helper")
ui.settings.jump_scout_label = groups.aa.angles:label("Will adjust your \11hit chance,")
ui.settings.jump_scout_label_2 = groups.aa.angles:label("\11auto stop\r & etc automatically.")
ui.settings.jump_scout_label:depend(ui.settings.jump_scout)
ui.settings.jump_scout_label_2:depend(ui.settings.jump_scout)
ui.settings.ideal_tick = groups.aa.angles:checkbox("Ideal tick", 0)
ui.settings.ideal_tick_settings = groups.aa.angles:multiselect("\nIdeal tick settings", { "Double tap", "Freestanding", "Auto peek" })
ui.settings.ideal_tick_settings:depend(ui.settings.ideal_tick)
ui.settings.swap_on_quick_peek = groups.aa.angles:checkbox("Swap to knife with auto peek  [SSG-08]")
ui.settings.unsafe_recharge = groups.aa.angles:checkbox("\12<exploit>Unsafe exploit recharge")
ui.settings.duck_peek_assist_fix = groups.aa.angles:checkbox("Crouch with duck peek assist")
ui.settings.auto_exploit = groups.aa.angles:checkbox("Auto exploit switch")
ui.settings.auto_exploit_states = groups.aa.angles:multiselect("\nAuto exploit states", { "Standing", "Walking", "Crouching", "Sneaking" })
ui.settings.auto_exploit_avoid = groups.aa.angles:multiselect("Auto exploit avoid", { "Pistols", "Desert eagle", "Auto snipers", "Desert eagle + Crouch" })

pui.traverse({ ui.settings.auto_exploit_states, ui.settings.auto_exploit_avoid }, function(item)
    item:depend(ui.settings.auto_exploit)
end)

ui.settings.auto_teleport = groups.aa.angles:checkbox("Auto break lag compensation", 0)
ui.settings.auto_teleport:set_enabled(true)
ui.settings.auto_teleport_dist = groups.aa.angles:slider("\nAuto teleport threat distance", 100, 2000, 800)
ui.settings.auto_teleport_fov = groups.aa.angles:slider("\nAuto teleport threat FOV", 10, 180, 60)

pui.traverse({ ui.settings.auto_teleport_dist, ui.settings.auto_teleport_fov }, function(item)
    item:depend(ui.settings.auto_teleport)
end)

ui.settings.peek_bot = groups.aa.angles:checkbox("Peek bot", 0)

ui.settings.v_space = groups.aa.angles:label("\nspace")
ui.settings.v_label = groups.aa.angles:label("\11\226\139\134\226\152\129\239\184\142\226\139\134\r  Visuals")
ui.settings.v_separation = groups.aa.angles:label("\12<gray>\12<seperation>")
ui.settings.accent_label = groups.aa.angles:label("Accent color")
ui.settings.accent = groups.aa.angles:color_picker("Accent color", 159, 166, 205)
ui.settings.force_watermark = groups.aa.angles:checkbox("Force branded watermark")
ui.settings.crosshair = groups.aa.angles:checkbox("Crosshair indicators")
ui.settings.arrow = groups.aa.angles:checkbox("Angle arrow")
ui.settings.scope = groups.aa.angles:checkbox("Custom scope")
ui.settings.scope_color = groups.aa.angles:color_picker("\nScope color", 159, 166, 205)
ui.settings.scope_color_2 = groups.aa.angles:color_picker("\nScope color 2", 159, 166, 205, 0)
ui.settings.scope_exclude = groups.aa.angles:multiselect("\nScope exclude", { "Top", "Bottom", "Left", "Right" })
ui.settings.scope_gap = groups.aa.angles:slider("\nScope gap", 0, 100, 10, true, "\226\134\185")
ui.settings.scope_size = groups.aa.angles:slider("\nScope size", 5, 400, 30, true, "%")

pui.traverse({ ui.settings.scope_color, ui.settings.scope_color_2, ui.settings.scope_exclude, ui.settings.scope_gap, ui.settings.scope_size }, function(item)
    item:depend(ui.settings.scope)
end)

ui.settings.zoom = groups.aa.angles:checkbox("Animated zoom")
ui.settings.zoom_fov = groups.aa.angles:slider("\nZoom FOV", 1, 100, 10, true, "%")
ui.settings.zoom_speed = groups.aa.angles:slider("\nZoom speed", 1, 45, 10, true, "ms")

pui.traverse({ ui.settings.zoom_fov, ui.settings.zoom_speed }, function(item)
    item:depend(ui.settings.zoom)
end)

ui.settings.logger = groups.aa.angles:checkbox("Event logger")
ui.settings.logger_on_screen = groups.aa.angles:checkbox("\12<sub> On screen")
ui.settings.logger_on_screen:depend(ui.settings.logger)

ui.settings.m_space = groups.aa.angles:label("\nspace")
ui.settings.m_label = groups.aa.angles:label("\11\238\132\149\r  Miscellaneous")
ui.settings.m_separation = groups.aa.angles:label("\12<gray>\12<seperation>")
ui.settings.ratio = groups.aa.angles:checkbox("Aspect ratio")
ui.settings.ratio_width = groups.aa.angles:slider("\nWidth", 1, 195, 100, true, "%")
ui.settings.ratio_width:depend(ui.settings.ratio)
ui.settings.viewmodel = groups.aa.angles:checkbox("Viewmodel")
ui.settings.viewmodel_in_scope = groups.aa.angles:checkbox("\12<sub> In scope")
ui.settings.viewmodel_center = groups.aa.angles:checkbox("\12<sub> Center in scope")
ui.settings.viewmodel_center:depend(ui.settings.viewmodel, ui.settings.viewmodel_in_scope)
ui.settings.viewmodel_fov = groups.aa.angles:slider("\nFOV", 0, 120, 68, true, "\194\176")
ui.settings.viewmodel_x = groups.aa.angles:slider("\nX", -100.0, 100, 0, true, "u", 0.1)
ui.settings.viewmodel_y = groups.aa.angles:slider("\nY", -100.0, 100, 0, true, "u", 0.1)
ui.settings.viewmodel_z = groups.aa.angles:slider("\nZ", -100.0, 100, 0, true, "u", 0.1)

pui.traverse({ ui.settings.viewmodel_in_scope, ui.settings.viewmodel_fov, ui.settings.viewmodel_x, ui.settings.viewmodel_y, ui.settings.viewmodel_z }, function(item)
    item:depend(ui.settings.viewmodel)
end)

ui.settings.animation_breaker = groups.aa.angles:checkbox("Animation breaker")
ui.settings.anim_in_moving = groups.aa.angles:combobox("Moving", { "Off", "Static", "Jitter" })
ui.settings.anim_in_air = groups.aa.angles:combobox("In air", { "Off", "Static", "Jitter", "Walking" })
ui.settings.anim_etc = groups.aa.angles:multiselect("Add-ons", { "Zero pitch on land", "Disable balance adjustment", "Smooth yaw angles", "Smooth player animation" })

pui.traverse({ ui.settings.anim_in_moving, ui.settings.anim_in_air, ui.settings.anim_etc }, function(item)
    item:depend(ui.settings.animation_breaker)
end)

ui.settings.edge_stop = groups.aa.angles:checkbox("Stop on edge", 0)
ui.settings.edge_stop:set_enabled(true)
ui.settings.console_filter = groups.aa.angles:checkbox("Console filter")
ui.settings.optimization = groups.aa.angles:checkbox("Optimization")
ui.settings.optimization:set_enabled(true)
ui.settings.trash_talk = groups.aa.angles:checkbox("Trash talk")
ui.settings.trash_talk:set_enabled(true)
ui.settings.trash_talk_mode = groups.aa.angles:combobox("\nTrash talk mode", { "skebob.vip", "Kawaii" })
ui.settings.trash_talk_type = groups.aa.angles:multiselect("\nTrash talk type", { "Kill", "Death", "Miss" })

pui.traverse({ ui.settings.trash_talk_mode, ui.settings.trash_talk_type }, function(item)
    item:depend(ui.settings.trash_talk)
end)

ui.settings.clan_tag = groups.aa.angles:checkbox("Clan tag spammer")

ui.settings.cs_space = groups.aa.angles:label("\nspace")
ui.settings.cs_label = groups.aa.angles:label("\11\238\128\173\r  Custom Crosshair")
ui.settings.cs_separation = groups.aa.angles:label("\12<gray>\12<seperation>")

ui.settings.custom_crosshair = groups.aa.angles:checkbox("Enable custom crosshair")
ui.settings.crosshair_size = groups.aa.angles:slider("\nCrosshair size", 2, 25, 8, true, "px")
ui.settings.crosshair_speed = groups.aa.angles:slider("\nRotation speed", 1, 15, 4, true, "x")
ui.settings.crosshair_rainbow = groups.aa.angles:checkbox("Rainbow RGB")
ui.settings.crosshair_color = groups.aa.angles:color_picker("\nCrosshair color", 255, 255, 255, 255)

pui.traverse({
    ui.settings.crosshair_size,
    ui.settings.crosshair_speed,
    ui.settings.crosshair_rainbow,
    ui.settings.crosshair_color
}, function(item)
    item:depend(ui.settings.custom_crosshair)
end)

ui.settings.crosshair_color:depend({ ui.settings.custom_crosshair, true }, { ui.settings.crosshair_rainbow, false })

ui.settings.hitmarker = groups.aa.angles:checkbox("Advanced custom hitmarker")
ui.settings.hitmarker_color = groups.aa.angles:color_picker("\nHitmarker color", 255, 255, 255, 255)
ui.settings.hitmarker_color:depend(ui.settings.hitmarker)

ui.settings.esp_space = groups.aa.angles:label("\nspace")
ui.settings.esp_label = groups.aa.angles:label("\11\238\129\167\r  ESP")
ui.settings.esp_separation = groups.aa.angles:label("\12<gray>\12<seperation>")

ui.settings.esp_box = groups.aa.angles:checkbox("Rainbow box + health/name ESP")
ui.settings.esp_snaplines = groups.aa.angles:checkbox("Rainbow snaplines")
ui.settings.esp_hats = groups.aa.angles:checkbox("Hat ESP (draw on enemies)")
ui.settings.esp_hats_color = groups.aa.angles:color_picker("\nHat color", 255, 70, 70, 200)
ui.settings.esp_hats_color:depend(ui.settings.esp_hats)

ui.settings.fx_space = groups.aa.angles:label("\nspace")
ui.settings.fx_label = groups.aa.angles:label("\11\238\129\167\r  Effects")
ui.settings.fx_separation = groups.aa.angles:label("\12<gray>\12<seperation>")

ui.settings.tracers = groups.aa.angles:checkbox("skebob.vip RGB lasers (tracers)")
ui.settings.kill_effect = groups.aa.angles:checkbox("skebob.vip kill effect (lightning + blood)")
ui.settings.particles = groups.aa.angles:checkbox("skebob.vip aura (3D particles)")
ui.settings.particles_color = groups.aa.angles:color_picker("\nParticle color", 180, 70, 255, 255)
ui.settings.particles_color:depend(ui.settings.particles)

pui.traverse(ui.settings, function(item)
    item:depend({ ui.toggle, true }, { ui.tabs.main, "Settings" })
end)

ui.aa = {}
pui.traverse(ui.aa, function(item)
    item:depend({ ui.toggle, true }, { ui.tabs.main, "Anti-aimbot angles" })
end)

ui.angles = {}
ui.angles.space = groups.aa.angles:label("\nspace")
ui.angles.type_label = groups.aa.angles:label("Why are there two anti-aim types?")
ui.angles.type_label_2 = groups.aa.angles:label("\12<gray>\226\128\162 \11Default\r: Most stable and reliable")
ui.angles.type_label_3 = groups.aa.angles:label("semi-static angles.")
ui.angles.type_label_4 = groups.aa.angles:label("\12<gray>\226\128\162 \11Experimental\r: Adaptive jitter")
ui.angles.type_label_5 = groups.aa.angles:label("angles, more unpredictable, may be")
ui.angles.type_label_6 = groups.aa.angles:label("luck-based or inconsistent.")
ui.angles.type = groups.aa.angles:combobox("\nDefault anti-aim", { "Default", "Experimental" })
ui.angles.defensive = groups.aa.angles:multiselect("Defensive anti-aim", { "Safe head", "Bait", "In air", "Walking", "Weapon events" })
ui.angles.unsafe = groups.aa.angles:checkbox("\12<sub> \12<exploit>Unsafe states")
ui.angles.us_states = groups.aa.angles:multiselect("\nUnsafe defensive anti-aim", { "Standing", "Manual angles", "Freestanding" })
ui.angles.us_states:depend(ui.angles.unsafe)

pui.traverse(ui.angles, function(item)
    item:depend({ ui.toggle, true }, { ui.tabs.main, "Anti-aimbot angles" })
end)

ui.hotkeys = {}
ui.hotkeys.space = groups.aa.angles:label("\nspace")
ui.hotkeys.static = groups.aa.angles:checkbox("Static manual angles")
ui.hotkeys.left = groups.aa.angles:hotkey("Manual left")
ui.hotkeys.right = groups.aa.angles:hotkey("Manual right")
ui.hotkeys.forward = groups.aa.angles:hotkey("Manual forward")
ui.hotkeys.reset = groups.aa.angles:hotkey("Manual reset")
ui.hotkeys.edge_yaw = groups.aa.angles:hotkey("Edge yaw")
ui.hotkeys.freestanding = groups.aa.angles:hotkey("Freestanding")
ui.hotkeys.auto_teleport = groups.aa.angles:hotkey("Auto teleport dash")
ui.hotkeys.disablers = groups.aa.angles:multiselect("Freestanding state disablers", unpack({ table.unpack(player_states, 1, #player_states - 2) }))

pui.traverse(ui.hotkeys, function(item)
    item:depend({ ui.toggle, true }, { ui.tabs.main, "Anti-aimbot angles" })
end)

ui.addons = {}
ui.addons.anti_backstab = groups.aa.fake_lag:checkbox("Anti-backstab")
ui.addons.legit_aa = groups.aa.fake_lag:checkbox("Anti-aim on use")
ui.addons.fast_ladder = groups.aa.fake_lag:checkbox("Fast ladder")
ui.addons.defensive_legs = groups.aa.fake_lag:checkbox("\12<exploit>Leg movement exploit")
ui.addons.defensive_peek = groups.aa.fake_lag:checkbox("\12<exploit>Defensive on peek fix")
ui.addons.defensive_peek_label = groups.aa.fake_lag:label("\7FFAA00FFExperimental Feature!")
ui.addons.defensive_peek_label_2 = groups.aa.fake_lag:label("May improve some peeking scenarios,")
ui.addons.defensive_peek_label_3 = groups.aa.fake_lag:label("but can also create new issues or risks.")

pui.traverse({ ui.addons.defensive_peek_label, ui.addons.defensive_peek_label_2, ui.addons.defensive_peek_label_3 }, function(item)
    item:depend(ui.addons.defensive_peek)
end)

ui.addons.shit_aa = groups.aa.other:multiselect("PAKETA AA on", { "Warm-up", "If enemies dead" })
ui.addons.shit_aa:set_enabled(true)

pui.traverse(ui.addons, function(item)
    item:depend({ ui.toggle, true }, { ui.tabs.main, "Anti-aimbot angles" })
end)

config_system = pui.setup({ ui.settings, ui.angles, ui.hotkeys, ui.addons })

do
    local stats_db_key = "mr_skebobvip_stats"
    local stats = database.read(stats_db_key) or {
        hours_played = 0,
        times_loaded = 0,
        enemies_killed = 0,
        shots_hit = 0,
        shots_missed = 0,
        last_time_counter = 0
    }
    local update_statistics_ui

    local function save_stats(key)
        if key then
            database.write(stats_db_key .. "_" .. key, stats[key])
        else
            for k, _ in pairs(stats) do
                database.write(stats_db_key .. "_" .. k, stats[k])
            end
        end
    end

    local function add_kill(event)
        if client.userid_to_entindex(event.userid) == 0 then return end
        stats.enemies_killed = stats.enemies_killed + 1
        save_stats("enemies_killed")
        update_statistics_ui()
    end

    local function add_hit(event)
        if client.userid_to_entindex(event.target) == 0 then return end
        stats.shots_hit = stats.shots_hit + 1
        save_stats("shots_hit")
        update_statistics_ui()
    end

    local function add_miss(event)
        if client.userid_to_entindex(event.target) == 0 then return end
        stats.shots_missed = stats.shots_missed + 1
        save_stats("shots_missed")
        update_statistics_ui()
    end

    local function add_playtime()
        local now = globals.realtime()
        if stats.last_time_counter == 0 then
            stats.last_time_counter = now
        end
        if (now - stats.last_time_counter) > 30 then
            stats.hours_played = stats.hours_played + ((now - stats.last_time_counter) / 3600)
            stats.last_time_counter = now
            save_stats("hours_played")
            save_stats("last_time_counter")
        end
    end

    local function get_hitrate()
        local total = stats.shots_hit + stats.shots_missed
        if total == 0 then return 100 end
        return (stats.shots_hit / total) * 100
    end

    update_statistics_ui = function()
        ui.statistics.hours_played:set(string.format("\12<gray>Hours played \226\151\166: \11%.2f", stats.hours_played))
        ui.statistics.times_loaded:set("\12<gray>Times loaded \226\151\166: \11" .. stats.times_loaded)
        ui.statistics.enemies_killed:set("\12<gray>Enemies killed \226\151\166: \11" .. stats.enemies_killed)
        ui.statistics.hitrate:set(string.format("\12<gray>Hitrate \226\151\166: \11%.1f%%", get_hitrate()))
    end

    stats.times_loaded = stats.times_loaded + 1
    save_stats("times_loaded")
    update_statistics_ui()

    client.set_event_callback("aim_hit", add_hit)
    client.set_event_callback("aim_miss", add_miss)
    client.set_event_callback("player_death", function(event)
        if client.userid_to_entindex(event.attacker) == entity.get_local_player() then
            add_kill(event)
        end
    end)
    client.set_event_callback("paint_ui", add_playtime)
end

local features = {}
local globals_state = {
    local_player = 0,
    is_alive = false,
    is_scoped = false,
    weapon = "None",
    on_ground = true,
    in_air = false,
    in_duck = false,
    duck_amount = 0,
    velocity = 0,
    speed = 0,
    hp = 100,
    choked = 0,
    tickcount = 0,
    desync_side = 1,
    manual_yaw = 0,
    freestanding_side = 0,
    defensive_active = false,
    last_damage = 0,
    clan_tag_index = 0,
    clan_tag_text = "",
    original_viewmodel = { fov = 68, x = 0, y = 0, z = 0 },
    original_zoom = 90,
    current_zoom = 90,
    scope_alpha = 0,
    peek_position = nil,
    peeking = false,
    ideal_ticking = false,
    dormant_mode = 0,
    hit_in_ground = false,
    real_yaw = 0,
    desync = 0,
    side = 0,
    send = false,
    body_yaw = 0,
    state = "Global",
    additional_state = "Global",
    shifting_enough = false,
    in_fake_lag = false,
}

local weapon_type_map = {
    [0] = "Knife", [1] = "Pistols", [2] = "SMG", [3] = "Rifles",
    [4] = "Shotgun", [5] = "Sniper", [6] = "Machinegun",
    [7] = "C4", [9] = "Grenade", [11] = "Stackableitem",
    [12] = "Fists", [13] = "Breachcharge", [14] = "Bumpmine",
    [15] = "Tablet", [16] = "Melee", [19] = "Equipment"
}

local function get_weapon_name(player)
    local weapon_ent = entity.get_player_weapon(player)
    if not weapon_ent then return "None" end
    local info = csgo_weapons(weapon_ent)
    if not info then return "None" end

    local category = weapon_type_map[info.type] or "Unknown"
    local console_name = info.console_name or ""
    local name = console_name:gsub("weapon_", ""):gsub("_.*", "")

    local is_knife = (category == "Knife") or name:find("knife") or name:find("bayonet")
    local is_sniper = (category == "Sniper")
    local is_deagle = (name == "deagle")
    local is_revolver = info.is_revolver or (name == "revolver")

    if is_knife or is_sniper or is_deagle or is_revolver then
        if name == "ssg08" then return "SSG08" end
        if name == "awp" then return "AWP" end
        if name == "revolver" or is_revolver then return "Revolver" end
        if name == "deagle" then return "Deagle" end
        if name == "bayonet" then return "Knife" end
        if name == "g3sg1" or name == "scar20" then return "Auto snipers" end
        return name:sub(1, 1):upper() .. name:sub(2):lower()
    end

    return category
end

local function is_in_fake_lag(cmd)
    local choked = cmd and cmd.chokedcommands or 0
    if refs.aa.fakelag.enabled:get() then
        if refs.aa.fakelag.limit:get() > 1 then
            local dt = refs.rage.aimbot.double_tap[1]:get() and refs.rage.aimbot.double_tap[1].hotkey:get()
            local osaa = refs.aa.other.on_shot_anti_aim[1]:get() and refs.aa.other.on_shot_anti_aim[1].hotkey:get()
            local not_fd = not refs.rage.other.fake_duck:get()
            if dt and not_fd then
                if choked > refs.rage.aimbot.double_tap_limit:get() then
                    return true
                end
            elseif osaa and not_fd then
                if choked > 1 then
                    return true
                end
            elseif choked ~= nil then
                return true
            end
        end
    end
    return false
end

local function get_state_name()
    if not globals_state.is_alive then return "Global", "Global" end

    local add_state
    if globals_state.in_fake_lag then
        add_state = "Fake lag"
    else
        local fs = refs.aa.angles.freestanding[1]:get() and refs.aa.angles.freestanding[1].hotkey:get()
        if fs then
            add_state = "Freestanding"
        else
            add_state = nil
        end
    end

    local state
    if not globals_state.on_ground then
        if globals_state.in_duck then
            state = "In air-crouch"
        else
            state = "In air"
        end
    else
        local fd = refs.rage.other.fake_duck:get()
        if globals_state.in_duck or fd then
            if globals_state.speed > 10 then
                state = "Sneaking"
            else
                state = "Crouching"
            end
        elseif globals_state.speed > 10 then
            local sm = refs.aa.other.slow_motion[1]:get() and refs.aa.other.slow_motion[1].hotkey:get()
            if sm then
                state = "Walking"
            else
                state = "Moving"
            end
        else
            state = "Standing"
        end
    end

    if not add_state then
        add_state = state
    end

    return state, add_state
end

local function update_local_state(cmd)
    local lp = entity.get_local_player()
    globals_state.local_player = lp or 0
    globals_state.is_alive = lp and entity.is_alive(lp) or false

    if not globals_state.is_alive then
        globals_state.weapon = "None"
        globals_state.on_ground = false
        return
    end

    local vx, vy = entity.get_prop(lp, "m_vecVelocity")
    local vel = vector(vx or 0, vy or 0, 0)
    globals_state.speed = vel:length()
    globals_state.velocity = globals_state.speed

    globals_state.hp = entity.get_prop(lp, "m_iHealth") or 100
    globals_state.weapon = get_weapon_name(lp)

    local flags = entity.get_prop(lp, "m_fFlags") or 0
    globals_state.on_ground = bit.band(flags, 1) ~= 0
    globals_state.in_air = not globals_state.on_ground

    local duck_amount = entity.get_prop(lp, "m_flDuckAmount") or 0
    globals_state.in_duck = duck_amount == 1
    globals_state.duck_amount = duck_amount

    globals_state.is_scoped = entity.get_prop(lp, "m_bIsScoped") == 1

    local success, result = pcall(function()
        return gs_entity(lp):get_anim_state()
    end)
    if success and result then
        globals_state.hit_in_ground = result.hit_in_ground_animation or false
    else
        globals_state.hit_in_ground = false
    end

    if cmd then
        globals_state.send = (cmd.chokedcommands or 0) == 0
        globals_state.in_fake_lag = is_in_fake_lag(cmd)
    end

    local state, add_state = get_state_name()
    globals_state.state = state
    globals_state.additional_state = add_state
end

features.resolver = {}
do
    local resolver_player_data = {}
    local resolver_states = {}
    local last_target = nil
    local BROKE_LC_DIST_SQ = 1024
    local LBY_UPDATE_TIME = 0.22
    local LBY_FLICK_MIN_DELTA = 10
    local FAKE_LAG_MIN_DIFF = 12

    local function to_ticks(simtime)
        return math.floor((simtime or 0) * 64 + 0.5)
    end

    local get_client_entity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")

    local anim_state_type = ffi.typeof([[
        struct {
            char pad0[0x18];
            float anim_update_timer;
            char pad1[0xC];
            float started_moving_time;
            float last_move_time;
            char pad2[0x10];
            float last_lby_time;
            char pad3[0x8];
            float run_amount;
            char pad4[0x10];
            void* entity;
            void* active_weapon;
            void* last_active_weapon;
            float last_client_side_animation_update_time;
            int last_client_side_animation_update_framecount;
            float eye_timer;
            float eye_angles_y;
            float eye_angles_x;
            float goal_feet_yaw;
            float current_feet_yaw;
            float torso_yaw;
            float last_move_yaw;
            float lean_amount;
            char pad5[0x4];
            float feet_cycle;
            float feet_yaw_rate;
            char pad6[0x4];
            float duck_amount;
            float landing_duck_amount;
            char pad7[0x4];
            float current_origin[3];
            float last_origin[3];
            float velocity_x;
            float velocity_y;
            char pad8[0x4];
            float unknown_float1;
            char pad9[0x8];
            float unknown_float2;
            float unknown_float3;
            float unknown;
            float m_velocity;
            float jump_fall_velocity;
            float clamped_velocity;
            float feet_speed_forwards_or_sideways;
            float feet_speed_unknown_forwards_or_sideways;
            float last_time_started_moving;
            float last_time_stopped_moving;
            bool on_ground;
            bool hit_in_ground_animation;
            char pad10[0x4];
            float time_since_in_air;
            float last_origin_z;
            float head_from_ground_distance_standing;
            float stop_to_full_running_fraction;
            char pad11[0x4];
            float magic_fraction;
            char pad12[0x3C];
            float world_force;
            char pad13[0x1CA];
            float min_yaw;
            float max_yaw;
        }*
    ]])

    local function get_anim_state(ent)
        if not ent then return nil end
        local ptr = get_client_entity(ent)
        if not ptr then return nil end
        local state = ffi.cast(anim_state_type, ffi.cast("char*", ffi.cast("void***", ptr)) + 39264)
        local gf = state.goal_feet_yaw
        if gf ~= gf or math.abs(gf) > 360 then return nil end
        return state
    end

    local function get_max_body_yaw(anim)
        if not anim then return 60 end
        local speed = math.max(math.min(anim.feet_speed_forwards_or_sideways or 0, 1), 0)
        local fraction = math.max(0, math.min(1, anim.stop_to_full_running_fraction or 0))
        local multiplier = ((fraction * -0.3) - 0.2) * speed + 1
        local duck = math.max(0, math.min(1, anim.duck_amount or 0))
        if duck > 0 then
            multiplier = multiplier + (duck * speed * (0.5 - multiplier))
        end
        return math.max(math.min(multiplier, 1), 0.5) * 60
    end

    local function create_player_data(ent)
        local data = {
            player = ent,
            last_simtime = 0,
            origin_x = 0, origin_y = 0, origin_z = 0,
            broke_lc = false,
            in_defensive = false,
            ticks_left = 0,
            max_tickbase = (tonumber(cvar.sv_maxusrcmdprocessticks:get_string()) or 16) - 1,
            tickbase_difference = 0,
        }
        function data.update()
            local simtime = entity.get_prop(data.player, "m_flSimulationTime") or 0
            local tick_sim = to_ticks(simtime)
            local ox, oy, oz = entity.get_prop(data.player, "m_vecOrigin")
            ox, oy, oz = ox or 0, oy or 0, oz or 0
            local tickbase = entity.get_prop(data.player, "m_nTickBase") or 0
            local diff = tick_sim - data.last_simtime

            if tickbase then
                if diff < 0 then
                    data.ticks_left = math.max(math.min(math.abs(diff), data.max_tickbase), 0)
                    data.tickbase_difference = tickbase
                else
                    if data.tickbase_difference > 0 then
                        local shift = math.abs(tickbase - data.tickbase_difference)
                        data.ticks_left = math.max(math.min(shift, data.max_tickbase), 0)
                    end
                    data.tickbase_difference = math.max(tickbase, data.tickbase_difference or 0)
                end
                data.in_defensive = (data.ticks_left > 1) and (data.ticks_left < data.max_tickbase)
            else
                data.in_defensive = false
                data.ticks_left = 0
            end

            if diff >= 0 then
                local dx = data.origin_x - ox
                local dy = data.origin_y - oy
                local dz = data.origin_z - oz
                data.broke_lc = (dx * dx + dy * dy + dz * dz) > BROKE_LC_DIST_SQ
                data.origin_x, data.origin_y, data.origin_z = ox, oy, oz
            end

            -- Fake lag detection: враг дёргает simtime
            data.in_fake_lag = (diff >= FAKE_LAG_MIN_DIFF) or (data.ticks_left > 1 and data.ticks_left < data.max_tickbase)

            data.last_simtime = tick_sim
        end
        return data
    end

    local function set_resolve(ent, values)
        if not ent then return end
        plist.set(ent, "Force body yaw", values.force_body_yaw and 1 or 0)
        plist.set(ent, "Force body yaw value", values.yaw_value or 0)
    end

    local function track_delay(state, tick)
        if not state.angle_history then
            state.angle_history = {}
            state.delay_history = {}
            state.cached_delay = nil
            state.delay_consistency = 0
            state.last_update_tick = tick
            return nil
        end

        local delta = tick - state.last_update_tick
        state.last_update_tick = tick

        if (delta >= 2) and (delta < 10) then
            table.insert(state.delay_history, delta)
            if #state.delay_history > 8 then
                table.remove(state.delay_history, 1)
            end

            if #state.delay_history >= 3 then
                local sum = 0
                local consistent = true
                local first = state.delay_history[1]
                for i = 1, #state.delay_history do
                    sum = sum + state.delay_history[i]
                    if math.abs(state.delay_history[i] - first) > 1 then
                        consistent = false
                    end
                end

                if consistent and (first > 2) then
                    state.cached_delay = first
                    state.delay_consistency = math.min((state.delay_consistency or 0) + 1, 5)
                else
                    state.delay_consistency = math.max((state.delay_consistency or 0) - 1, 0)
                    if state.delay_consistency == 0 then
                        state.cached_delay = nil
                    end
                end
            end
        elseif delta <= 2 then
            state.delay_consistency = math.max((state.delay_consistency or 0) - 1, 0)
            if state.delay_consistency == 0 then
                state.cached_delay = nil
                state.delay_history = {}
            end
        end

        return state.cached_delay
    end

    local function get_history_angle(state, delay)
        if (not state.angle_history) or (#state.angle_history < (delay + 1)) then
            return nil
        end
        local idx = #state.angle_history - delay
        if idx >= 1 then
            return state.angle_history[idx]
        end
        return nil
    end
    local function get_aa_state(state, yaw_delta, max_yaw, tick)
        local abs_delta = math.abs(yaw_delta)
        if abs_delta < 5 then
            state.static_ticks = (state.static_ticks or 0) + 1
            if state.static_ticks >= 3 then
                return "S"
            end
        else
            state.static_ticks = 0
        end

        if abs_delta > 30 then
            state.jitter_ticks = (state.jitter_ticks or 0) + 1
            if state.jitter_ticks >= 2 then
                local delay = track_delay(state, tick)
                if delay and ((state.delay_consistency or 0) >= 3) then
                    return "DJ"
                end
                return "J"
            end
        else
            state.jitter_ticks = math.max((state.jitter_ticks or 0) - 1, 0)
        end

        return "S"
    end

    local function resolve_player(ent)
        if not entity.is_enemy(ent) then return end

        local data = resolver_player_data[ent]
        if not data then
            data = create_player_data(ent)
            resolver_player_data[ent] = data
        end
        data.update()

        local anim = get_anim_state(ent)
        if not anim then return end

        local simtime = entity.get_prop(ent, "m_flSimulationTime") or 0
        local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles")) or 0
        if not eye_yaw then return end

        local pose_yaw_raw = entity.get_prop(ent, "m_flPoseParameter", 11)
        local pose_yaw = pose_yaw_raw and ((pose_yaw_raw * 360) - 180) or nil

        -- LBY tracking
        local lby = entity.get_prop(ent, "m_flLowerBodyYawTarget") or 0
        local goal_feet = anim.goal_feet_yaw or eye_yaw
        local lby_delta = math.abs(utils.normalize_yaw(lby - eye_yaw))
        local goal_delta = math.abs(utils.normalize_yaw(goal_feet - eye_yaw))

        local tick_sim = to_ticks(simtime)

        local state = resolver_states[ent]
        if not state then
            state = {
                last_yaw = eye_yaw,
                last_simtime = simtime,
                side = 1,
                jitter_ticks = 0,
                static_ticks = 0,
                no_update_ticks = 0,
                resolve_yaw = 0,
                last_resolve_yaw = 0,
                aa_state = "S",
                angle_history = {},
                delay_history = {},
                cached_delay = nil,
                delay_consistency = 0,
                last_update_tick = tick_sim,
                cum_delta = 0,
                last_lby = lby,
                last_lby_update_time = 0,
                force_brute = nil,
                brute_ticks = 0,
                brute_flip = 1,
                brute_base_side = nil,
                miss_count = 0,
                hit_count = 0,
            }
            resolver_states[ent] = state
            return
        end

        if simtime == state.last_simtime then
            state.no_update_ticks = (state.no_update_ticks or 0) + 1
            local defensive = data.in_defensive or false
            if not defensive then
                set_resolve(ent, {force_body_yaw = true, yaw_value = state.last_resolve_yaw})
            else
                set_resolve(ent, {force_body_yaw = false, yaw_value = 0})
            end
            return
        end

        state.no_update_ticks = 0
        local yaw_delta = utils.normalize_yaw(eye_yaw - state.last_yaw)
        local max_yaw = get_max_body_yaw(anim)

        table.insert(state.angle_history, eye_yaw)
        if #state.angle_history > 16 then
            table.remove(state.angle_history, 1)
        end

        -- LBY update detection
        local curtime = globals.curtime()
        local lby_changed = (lby ~= state.last_lby)
        local time_since_update = curtime - (state.last_lby_update_time or 0)
        local lby_flick_confirmed = lby_changed and lby_delta > LBY_FLICK_MIN_DELTA and time_since_update > LBY_UPDATE_TIME

        if lby_changed then
            state.last_lby_update_time = curtime
        end
        state.last_lby = lby

        -- Bruteforce: если попали в brute-режим, используем сохранённый угол
        if state.force_brute then
            state.brute_ticks = (state.brute_ticks or 0) + 1
            if state.brute_ticks > 8 then
                state.force_brute = nil
                state.brute_ticks = 0
                state.brute_base_side = nil
                state.brute_flip = 1
            else
                state.resolve_yaw = state.force_brute
                state.last_resolve_yaw = state.resolve_yaw
                local defensive = data.in_defensive or false
                if not defensive then
                    set_resolve(ent, {force_body_yaw = true, yaw_value = state.resolve_yaw})
                end
                state.last_yaw = eye_yaw
                state.last_simtime = simtime
                return
            end
        end

        -- Приоритет 1: LBY updated → real angle точно известен
        if lby_flick_confirmed then
            state.resolve_yaw = utils.normalize_yaw(lby)
            state.last_resolve_yaw = state.resolve_yaw
            local defensive = data.in_defensive or false
            if not defensive then
                set_resolve(ent, {force_body_yaw = true, yaw_value = state.resolve_yaw})
            end
            state.last_yaw = eye_yaw
            state.last_simtime = simtime
            state.aa_state = "LBY"
            return
        end

        -- Если враг в fakelag — pose parameter может быть мусором, не форсим
        if not data.in_fake_lag and pose_yaw then
            -- Приоритет 1.5: pose parameter даёт точный desync
            local pose_delta = math.abs(utils.normalize_yaw(pose_yaw - eye_yaw))
            if pose_delta > 15 and pose_delta < 60 then
                state.resolve_yaw = utils.normalize_yaw(pose_yaw)
                state.last_resolve_yaw = state.resolve_yaw
                local defensive = data.in_defensive or false
                if not defensive then
                    set_resolve(ent, {force_body_yaw = true, yaw_value = state.resolve_yaw})
                end
                state.last_yaw = eye_yaw
                state.last_simtime = simtime
                state.aa_state = "P"
                return
            end
        end

        -- Приоритет 2: goal_feet_yaw сильно расходится с eye_yaw → desync known
        if not data.in_fake_lag and goal_delta > 20 and goal_delta < 60 then
            state.resolve_yaw = utils.normalize_yaw(goal_feet)
            state.last_resolve_yaw = state.resolve_yaw
            local defensive = data.in_defensive or false
            if not defensive then
                set_resolve(ent, {force_body_yaw = true, yaw_value = state.resolve_yaw})
            end
            state.last_yaw = eye_yaw
            state.last_simtime = simtime
            state.aa_state = "G"
            return
        end

        -- Если враг в fakelag — не форсим резолв, ждём
        if data.in_fake_lag then
            state.aa_state = "FL"
            state.last_yaw = eye_yaw
            state.last_simtime = simtime
            return
        end

        -- Приоритет 3: обычная jitter/static логика
        state.aa_state = get_aa_state(state, yaw_delta, max_yaw, tick_sim)

        if (state.aa_state == "DJ") and state.cached_delay then
            local old_angle = get_history_angle(state, state.cached_delay)
            if old_angle then
                local delta = utils.normalize_yaw(eye_yaw - old_angle)
                if math.abs(delta) > 30 then
                    state.side = (delta > 0) and 1 or -1
                end
                local abs_delta = math.abs(delta)
                local scale = math.max(math.min(abs_delta / max_yaw, 1), 0.15)
                state.resolve_yaw = state.side * max_yaw * scale
            else
                if math.abs(yaw_delta) > 30 then
                    local cum = (state.cum_delta or 0) * 0.8 + yaw_delta * 0.2
                    state.cum_delta = cum
                    state.side = (cum > 0) and 1 or -1
                end
                local abs_delta = math.abs(yaw_delta)
                local scale = math.max(math.min(abs_delta / max_yaw, 1), 0.15)
                state.resolve_yaw = state.side * max_yaw * scale
            end
        else
            if math.abs(yaw_delta) > 30 then
                state.side = (yaw_delta > 0) and 1 or -1
            end
            local abs_delta = math.abs(yaw_delta)
            local scale = math.max(math.min(abs_delta / max_yaw, 1), 0.15)
            state.resolve_yaw = state.side * max_yaw * scale
        end

        state.last_resolve_yaw = state.resolve_yaw
        local defensive = data.in_defensive or false

        -- Форсим ТОЛЬКО когда есть признаки AA
        local has_aa = (state.aa_state ~= "S") or data.broke_lc or (math.abs(yaw_delta) > 15)
        
        -- Confidence система: если miss_count растёт — снижаем уверенность
        if has_aa and not defensive then
            if state.miss_count >= 1 and state.force_brute == nil then
                state.force_brute = (state.brute_base_side or state.side) * 60 * (state.brute_flip or 1)
                state.brute_ticks = 0
                set_resolve(ent, {force_body_yaw = true, yaw_value = state.force_brute})
                state.last_resolve_yaw = state.force_brute
            else
                if state.last_resolve_yaw ~= state.resolve_yaw then
                    set_resolve(ent, {force_body_yaw = true, yaw_value = state.resolve_yaw})
                    state.last_resolve_yaw = state.resolve_yaw
                end
            end
        else
            state.force_brute = nil
            state.brute_ticks = 0
            state.brute_base_side = nil
            state.brute_flip = 1
            if state.last_resolve_yaw ~= 0 then
                set_resolve(ent, {force_body_yaw = false, yaw_value = 0})
                state.last_resolve_yaw = 0
            end
        end

        state.last_yaw = eye_yaw
        state.last_simtime = simtime
    end

    local function cleanup_resolver()
        for ent in pairs(resolver_states) do
            set_resolve(ent, {force_body_yaw = false, yaw_value = 0})
        end
        resolver_player_data = {}
        resolver_states = {}
    end

    local function reset_resolver()
        resolver_player_data = {}
        resolver_states = {}
    end

    local function resolver_run()
        local ok, err = pcall(function()
            local lp = entity.get_local_player()
            if (not lp) or (not entity.is_alive(lp)) then
                cleanup_resolver()
                return
            end

            local target = client.current_threat and client.current_threat()
            if target ~= nil then
                last_target = target
            end

            if (not target) or (not entity.is_alive(target)) then
                for ent, _ in pairs(resolver_states) do
                    if not entity.is_alive(ent) then
                        set_resolve(ent, {force_body_yaw = false, yaw_value = 0})
                        resolver_states[ent] = nil
                        resolver_player_data[ent] = nil
                    end
                end
                return
            end

            if entity.is_dormant(target) then
                set_resolve(target, {force_body_yaw = false, yaw_value = 0})
                return
            end

            resolve_player(target)
        end)
        if not ok then
            client.log("[resolver error] " .. tostring(err))
        end
    end

    local resolver_hooked = false
    local function resolver_toggle_callback(item)
        local enabled = ui.toggle:get() and item:get()
        if enabled then
            if not resolver_hooked then
                client.set_event_callback("net_update_end", resolver_run)
                client.set_event_callback("round_prestart", reset_resolver)
                resolver_hooked = true
            end
        else
            if resolver_hooked then
                client.unset_event_callback("net_update_end", resolver_run)
                client.unset_event_callback("round_prestart", reset_resolver)
                resolver_hooked = false
            end
            cleanup_resolver()
            refs.player_list.reset:set(true)
        end
    end

    function features.resolver.on_hit(ent)
        if not ent then return end
        local state = resolver_states[ent]
        if not state then return end
        state.hit_count = (state.hit_count or 0) + 1
        state.miss_count = 0
        state.force_brute = nil
        state.brute_ticks = 0
        state.brute_flip = 1
        state.brute_base_side = nil
        state.brute_index = nil
    end

    local BRUTE_ANGLES = {58, -58, 29, -29, 90, -90, 180, 0}

    function features.resolver.on_miss(ent)
        if not ent then return end
        local state = resolver_states[ent]
        if not state then return end
        state.miss_count = (state.miss_count or 0) + 1
        state.hit_count = 0
        state.brute_index = ((state.brute_index or 0) % #BRUTE_ANGLES) + 1
        state.force_brute = BRUTE_ANGLES[state.brute_index]
        state.brute_ticks = 0
    end

    ui.settings.resolver:set_callback(resolver_toggle_callback, true)
end

features.predict = {}
do
    local predict_hooked = false

    local function predict_cvars()
        cvar.cl_interpolate:set_int(0)
        cvar.cl_interp_ratio:set_int(1)
    end

    local function restore_predict_cvars()
        cvar.cl_interpolate:set_int(1)
        cvar.cl_interp_ratio:set_int(2)
    end

    local function predict_callback()
        if ui.settings.predict:get() then
            predict_cvars()
        end
    end

    ui.settings.predict:set_callback(function(item)
        local enabled = ui.toggle:get() and item:get()
        if enabled then
            if not predict_hooked then
                client.set_event_callback("pre_render", predict_callback)
                predict_hooked = true
            end
        else
            if predict_hooked then
                client.unset_event_callback("pre_render", predict_callback)
                predict_hooked = false
            end
            restore_predict_cvars()
        end
    end, true)
end

features.aimbot_helper = {}
function features.aimbot_helper.run(cmd)
    if not ui.settings.aimbot_helper:get() then
        refs.rage.aimbot.force_body:override()
        refs.rage.aimbot.force_safe:override()
        return
    end

    local lp = globals_state.local_player
    if not lp or not entity.is_alive(lp) then
        refs.rage.aimbot.force_body:override()
        refs.rage.aimbot.force_safe:override()
        return
    end

    local target = client.current_threat and client.current_threat()
    if not target or not entity.is_alive(target) then
        refs.rage.aimbot.force_body:override()
        refs.rage.aimbot.force_safe:override()
        return
    end

    local hp = entity.get_prop(target, "m_iHealth") or 100
    local vx, vy, vz = entity.get_prop(target, "m_vecVelocity")
    local speed = 0
    if vx then speed = math.sqrt(vx * vx + (vy or 0) * (vy or 0) + (vz or 0) * (vz or 0)) end

    -- Если у врага мало HP — force safe point
    if hp <= 30 then
        refs.rage.aimbot.force_safe:override(true)
    else
        refs.rage.aimbot.force_safe:override()
    end

    -- Если враг быстро движется — force body aim
    if speed > 100 then
        refs.rage.aimbot.force_body:override(true)
    else
        refs.rage.aimbot.force_body:override()
    end
end

features.jump_scout = {}
do
    local last_enabled = false

    local function calc_hitchance(dist)
        local clamped = math.min(dist, 1350)
        local hc = 55 + (20 * (clamped / 1350))
        return math.floor(hc + 0.5)
    end

    local function reset_overrides(include_strafe)
        refs.rage.aimbot.target_selection:override()
        refs.rage.aimbot.mp_scale:override()
        refs.rage.aimbot.minimum_hitchance:override()
        if include_strafe then
            refs.misc.movement.air_strafe_dir:override()
        end
    end

    function features.jump_scout.run(cmd)
        if not ui.settings.jump_scout:get() then
            if last_enabled then
                reset_overrides(true)
                last_enabled = false
            end
            return
        end
        last_enabled = true

        local lp = globals_state.local_player
        if (not lp) or (not entity.is_alive(lp)) or (globals_state.weapon ~= "SSG08") then
            reset_overrides(true)
            return
        end

        local scoped = entity.get_prop(lp, "m_bIsScoped") == 1
        if not scoped then
            reset_overrides(true)
            return
        end

        local mx, my, mz = entity.get_prop(lp, "m_vecOrigin")
        local my_pos = vector(mx or 0, my or 0, mz or 0)

        if (not globals_state.on_ground) or (cmd.in_jump == 1) then
            refs.rage.aimbot.target_selection:override("Best hit chance")
            refs.rage.aimbot.mp_scale:override(24)

            local hc = 60
            local target = client.current_threat and client.current_threat()

            if not target then
                local enemies = entity.get_players(true)
                local closest = math.huge
                for _, ent in ipairs(enemies) do
                    if entity.is_alive(ent) then
                        local tx, ty, tz = entity.get_prop(ent, "m_vecOrigin")
                        local their_pos = vector(tx or 0, ty or 0, tz or 0)
                        local dist = (my_pos - their_pos):length()
                        if dist < closest then
                            closest = dist
                            target = ent
                        end
                    end
                end
            end

            if target then
                local tx, ty, tz = entity.get_prop(target, "m_vecOrigin")
                local their_pos = vector(tx or 0, ty or 0, tz or 0)
                local dist = (my_pos - their_pos):length()
                hc = calc_hitchance(dist)
            end
            refs.rage.aimbot.minimum_hitchance:override(hc)

        elseif globals_state.hit_in_ground then
            refs.rage.aimbot.target_selection:override("Best hit chance")
            refs.rage.aimbot.mp_scale:override()
            refs.rage.aimbot.minimum_hitchance:override()
        else
            refs.rage.aimbot.target_selection:override("Highest damage")
            refs.rage.aimbot.mp_scale:override()
            refs.rage.aimbot.minimum_hitchance:override()
        end

        local movetype = entity.get_prop(lp, "m_MoveType") or 0
        local on_ladder = (movetype == 9) or (movetype == 8)

        if (globals_state.speed < 10) and (not globals_state.on_ground) and (not on_ladder) then
            refs.misc.movement.air_strafe_dir:override("Movement keys")
            cmd.in_duck = 1
        else
            refs.misc.movement.air_strafe_dir:override()
        end
    end
end

features.ideal_tick = {}
do
    local last_enabled = false

    function features.ideal_tick.run(cmd)
        local enabled = ui.settings.ideal_tick:get() and ui.settings.ideal_tick.hotkey:get()
        local settings = ui.settings.ideal_tick_settings:get() or {}

        if not enabled then
            if last_enabled then
                if table_contains(settings, "Double tap") then
                    hotkey_manager.restore(refs.rage.aimbot.double_tap[1], "double_tap")
                end
                if table_contains(settings, "Auto peek") then
                    hotkey_manager.restore(refs.rage.other.quick_peek[1], "auto_peek")
                end
                last_enabled = false
            end
            return
        end
        last_enabled = true

        hotkey_manager.update(refs.rage.aimbot.double_tap[1], "double_tap", table_contains(settings, "Double tap"))
        if table_contains(settings, "Freestanding") then
            refs.aa.angles.freestanding[1]:override(true)
        end
        hotkey_manager.update(refs.rage.other.quick_peek[1], "auto_peek", table_contains(settings, "Auto peek"))
    end
end

features.quick_peek_swap = {}
do
    local swap_state = 0
    local swap_timer = 0
    local next_attack = 0
    local tick_base = 0
    local last_switch_time = 0
    local last_slot = 1

    local function can_switch()
        return (globals.realtime() - last_switch_time) >= 0.05
    end

    local function send_slot(slot)
        if (last_slot == slot) or (not can_switch()) then return end
        client.exec((slot == 1) and "slot1" or "slot3")
        last_slot = slot
        last_switch_time = globals.realtime()
    end

    local function reset_swap(go_primary)
        if go_primary then send_slot(1) end
        swap_state = 0
        swap_timer = 0
        next_attack = 0
        tick_base = 0
    end

    local function is_peeking()
        return refs.rage.other.quick_peek[1]:get() and refs.rage.other.quick_peek[1].hotkey:get()
    end

    local function can_swap_weapon()
        if globals_state.weapon ~= "SSG08" then
            next_attack = 0
            tick_base = 0
            return false
        end
        local lp = globals_state.local_player
        if not lp then return false end
        local weapon_ent = entity.get_player_weapon(lp)
        if not weapon_ent then return false end
        if entity.get_prop(weapon_ent, "m_bInReload") == 1 then
            next_attack = 0
            tick_base = 0
            return false
        end
        local next_atk = entity.get_prop(weapon_ent, "m_flNextPrimaryAttack")
        local tb = entity.get_prop(lp, "m_nTickBase")
        if (not next_atk) or (not tb) then return false end
        local fired = false
        if next_attack ~= 0 then
            if (next_atk > next_attack) and (tb > tick_base) then
                fired = true
            end
        end
        next_attack = next_atk
        tick_base = tb
        return fired
    end

    local last_enabled = false

    function features.quick_peek_swap.run(cmd)
        if not ui.settings.swap_on_quick_peek:get() then
            if last_enabled then
                reset_swap(true)
                last_enabled = false
            end
            return
        end
        last_enabled = true

        local lp = globals_state.local_player
        if (not lp) or (not entity.is_alive(lp)) then
            reset_swap(false)
            return
        end

        if not is_peeking() then
            reset_swap(true)
            return
        end

        if swap_state == 0 then
            if can_swap_weapon() then
                send_slot(3)
                swap_state = 1
                swap_timer = globals.realtime()
            end
        elseif swap_state == 1 then
            if (globals.realtime() - swap_timer) >= 0.35 then
                send_slot(1)
                reset_swap(false)
            end
        end
    end
end

features.unsafe_recharge = {}
do
    local recharge_timer = globals.tickcount()
    local recharge_ticks = 14
    local last_enabled = false

    function features.unsafe_recharge.run(cmd)
        if not ui.settings.unsafe_recharge:get() then
            if last_enabled then
                refs.rage.aimbot.enabled[1]:override()
                last_enabled = false
            end
            return
        end
        last_enabled = true

        local lp = globals_state.local_player
        if (not lp) or (not entity.is_alive(lp)) then
            refs.rage.aimbot.enabled[1]:override()
            return
        end

        local dt = refs.rage.aimbot.double_tap[1]:get() and refs.rage.aimbot.double_tap[1].hotkey:get() and (not refs.rage.other.fake_duck:get())
        local osaa = refs.aa.other.on_shot_anti_aim[1]:get() and refs.aa.other.on_shot_anti_aim[1].hotkey:get() and (not refs.rage.other.fake_duck:get())

        local weapon_ent = entity.get_player_weapon(lp)
        if weapon_ent then
            local info = csgo_weapons(weapon_ent)
            recharge_ticks = (info and info.is_revolver) and 17 or 14
        end

        if dt or osaa then
            if globals.tickcount() >= (recharge_timer + recharge_ticks) then
                refs.rage.aimbot.enabled[1]:override(true)
            else
                refs.rage.aimbot.enabled[1]:override(false)
            end
        else
            recharge_timer = globals.tickcount()
            refs.rage.aimbot.enabled[1]:override()
        end
    end

    client.set_event_callback("round_start", function()
        recharge_timer = globals.tickcount()
    end)
end

features.duck_peek_fix = {}
do
    local saved_fd_state = nil
    local modified = false
    local last_enabled = false

    local function get_fd_state(item)
        return {item:get()}
    end

    function features.duck_peek_fix.run(cmd)
        if not ui.settings.duck_peek_assist_fix:get() then
            if last_enabled and saved_fd_state then
                refs.rage.other.fake_duck:set(table.unpack(saved_fd_state))
                saved_fd_state = nil
                modified = false
                last_enabled = false
            end
            return
        end
        last_enabled = true

        local lp = globals_state.local_player
        if (not lp) or (not entity.is_alive(lp)) then return end

        local ducking = (cmd.in_duck == 1) and (entity.get_prop(lp, "m_flDuckAmount") > 0.8)
        local fd_vals = {refs.rage.other.fake_duck:get()}

        if ducking and fd_vals[1] and (not modified) then
            saved_fd_state = get_fd_state(refs.rage.other.fake_duck)
            local mode = fd_vals[2] or 0
            local new_mode = (((mode == 2) or (mode == 3)) and "On hotkey") or "Off hotkey"
            refs.rage.other.fake_duck:set(new_mode)
            modified = true
        elseif (not ducking) and modified and saved_fd_state then
            refs.rage.other.fake_duck:set(table.unpack(saved_fd_state))
            saved_fd_state = nil
            modified = false
        end
    end
end

features.auto_exploit = {}
do
    local last_enabled = false

    local function should_exploit()
        if globals_state.additional_state == "Fake lag" then return false end
        local states = ui.settings.auto_exploit_states:get() or {}
        if not table_contains(states, globals_state.state) then return false end

        local avoid = ui.settings.auto_exploit_avoid:get() or {}
        if table_contains(avoid, "Pistols") and (globals_state.weapon == "Pistols") then return false end
        if table_contains(avoid, "Desert eagle") and (globals_state.weapon == "Deagle") then return false end
        if table_contains(avoid, "Auto snipers") and (globals_state.weapon == "Auto snipers") then return false end
        if table_contains(avoid, "Desert eagle + Crouch") and (globals_state.weapon == "Deagle") and ((globals_state.state == "Crouching") or (globals_state.state == "Sneaking")) then return false end
        return true
    end

    function features.auto_exploit.run(cmd)
        if not ui.settings.auto_exploit:get() then
            if last_enabled then
                refs.rage.aimbot.double_tap[1]:override()
                hotkey_manager.restore(refs.aa.other.on_shot_anti_aim[1], "on_shot")
                hotkey_manager.restore(refs.rage.aimbot.double_tap[1], "double_tap")
                last_enabled = false
            end
            return
        end
        last_enabled = true

        if should_exploit() then
            refs.rage.aimbot.double_tap[1]:override(false)
            hotkey_manager.restore(refs.rage.aimbot.double_tap[1], "double_tap")
            hotkey_manager.force(refs.aa.other.on_shot_anti_aim[1], "on_shot")
        else
            refs.rage.aimbot.double_tap[1]:override()
            hotkey_manager.restore(refs.aa.other.on_shot_anti_aim[1], "on_shot")
            hotkey_manager.restore(refs.rage.aimbot.double_tap[1], "double_tap")
        end
    end
end

features.auto_teleport = {}

local at_saved_pos = nil
local at_dashing = false
local at_returning = false
local at_fl_state_saved = false
local at_original_fl = false

local function at_reset_state()
    at_saved_pos = nil
    at_dashing = false
    at_returning = false
    if at_fl_state_saved then
        refs.aa.fakelag.enabled:set(at_original_fl)
        at_fl_state_saved = false
        at_original_fl = false
    end
end

local function at_is_visible(me, enemy)
    local mx, my, mz = entity.get_prop(me, "m_vecOrigin")
    local vx, vy, vz = entity.get_prop(me, "m_vecViewOffset[0]")
    if not mx or not vx then return false end

    local hx, hy, hz = entity.hitbox_position(enemy, 0)
    if not hx or not hy or not hz then return false end

    local pitch, yaw = client.camera_angles()
    if yaw then
        local dx = hx - (mx + vx)
        local dy = hy - (my + vy)
        local enemy_yaw = math.deg(math.atan2(dy, dx))
        local yaw_diff = math.abs((enemy_yaw - yaw + 180) % 360 - 180)
        if yaw_diff > (ui.settings.auto_teleport_fov and ui.settings.auto_teleport_fov:get() or 60) / 2 then
            return false
        end
    end

    local frac, ent = client.trace_line(me, mx + vx, my + vy, mz + vz, hx, hy, hz)
    if not frac then return false end
    return frac > 0.95 or ent == enemy
end

local function at_check_threat(me, my_pos)
    local enemies = entity.get_players(true)
    for i = 1, #enemies do
        local enemy = enemies[i]
        if entity.is_alive(enemy) and not entity.is_dormant(enemy) then
            local ex, ey, ez = entity.get_prop(enemy, "m_vecOrigin")
            if ex and ey and ez then
                local e_pos = vector(ex, ey, ez)
                if my_pos:dist(e_pos) <= (ui.settings.auto_teleport_dist and ui.settings.auto_teleport_dist:get() or 800) and at_is_visible(me, enemy) then
                    return true
                end
            end
        end
    end
    return false
end

function features.auto_teleport.run(cmd)
    if not ui.settings.auto_teleport:get() then
        if at_fl_state_saved then at_reset_state() end
        return
    end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        at_reset_state()
        return
    end

    local cx, cy, cz = entity.get_prop(me, "m_vecOrigin")
    if not cx or not cy or not cz then return end
    local my_pos = vector(cx, cy, cz)

    if ui.hotkeys.auto_teleport:get() then
        if not at_saved_pos and not at_returning then
            at_saved_pos = my_pos
            at_dashing = true

            if not at_fl_state_saved then
                at_original_fl = refs.aa.fakelag.enabled:get()
                at_fl_state_saved = true
                refs.aa.fakelag.enabled:set(false)
            end
        end
    else
        if at_saved_pos then
            at_dashing = false
            at_returning = true
        end
    end

    if at_dashing and at_saved_pos then
        if at_check_threat(me, my_pos) then
            if client.choked_commands() < 14 then
                cmd.allow_send_packet = false
                cmd.forwardmove = 450
            else
                cmd.allow_send_packet = true
                at_dashing = false
                at_returning = true
            end
        end
    elseif at_returning and at_saved_pos then
        cmd.allow_send_packet = true
        local dist = my_pos:dist(at_saved_pos)

        if dist > 15 then
            local dx = at_saved_pos.x - my_pos.x
            local dy = at_saved_pos.y - my_pos.y
            local yaw = math.deg(math.atan2(dy, dx))

            local current_yaw = cmd.yaw or 0
            local yaw_diff = yaw - current_yaw

            cmd.forwardmove = math.cos(math.rad(yaw_diff)) * 450
            cmd.sidemove = -math.sin(math.rad(yaw_diff)) * 450
        else
            at_reset_state()
        end
    end
end

client.set_event_callback("player_death", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        at_reset_state()
    end
end)

client.set_event_callback("round_start", at_reset_state)

features.peek_bot = {}
local peek_state = { peeking = false, start_pos = nil, timer = 0 }

function features.peek_bot.run(cmd)
    if not ui.settings.peek_bot:get() then
        peek_state.peeking = false
        peek_state.start_pos = nil
        return
    end

    local lp = globals_state.local_player
    if not lp or not entity.is_alive(lp) then
        peek_state.peeking = false
        return
    end

    local target = client.current_threat and client.current_threat()
    if not target or not entity.is_alive(target) then
        peek_state.peeking = false
        return
    end

    local cx, cy, cz = entity.get_prop(lp, "m_vecOrigin")
    if not cx then return end
    local my_pos = vector(cx, cy, cz)

    if not peek_state.peeking then
        peek_state.start_pos = my_pos
        peek_state.peeking = true
        peek_state.timer = 0
    end

    peek_state.timer = peek_state.timer + 1

    -- Пикаем 0.5 секунды вперёд, потом назад
    if peek_state.timer < 32 then
        cmd.forwardmove = 450
    else
        local dx = peek_state.start_pos.x - my_pos.x
        local dy = peek_state.start_pos.y - my_pos.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 15 then
            local yaw = math.deg(math.atan2(dy, dx))
            local yaw_diff = yaw - (cmd.yaw or 0)
            cmd.forwardmove = math.cos(math.rad(yaw_diff)) * 450
            cmd.sidemove = -math.sin(math.rad(yaw_diff)) * 450
        else
            peek_state.peeking = false
        end
    end
end

features.visuals = {}

do
    local crosshair_alpha = 0
    local scope_offset_x = 0
    local base_offset_y = 0

    local progress = {
        alpha = 0,
        offset_y = 0,
        add_x = 0,
        width_progress = 0,
        progress = 0,
        max_time = 3,
        height = 2,
        base_offset = 7.99
    }

    local indicator_items = {}

    local function update_progress(time_left, is_scoped, text_width, scope_pad)
        local ratio = math.max(0, math.min(1, time_left / progress.max_time))
        local active = time_left > 0
        progress.alpha = smooth_lerp(progress.alpha, active and 255 or 0, 0.1)
        progress.offset_y = smooth_lerp(progress.offset_y, active and progress.base_offset or 0, 0.1)
        progress.width_progress = smooth_lerp(progress.width_progress, active and 1 or 0, 0.1)
        progress.progress = smooth_lerp(progress.progress, ratio, 0.1)
        if progress.alpha > 1 then
            local target_add = (is_scoped and ((text_width / 2) + scope_pad + 0.99)) or 0
            progress.add_x = smooth_lerp(progress.add_x, target_add, 0.05)
        end
    end

    local function draw_progress_bar(cx, cy, text_width, r, g, b, alpha)
        if progress.alpha < 1 then return end
        local w = text_width * progress.width_progress
        local y = (cy / 2) + base_offset_y + progress.offset_y
        local x = (((cx / 2) + progress.add_x) - (w / 2)) + 1
        local x2 = x + (w * progress.progress)
        renderer.rectangle(x, y - 1, w, progress.height + 1, 0, 0, 0, progress.alpha * 0.5 * (alpha / 255))
        for i = 0, progress.height - 1 do
            renderer.line(x, y + i, x2, y + i, r, g, b, progress.alpha * (alpha / 255))
        end
    end

    local function update_indicators(list)
        for i, data in ipairs(list) do
            if not indicator_items[i] then
                indicator_items[i] = { add_x = 0, alpha = 0, color_r = 255, color_g = 255, color_b = 255 }
            end
            local item = indicator_items[i]
            item.name = data.name
            item.value = data.value
            item.color = data.color

            item.measure = cached_measure(0, item.name) + 0.99	
            local target_alpha = (item.value and 255) or 0
            item.alpha = smooth_lerp(item.alpha, target_alpha, 0.05)
            item.color_r = smooth_lerp(item.color_r, item.color[1], 0.1)
            item.color_g = smooth_lerp(item.color_g, item.color[2], 0.1)
            item.color_b = smooth_lerp(item.color_b, item.color[3], 0.1)
        end
    end

    local function draw_indicators(cx, cy, is_scoped, scope_pad, alpha)
        local spacing = math.floor(10 + (progress.width_progress * 6) + 0.5)
        for _, item in ipairs(indicator_items) do
            if item.alpha > 1 then
                local target_add = (is_scoped and ((item.measure / 2) + scope_pad)) or 0
                item.add_x = smooth_lerp(item.add_x, target_add, 0.05)
                local x = (cx / 2) + item.add_x
                local y = (cy / 2) + base_offset_y + spacing
                local a = item.alpha * (alpha / 255)
                renderer.text(x, y, item.color_r, item.color_g, item.color_b, a, "cb", 0, item.name)
                spacing = spacing + 11
            end
        end
    end

    function features.visuals.crosshair()
        if not ui.settings.crosshair:get() then return end
        if not globals_state.is_alive then return end

        local cx, cy = client.screen_size()
        local ar, ag, ab = ui.settings.accent:get()
        local lp = globals_state.local_player
        local is_scoped = lp and (entity.get_prop(lp, "m_bIsScoped") == 1) or false

        local build_text = script_info.name:lower()
        local text_width = cached_measure(0, build_text) + 0.99

        local target_scope_offset = (is_scoped and ((text_width / 2) + 5)) or 0
        scope_offset_x = smooth_lerp(scope_offset_x, target_scope_offset, 0.05)

        local target_base_y = (ui.settings.arrow:get() and 49.99) or 20
        base_offset_y = smooth_lerp(base_offset_y, target_base_y, 0.05)

        local target_alpha = 255
        crosshair_alpha = smooth_lerp(crosshair_alpha, target_alpha, 0.15)
        if crosshair_alpha < 1 then return end

        local a = math.floor(crosshair_alpha)

                renderer.text((cx / 2) + scope_offset_x, (cy / 2) + base_offset_y, ar, ag, ab, a, "cb", 0, build_text)

                update_progress(features.aa.builder.time_left or 0, is_scoped, text_width, 5)
        draw_progress_bar(cx, cy, text_width, ar, ag, ab, a)

                local dt_on = refs.rage.aimbot.double_tap[1]:get() and refs.rage.aimbot.double_tap[1].hotkey:get()
        local hs_on = refs.aa.other.on_shot_anti_aim[1]:get() and refs.aa.other.on_shot_anti_aim[1].hotkey:get()
        local shifting = globals_state.in_fake_lag

        local exploit_name = "exploit"
        local exploit_color = {255, 255, 255}
        if dt_on and hs_on then
            exploit_name = "exploit [!!!]"
            exploit_color = {196, 127, 109}
        elseif hs_on then
            exploit_color = {230, 255, 132}
        end
        if (dt_on or hs_on) and shifting then
            exploit_name = "exploit charging"
        end

                local indicators = {
            {
                name = script_info.build:lower(),
                value = true,
                color = {ar, ag, ab}
            },
            {
                name = at_dashing and "dashing" or (at_returning and "returning") or "",
                value = at_dashing or at_returning,
                color = {255, 200, 100}
            },
            {
                name = (features.aa.builder.state or "Standing"):lower(),
                value = true,
                color = {255, 255, 255}
            },
            {
                name = exploit_name,
                value = (dt_on or hs_on),
                color = exploit_color
            },
            {
                name = "safe",
                value = refs.rage.aimbot.force_safe:get(),
                color = {255, 255, 255},
                use_gradient = false
            },
            {
                name = "body",
                value = refs.rage.aimbot.force_body:get(),
                color = {255, 255, 255},
                use_gradient = false
            }
        }

        update_indicators(indicators)
        draw_indicators(cx, cy, is_scoped, 5, a)
    end
end

function features.visuals.arrow()
    if not ui.settings.arrow:get() then return end
    if not globals_state.is_alive then return end
        local cx, cy = client.screen_size()
    cx, cy = cx / 2, cy / 2
    local yaw = globals_state.real_yaw or 0
    local rad = math.rad(yaw)
    local x = cx + math.sin(rad) * 40
    local y = cy - math.cos(rad) * 40
    renderer.triangle(x, y, x - 5, y - 10, x + 5, y - 10, 255, 255, 255, 200)
end

do
    local scope_alpha = 0
    local scope_size = 0
    local scope_overridden = false

local function scope_enable_callback()
    if not scope_overridden then
        scope_overridden = true -- Ставим флаг ДО вызова override!
        refs.visuals.scope:override(true)
    end
end

local function scope_paint_callback()
    local lp = globals_state.local_player
    if (not lp) or (not entity.is_alive(lp)) then
        return
    end

    local weapon = entity.get_player_weapon(lp)
    if weapon == nil then
        return
    end

    local zoom_level = entity.get_prop(weapon, "m_zoomLevel")
    local is_scoped = entity.get_prop(lp, "m_bIsScoped") == 1
    local resume_zoom = entity.get_prop(lp, "m_bResumeZoom") == 1
    local has_zoom = zoom_level ~= nil
    local show_scope = has_zoom and (zoom_level > 0) and is_scoped and (not resume_zoom)

    local target_alpha = show_scope and 255 or 0 -- Исправлено: 255 вместо ui.settings.scope_size:get()
    local target_size = show_scope and ui.settings.scope_size:get() or 0
    scope_alpha = smooth_lerp(scope_alpha, target_alpha, 0.22)
    scope_size = smooth_lerp(scope_size, target_size, 0.15)

    local alpha = scope_alpha
    local size = scope_size
    if alpha < 1 or size < 1 then return end

    local w, h = client.screen_size()
    local cx, cy = w / 2, h / 2
    local gap = ui.settings.scope_gap:get()
    local c1 = { ui.settings.scope_color:get() }
    local c2 = { ui.settings.scope_color_2:get() }
    local r1, g1, b1, a1 = c1[1], c1[2], c1[3], (c1[4] or 255) * (alpha / 255)
    local r2, g2, b2, a2 = c2[1], c2[2], c2[3], (c2[4] or 0) * (alpha / 255)
    local draw_size = size * (alpha / 255)
    local line_a = math.floor(alpha * ((c1[4] or 255) / 255))
    if not ui.settings.scope_exclude:get("Left") then
        renderer.line(cx - gap, cy, cx - gap - draw_size, cy, r1, g1, b1, line_a)
    end
    if not ui.settings.scope_exclude:get("Right") then
        renderer.line(cx + gap, cy, cx + gap + draw_size, cy, r1, g1, b1, line_a)
    end
    if not ui.settings.scope_exclude:get("Top") then
        renderer.line(cx, cy - gap, cx, cy - gap - draw_size, r1, g1, b1, line_a)
    end
    if not ui.settings.scope_exclude:get("Bottom") then
        renderer.line(cx, cy + gap, cx, cy + gap + draw_size, r1, g1, b1, line_a)
    end
 end

    local function on_scope_toggle(item)
        local enabled = ui.toggle:get() and item:get()
        if not enabled then
            scope_alpha = 0
            scope_size = 0
        end
        if enabled then
            client.set_event_callback("paint_ui", scope_enable_callback)
            client.set_event_callback("paint", scope_paint_callback)
        else
            client.unset_event_callback("paint_ui", scope_enable_callback)
            client.unset_event_callback("paint", scope_paint_callback)
            refs.visuals.scope:override()
            scope_overridden = false
        end
    end

    ui.settings.scope:set_callback(on_scope_toggle, true)

        ui.toggle:set_callback(function()
        on_scope_toggle(ui.settings.scope)
    end, true)

        features.visuals.scope_disable = function()
        client.unset_event_callback("paint_ui", scope_enable_callback)
        client.unset_event_callback("paint", scope_paint_callback)
        refs.visuals.scope:override()
        scope_overridden = false
    end
end

do
    local hitmarker_time = 0
    local kill_flash_time = 0
    local particles = {}
    local bullet_tracers = {}
    local kill_blood = {}
    local kill_lightnings = {}

    local function on_player_hurt(e)
        if not ui.toggle:get() or not ui.settings.hitmarker:get() then return end
        local attacker = client.userid_to_entindex(e.attacker)
        if attacker == entity.get_local_player() then
            hitmarker_time = globals.realtime()
        end
    end

    local function on_bullet_impact(e)
        if not ui.toggle:get() or not ui.settings.tracers:get() then return end
        local shooter = client.userid_to_entindex(e.userid)
        if shooter == entity.get_local_player() then
            table.insert(bullet_tracers, { x = e.x, y = e.y, z = e.z, time = globals.realtime() })
        end
    end

    local function on_player_death(e)
        if not ui.toggle:get() or not ui.settings.kill_effect:get() then return end
        local local_player = entity.get_local_player()
        if not local_player then return end

        local attacker = client.userid_to_entindex(e.attacker)
        local victim = client.userid_to_entindex(e.userid)

        if attacker == local_player and victim ~= local_player and entity.is_enemy(victim) then
            kill_flash_time = globals.realtime()
            local vx, vy, vz = entity.get_prop(victim, "m_vecOrigin")
            if vx then
                table.insert(kill_lightnings, { x = vx, y = vy, z = vz, time = globals.realtime() })
                for i = 1, 40 do
                    table.insert(kill_blood, {
                        x = vx, y = vy, z = vz + math.random(20, 60),
                        vx = math.random(-250, 250),
                        vy = math.random(-250, 250),
                        vz = math.random(100, 350),
                        time = globals.realtime()
                    })
                end
            end
        end
    end

    local function on_paint()
        if not ui.toggle:get() then return end

        local screen_w, screen_h = client.screen_size()
        if not screen_w or not screen_h then return end
        local cx, cy = math.floor(screen_w / 2), math.floor(screen_h / 2)
        local cur_time = globals.realtime()
        local frametime = globals.frametime()
        local local_player = entity.get_local_player()

        local ox, oy, oz = nil, nil, nil
        if local_player and entity.is_alive(local_player) then
            ox, oy, oz = entity.get_prop(local_player, "m_vecOrigin")
        end

        local rr = math.floor(math.sin(cur_time * 2) * 127 + 128)
        local rg = math.floor(math.sin(cur_time * 2 + 2) * 127 + 128)
        local rb = math.floor(math.sin(cur_time * 2 + 4) * 127 + 128)

        -- 1. Kill effect (lightning + blood)
        if ui.settings.kill_effect:get() then
            local flash_delta = cur_time - kill_flash_time
            if flash_delta < 0.6 then
                local alpha = math.floor(80 * (1 - (flash_delta / 0.6)))
                renderer.rectangle(0, 0, screen_w, screen_h, 255, 0, 0, alpha)
            end

            for i = #kill_lightnings, 1, -1 do
                local l = kill_lightnings[i]
                local age = cur_time - l.time
                if age > 0.8 then
                    table.remove(kill_lightnings, i)
                else
                    local alpha = math.floor(255 * (1 - (age / 0.8)))
                    local sx1, sy1 = renderer.world_to_screen(l.x, l.y, l.z)
                    local sx2, sy2 = renderer.world_to_screen(l.x, l.y, l.z + 1000)
                    if sx1 and sy1 and sx2 and sy2 then
                        renderer.line(sx1 - 1, sy1, sx2 - 1, sy2, rr, rg, rb, alpha)
                        renderer.line(sx1, sy1, sx2, sy2, 255, 255, 255, alpha)
                        renderer.line(sx1 + 1, sy1, sx2 + 1, sy2, rr, rg, rb, alpha)
                        renderer.circle(sx1, sy1, rr, rg, rb, math.floor(alpha * 0.5), 30 + (age * 100), 0, 1)
                    end
                end
            end

            for i = #kill_blood, 1, -1 do
                local p = kill_blood[i]
                local age = cur_time - p.time
                if age > 1.5 then
                    table.remove(kill_blood, i)
                else
                    p.x = p.x + (p.vx * frametime)
                    p.y = p.y + (p.vy * frametime)
                    p.z = p.z + (p.vz * frametime)
                    p.vz = p.vz - (800 * frametime)

                    local sx, sy = renderer.world_to_screen(p.x, p.y, p.z)
                    if sx and sy then
                        local alpha = math.floor(255 * (1 - (age / 1.5)))
                        renderer.circle(sx, sy, 255, 30, 30, alpha, math.random(2, 4), 0, 1)
                    end
                end
            end
        end

        -- 2. Tracers
        if ui.settings.tracers:get() then
            for i = #bullet_tracers, 1, -1 do
                local t = bullet_tracers[i]
                local delta = cur_time - t.time
                if delta > 1.5 then
                    table.remove(bullet_tracers, i)
                else
                    local sx, sy = renderer.world_to_screen(t.x, t.y, t.z)
                    if sx and sy then
                        local alpha = math.floor(255 * (1 - (delta / 1.5)))
                        renderer.line(cx, screen_h, sx, sy, rr, rg, rb, alpha)
                    end
                end
            end
        end

        -- 3. Particles aura
        if ui.settings.particles:get() and ox then
            if globals.tickcount() % 2 == 0 then
                table.insert(particles, {
                    x = ox + math.random(-35, 35), y = oy + math.random(-35, 35), z = oz + math.random(-5, 10),
                    speed = math.random(15, 40) / 10, alpha = 255, size = math.random(2, 4)
                })
            end
            local pr, pg, pb, pa = ui.settings.particles_color:get()
            for i = #particles, 1, -1 do
                local p = particles[i]
                p.z = p.z + (p.speed * frametime * 40)
                p.alpha = p.alpha - (frametime * 120)
                if p.alpha <= 0 then table.remove(particles, i) else
                    local sx, sy = renderer.world_to_screen(p.x, p.y, p.z)
                    if sx and sy then
                        renderer.circle(sx, sy, pr, pg, pb, math.min(pa, math.floor(p.alpha)), p.size, 0, 1)
                    end
                end
            end
        end

        -- 4. ESP
        if ui.settings.esp_box:get() or ui.settings.esp_snaplines:get() or ui.settings.esp_hats:get() then
            local enemies = entity.get_players(true)
            for i = 1, #enemies do
                local enemy = enemies[i]
                local x1, y1, x2, y2, alpha = entity.get_bounding_box(enemy)

                if x1 and y1 and alpha > 0 then
                    local w, h = x2 - x1, y2 - y1

                    if ui.settings.esp_box:get() then
                        renderer.line(x1, y1, x2, y1, rr, rg, rb, alpha * 255)
                        renderer.line(x2, y1, x2, y2, rr, rg, rb, alpha * 255)
                        renderer.line(x2, y2, x1, y2, rr, rg, rb, alpha * 255)
                        renderer.line(x1, y2, x1, y1, rr, rg, rb, alpha * 255)

                        local hp = entity.get_prop(enemy, "m_iHealth") or 100
                        hp = math.min(100, math.max(0, hp))
                        local hp_y = y1 + h * (1 - hp / 100)
                        renderer.rectangle(x1 - 6, y1 - 1, 4, h + 2, 0, 0, 0, alpha * 180)
                        renderer.rectangle(x1 - 5, hp_y, 2, y2 - hp_y, 255 - (hp * 2.5), hp * 2.5, 0, alpha * 255)

                        local name = entity.get_player_name(enemy) or "Unknown"
                        renderer.text(x1 + w / 2, y1 - 15, 255, 255, 255, alpha * 255, "c", 0, name)
                    end

                    if ui.settings.esp_snaplines:get() then
                        renderer.line(cx, screen_h, x1 + (w / 2), y2, rr, rg, rb, alpha * 180)
                    end

                    if ui.settings.esp_hats:get() then
                        local hr, hg, hb, ha = ui.settings.esp_hats_color:get()
                        local hat_x = x1 + (w / 2)
                        local hat_y = y1 - (w * 0.9)
                        renderer.triangle(x1, y1, x2, y1, hat_x, hat_y, hr, hg, hb, ha * alpha)
                        renderer.circle(hat_x, hat_y, 255, 255, 255, ha * alpha, math.floor(w / 6), 0, 1)
                    end
                end
            end
        end

        -- 5. Hitmarker
        if ui.settings.hitmarker:get() then
            local delta = cur_time - hitmarker_time
            if delta < 0.35 then
                local progress = delta / 0.35
                local alpha = math.floor(255 * (1 - progress))
                local scale = math.floor(5 + (progress * 10))
                local hr, hg, hb, ha = ui.settings.hitmarker_color:get()
                local final_alpha = math.floor(ha * (alpha / 255))

                renderer.line(cx - scale - 5, cy - scale - 5, cx - scale, cy - scale, hr, hg, hb, final_alpha)
                renderer.line(cx + scale, cy + scale, cx + scale + 5, cy + scale + 5, hr, hg, hb, final_alpha)
                renderer.line(cx - scale - 5, cy + scale + 5, cx - scale, cy + scale, hr, hg, hb, final_alpha)
                renderer.line(cx + scale, cy - scale, cx + scale + 5, cy - scale - 5, hr, hg, hb, final_alpha)
            end
        end

        -- 6. Custom crosshair
        local is_enabled = ui.settings.custom_crosshair:get()
        if cvar.cl_crosshairalpha then
            cvar.cl_crosshairalpha:set_int(is_enabled and 0 or 200)
        end

        if not is_enabled then return end

        -- Не рисовать в зуме
        if local_player and entity.get_prop(local_player, "m_bIsScoped") == 1 then return end

        local r, g, b, a
        if ui.settings.crosshair_rainbow:get() then
            r, g, b = rr, rg, rb
            _, _, _, a = ui.settings.crosshair_color:get()
        else
            r, g, b, a = ui.settings.crosshair_color:get()
        end

        -- Красный при наведении на врага
        local target = client.current_threat and client.current_threat()
        if target and entity.is_alive(target) then
            local tx1, ty1, tx2, ty2 = entity.get_bounding_box(target)
            if tx1 and tx2 and cx >= tx1 and cx <= tx2 and cy >= ty1 and cy <= ty2 then
                r, g, b = 255, 80, 80
            end
        end

        local size = ui.settings.crosshair_size:get()
        local angle = cur_time * ui.settings.crosshair_speed:get() * 2.5
        local cos_a, sin_a = math.cos(angle), math.sin(angle)

        local points = {
            { 0, 0, 0, -size }, { 0, 0, 0, size }, { 0, 0, -size, 0 }, { 0, 0, size, 0 },
            { 0, -size, size, -size }, { 0, size, -size, size }, { -size, 0, -size, -size }, { size, 0, size, size }
        }

        local function rot(px, py)
            return cx + math.floor(px * cos_a - py * sin_a + 0.5), cy + math.floor(px * sin_a + py * cos_a + 0.5)
        end

        for _, p in ipairs(points) do
            local x1, y1 = rot(p[1], p[2])
            local x2, y2 = rot(p[3], p[4])
            renderer.line(x1, y1, x2, y2, r, g, b, a)
        end
        renderer.rectangle(cx - 1, cy - 1, 2, 2, 255, 255, 255, 255)
    end

    local function on_unload()
        if cvar.cl_crosshairalpha then cvar.cl_crosshairalpha:set_int(200) end
    end

    client.set_event_callback("paint", function()
        local ok, err = pcall(on_paint)
        if not ok then
            client.log("[skebob.vip visuals paint error] " .. tostring(err))
        end
    end)

    client.set_event_callback("player_hurt", function(e)
        local ok, err = pcall(on_player_hurt, e)
        if not ok then
            client.log("[skebob.vip visuals player_hurt error] " .. tostring(err))
        end
    end)

    client.set_event_callback("bullet_impact", function(e)
        local ok, err = pcall(on_bullet_impact, e)
        if not ok then
            client.log("[skebob.vip visuals bullet_impact error] " .. tostring(err))
        end
    end)

    client.set_event_callback("player_death", function(e)
        local ok, err = pcall(on_player_death, e)
        if not ok then
            client.log("[skebob.vip visuals player_death error] " .. tostring(err))
        end
    end)

    client.set_event_callback("shutdown", on_unload)
end

local zoom_state = { fov = 0 }

function features.visuals.zoom_callback(view)
    if not ui.settings.zoom:get() then return end
    if not globals_state.is_alive then return end
    local target_fov = ui.settings.zoom_fov:get()
    local speed = ui.settings.zoom_speed:get()
    local is_scoped = globals_state.is_scoped
    zoom_state.fov = smooth_lerp(zoom_state.fov, is_scoped and target_fov or 0, speed / 100)
    view.fov = view.fov - zoom_state.fov
end

local watermark_alpha = 0

function features.visuals.watermark()
    local crosshair_on = ui.settings.crosshair:get()
    local force = ui.settings.force_watermark:get()
    local should_show = ui.toggle:get() and (force or not crosshair_on)
    local target_alpha = should_show and 255 or 0
    watermark_alpha = smooth_lerp(watermark_alpha, target_alpha, 0.15)
    if watermark_alpha < 1 then return end

    local a = math.floor(watermark_alpha)
    local ar, ag, ab = ui.settings.accent:get()
    local frametime = globals.frametime()
    local fps = (frametime > 0) and math.floor(1 / frametime) or 0
    local ping = math.floor(client.latency() * 1000)

    local text = string.format("%s %s %s | FPS: %d | PING: %dms",
        script_info.name, script_info.build, script_info.version, fps, ping)
    local text_w = cached_measure(0, text)

    renderer.rectangle(10, 10, text_w + 10, 25, 20, 20, 20, math.floor(220 * (a / 255)))
    renderer.rectangle(10, 10, text_w + 10, 2, ar, ag, ab, a)
    renderer.text(15, 16, 255, 255, 255, a, "", 0, text)
end

local log_entries = {}

function features.visuals.logger()
    if not ui.settings.logger:get() then return end
    if not ui.settings.logger_on_screen:get() then return end

    local now = globals.realtime()
    local x, y = 8, 400

    for i = #log_entries, 1, -1 do
        if now - log_entries[i].time > 8 then
            table.remove(log_entries, i)
        end
    end

    if #log_entries == 0 then return end

    local current_x = x
    local current_y = y

    for i = #log_entries, 1, -1 do
        local entry = log_entries[i]
        local age = now - entry.time
        local alpha = 255
        if age < 0.2 then
            alpha = (age / 0.2) * 255
        elseif age > 7.8 then
            alpha = ((8 - age) / 0.2) * 255
        end
        alpha = math.max(0, math.min(255, alpha))

        renderer.text(current_x, current_y, entry.r, entry.g, entry.b, alpha, "", 0, entry.text)
        local tw, th = cached_measure("", entry.text)
        if entry.newline then
            current_y = current_y + th + 1
            current_x = x
        else
            current_x = current_x + tw
        end
    end
end

function features.visuals.add_log(text, r, g, b)
    r = r or 255
    g = g or 255
    b = b or 255
    table.insert(log_entries, {
        text = text,
        r = r, g = g, b = b,
        time = globals.realtime(),
        newline = text:sub(-1) ~= "\0"
    })
    local lines = 0
    for i = #log_entries, 1, -1 do
        if log_entries[i].newline then lines = lines + 1 end
        if lines > 6 then
            table.remove(log_entries, 1)
        end
    end
end

features.aa = {}

local MANUAL_NONE = -1
local MANUAL_LEFT = 1
local MANUAL_RIGHT = 2
local MANUAL_FORWARD = 3
local manual_offsets = { [MANUAL_LEFT] = -90, [MANUAL_RIGHT] = 90, [MANUAL_FORWARD] = 180 }

local cheat_detector = {}
do
    local voice_struct = ffi.typeof([[struct {
        char pad_0000[8];
        int32_t client;
        int32_t audible_mask;
        uint32_t xuid_low;
        uint32_t xuid_high;
        void* voice_data;
        bool proximity;
        bool caster;
        char pad_001E[2];
        int32_t format;
        int32_t sequence_bytes;
        uint32_t section_number;
        uint32_t uncompressed_sample_offset;
        char pad_0030[4];
        uint32_t has_bits;
    }*]])

    local names = {
        gs = { long = "gamesense", color = "95B80CFF" },
        nl = { long = "neverlose", color = "037696FF" },
        nw = { long = "nixware", color = "FFFFFFFF" },
        pd = { long = "pandora", color = "D4A9FFFF" },
        pr = { long = "primordial", color = "E2B6C7FF" },
        ot = { long = "onetap", color = "f7a414FF" },
        ft = { long = "fatality", color = "f00657FF" },
        pl = { long = "plaguecheat", color = "6BFF87FF" },
        ev = { long = "ev0lve", color = "42B7FFFF" },
        r7 = { long = "rifk7", color = "FF00FFFF" },
        af = { long = "airflow", color = "8E76C0FF" },
        wh = { long = "unknown", color = "9F9F9FFF" }
    }

    local colored_names = {
        gs = { short = "\007EAEAEAFFG\00795B80CFFS", long = "\007EAEAEAFFgame\00795B80CFFsense" },
        nl = { short = "\007557FC6FFNL", long = "\007EAEAEAFFnever\007557FC6FFlose" },
        nw = { short = "\007FFFFFFFFNW", long = "\007FFFFFFFFnixware" },
        pd = { short = "\007D4A9FFFFPD", long = "\007D4A9FFFFpandora" },
        pr = { short = "\007E2B6C7FFPR", long = "\007E2B6C7FFprimordial" },
        ot = { short = "\007EAEAEAFFO\007f7a414FFT", long = "\007EAEAEAFFone\007f7a414FFtap" },
        ft = { short = "\007f00657FFFT", long = "\007F00657FFfatality" },
        pl = { short = "\0076BFF87FFPLG", long = "\0076BFF87FFplaguecheat" },
        ev = { short = "\00742B7FFFFEV0", long = "\00742B7FFFFev0\007FFFFFFFFlve" },
        r7 = { short = "\00700F600FFR\007FF00FFFF7", long = "\00700F600FFrifk\007FF00FFFF7" },
        af = { short = "\0078E76C0FFAF", long = "\0078E76C0FFairflow" },
        wh = { short = "unknown", long = "unknown" }
    }

    local users = {}
    local state = {
        nl = { sig_count = {}, found = {} },
        nw = {}, pd = {}, ot = {}, ft = {}, pl = {}, ev = {}, r7 = {}, af = {}, gs = {}
    }

    local function sig_check(arr, step)
        local seen = {}
        for i = 1, #arr do
            local v = arr[i]
            if not seen[v] then
                seen[v] = true
                for j = i + 4, #arr do
                    if (i % step) == 0 then
                        if arr[j] == v then return true end
                    else
                        if arr[j] == v then return false end
                    end
                end
            end
        end
        return false
    end

    local detectors = {
        nl = function(packet, ent)
            if packet.xuid_high == 0 then return false end
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])
            if sig == state.nl.current_signature then
                state.nl.sig_count[ent] = (state.nl.sig_count[ent] or 0) + 1
                if state.nl.sig_count[ent] > 24 then
                    state.nl.found[ent] = 1
                    return true
                else
                    state.nl.sig_count[ent] = nil
                end
            end
            local found_count = 0
            for _ in pairs(state.nl.found) do found_count = found_count + 1 end
            if found_count > 3 then return false end
            if not state.nl[ent] then state.nl[ent] = {} end
            table.insert(state.nl[ent], packet.xuid_high)
            if #state.nl[ent] > 24 then
                if sig_check(state.nl[ent], 4) and packet.xuid_high ~= 0 then
                    state.nl.current_signature = sig
                    state.nl[ent] = {}
                    return true
                end
                table.remove(state.nl[ent], 1)
            end
            return false
        end,
        nw = function(packet, ent)
            if not state.nw[ent] then state.nw[ent] = 0 end
            if state.nw[ent] > 34 then
                state.nw[ent] = nil
                return true
            elseif packet.xuid_high == 0 then
                state.nw[ent] = state.nw[ent] + 1
            else
                state.nw[ent] = 0
            end
            return false
        end,
        pd = function(packet, ent)
            if not state.pd[ent] then state.pd[ent] = 0 end
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])
            if state.pd[ent] > 24 then
                return true
            elseif sig == "695B" or sig == "1B39" then
                state.pd[ent] = state.pd[ent] + 1
            else
                state.pd[ent] = 0
            end
            return false
        end,
        ot = function(packet, ent)
            if not state.ot[ent] then state.ot[ent] = {} end
            table.insert(state.ot[ent], {
                sequence_bytes = packet.sequence_bytes,
                xuid_low = packet.xuid_low,
                section_number = packet.section_number,
                umcompressed_sample_offset = packet.uncompressed_sample_offset
            })
            if #state.ot[ent] > 16 then
                local first = state.ot[ent][1]
                for i = 2, #state.ot[ent] do
                    local cur = state.ot[ent][i]
                    if cur.xuid_low ~= first.xuid_low or cur.section_number ~= first.section_number or cur.umcompressed_sample_offset ~= first.umcompressed_sample_offset then
                        table.remove(state.ot[ent], 1)
                        return false
                    end
                end
                table.remove(state.ot[ent], 1)
                return true
            end
            return false
        end,
        ft = function(packet, ent)
            if not state.ft[ent] then state.ft[ent] = 0 end
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])
            if state.ft[ent] > 36 then
                return true
            elseif sig == "7FFA" or sig == "7FFB" then
                state.ft[ent] = state.ft[ent] + 1
            end
            return false
        end,
        pl = function(packet, ent)
            if not state.pl[ent] then state.pl[ent] = 0 end
            if state.pl[ent] > 24 then
                return true
            elseif ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 44)[0]) == "7275" then
                state.pl[ent] = state.pl[ent] + 1
            else
                state.pl[ent] = 0
            end
            return false
        end,
        ev = function(packet, ent)
            if not state.ev[ent] then state.ev[ent] = {} end
            table.insert(state.ev[ent], packet.xuid_high)
            if #state.ev[ent] > 44 then
                for i = 1, #state.ev[ent] - 4 do
                    local a = state.ev[ent][i]
                    if (state.ev[ent][i + 1] + state.ev[ent][i + 2]) == (state.ev[ent][i] * 2) and state.ev[ent][i + 4] == (a + 1) then
                        state.ev[ent] = {}
                        return true
                    end
                end
                table.remove(state.ev[ent], 1)
            end
            return false
        end,
        r7 = function(packet, ent)
            if not state.r7[ent] then state.r7[ent] = 0 end
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])
            if state.r7[ent] > 24 then
                return true
            elseif sig == "234" or sig == "134" then
                state.r7[ent] = state.r7[ent] + 1
            else
                state.r7[ent] = 0
            end
            return false
        end,
        af = function(packet, ent)
            if not state.af[ent] then state.af[ent] = 0 end
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])
            if state.af[ent] > 24 then
                return true
            elseif sig == "AFF1" then
                state.af[ent] = state.af[ent] + 1
            else
                state.af[ent] = 0
            end
            return false
        end,
        gs = function(packet, ent)
            local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])
            local bytes = string.sub(tostring(packet.sequence_bytes), 1, 4)
            if not state.gs[ent] then state.gs[ent] = { repeated = 0, packet = sig, bytes = bytes } end
            if bytes ~= state.gs[ent].bytes and sig ~= state.gs[ent].packet then
                state.gs[ent].packet = sig
                state.gs[ent].bytes = bytes
                state.gs[ent].repeated = state.gs[ent].repeated + 1
            else
                state.gs[ent].repeated = 0
            end
            if state.gs[ent].repeated >= 36 then
                state.gs[ent] = { repeated = 0, packet = sig, bytes = bytes }
                return true
            end
            return false
        end
    }

    client.set_event_callback("voice", function(e)
        local ok, err = pcall(function()
            if not e.data then return end
            local packet = ffi.cast(voice_struct, e.data)
            if packet.client < 0 or packet.client > 64 then return end
            local ent = packet.client + 1
            if not entity.is_alive(ent) then return end
            if not users[ent] then users[ent] = {} end
            local user = users[ent]

            for id, detector in pairs(detectors) do
                local current = user.cheat
                local allow = true
                if current and current ~= id then
                    if id == "nl" then
                        if current == "ev" or current == "gs" or current == "pl" or current == "pd" or current == "r7" or current == "af" or current == "ft" then allow = false end
                    elseif id == "nw" then
                        if current == "nl" then allow = false end
                    elseif id == "ev" then
                        if current == "pd" or current == "nl" or current == "ft" then allow = false end
                    elseif id == "gs" then
                        if current == "ev" or current == "ot" or current == "pl" or current == "pd" or current == "r7" or current == "ft" then allow = false end
                    elseif id == "ot" then
                        if current == "nw" or current == "ft" or current == "pd" or current == "pl" then allow = false end
                    end
                end
                if id == "ft" and (current == "nw" or current == "pd") then break end
                if allow then
                    if detector(packet, ent) then
                        user.cheat = id
                    end
                end
            end
        end)
        if not ok then
            client.log("[voice error] " .. tostring(err))
        end
    end)

    client.set_event_callback("player_connect_full", function(e)
        local ent = client.userid_to_entindex(e.userid)
        if ent == entity.get_local_player() then
            users = {}
        else
            for _, data in pairs(users) do
                data[ent] = {}
            end
        end
    end)

    function cheat_detector.get_cheat(ent)
        local id = (users[ent] and users[ent].cheat) or "wh"
        local name = names[id] or names.wh
        local colored = colored_names[id] or colored_names.wh
        return {
            cheat_id = id,
            cheat_long = name.long,
            cheat_short_colored = colored.short,
            cheat_long_colored = colored.long,
            cheat_color = name.color
        }
    end

    function cheat_detector.has_data(ent)
        return users[ent] ~= nil
    end

    function cheat_detector.clear_data(ent)
        if users[ent] == nil then return false end
        users[ent] = nil
        for _, t in pairs(state) do
            if type(t) == "table" then
                if t[ent] ~= nil then t[ent] = nil end
                if t.sig_count and t.sig_count[ent] ~= nil then t.sig_count[ent] = nil end
                if t.found and t.found[ent] ~= nil then t.found[ent] = nil end
            end
        end
        return true
    end
end

local builder = {}
builder.peek_side = "none"
builder.threat_cheat = "unknown"
builder.last_tick_before_peek = false
builder.show_last_tick = false
builder.time_left = 0
builder._last_peek_tick_time = nil
builder.state = "Searching"
builder.enemy_in_dormant = false
builder._was_peeking_after = false
builder._peek_end_tick = nil

function builder.is_peeking()
    local lp = globals_state.local_player
    if not lp or not entity.is_alive(lp) then return false end
    local target = client.current_threat and client.current_threat()
    if not target or not entity.is_alive(target) then return false end
    local my_pos = { entity.get_prop(lp, "m_vecOrigin") }
    local their_pos = { entity.get_prop(target, "m_vecOrigin") }
    if not my_pos[1] or not their_pos[1] then return false end
    local dx, dy = my_pos[1] - their_pos[1], my_pos[2] - their_pos[2]
    local dist = math.sqrt(dx*dx + dy*dy)
    return dist < 600
end

function builder.get_peek_side()
    local lp = globals_state.local_player
    if not lp or not entity.is_alive(lp) then return "none" end
    if not builder.is_peeking() then return "none" end
    local target = client.current_threat and client.current_threat()
    if not target or target == 0 or not entity.is_alive(target) then return "none" end
    if entity.is_dormant(target) then return "none" end

    local ex, ey, ez = client.eye_position()
    if not ex then return "none" end
    local yaw = entity.get_prop(lp, "m_angEyeAngles[1]") or 0
    local rad = math.rad(yaw)
    local sin_y, cos_y = math.sin(rad), math.cos(rad)

    local left_x = ex - (cos_y * 24)
    local left_y = ey + (sin_y * 24)
    local right_x = ex + (cos_y * 24)
    local right_y = ey - (sin_y * 24)

    local their_pos = { entity.get_prop(target, "m_vecOrigin") }
    local tex, tey, tez = client.eye_position(target)
    if not tex then
        tex, tey, tez = their_pos[1] or 0, their_pos[2] or 0, (their_pos[3] or 0) + 64
    end
    local center_x, center_y, center_z = ex, ey, ez
    local left_frac = client.trace_line(target, tex, tey, tez, left_x, left_y, ez)
    local right_frac = client.trace_line(target, tex, tey, tez, right_x, right_y, ez)
    local center_frac = client.trace_line(target, tex, tey, tez, center_x, center_y, center_z)

    local left_dmg = left_frac >= 0.85 and 1 or 0
    local right_dmg = right_frac >= 0.85 and 1 or 0
    local center_dmg = center_frac >= 0.85 and 1 or 0

    local J = left_dmg > 0
    local P = right_dmg > 0
    if (J or P) and ((J and P) or (center_dmg > 0)) then
        return "both"
    end
    if J and not P then return "left" end
    if P and not J then return "right" end
    return "none"
end

function builder.is_last_tick_after_peek()
    local current_tick = globals.tickcount()
    local was_peeking = builder._was_peeking_after or false
    local is_peeking = builder.get_peek_side() ~= "none"
    if was_peeking and not is_peeking then
        builder._peek_end_tick = current_tick
    end
    builder._was_peeking_after = is_peeking
    if builder._peek_end_tick and (current_tick - builder._peek_end_tick) <= 1 then
        return true
    end
    return false
end

function builder.get_freestand_direction()
    local target = client.current_threat and client.current_threat()
    if not target then return 0 end
    local ex, ey, ez = client.eye_position()
    local tx, ty, tz = entity.get_prop(target, "m_vecOrigin")
    if not ex or not tx then return 0 end
    tz = (tz or 0) + 40
    local dx, dy = tx - ex, ty - ey
    local angle = math.deg(math.atan2(dy, dx))
    angle = utils.normalize_yaw(angle + 180)
        while angle > 90 do angle = angle - 180 end
    while angle < -90 do angle = angle + 180 end
    return angle
end

function builder.detect_cheat(ent)
    local info = cheat_detector.get_cheat(ent)
    return (info and info.cheat_long) or "unknown"
end

local inverter_states = {}

local function init_inverter_state(state_name, config)
    inverter_states[state_name] = {
        current_side = 1,
        base_offset = config.base_offset or 0,
        left_offset = config.left_offset or 0,
        right_offset = config.right_offset or 0,
        left_delay_mode = config.left_delay_mode or "static",
        left_delay_value = config.left_delay_value or 1,
        left_delay_min = config.left_delay_min or 1,
        left_delay_max = config.left_delay_max or 5,
        right_delay_mode = config.right_delay_mode or "static",
        right_delay_value = config.right_delay_value or 1,
        right_delay_min = config.right_delay_min or 1,
        right_delay_max = config.right_delay_max or 5,
        randomize_amount = config.randomize_amount or 0,
        enemy_ping = config.enemy_ping or 0,
        last_switch_tick = 0,
        next_switch_delay = 1,
        is_frozen = false,
        freeze_until_tick = 0,
        freeze_chance = 0.15,
        freeze_time = 3,
        ways_pattern = {1, -1, 1, 1, -1, -1},
        ways_index = 1,
        jitter_counter = 0,
    }
end

local function calculate_delay(state, side_name)
    local mode, value, min_val, max_val
    if side_name == "left" then
        mode = state.left_delay_mode
        value = state.left_delay_value
        min_val = state.left_delay_min
        max_val = state.left_delay_max
    else
        mode = state.right_delay_mode
        value = state.right_delay_value
        min_val = state.right_delay_min
        max_val = state.right_delay_max
    end

    if mode == "static" then
        return value
    elseif mode == "random" then
        return math.random(min_val, max_val)
    elseif mode == "flick" then
        return (math.random() > 0.7) and math.random(1, 2) or math.random(min_val, max_val)
    elseif mode == "adaptive" then
        local ping_factor = math.min(state.enemy_ping / 100, 1)
        return math.floor(min_val + (max_val - min_val) * ping_factor)
    elseif mode == "ways" then
        return value
    elseif mode == "fluctuate" then
        return value + math.random(-1, 1)
    end
    return value
end

local function should_freeze(state)
    return math.random() < state.freeze_chance
end

local function inverter_get(state_name, config, cmd)
    if not inverter_states[state_name] then
        init_inverter_state(state_name, config)
    end
if config then
    local changed = false
    for k, v in pairs(config) do
        if state[k] ~= v then changed = true; break end
    end
    if changed then
        for k, v in pairs(config) do state[k] = v end
        state.current_side = 1
        state.last_switch_tick = 0
        state.is_frozen = false
        state.ways_index = 1
    end
end

    if cmd and cmd.chokedcommands ~= 0 then
        return state.current_side
    end

    local current_tick = globals.tickcount()
    local lp = entity.get_local_player()
    local tickbase = lp and entity.get_prop(lp, "m_nTickBase") or 0

        if state.left_delay_mode == "adaptive" or state.right_delay_mode == "adaptive" then
                state.jitter_counter = state.jitter_counter + 1
    end
        if state.is_frozen then
        if current_tick >= state.freeze_until_tick then
            state.is_frozen = false
        else
            return state.current_side
        end
    end

        if (current_tick - state.last_switch_tick) >= state.next_switch_delay then
        if state.left_delay_mode == "ways" or state.right_delay_mode == "ways" then
            state.current_side = state.ways_pattern[state.ways_index]
            state.ways_index = (state.ways_index % #state.ways_pattern) + 1
        else
            state.current_side = -state.current_side
        end
        state.last_switch_tick = current_tick
        local side_name = (state.current_side == -1) and "left" or "right"
        state.next_switch_delay = calculate_delay(state, side_name)
        if should_freeze(state) then
            state.is_frozen = true
            state.freeze_until_tick = current_tick + state.freeze_time
        end
    end

    return state.current_side
end

local function inverter_get_offset(state_name)
    local state = inverter_states[state_name]
    if not state then return 0 end
    local offset = state.current_side * state.base_offset
    if state.left_offset ~= 0 and state.right_offset ~= 0 then
        offset = (state.current_side == -1) and state.left_offset or state.right_offset
    end
    local rand = state.randomize_amount or 0
    if rand > 0 then
        offset = offset + math.random(-rand, rand)
    end
    return offset
end

function builder.setup(cmd)
    builder.peek_side = builder.get_peek_side()
    builder.last_tick_before_peek = builder.is_last_tick_before_peek()
    builder.show_last_tick = builder.is_last_tick_after_peek()

    local angles = {
        pitch = "Down", pitch_angle = 0,
        yaw_base = "At targets", yaw = "180", yaw_offset = 0,
        yaw_jitter = "Off", jitter_offset = 0,
        body_yaw = "Opposite", body_yaw_angle = 0,
        fs_body_yaw = true,
    }

    local lp = globals_state.local_player
    local px, py, pz = entity.get_prop(lp, "m_vecOrigin")
    local height_diff = 0
    local target = client.current_threat and client.current_threat()
    if target then
        local tx, ty, tz = entity.get_prop(target, "m_vecOrigin")
        if px and tx then
            height_diff = math.abs(pz - tz)
        end
        builder.threat_cheat = builder.detect_cheat(target)
        builder.state = string.format("Preset [%s]", builder.threat_cheat)
    else
        builder.state = "Searching"
    end

    local aa_type = ui.angles.type:get()
    local state = globals_state.state

    local function set_body_yaw(mode, angle, fs)
        angles.body_yaw = mode
        angles.body_yaw_angle = angle
        angles.fs_body_yaw = fs or false
    end

    if aa_type == "Default" then
        if target then
            if builder.threat_cheat == "neverlose" then
                if state == "Moving" then
                    if builder.last_tick_before_peek then
                        if builder.peek_side == "left" then
                            set_body_yaw("Static", 90)
                        elseif builder.peek_side == "right" then
                            set_body_yaw("Static", -90)
                        else
                            set_body_yaw("Jitter", 180, true)
                        end
                    elseif builder.show_last_tick then
                        builder.state = string.format("Dynamic [%s]", builder.threat_cheat)
                        set_body_yaw("Jitter", 180, true)
                    elseif builder.peek_side == "left" then
                        set_body_yaw("Static", -90)
                    elseif builder.peek_side == "right" then
                        set_body_yaw("Static", 90)
                    elseif builder.peek_side == "both" then
                        set_body_yaw("Jitter", 180)
                    end
                else
                    if builder.peek_side == "left" then
                        set_body_yaw("Static", -90)
                    elseif builder.peek_side == "right" then
                        set_body_yaw("Static", 90)
                    elseif builder.peek_side == "both" then
                        set_body_yaw("Jitter", 180)
                    end
                end
            elseif builder.threat_cheat == "gamesense" then
                if builder.peek_side == "left" then
                    set_body_yaw("Static", 90)
                elseif builder.peek_side == "right" then
                    set_body_yaw("Static", -90)
                elseif builder.peek_side == "both" then
                    set_body_yaw("Jitter", 180)
                end
            else
                if builder.peek_side == "left" then
                    set_body_yaw("Static", -90)
                elseif builder.peek_side == "right" then
                    set_body_yaw("Static", 90)
                elseif builder.peek_side == "both" then
                    set_body_yaw("Jitter", 180)
                end
            end
        end
    elseif aa_type == "Experimental" then
        if globals_state.additional_state == "Fake lag" or (height_diff > 120 and globals_state.hp > 93) then
            builder.state = (globals_state.additional_state == "Fake lag") and "Fake lag" or "Height advantage"
            set_body_yaw("Off", 0)
        else
            local config = {
                Standing = { left_delay_mode = "flick", left_delay_value = 3, right_delay_mode = "random", right_delay_min = 1, right_delay_max = 3, left_offset = -31, right_offset = 31 },
                Moving = {
                    neverlose = { left_delay_mode = "adaptive", left_delay_value = 1, left_delay_min = 1, left_delay_max = 14, right_delay_mode = "adaptive", right_delay_value = 1, right_delay_min = 1, right_delay_max = 14, left_offset = -31, right_offset = 33, randomize_amount = 0, enemy_ping = 0 },
                    gamesense = { left_delay_mode = "random", left_delay_value = 2, left_delay_min = 2, left_delay_max = 3, right_delay_mode = "random", right_delay_value = 4, right_delay_min = 2, right_delay_max = 3, left_offset = -29, right_offset = 37, randomize_amount = 2, enemy_ping = 0 },
                    unknown = { left_offset = -26, right_offset = 32, randomize_amount = 2 },
                },
                Walking = { left_delay_mode = "ways", left_delay_value = 2, left_delay_min = 2, left_delay_max = 3, right_delay_mode = "random", right_delay_value = 2, right_delay_min = 2, right_delay_max = 3, left_offset = -27, right_offset = 31, randomize_amount = 0 },
                Crouching = { left_offset = -21, right_offset = 34 },
                Sneaking = { left_offset = -21, right_offset = 34, randomize_amount = 9 },
                ["In air"] = {
                    neverlose = { left_delay_mode = "adaptive", left_delay_value = 1, left_delay_min = 1, left_delay_max = 3, right_delay_mode = "adaptive", right_delay_value = 1, right_delay_min = 1, right_delay_max = 3, left_offset = -5, right_offset = -2, randomize_amount = 4, enemy_ping = 0 },
                    gamesense = { left_delay_mode = "adaptive", left_delay_value = 6, left_delay_min = 1, left_delay_max = 4, right_delay_mode = "adaptive", right_delay_value = 1, right_delay_min = 1, right_delay_max = 6, left_offset = -31, right_offset = 40, randomize_amount = 1, enemy_ping = 0 },
                    unknown = { left_delay_mode = "random", left_delay_min = 1, left_delay_max = 4, right_delay_mode = "random", right_delay_min = 1, right_delay_max = 3, base_offset = 3, randomize_amount = 0 },
                },
                ["In air-crouch"] = {
                    neverlose = { left_delay_mode = "adaptive", left_delay_value = 1, left_delay_min = 1, left_delay_max = 3, right_delay_mode = "adaptive", right_delay_value = 1, right_delay_min = 1, right_delay_max = 3, left_offset = -36, right_offset = 44, randomize_amount = 8, enemy_ping = 0 },
                    gamesense = { left_delay_mode = "random", left_delay_value = 3, left_delay_min = 2, left_delay_max = 3, right_delay_mode = "random", right_delay_value = 4, right_delay_min = 2, right_delay_max = 3, left_offset = -27, right_offset = 38, randomize_amount = 3, enemy_ping = 0 },
                    unknown = { left_delay_mode = "adaptive", left_delay_value = 2, left_delay_min = 1, left_delay_max = 5, right_delay_mode = "adaptive", right_delay_value = 4, right_delay_min = 1, right_delay_max = 8, left_offset = -31, right_offset = 42, randomize_amount = 2, enemy_ping = 0 },
                },
            }

            local state_config
            if config[state] then
                if type(config[state]) == "table" and config[state].neverlose then
                    local cheat = builder.threat_cheat
                    if cheat ~= "neverlose" and cheat ~= "gamesense" then
                        cheat = "unknown"
                    end
                    state_config = config[state][cheat]
                else
                    state_config = config[state]
                end
            end

            if state_config then
                local side = inverter_get(state, state_config, cmd)
                set_body_yaw("Static", side * 90)
                angles.yaw_offset = inverter_get_offset(state)
            end
        end
    end

        if ((globals_state.weapon == "Knife") or (globals_state.weapon == "Taser")) and (state == "In air-crouch") then
        builder.state = "Safe head"
        angles.yaw_offset = 0
        angles.yaw_jitter = "Off"
        angles.jitter_offset = 0
        set_body_yaw("Off", 0)
    end

    return angles
end

function builder.push(angles)
    angles = angles or {}
    refs.aa.angles.enabled:override(true)
    refs.aa.angles.pitch[1]:override(angles.pitch or "Down")
    refs.aa.angles.pitch[2]:override(utils.clamp(angles.pitch_angle or 0, -89, 89))
    refs.aa.angles.yaw_base:override(angles.yaw_base or "At targets")
    refs.aa.angles.yaw[1]:override(angles.yaw or "180")
    refs.aa.angles.yaw[2]:override(utils.clamp(angles.yaw_offset or 0, -180, 180))
    refs.aa.angles.yaw_jitter[1]:override(angles.yaw_jitter or "Off")
    refs.aa.angles.yaw_jitter[2]:override(angles.jitter_offset or 0)
    refs.aa.angles.body_yaw[1]:override(angles.body_yaw or "Off")
    refs.aa.angles.body_yaw[2]:override(angles.body_yaw_angle or 0)
    refs.aa.angles.fs_body_yaw:override(angles.fs_body_yaw or false)
end

features.aa.builder = builder

features.aa.manual = {}
features.aa.manual.current_side = MANUAL_NONE
features.aa.manual._pressed_states = {}

function features.aa.manual.update_hotkeys()
    local sides = { left = MANUAL_LEFT, right = MANUAL_RIGHT, forward = MANUAL_FORWARD }
    for name, side_val in pairs(sides) do
        local pressed = ui.hotkeys[name]:get()
        local was_pressed = features.aa.manual._pressed_states[name] or false
        if pressed and (not was_pressed) then
            if features.aa.manual.current_side == side_val then
                features.aa.manual.current_side = MANUAL_NONE
            else
                features.aa.manual.current_side = side_val
            end
        end
        features.aa.manual._pressed_states[name] = pressed
    end
    local reset_pressed = ui.hotkeys.reset:get()
    local was_reset = features.aa.manual._pressed_states.reset or false
    if reset_pressed and (not was_reset) then
        features.aa.manual.current_side = MANUAL_NONE
    end
    features.aa.manual._pressed_states.reset = reset_pressed
end

function features.aa.manual.run(cmd, angles)
    features.aa.manual.update_hotkeys()

    local edge_yaw = ui.hotkeys.edge_yaw:get()
    local freestanding = ui.hotkeys.freestanding:get()
    local legit_aa = ui.addons.legit_aa:get() and (cmd.in_use == 1)

    refs.aa.angles.edge_yaw:override(edge_yaw)
    refs.aa.angles.freestanding[1]:override(freestanding and (features.aa.manual.current_side == MANUAL_NONE)
        and (not ui.hotkeys.disablers:get(globals_state.state)) and (not legit_aa))

    if features.aa.manual.current_side == MANUAL_NONE then
        return false
    end

    angles.yaw_base = "Local view"
    angles.yaw = "180"
    angles.yaw_offset = manual_offsets[features.aa.manual.current_side] or 0

    if ui.hotkeys.static:get() then
        angles.yaw_jitter = "Off"
        angles.jitter_offset = 0
        angles.body_yaw = "Off"
        angles.body_yaw_angle = 0
    end

    return true
end

features.aa.defensive = {}
features.aa.defensive.in_defensive = false
features.aa.defensive.ticks_left = 0

local defensive_tracker = {
    max_tickbase = (tonumber(cvar.sv_maxusrcmdprocessticks:get_string()) or 16) - 1,
    tickbase_difference = 0,
    command_number = 0,
    choked_commands = 0,
}

function features.aa.defensive.track(cmd)
    defensive_tracker.command_number = cmd.command_number or 0
    defensive_tracker.choked_commands = cmd.chokedcommands or 0
end

function features.aa.defensive.update()
    local lp = entity.get_local_player()
    local tickbase = lp and entity.get_prop(lp, "m_nTickBase") or 0
    if defensive_tracker.command_number ~= 0 then
        features.aa.defensive.ticks_left = math.max(math.min(math.abs(tickbase - defensive_tracker.tickbase_difference), defensive_tracker.max_tickbase - defensive_tracker.choked_commands), 0)
        defensive_tracker.tickbase_difference = math.max(tickbase, defensive_tracker.tickbase_difference or 0)
        defensive_tracker.command_number = 0
    end

    local dt_enabled = refs.rage.aimbot.double_tap[1]:get()
    local osaa_enabled = refs.aa.other.on_shot_anti_aim[1]:get()
    local exploit_active = dt_enabled or osaa_enabled
    if not refs.rage.other.fake_duck:get() then
        if exploit_active and (features.aa.defensive.ticks_left > 1) and (features.aa.defensive.ticks_left < defensive_tracker.max_tickbase) then
            features.aa.defensive.in_defensive = true
        else
            features.aa.defensive.in_defensive = false
        end
    else
        features.aa.defensive.in_defensive = false
    end
end

function features.aa.defensive.reset()
    features.aa.defensive.in_defensive = false
    features.aa.defensive.ticks_left = 0
    defensive_tracker.tickbase_difference = 0
    defensive_tracker.command_number = 0
    defensive_tracker.choked_commands = 0
end

local function oscillate(tick, speed, angle, max_angle, intensity)
    return math.sin(tick * speed * 0.1) * max_angle * intensity
end

local function heartbeat(tick, speed, angle, max_angle, intensity)
    local beat = math.sin(tick * speed * 0.2)
    return (beat > 0.5) and (max_angle * intensity) or (-max_angle * 0.3 * intensity)
end

local function sway(tick, speed, angle, max_angle, intensity)
    return math.sin(tick * speed * 0.15) * max_angle * intensity
end

local function jitter(tick, speed, angle, max_angle, intensity)
    return ((tick % math.floor(4 / speed)) == 0) and (max_angle * intensity) or (-max_angle * intensity)
end

local function sawtooth(tick, speed, angle, max_angle, intensity)
    local cycle = (tick * speed) % 20
    return ((cycle / 20) * 2 - 1) * max_angle * intensity
end

local function chaotic_blend(tick, speed, angle, max_angle, intensity)
    return (math.sin(tick * 0.3) + math.cos(tick * 0.7)) * 0.5 * max_angle * intensity
end

function features.aa.defensive.run(cmd, angles)
    if not ui.toggle:get() then return end
    local options = ui.angles.defensive:get() or {}
    if #options == 0 then return end
    local opt_set = {}
    for _, v in ipairs(options) do opt_set[v] = true end

    features.aa.defensive.track(cmd)
    features.aa.defensive.update()

    local fs_dir = builder.get_freestand_direction()
    local lp = globals_state.local_player
    local in_reload = false
    if lp then
        local weapon = entity.get_player_weapon(lp)
        if weapon then
            in_reload = entity.get_prop(weapon, "m_bInReload") == 1
        end
    end

        if (features.aa.manual.current_side ~= MANUAL_NONE) and (not (ui.angles.unsafe:get() and ui.angles.us_states:get("Manual angles"))) then
        return
    end

        if opt_set["Bait"] then
        if globals_state.state == "Crouching" or globals_state.state == "Sneaking" then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                angles.pitch = "Custom"
                angles.pitch_angle = math.random(-10, 10)
                angles.body_yaw = "Static"
                angles.yaw_jitter = "Off"
                angles.jitter_offset = 0
                if fs_dir < 0 then
                    angles.yaw_offset = -90
                    angles.body_yaw_angle = -90
                elseif fs_dir > 0 then
                    angles.yaw_offset = 90
                    angles.body_yaw_angle = 90
                end
                if fs_dir == 0 or fs_dir < -74 or fs_dir > 74 then
                    angles.yaw_jitter = "Center"
                    angles.jitter_offset = 180
                    angles.pitch_angle = 0
                    angles.yaw_offset = 0
                    angles.body_yaw_angle = 0
                    angles.body_yaw = "Jitter"
                end
                angles.yaw = "180"
                angles.fs_body_yaw = true
            end
        end
    end

        if opt_set["In air"] then
        if globals_state.state == "In air" and globals_state.send then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                angles.pitch = "Custom"
                angles.yaw = "180"
                angles.body_yaw = "Jitter"
                angles.body_yaw_angle = 0
                angles.fs_body_yaw = true
                angles.pitch_angle = heartbeat(globals.tickcount(), 1.2, -45, 89, 1.45)
                angles.yaw_offset = sway(globals.tickcount(), 0.85, -140, 180, 1.15)
            end
        elseif globals_state.state == "In air-crouch" and globals_state.send then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                angles.pitch = "Custom"
                angles.yaw = "180"
                angles.body_yaw = "Jitter"
                angles.body_yaw_angle = 0
                angles.fs_body_yaw = false
                if builder.threat_cheat == "neverlose" then
                    angles.pitch_angle = jitter(globals.tickcount(), 2.5, 45, 75, 1.25)
                    angles.yaw_offset = 0
                    angles.yaw_jitter = "Center"
                    angles.jitter_offset = 180
                else
                    angles.pitch_angle = chaotic_blend(globals.tickcount(), 2.5, 20, 45, 1.25)
                    angles.yaw_offset = sawtooth(globals.tickcount(), 2.3, 110, 175, 1.1)
                end
            end
        end
    end

        if opt_set["Walking"] then
        if globals_state.state == "Walking" then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                if fs_dir < 0 then
                    angles.yaw_offset = -90
                else
                    angles.yaw_offset = 90
                end
                angles.pitch = "Custom"
                angles.pitch_angle = math.random(-10, 10)
                angles.yaw = "180"
                angles.body_yaw = "Opposite"
                angles.body_yaw_angle = 0
                angles.fs_body_yaw = true
            end
        end
    end

        if ui.angles.unsafe:get() then
        if globals_state.state == "Standing" and ui.angles.us_states:get("Standing") then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                if fs_dir < 0 then
                    angles.yaw_offset = -90
                    angles.body_yaw_angle = -90
                else
                    angles.yaw_offset = 90
                    angles.body_yaw_angle = 90
                end
                angles.pitch = "Custom"
                angles.pitch_angle = math.random(-10, 10)
                angles.yaw = "180"
                angles.body_yaw = "Static"
                angles.fs_body_yaw = false
            end
        end

        if (features.aa.manual.current_side ~= MANUAL_NONE) and ui.angles.us_states:get("Manual angles") then
            cmd.force_defensive = false
            if features.aa.defensive.in_defensive then
                if features.aa.manual.current_side == MANUAL_LEFT then
                    angles.pitch = "Custom"
                    angles.pitch_angle = 0
                    angles.yaw = "180"
                    angles.yaw_offset = 90
                    angles.body_yaw = "Opposite"
                    angles.body_yaw_angle = 0
                    angles.fs_body_yaw = true
                elseif features.aa.manual.current_side == MANUAL_RIGHT then
                    angles.pitch = "Custom"
                    angles.pitch_angle = 0
                    angles.yaw = "180"
                    angles.yaw_offset = -90
                    angles.body_yaw = "Opposite"
                    angles.body_yaw_angle = 0
                    angles.fs_body_yaw = true
                end
            end
        end

        if globals_state.additional_state == "Freestanding" and ui.angles.us_states:get("Freestanding") then
            cmd.force_defensive = false
            if features.aa.defensive.in_defensive then
                if fs_dir < 0 then
                    angles.yaw_offset = -90
                else
                    angles.yaw_offset = 90
                end
                angles.pitch = "Custom"
                angles.pitch_angle = -89
                angles.yaw = "180"
                angles.body_yaw = "Opposite"
                angles.body_yaw_angle = 0
                angles.fs_body_yaw = true
            end
        end
    end

        if opt_set["Weapon events"] then
        if in_reload then
            cmd.force_defensive = true
            if features.aa.defensive.in_defensive then
                angles.pitch = "Custom"
                angles.pitch_angle = -45
                angles.yaw = "Spin"
                angles.yaw_offset = 25
                angles.body_yaw = "Jitter"
                angles.body_yaw_angle = 45
                angles.fs_body_yaw = true
            end
        end
    end

        if opt_set["Safe head"] then
        if globals_state.state == "In air-crouch" then
            if globals_state.weapon == "Knife" or globals_state.weapon == "Taser" then
                cmd.force_defensive = true
                if features.aa.defensive.in_defensive then
                    angles.pitch = "Custom"
                    angles.pitch_angle = 0
                    angles.yaw = "180"
                    angles.yaw_offset = 180
                    if builder.peek_side == "left" then
                        angles.body_yaw = "Static"
                        angles.body_yaw_angle = -90
                    elseif builder.peek_side == "right" then
                        angles.body_yaw = "Static"
                        angles.body_yaw_angle = 90
                    else
                        angles.body_yaw = "Jitter"
                        angles.body_yaw_angle = 180
                    end
                    angles.fs_body_yaw = false
                end
            end
        end
    end
end

features.aa.anti_backstab = {}
function features.aa.anti_backstab.run(cmd, angles)
    if not ui.addons.anti_backstab:get() then return end
    if not globals_state.is_alive then return end
    local enemies = entity.get_players(true)
    local lp = globals_state.local_player
    local ex, ey, ez = client.eye_position()
    local eye_pos = vector(ex, ey, ez)
    for _, ent in ipairs(enemies) do
        if entity.is_alive(ent) and entity.get_classname(entity.get_player_weapon(ent)) == "CKnife" then
            local enx, eny, enz = entity.get_prop(ent, "m_vecOrigin")
            local enemy_pos = vector(enx or 0, eny or 0, enz or 0)
            if (eye_pos - enemy_pos):length() < 389 then
                                local ehx, ehy, ehz = entity.get_prop(ent, "m_vecOrigin")
                ehz = (ehz or 0) + 64
                local frac = client.trace_line(lp, ehx, ehy, ehz, ex, ey, ez)
                if frac >= 0.9 then
                    angles.pitch = "Down"
                    angles.yaw_base = "At targets"
                    angles.yaw = "180"
                    angles.yaw_offset = 180
                    angles.yaw_jitter = "Off"
                    angles.jitter_offset = 0
                    angles.body_yaw = "Static"
                    angles.body_yaw_angle = 69
                    break
                end
            end
        end
    end
end

features.aa.legit_aa = {}
function features.aa.legit_aa.run(cmd, angles)
    if not ui.addons.legit_aa:get() then return end
    if (cmd.in_attack or 0) == 0 then return false end

    cmd.force_defensive = false
    angles.pitch = "Off"
    angles.yaw_base = "Local view"
    angles.yaw = "180"
    angles.yaw_offset = 180
    return true
end

features.aa.fast_ladder = {}
function features.aa.fast_ladder.run(cmd)
    if not ui.addons.fast_ladder:get() then return end
    if not globals_state.is_alive then return end
    local lp = globals_state.local_player
    local movetype = entity.get_prop(lp, "m_MoveType") or 0
    local weapon = entity.get_player_weapon(lp)
    local throw_time = weapon and entity.get_prop(weapon, "m_fThrowTime") or 0
    if movetype == 9 and weapon and (throw_time == nil or throw_time == 0) then
        if cmd.forwardmove > 0 then
            if cmd.pitch < 45 then
                cmd.pitch = 89
                cmd.in_moveright = 1
                cmd.in_moveleft = 0
                cmd.in_forward = 0
                cmd.in_back = 1
                -- yaw модификацию убрали — только pitch и move keys
            end
        elseif cmd.forwardmove < 0 then
            cmd.pitch = 89
            cmd.in_moveleft = 1
            cmd.in_moveright = 0
            cmd.in_forward = 1
            cmd.in_back = 0
        end
    end
end

features.aa.defensive_legs = {}
function features.aa.defensive_legs.run(cmd)
    if not ui.addons.defensive_legs:get() then return end
    if features.aa.defensive.in_defensive then
        local current = refs.aa.other.leg_movement:get()
        if current == "Never slide" or current == "Off" then
            refs.aa.other.leg_movement:override("Always slide")
        end
    else
        refs.aa.other.leg_movement:override()
    end
end

features.aa.defensive_peek = {}
function features.aa.defensive_peek.run(cmd)
    if not ui.addons.defensive_peek:get() then return end
    if not globals_state.is_alive then return end
    if refs.rage.other.fake_duck:get() then return end

    local dt_active = refs.rage.aimbot.double_tap[1]:get() and refs.rage.aimbot.double_tap[1].hotkey:get()
    if dt_active and builder.peek_side ~= "none" and builder.peek_side ~= "both" then
        cmd.force_defensive = true
        if features.aa.defensive.ticks_left > 1 and globals_state.on_ground then
            cmd.no_choke = false
            cmd.allow_send_packet = false
        end
    end
end

features.misc = {}

function features.misc.aspect_ratio()
    if not ui.settings.ratio:get() then
        cvar.r_aspectratio:set_raw_float(0)
        return
    end
    local width = ui.settings.ratio_width:get()
    cvar.r_aspectratio:set_raw_float(width / 100)
end

function features.misc.viewmodel()
    if not ui.settings.viewmodel:get() then
        cvar.viewmodel_fov:set_raw_float(68)
        cvar.viewmodel_offset_x:set_raw_float(0)
        cvar.viewmodel_offset_y:set_raw_float(0)
        cvar.viewmodel_offset_z:set_raw_float(0)
        return
    end
    cvar.viewmodel_fov:set_raw_float(ui.settings.viewmodel_fov:get())
    cvar.viewmodel_offset_x:set_raw_float(ui.settings.viewmodel_x:get())
    cvar.viewmodel_offset_y:set_raw_float(ui.settings.viewmodel_y:get())
    cvar.viewmodel_offset_z:set_raw_float(ui.settings.viewmodel_z:get())
end

features.misc.animation_breaker = {}
do
    local anim_breaker_cmd_num = 0
    local smooth_yaw = 0

    local function anim_breaker_run_command(cmd)
        anim_breaker_cmd_num = cmd.command_number
    end

    local function anim_breaker_pre_render()
        local ok, err = pcall(function()
            if not ui.settings.animation_breaker:get() then return end
            if not globals_state.is_alive then return end

            local lp = entity.get_local_player()
            if not lp then return end

            local ent_obj = gs_entity(lp)
            local anim = ent_obj:get_anim_state()
            local time_val = (globals.curtime() * 0.5) % 1

            local moving = ui.settings.anim_in_moving:get()
            local air = ui.settings.anim_in_air:get()
            local addons = ui.settings.anim_etc:get() or {}
            local on_ground = globals_state.on_ground

            if moving ~= "Off" and on_ground then
                local leg_idx = (refs.aa.other.leg_movement:get() == "Never slide") and 7 or 0
                local jitter_idx = ((globals.tickcount() % 4) > 1) and leg_idx or 1
                if moving == "Static" then
                    ent_obj:set_prop("m_flPoseParameter", 1, leg_idx)
                elseif moving == "Jitter" then
                    refs.aa.other.leg_movement:override(((anim_breaker_cmd_num % 3) == 0) and "off" or "always slide")
                    ent_obj:set_prop("m_flPoseParameter", ((globals.tickcount() % 4) > 1) and 0.5 or 1, jitter_idx)
                    if globals_state.velocity < 1 then
                        ent_obj:set_prop("m_flPoseParameter", client.random_float(0.4, 0.8), 7)
                    end
                end
            end

            if air ~= "Off" and not on_ground then
                local air_idx = ((globals.tickcount() % 4) > 1) and 7 or 6
                if air == "Static" then
                    ent_obj:set_prop("m_flPoseParameter", 1, 6)
                elseif air == "Jitter" then
                    ent_obj:set_prop("m_flPoseParameter", 1, air_idx)
                elseif air == "Walking" then
                    ent_obj:get_anim_overlay(6).weight = 1
                    ent_obj:get_anim_overlay(7).cycle = time_val
                    ent_obj:get_anim_overlay(6).cycle = time_val
                end
            end

            if table_contains(addons, "Zero pitch on land") and anim.hit_in_ground_animation and (anim.magic_fraction == 1) and on_ground then
                ent_obj:set_prop("m_flPoseParameter", 0.5, 12)
            end

            if table_contains(addons, "Disable balance adjustment") then
                ent_obj:get_anim_overlay(3).weight = 0
                ent_obj:get_anim_overlay(3).cycle = 0
                ent_obj:get_anim_overlay(3).sequence = 979
            end

            if table_contains(addons, "Smooth yaw angles") then
                smooth_yaw = smooth_lerp(smooth_yaw, ent_obj:get_prop("m_flPoseParameter", 11), 0.15)
                ent_obj:set_prop("m_flPoseParameter", smooth_yaw, 11)
            end

            if table_contains(addons, "Smooth player animation") then
                ent_obj:get_anim_overlay(12).cycle = time_val
                ent_obj:get_anim_overlay(7).cycle = time_val
                ent_obj:get_anim_overlay(6).cycle = time_val
            end
        end)
        if not ok then
            client.log("[animation_breaker error] " .. tostring(err))
        end
    end

    local anim_breaker_hooked = false
    local function animation_breaker_toggle_callback(item)
        local enabled = ui.toggle:get() and item:get()
        if enabled then
            if not anim_breaker_hooked then
                client.set_event_callback("run_command", anim_breaker_run_command)
                client.set_event_callback("pre_render", anim_breaker_pre_render)
                anim_breaker_hooked = true
            end
        else
            if anim_breaker_hooked then
                client.unset_event_callback("run_command", anim_breaker_run_command)
                client.unset_event_callback("pre_render", anim_breaker_pre_render)
                anim_breaker_hooked = false
            end
        end
    end

    ui.settings.animation_breaker:set_callback(animation_breaker_toggle_callback, true)
end

function features.misc.edge_stop(cmd)
    if not ui.settings.edge_stop:get() then return end
    local lp = globals_state.local_player
    if not lp or not entity.is_alive(lp) then return end
    if globals_state.speed < 10 then return end

    -- берём позицию ног, а не глаз
    local px, py, pz = entity.get_prop(lp, "m_vecOrigin")
    if not px then return end

    local yaw = cmd.yaw or 0
    local rad = math.rad(yaw)
    local check_dist = 32  -- дистанция проверки впереди

    -- точка впереди на уровне ног
    local fx = px + math.sin(rad) * check_dist
    local fy = py + math.cos(rad) * check_dist
    local fz = pz  -- тот же уровень

    -- трейс от ног вниз во впереди стоящей точке
    local frac, ent = client.trace_line(lp, fx, fy, fz + 10, fx, fy, fz - 80)
    local no_ground_ahead = (frac == nil) or (frac >= 1.0)

    if no_ground_ahead then
        cmd.forwardmove = 0
        cmd.sidemove = 0
        cmd.in_forward = 0
        cmd.in_back = 0
        cmd.in_moveleft = 0
        cmd.in_moveright = 0
    end
end

features.misc.console_filter = {}
do
    local filter_hooked = false
    local function console_filter_toggle(item)
        local enabled = ui.toggle:get() and item:get()
        if enabled then
            if not filter_hooked then
                client.exec("con_filter_enable 1")
                client.exec("con_filter_text_out \"Damage given to\"")
                filter_hooked = true
            end
        else
            if filter_hooked then
                client.exec("con_filter_enable 0")
                client.exec("con_filter_text_out \"\"")
                filter_hooked = false
            end
        end
    end

    ui.settings.console_filter:set_callback(console_filter_toggle, true)
end

features.misc.clan_tag = {}
features.misc.clan_tag.last_update = 0
features.misc.clan_tag.sequence = {
    "s", "sk", "ske", "skeb", "skebo", "skebob", "skebob.", "skebob.v", "skebob.vi", "skebob.vip",
    "skebob.vip", "skebob.vi", "skebob.v", "skebob.", "skebob", "skebo", "skeb", "ske", "sk", "s"
}

function features.misc.clan_tag.run()
    if not ui.settings.clan_tag:get() then
        client.set_clan_tag("")
        return
    end
    local now = globals.realtime()
    if now - features.misc.clan_tag.last_update < 0.5 then return end
    features.misc.clan_tag.last_update = now
    features.misc.clan_tag.index = (features.misc.clan_tag.index or 0) + 1
    if features.misc.clan_tag.index > #features.misc.clan_tag.sequence then
        features.misc.clan_tag.index = 1
    end
    client.set_clan_tag(features.misc.clan_tag.sequence[features.misc.clan_tag.index])
end

features.misc.trash_talk = {}
features.misc.trash_talk.lines = {
    skebob = {
        kill = {
            "owned by skebob.vip",
            "skebob.vip on top",
            "sit down noname",
            "easy round for skebob.vip",
            "your config is expired, try skebob.vip",
            "delete your game and install skebob.vip",
            "masterclass by skebob.vip",
            "zero resistance",
            "another bot cleared by skebob.vip",
            "system initialized: opponent eliminated by skebob.vip"
        },
        death = {
            "unlucky angle",
            "nice shot, enjoy it while it lasts",
            "game is lagging",
            "tickrate issues",
            "that was a lucky hit",
            "i was alt-tabbed"
        },
        miss = {
            "?",
            "nice spread",
            "so close",
            "resolver said no",
            "hitbox error",
            "p-loss strikes again",
            "visual bug"
        }
    },
    kawaii = {
kill = {
            "OwO, oopsie! Did you accidentally fall down into my arms? (๑>◡<๑)",
            "UwU, my little bullet found your forehead with so much love :3",
            "Hugs and kisses, sweetie! You tried your absolute best! >_<",
            "Yamete kudasai, you're making this victory way too adorable! (⁄ ⁄•⁄ω⁄•⁄ ⁄)",
            "Pew pew! Sending you a magical heart straight to your screen~ ★❣",
            "So-sorry, my little sugar cube! Did my aim startle your gentle heart? (◡_◡)",
            "Bop! You just received a warm headpat and a kiss from skebob.vip (｡♥‿♥｡)",
            "Senpai finally noticed your cute crosshair... and hugged you to sleep! (o^.^o)",
            "Aww, please don't cry my little angel, it's just a game~ (╥﹏╥)❣",
            "Boop! Your HP bar reached zero, but my affection for you is infinite! (ʃƪ˘ ³˘)",
            "You fought like a brave little kitten, time for a nice catnap now! (๑˃̵ᴗ˂̵)و",
            "Sending healing sparkles and warm snuggles to your poor pixel soul~ (*˘︶˘*).｡.:*♡",
            "Tee-hee! My weapon just gave your cute face a sweet little goodnight kiss! (つ✧ω✧)つ",
            "Nom nom, devoured your health points with an overdose of pure sweetness! (｡♥‿♥｡)",
            "Oopsie daisy, my lovely bullet couldn't resist hugging your sweet cheeks! (⁄˘⁄ ⁄ω⁄ ⁄˘⁄)",
            "B-baka! Why did you jump right into the path of my affection? (>_<)♥",
            "Look at you sparkling on the floor like a fallen star, so cute! (◕◡◕)",
            "Sending a big fluffy cloud of hugs to carry your soul away~ (´｡• ᵕ •｡`)",
            "Mission complete! Now let's share some virtual strawberry pocky together! ( ˘ ³˘)♥",
            "Oh noes! Did my explosive love accidentally blow up your cute outfit? (⊙_⊙;)",
            "Poof! You turned into a cloud of pink cherry blossoms, how magical! (◠‿◠)",
            "Rest well, sweet prince, while I do a happy little victory dance! \\(★ω★)/",
            "My love bullet hit target locked onto your precious little heart! ",
            "Eep! You made my trigger finger slip from how overwhelmingly cute you are! (⁄ ⁄•⁄ω⁄•⁄ ⁄)"
        },
        death = {
            "Eep! That little hit touched my sensitive heart... (っ˘̩╭╮˘̩)っ",
            "I was only letting you win because I love you, b-buka! (>_<)❣",
            "No fair, my little kitty paws slipped on the keyboard >.<",
            "Owies... Why are you so mean to my poor feelings? (｡•́︿•̀｡)",
            "Going to drink some warm cocoa with marshmallows and come back for hugs! ",
            "Your aim is as stunning as your beautiful eyes, senpai! (◡ ω ◡)",
            "You hit me right in the feels instead of the hitboxes, you big bully! (ಥ﹏ಥ)",
            "My armor of love shattered into a million tiny sparkling glitter pieces! ",
            "How can someone so cute be so devastatingly lethal with a weapon? (⸝⸝> und <⸝⸝)",
            "I accept this defeat only if you promise to cuddle me afterwards! (ʃƪ˘ ³˘)",
            "Achoo! Someone must be talking about how terribly I just lost to you~ (⁎˃ᆺ˂)",
            "My screen turned completely grey, but my love for you shines even brighter! (╥_╥)",
            "You sneaky little angel, you caught me completely off guard with that charm! (๑♡3♡๑)",
            "Buried under an avalanche of your overwhelming tactical superiority~ (×_×)★",
            "I'm telling mom that you bullied my fragile little character model! (｡•́︿•̀｡)",
            "Respawning in 3... 2... 1... to throw more hearts at you! (੭ˊ꒳ˋ)੭✧"
        },
        miss = {
            "Oopsy-daisy! My eyes got too sleepy looking at your cute profile Q_Q",
            "Ahaha, a friendly butterfly flew right into my crosshair! ( ﾟ◡ﾟ)",
            "I missed you completely on purpose so you wouldn't feel sad, honey~ (´｡• ᵕ •｡｡)",
            "W-what was that?! My pointer slipped because I was thinking of you! (>_<)",
            "Tee-hee, just a cute little warning shot for my favorite opponent! (*^.^*)",
            "My bullets are too shy to touch someone as gorgeous as you! (*/ω＼*)",
            "Whoopsie! The wind blew my shot away because it wanted to hug you instead! ",
            "I was busy drawing a tiny heart on the wall with my bullets, did you see it? (◕ω◕)",
            "Target acquired... wait, your smile distracted my entire operating system! (♡μ◡μ)",
            "Missed! But hey, that means we get to play together a little bit longer~ ( ˘ ³˘)♥",
            "My gun refused to fire because it respects your royal cuteness too much! ",
            "Oops, my trigger finger sneezed! Bless my clumsy little heart~ (≧◡≦)",
            "I am practicing my stormtrooper arts just so I can gaze at you longer! (•̀ 3 •́)",
            "Swish! Air guitar solo instead of a hit, because you rock too hard! (≧▽≦)"
        }
    }
}

function features.misc.trash_talk.on_kill()
    if not ui.settings.trash_talk:get() then return end
    local types = ui.settings.trash_talk_type:get() or {}
    if not table_contains(types, "Kill") then return end
    
    local mode = ui.settings.trash_talk_mode:get()
    local lines
    if mode == "Kawaii" then
        lines = features.misc.trash_talk.lines.kawaii.kill
    else
        lines = features.misc.trash_talk.lines.skebob.kill
    end
    
    local line = lines[math.random(1, #lines)]
    client.exec("say " .. line)
end

function features.misc.trash_talk.on_death()
    if not ui.settings.trash_talk:get() then return end
    local types = ui.settings.trash_talk_type:get() or {}
    if not table_contains(types, "Death") then return end
    
    local mode = ui.settings.trash_talk_mode:get()
    local lines
    if mode == "Kawaii" then
        lines = features.misc.trash_talk.lines.kawaii.death
    else
        lines = features.misc.trash_talk.lines.skebob.death
    end
    
    client.exec("say " .. lines[math.random(1, #lines)])
end

function features.misc.trash_talk.on_miss()
    if not ui.settings.trash_talk:get() then return end
    local types = ui.settings.trash_talk_type:get() or {}
    if not table_contains(types, "Miss") then return end
    
    local mode = ui.settings.trash_talk_mode:get()
    local lines
    if mode == "Kawaii" then
        lines = features.misc.trash_talk.lines.kawaii.miss
    else
        lines = features.misc.trash_talk.lines.skebob.miss
    end
    
    client.exec("say " .. lines[math.random(1, #lines)])
end

client.set_event_callback("setup_command", function(cmd)
    local ok, err = pcall(function()
        if not ui.toggle:get() then return end
        update_local_state(cmd)
        globals_state.tickcount = globals.tickcount()
        globals_state.choked = cmd.chokedcommands or 0
        -- Update exploit progress bar
        do
            local dt_on = refs.rage.aimbot.double_tap[1]:get() and refs.rage.aimbot.double_tap[1].hotkey:get()
            local osaa_on = refs.aa.other.on_shot_anti_aim[1]:get() and refs.aa.other.on_shot_anti_aim[1].hotkey:get()
            if dt_on or osaa_on then
                local max_limit = refs.rage.aimbot.double_tap_limit:get() or 16
                local choked = cmd.chokedcommands or 0
                features.aa.builder.time_left = math.max(0, max_limit - choked) / math.max(1, max_limit) * 3
            else
                features.aa.builder.time_left = 0
            end
        end

        features.aimbot_helper.run(cmd)
        features.jump_scout.run(cmd)
        features.ideal_tick.run(cmd)
        features.quick_peek_swap.run(cmd)
        features.unsafe_recharge.run(cmd)
        features.duck_peek_fix.run(cmd)
        features.auto_exploit.run(cmd)
        features.auto_teleport.run(cmd)
        features.peek_bot.run(cmd)

        local angles = features.aa.builder.setup(cmd)
        features.aa.manual.run(cmd, angles)
        features.aa.defensive.run(cmd, angles)
        features.aa.anti_backstab.run(cmd, angles)
        features.aa.legit_aa.run(cmd, angles)
        features.aa.fast_ladder.run(cmd)
        features.aa.defensive_legs.run(cmd)
        features.aa.defensive_peek.run(cmd)
        features.aa.builder.push(angles)
        
        features.misc.edge_stop(cmd)
    end)
    if not ok then
        client.log("[setup_command error] " .. tostring(err))
    end
end)

refs.rage.log_hit:override(false)
refs.rage.other.log_spread:override(false)

client.set_event_callback("override_view", function(view)
    local ok, err = pcall(function()
        features.visuals.zoom_callback(view)
    end)
    if not ok then
        client.log("[override_view error] " .. tostring(err))
    end
end)

client.set_event_callback("paint", function()
    local ok, err = pcall(function()
        if not ui.toggle:get() then return end
        update_local_state()

        features.visuals.crosshair()
        features.visuals.arrow()
    end)
    if not ok then
        client.log("[paint error] " .. tostring(err))
    end
end)

client.set_event_callback("paint_ui", function()
    local ok, err = pcall(function()
        if not ui.toggle:get() then return end

        features.visuals.watermark()
        features.visuals.logger()
        features.misc.clan_tag.run()
        features.misc.aspect_ratio()
        features.misc.viewmodel()
    end)
    if not ok then
        client.log("[paint_ui error] " .. tostring(err))
    end
end)

local shot_predict = { hc = 0, bt = 0, predicted_dmg = 0, predicted_hitgroup = 0 }
local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}
local function totime(ticks)
    return ticks / 64
end

client.set_event_callback("aim_fire", function(e)
    local ok, err = pcall(function()
        shot_predict.hc = math.floor(e.hit_chance)
        shot_predict.bt = globals.tickcount() - e.tick
        shot_predict.predicted_dmg = e.damage
        shot_predict.predicted_hitgroup = e.hitgroup
    end)
    if not ok then
        client.log("[aim_fire error] " .. tostring(err))
    end
end)

client.set_event_callback("aim_hit", function(e)
    local ok, err = pcall(function()

        if features.resolver and features.resolver.on_hit then
            features.resolver.on_hit(e.target)
        end

        globals_state.last_damage = e.damage

        local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
        local target_name = entity.get_player_name(e.target)
        local health = entity.get_prop(e.target, "m_iHealth") or 0
        local hc = shot_predict.hc
        local bt = shot_predict.bt

        local dmg_diff = ""
        if shot_predict.predicted_dmg > e.damage then
            dmg_diff = "-" .. tostring(shot_predict.predicted_dmg - e.damage)
        elseif shot_predict.predicted_dmg < e.damage then
            dmg_diff = "+" .. tostring(e.damage - shot_predict.predicted_dmg)
        else
            dmg_diff = "+0"
        end

        local ar, ag, ab = ui.settings.accent:get()
        client.color_log(ar, ag, ab, string.format("%s \0", script_info.name:lower()))
        if health == 0 then
            client.color_log(255, 255, 255, string.format("did -%d (%s) in %s (%d%%) to %s (%dms/%dt)",
                e.damage, dmg_diff, hitgroup, hc, target_name, math.floor(totime(bt) * 1000), bt))
        else
            client.color_log(255, 255, 255, string.format("did -%d (%s) in %s (%d%%) to %s (hp left: %d | %dms/%dt)",
                e.damage, dmg_diff, hitgroup, hc, target_name, health, math.floor(totime(bt) * 1000), bt))
        end

        features.visuals.add_log(string.format("Hit %s for %d", target_name, e.damage), 0, 255, 100)
    end)
    if not ok then
        client.log("[aim_hit error] " .. tostring(err))
    end
end)

client.set_event_callback("aim_miss", function(e)
    local ok, err = pcall(function()
        -- Резолвер feedback: пропуск bruteforce при промахе
        if features.resolver and features.resolver.on_miss then
            features.resolver.on_miss(e.target)
        end

        local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
        local target_name = entity.get_player_name(e.target)
        local hc = shot_predict.hc
        local bt = shot_predict.bt

        local reason = e.reason
        if reason == "?" then
            reason = "unknown"
        end

        client.color_log(255, 0, 50, string.format("%s \0", script_info.name:lower()))
        client.color_log(255, 255, 255, string.format("missed shot due to %s (%d%%) (target: %s | group: %s | %dms/%dt)",
            reason, hc, target_name, hitgroup, math.floor(totime(bt) * 1000), bt))

        features.visuals.add_log(string.format("Missed %s (%s)", target_name, reason), 255, 80, 80)
        features.misc.trash_talk.on_miss()
    end)
    if not ok then
        client.log("[aim_miss error] " .. tostring(err))
    end
end)

client.set_event_callback("player_death", function(e)
    local ok, err = pcall(function()
        if client.userid_to_entindex(e.attacker) == globals_state.local_player then
            features.misc.trash_talk.on_kill()
        elseif client.userid_to_entindex(e.userid) == globals_state.local_player then
            features.misc.trash_talk.on_death()
        end
    end)
    if not ok then
        client.log("[player_death error] " .. tostring(err))
    end
end)

client.set_event_callback("player_death", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        features.aa.manual.current_side = MANUAL_NONE
    end
end)

client.set_event_callback("shutdown", function()
    at_reset_state()
    cvar.r_aspectratio:set_raw_float(0)
    client.set_clan_tag("")
    if features.visuals.scope_disable then features.visuals.scope_disable() end
    refs.rage.log_hit:override()
    refs.rage.other.log_spread:override()
end)

return {
    ui = ui,
    refs = refs,
    utils = utils,
    features = features,
    hotkey_manager = hotkey_manager,
    script_info = script_info,
    globals_state = globals_state
}
