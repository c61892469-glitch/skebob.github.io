local http = require("gamesense/http")
local base64 = require("gamesense/base64")
local json = require("json")

if not http or not base64 or not json then 
    print("[skebob.vip] Error: Required modules (http, base64, json) not found!")
    return 
end

local ui_label = ui.new_label("LUA", "A", "=== SKEBOB.VIP CLOUD ===")
local ui_email = ui.new_textbox("LUA", "A", "Email / Username")
local ui_pass = ui.new_textbox("LUA", "A", "Password")

local is_loaded = false

local function generate_stable_hwid()
    local local_player = entity.get_local_player()
    if not local_player then return nil end

    local steamid64 = tostring(entity.get_steam64(local_player))
    if not steamid64 or steamid64 == "nil" or steamid64 == "0" then 
        print("[skebob.vip] Error: Invalid SteamID64.")
        return nil 
    end

    local raw_hwid_string = string.format("SKEBOB_VIP_SECURE_SALT_%s_V1", steamid64)
    return raw_hwid_string
end

local function download_and_run_script(id_token, username)
    local script_url = "https://skebob-vip-4aa40-default-rtdb.firebaseio.com/script.json?auth=" .. id_token

    http.get(script_url, function(s_success, s_response)
        if not s_success or s_response.status ~= 200 then
            print("[skebob.vip] Error downloading main script! Server response: " .. tostring(s_response.status))
            return
        end

        local code_raw = s_response.body
        if not code_raw or code_raw == "null" then
            print("[skebob.vip] Empty or unauthorized response from database!")
            return
        end

        local code_clean = code_raw:gsub("^%s*[\"']", ""):gsub("[\"']%s*$", ""):gsub("%s+", "")
        local decoded_code = base64.decode(code_clean)
        
        if not decoded_code then
            print("[skebob.vip] Base64 decoding failed!")
            return
        end

        local load_func = loadstring or load
        local loaded_func, err = load_func(decoded_code)
        
        if not loaded_func then
            print("[skebob.vip] Script compilation error: " .. tostring(err))
            return
        end

        -- Передаем ник в твой основной скрипт
        _G._USER_NAME = username or "active user"
        _G.skebob_user = {
            username = username or "Authorized User",
            token = id_token
        }

        is_loaded = true
        print("[skebob.vip] Script successfully loaded! Welcome, " .. _G._USER_NAME)
        
        local success, runtime_err = pcall(loaded_func)
        if not success then
            print("[skebob.vip] Runtime error in loaded script: ", runtime_err)
        end
    end)
end

local function start_loader()
    if is_loaded then
        print("[skebob.vip] Script is already loaded!")
        return
    end

    local player_hwid = generate_stable_hwid()
    if not player_hwid then
        print("[skebob.vip] Error: Join a server before logging into your account!")
        return
    end

    local email = ui.get(ui_email)
    local password = ui.get(ui_pass)

    if email == "" or password == "" then
        print("[skebob.vip] Error: Please enter your email and password!")
        return
    end

    print("[skebob.vip] Connecting to servers...")

    local auth_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyCIuo4ppSQoskPiMkqLrDqSah2ph4ZJl10"
    local auth_body = string.format('{"email":"%s","password":"%s","returnSecureToken":true}', email, password)

    http.post(auth_url, {
        headers = { ["Content-Type"] = "application/json" },
        body = auth_body
    }, function(success, response)
        if not success or response.status ~= 200 then
            print("[skebob.vip] Login failed: Invalid email or password!")
            return
        end

        local parsed_auth = json.parse(response.body)
        local uid = parsed_auth and parsed_auth.localId
        local id_token = parsed_auth and parsed_auth.idToken

        if not uid or not id_token then
            print("[skebob.vip] Error parsing authentication data.")
            return
        end

        print("[skebob.vip] Authorization successful! Verifying profile & HWID...")

        local firestore_url = string.format("https://firestore.googleapis.com/v1/projects/skebob-vip-4aa40/databases/(default)/documents/users/%s", uid)

        http.get(firestore_url, function(f_success, f_response)
            if not f_success then
                print("[skebob.vip] Error connecting to database!")
                return
            end

            local parsed_db = json.parse(f_response.body)
            local db_hwid = nil
            local db_username = nil
            
            if parsed_db and parsed_db.fields then
                if parsed_db.fields.hwid then
                    db_hwid = parsed_db.fields.hwid.stringValue
                end
                if parsed_db.fields.username then
                    db_username = parsed_db.fields.username.stringValue
                end
            end

            if not db_username or db_username == "" then
                db_username = email:match("([^@]+)") or "User"
            end

            if db_hwid == nil or db_hwid == "" then
                print("[skebob.vip] First-time PC binding in progress...")
                
                local patch_url = firestore_url .. "?updateMask.fieldPaths=hwid"
                local patch_body = string.format('{"fields": {"hwid": {"stringValue": "%s"}}}', player_hwid)

                http.request("PATCH", patch_url, {
                    headers = { ["Content-Type"] = "application/json" },
                    body = patch_body
                }, function(p_success)
                    if p_success then
                        print("[skebob.vip] PC successfully bound! Downloading script...")
                        download_and_run_script(id_token, db_username)
                    else
                        print("[skebob.vip] Error binding HWID to database.")
                    end
                end)

            elseif db_hwid == player_hwid then
                print("[skebob.vip] HWID verification passed! Downloading script...")
                download_and_run_script(id_token, db_username)
            else
                print("[skebob.vip] Security Error: HWID mismatch (Unauthorized PC)!")
            end
        end)
    end)
end

ui.new_button("LUA", "A", "Login & Load", start_loader)
