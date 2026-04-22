-- ============================================================
--  Config.lua  |  Exvibe Music Player
--  Shared namespace, colors, database, state, utilities
-- ============================================================

_G.Exvibe = _G.Exvibe or {}
local E = _G.Exvibe

-- ============================================================
--  COLOR PALETTE
-- ============================================================
E.COLORS = {
    bg          = Color3.fromRGB(13,  13,  15),
    sidebar     = Color3.fromRGB(20,  20,  23),
    card        = Color3.fromRGB(30,  30,  35),
    cardHover   = Color3.fromRGB(44,  44,  52),
    accent      = Color3.fromRGB(255, 255, 255),
    accentBlue  = Color3.fromRGB(80,  140, 255),
    text        = Color3.fromRGB(242, 242, 247),
    subText     = Color3.fromRGB(148, 148, 163),
    playerBg    = Color3.fromRGB(22,  22,  26),
    nowPlayBg   = Color3.fromRGB(36,  36,  42),
    contextBg   = Color3.fromRGB(34,  34,  40),
    border      = Color3.fromRGB(52,  52,  62),
    pill        = Color3.fromRGB(60,  60,  72),
    red         = Color3.fromRGB(255, 70,  70),
}

-- ============================================================
--  MUSIC DATABASE  –  thêm / sửa nhạc tại đây
-- ============================================================
E.MusicDatabase = {
    {
        id       = 1,
        title    = "North Star",
        artist   = "Noah Moore",
        album    = "Celestial",
        assetId  = 1837849285,
        cover    = "rbxassetid://6023426923",
        duration = 214,
        genre    = "Indie",
        accentColor = Color3.fromRGB(72, 130, 240),
    },
    {
        id       = 2,
        title    = "Groovy",
        artist   = "DRFlynt",
        album    = "Seventeen Grams",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 187,
        genre    = "Jazz",
        accentColor = Color3.fromRGB(220, 160, 60),
    },
    {
        id       = 3,
        title    = "Shadow",
        artist   = "ZEKE ROWAN",
        album    = "Shadow EP",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 203,
        genre    = "R&B",
        accentColor = Color3.fromRGB(55, 140, 85),
    },
    {
        id       = 4,
        title    = "WANTED ME",
        artist   = "lukrrex",
        album    = "rot",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 195,
        genre    = "Hip-Hop",
        accentColor = Color3.fromRGB(180, 80, 60),
    },
    {
        id       = 5,
        title    = "VANGUARD",
        artist   = "rush",
        album    = "VANGUARD",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 221,
        genre    = "Electronic",
        accentColor = Color3.fromRGB(30, 180, 200),
    },
    {
        id       = 6,
        title    = "GAMOPHOBIA",
        artist   = "ZEKE ROWAN",
        album    = "Discography",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 178,
        genre    = "Alternative",
        accentColor = Color3.fromRGB(130, 70, 200),
    },
    {
        id       = 7,
        title    = "Bong toi",
        artist   = "ZEKE ROWAN",
        album    = "Shadow EP",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 203,
        genre    = "R&B",
        accentColor = Color3.fromRGB(40, 160, 140),
    },
    {
        id       = 8,
        title    = "hush",
        artist   = "Alex R.",
        album    = "hush",
        assetId  = 1843463229,
        cover    = "rbxassetid://6023426923",
        duration = 196,
        genre    = "Lo-Fi",
        accentColor = Color3.fromRGB(90, 100, 180),
    },
}

-- ============================================================
--  PLAYER STATE
-- ============================================================
E.State = {
    currentSong    = nil,
    isPlaying      = false,
    isPaused       = false,
    volume         = 0.8,
    currentPage    = "Discovery",
    sidebarOpen    = true,
    nowPlayingOpen = false,
    queue          = {},
    library        = {},
    favorites      = {},
    repeatMode     = false,
    shuffleMode    = false,
}

-- ============================================================
--  UTILITIES
-- ============================================================
local TweenService = game:GetService("TweenService")

function E.formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

function E.tween(obj, props, duration, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(
            duration or 0.25,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out
        ),
        props
    )
    t:Play()
    return t
end

-- Artist avatar colors (cycles through)
E.ARTIST_COLORS = {
    Color3.fromRGB(228, 108, 10),
    Color3.fromRGB(90,  60,  210),
    Color3.fromRGB(185, 45,  145),
    Color3.fromRGB(35,  160, 75),
    Color3.fromRGB(200, 55,  55),
    Color3.fromRGB(20,  140, 180),
}

print("[Exvibe] Config loaded")
