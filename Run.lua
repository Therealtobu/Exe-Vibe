-- ============================================================
--  Run.lua  |  Exvibe Music Player
--  Entry point — paste this into a LocalScript and run.
--  Pulls all modules via loadstring from your GitHub repo.
--
--  SETUP:
--    1. Push Config.lua, SoundEngine.lua, UI_Main.lua,
--       UI_NowPlaying.lua, Controls.lua to your repo.
--    2. Set BASE_URL to the raw.githubusercontent.com path.
--    3. Make sure HttpService is enabled in game settings.
-- ============================================================

local BASE_URL = "https://raw.githubusercontent.com/Therealtobu/Exe-Vibe/main/"

local MODULES = {
    "Config",
    "SoundEngine",
    "UI_Main",
    "UI_NowPlaying",
    "Controls",
    "UIEffect",
}

-- Safety: only allow loadstring in studio or via game settings
if not game:IsLoaded() then game.Loaded:Wait() end

for _, name in ipairs(MODULES) do
    local url = BASE_URL .. name .. ".lua"
    local ok, result = pcall(function()
        local src = game:HttpGet(url, true)
        assert(type(src) == "string" and #src > 10,
               "Empty or invalid response for " .. name)
        local fn, compErr = loadstring(src)
        assert(fn, "Compile error in " .. name .. ": " .. tostring(compErr))
        fn()
    end)

    if ok then
        print("[Exvibe] ✓ " .. name)
    else
        warn("[Exvibe] ✗ " .. name .. " — " .. tostring(result))
        -- Optionally stop loading on critical module failure:
        -- if name == "Config" or name == "SoundEngine" then break end
    end
end

print("[Exvibe] ✓ All modules loaded — click ♪ to open")
