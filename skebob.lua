local http = require("gamesense/http")
local base64 = require("gamesense/base64")

if not http then 
    print("[skebob.vip] Error: gamesense/http module not found!")
    return 
end

if not base64 then
    print("[skebob.vip] Error: gamesense/base64 module not found!")
    return
end

local ui_label = ui.new_label("LUA", "A", "=== CLOUD LOADER ===")
local ui_email = ui.new_textbox("LUA", "A", "Email / Username")
local ui_pass = ui.new_textbox("LUA", "A", "Password")

local is_loaded = false

local function start_loader()
    if is_loaded then
        print("[skebob.vip] Script is already loaded!")
        return
    end

    local local_player = entity.get_local_player()
    if not local_player then
        print("[skebob.vip] Error: Join a server before logging into your account!")
        return
    end

    local player_hwid = tostring(entity.get_steam64(local_player))
    if not player_hwid or player_hwid == "nil" or player_hwid == "0" then
        print("[skebob.vip] Error: Failed to retrieve SteamID. Please try again.")
        return
    end

    local email = ui.get(ui_email)
    local password = ui.get(ui_pass)

    if email == "" or password == "" then
        print("[skebob.vip] Error: Please enter your email and password!")
        return
    end

    print("[skebob.vip] Connecting to skebob.vip servers...")

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

        local uid = response.body:match('"localId"%s*:%s*"([^"]+)"')
        if not uid then
            print("[skebob.vip] Error parsing authentication data.")
            return
        end

        print("[skebob.vip] Authorization successful! Verifying HWID...")

        local firestore_url = string.format("https://firestore.googleapis.com/v1/projects/skebob-vip-4aa40/databases/(default)/documents/users/%s", uid)

        http.get(firestore_url, function(f_success, f_response)
            if not f_success then
                print("[skebob.vip] Error checking database!")
                return
            end

            local db_hwid = f_response.body:match('"hwid"%s*:%s*{%s*"stringValue"%s*:%s*"([^"]*)"')

            if db_hwid == nil or db_hwid == "" then
                print("[skebob.vip] First-time PC binding in progress...")
                
                local patch_url = string.format("https://firestore.googleapis.com/v1/projects/skebob-vip-4aa40/databases/(default)/documents/users/%s?updateMask.fieldPaths=hwid", uid)
                local patch_body = string.format('{"fields": {"hwid": {"stringValue": "%s"}}}', player_hwid)

                http.request("PATCH", patch_url, {
                    headers = { ["Content-Type"] = "application/json" },
                    body = patch_body
                }, function(p_success)
                    if p_success then
                        print("[skebob.vip] PC successfully bound! Downloading script...")
                        download_and_run_script()
                    else
                        print("[skebob.vip] Error binding HWID to database.")
                    end
                end)

            elseif db_hwid == player_hwid then
                print("[skebob.vip] HWID verification passed! Downloading script...")
                download_and_run_script()
            else
                print("[skebob.vip] Security Error: HWID mismatch (Unauthorized PC)!")
            end
        end)
    end)
end

function download_and_run_script()
    local script_url = "https://skebob-vip-4aa40-default-rtdb.firebaseio.com/script.json"

    http.get(script_url, function(s_success, s_response)
        if not s_success or s_response.status ~= 200 then
            print("[skebob.vip] Error downloading main script from cloud!")
            return
        end

        local code_raw = s_response.body
        if not code_raw then
            print("[skebob.vip] Empty response from database!")
            return
        end

        local code_clean = code_raw:gsub("^%s*[\"']", ""):gsub("[\"']%s*$", ""):gsub("%s+", "")

        local decoded_code = base64.decode(code_clean)
        if not decoded_code then
            print("[skebob.vip] Base64 decoding failed!")
            return
        end

        local loaded_func, err = load(decoded_code)
        if not loaded_func then
            print("[skebob.vip] Script compilation error: " .. tostring(err))
            return
        end

        is_loaded = true
        print("[skebob.vip] Script successfully loaded into memory!")
        
        pcall(loaded_func)
    end)
end

ui.new_button("LUA", "A", "Login & Load", start_loader)