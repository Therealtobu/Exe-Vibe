-- ============================================================
--  UIEffect.lua  |  Exvibe Music Player
--
--  SECTION 1 – Now Playing blur / accent-tint background
--  SECTION 2 – Song card context menu (hold gesture)
--  SECTION 3 – Repeat & Shuffle enhanced logic
--  SECTION 4 – Database Editor panel (add / edit / delete)
--
--  Load order:  Config → SoundEngine → UI_Main →
--               UI_NowPlaying → Controls → UIEffect  ← this
-- ============================================================

local E   = _G.Exvibe
local C   = E.COLORS
local UI  = E.UI
local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")

-- ============================================================
--  SECTION 1 – FULL-SCREEN BLUR + BEAT-SYNC GLOW
-- ============================================================
local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")

local Sheet = UI.NowPlaying
Sheet.BackgroundTransparency = 1
Sheet.ClipsDescendants = true

-- Real 3D world blur (Lighting BlurEffect)
local BlurFX = Instance.new("BlurEffect", Lighting)
BlurFX.Size    = 0
BlurFX.Enabled = false

-- 1a. Deep dark base — full sheet coverage
local NPBase = Instance.new("Frame", Sheet)
NPBase.Name             = "NPBase"
NPBase.Size             = UDim2.new(1,0,1,0)
NPBase.BackgroundColor3 = Color3.fromRGB(7,7,10)
NPBase.BorderSizePixel  = 0
NPBase.ZIndex           = 20
Instance.new("UICorner", NPBase).CornerRadius = UDim.new(0,18)

-- 1b. Full-coverage diagonal gradient tint
local NPTint = Instance.new("Frame", Sheet)
NPTint.Name                  = "NPTint"
NPTint.Size                  = UDim2.new(1,0,1,0)
NPTint.BackgroundColor3      = C.accentBlue
NPTint.BackgroundTransparency = 0.48
NPTint.BorderSizePixel       = 0
NPTint.ZIndex                = 20
local npGrad = Instance.new("UIGradient", NPTint)
npGrad.Rotation     = 145
npGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,    0.0),
    NumberSequenceKeypoint.new(0.35, 0.15),
    NumberSequenceKeypoint.new(0.65, 0.55),
    NumberSequenceKeypoint.new(1,    0.85),
})
Instance.new("UICorner", NPTint).CornerRadius = UDim.new(0,18)

-- 1c. Beat-sync orbs — 3 radial circles that pulse with PlaybackLoudness
local function makeOrb(xScale, yScale, size, baseAlpha)
    local orb = Instance.new("Frame", Sheet)
    orb.AnchorPoint     = Vector2.new(0.5, 0.5)
    orb.Size            = UDim2.new(0, size, 0, size)
    orb.Position        = UDim2.new(xScale, 0, yScale, 0)
    orb.BackgroundColor3 = C.accentBlue
    orb.BackgroundTransparency = baseAlpha
    orb.BorderSizePixel = 0
    orb.ZIndex          = 20
    Instance.new("UICorner", orb).CornerRadius = UDim.new(1,0)
    -- Radial fade (center bright → edge transparent)
    local g = Instance.new("UIGradient", orb)
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.0),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1,   1.0),
    })
    return orb
end

local Orb1 = makeOrb(0.18, 0.15, 340, 0.55)   -- top-left,  large
local Orb2 = makeOrb(0.78, 0.72, 260, 0.62)   -- bot-right, medium
local Orb3 = makeOrb(0.55, 0.42, 200, 0.70)   -- center,    small

-- 1d. Subtle top shimmer sheen
local NPShimmer = Instance.new("Frame", Sheet)
NPShimmer.Size                  = UDim2.new(1,0,0.18,0)
NPShimmer.BackgroundColor3      = Color3.new(1,1,1)
NPShimmer.BackgroundTransparency = 0.93
NPShimmer.BorderSizePixel       = 0
NPShimmer.ZIndex                = 20
local shimGrad = Instance.new("UIGradient", NPShimmer)
shimGrad.Rotation = 90
shimGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.0),
    NumberSequenceKeypoint.new(1, 1.0),
})

-- Smoothed loudness value (lerped each frame to avoid jitter)
local smoothLoudness = 0

-- Beat-sync RenderStepped connection
local beatConn = nil
local function startBeatSync()
    if beatConn then beatConn:Disconnect() end
    beatConn = RunService.RenderStepped:Connect(function(dt)
        if not E.State.nowPlayingOpen then return end
        local raw  = math.clamp(E.Engine.sound.PlaybackLoudness / 650, 0, 1)
        -- Smooth lerp so the effect breathes rather than snaps
        smoothLoudness = smoothLoudness + (raw - smoothLoudness) * math.clamp(dt * 7, 0, 1)
        local p = smoothLoudness

        -- Orbs pulse opacity + scale with loudness
        local s1 = 340 + p * 80
        Orb1.Size                  = UDim2.new(0, s1, 0, s1)
        Orb1.BackgroundTransparency = math.clamp(0.52 - p * 0.22, 0.28, 0.65)

        local s2 = 260 + p * 55
        Orb2.Size                  = UDim2.new(0, s2, 0, s2)
        Orb2.BackgroundTransparency = math.clamp(0.60 - p * 0.18, 0.35, 0.72)

        local s3 = 200 + p * 40
        Orb3.Size                  = UDim2.new(0, s3, 0, s3)
        Orb3.BackgroundTransparency = math.clamp(0.68 - p * 0.15, 0.42, 0.78)

        -- Tint layer subtly brightens on beat
        NPTint.BackgroundTransparency = math.clamp(0.48 - p * 0.12, 0.30, 0.55)
    end)
end

local function stopBeatSync()
    if beatConn then beatConn:Disconnect(); beatConn = nil end
    smoothLoudness = 0
end

-- Accent colour tween (all orbs + tint)
function E.setNowPlayingAccent(color)
    local ti = TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    for _, obj in ipairs({NPTint, Orb1, Orb2, Orb3}) do
        TS:Create(obj, ti, {BackgroundColor3 = color}):Play()
    end
end

-- Wrap openNowPlaying
local _origOpenNP = E.openNowPlaying
function E.openNowPlaying(song)
    local wasOpen = E.State.nowPlayingOpen
    _origOpenNP(song)

    if not wasOpen then
        -- Fresh open: start world blur + beat sync
        BlurFX.Enabled = true
        TS:Create(BlurFX,
            TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = 22}
        ):Play()
        startBeatSync()
    end
    -- Always smoothly tween to the new song's accent color
    if not song then return end
    local ac = song.accentColor
        or E.ARTIST_COLORS[((song.id - 1) % #E.ARTIST_COLORS) + 1]
    E.setNowPlayingAccent(ac)
end

-- Wrap closeNowPlaying
local _origCloseNP = E.closeNowPlaying
function E.closeNowPlaying()
    _origCloseNP()
    stopBeatSync()
    TS:Create(BlurFX,
        TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Size = 0}
    ):Play()
    task.delay(0.38, function() BlurFX.Enabled = false end)
end

-- ============================================================
--  SECTION 2 – SONG CARD CONTEXT MENU  (hold gesture)
-- ============================================================
local HOLD_TIME = 0.45   -- seconds before menu appears

-- ── Build the menu frame (single instance, repositioned per card) ──
local CM = Instance.new("Frame", UI.ScreenGui)
CM.Name             = "ContextMenu"
CM.BackgroundColor3 = C.contextBg
CM.Size             = UDim2.new(0, 218, 0, 0)    -- height animated in
CM.BorderSizePixel  = 0
CM.ClipsDescendants = true
CM.Visible          = false
CM.ZIndex           = 500
Instance.new("UICorner", CM).CornerRadius = UDim.new(0, 13)
local cmStroke = Instance.new("UIStroke", CM)
cmStroke.Color = C.border; cmStroke.Thickness = 1

-- Title (song name)
local CMTitle = Instance.new("TextLabel", CM)
CMTitle.Size             = UDim2.new(1, -20, 0, 28)
CMTitle.Position         = UDim2.new(0, 10, 0, 8)
CMTitle.BackgroundTransparency = 1
CMTitle.Text             = "Song"
CMTitle.TextColor3       = C.text
CMTitle.Font             = Enum.Font.GothamSemibold
CMTitle.TextSize         = 13
CMTitle.TextXAlignment   = Enum.TextXAlignment.Center
CMTitle.ZIndex           = 501

-- Two-column top row: Play Next | Play Last
local CMTopRow = Instance.new("Frame", CM)
CMTopRow.Size             = UDim2.new(1, -16, 0, 34)
CMTopRow.Position         = UDim2.new(0, 8, 0, 40)
CMTopRow.BackgroundTransparency = 1
CMTopRow.ZIndex           = 501

local function makeTopBtn(label, icon, xScale, xOff)
    local b = Instance.new("TextButton", CMTopRow)
    b.Size             = UDim2.new(0.5, -4, 1, 0)
    b.Position         = UDim2.new(xScale, xOff, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(52,52,62)
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel  = 0
    b.Text             = icon .. "  " .. label
    b.TextColor3       = C.text
    b.Font             = Enum.Font.Gotham
    b.TextSize         = 11
    b.ZIndex           = 502
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseEnter:Connect(function() E.tween(b, {BackgroundTransparency = 0}, 0.1) end)
    b.MouseLeave:Connect(function() E.tween(b, {BackgroundTransparency = 0.3}, 0.1) end)
    return b
end
local CMBtnPlayNext = makeTopBtn("Play Next", "⏭", 0,   0)
local CMBtnPlayLast = makeTopBtn("Play Last", "⬇", 0.5, 4)

-- Thin divider
local CMDiv = Instance.new("Frame", CM)
CMDiv.Size             = UDim2.new(1, -16, 0, 1)
CMDiv.Position         = UDim2.new(0, 8, 0, 80)
CMDiv.BackgroundColor3 = C.border
CMDiv.BorderSizePixel  = 0
CMDiv.ZIndex           = 501

-- List rows
local CM_ROWS = {
    { icon = "▶",   label = "Play"            },
    { icon = "+",   label = "Add To Library"  },
    { icon = "≡",   label = "Add To Playlist" },
    { icon = "☆",   label = "Favorite"        },
    { icon = "👎",  label = "Dislike"         },
    { icon = "⤴",   label = "Share Song"      },
}
local cmBtns = {}
for i, row in ipairs(CM_ROWS) do
    local btn = Instance.new("TextButton", CM)
    btn.Name             = "CMRow" .. i
    btn.Size             = UDim2.new(1, -16, 0, 36)
    btn.Position         = UDim2.new(0, 8, 0, 86 + (i-1) * 38)
    btn.BackgroundTransparency = 1
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.ZIndex           = 501
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local ico = Instance.new("TextLabel", btn)
    ico.Size             = UDim2.new(0, 28, 1, 0)
    ico.Position         = UDim2.new(0, 6, 0, 0)
    ico.BackgroundTransparency = 1
    ico.Text             = row.icon
    ico.TextColor3       = C.subText
    ico.Font             = Enum.Font.GothamBold
    ico.TextSize         = 14
    ico.ZIndex           = 502

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size             = UDim2.new(1, -38, 1, 0)
    lbl.Position         = UDim2.new(0, 36, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = row.label
    lbl.TextColor3       = C.text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 502

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.83 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1   end)

    cmBtns[i] = btn
end

-- Full open height:  8+28+4+34+4+1+4 + 6*38 + 8  =  319
local CM_FULL_H = 91 + #CM_ROWS * 38 + 8

-- ── Show / hide helpers ──
local cmSong = nil

local function openCM(song, card)
    cmSong        = song
    CMTitle.Text  = song.title

    local scrW  = UI.ScreenGui.AbsoluteSize.X
    local scrH  = UI.ScreenGui.AbsoluteSize.Y
    local cPos  = card.AbsolutePosition
    local cSz   = card.AbsoluteSize

    local mx = cPos.X + cSz.X * 0.2
    local my = cPos.Y + cSz.Y * 0.6

    mx = math.clamp(mx, 8, scrW - 226)
    my = math.clamp(my, 8, scrH - CM_FULL_H - 8)

    CM.Position = UDim2.new(0, mx, 0, my)
    CM.Size     = UDim2.new(0, 218, 0, 0)
    CM.Visible  = true
    E.tween(CM, { Size = UDim2.new(0, 218, 0, CM_FULL_H) }, 0.22,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function closeCM()
    if not CM.Visible then return end
    E.tween(CM, { Size = UDim2.new(0, 218, 0, 0) }, 0.15, Enum.EasingStyle.Quart)
    task.delay(0.17, function()
        CM.Visible = false
        cmSong = nil
    end)
end

-- ── Context menu button actions ──
CMBtnPlayNext.MouseButton1Click:Connect(function()
    if cmSong then E.playSong(cmSong) end
    closeCM()
end)

CMBtnPlayLast.MouseButton1Click:Connect(function()
    if cmSong then
        -- Append to end of queue list (Controls auto-advance reads E.State.queue if extended)
        table.insert(E.State.queue, cmSong)
    end
    closeCM()
end)

-- [1] Play
cmBtns[1].MouseButton1Click:Connect(function()
    if cmSong then E.playSong(cmSong) end
    closeCM()
end)

-- [2] Add To Library
cmBtns[2].MouseButton1Click:Connect(function()
    if cmSong then
        local dup = false
        for _, s in ipairs(E.State.library) do
            if s.id == cmSong.id then dup = true break end
        end
        if not dup then
            table.insert(E.State.library, cmSong)
            if E.rebuildLibrary then E.rebuildLibrary() end
        end
    end
    closeCM()
end)

-- [3] Add To Playlist  (placeholder – extend to playlist picker)
cmBtns[3].MouseButton1Click:Connect(function() closeCM() end)

-- [4] Favorite  (toggle)
cmBtns[4].MouseButton1Click:Connect(function()
    if cmSong then
        local found = false
        for i, s in ipairs(E.State.favorites) do
            if s.id == cmSong.id then
                table.remove(E.State.favorites, i)
                found = true; break
            end
        end
        if not found then table.insert(E.State.favorites, cmSong) end
    end
    closeCM()
end)

-- [5] Dislike
cmBtns[5].MouseButton1Click:Connect(function() closeCM() end)

-- [6] Share Song
cmBtns[6].MouseButton1Click:Connect(function() closeCM() end)

-- Dismiss on click outside the menu
UIS.InputBegan:Connect(function(inp)
    if not CM.Visible then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end

    local p  = inp.Position
    local cp = CM.AbsolutePosition
    local cs = CM.AbsoluteSize
    if p.X < cp.X or p.X > cp.X + cs.X
    or p.Y < cp.Y or p.Y > cp.Y + cs.Y then
        closeCM()
    end
end)

-- ── Attach hold detection to one card ──
local function attachHold(songId, card)
    local thread  = nil
    local holding = false

    card.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        holding = true
        thread  = task.delay(HOLD_TIME, function()
            if not holding then return end
            local song
            for _, s in ipairs(E.MusicDatabase) do
                if s.id == songId then song = s break end
            end
            if song then openCM(song, card) end
        end)
    end)

    card.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        holding = false
        if thread then task.cancel(thread); thread = nil end
    end)
end

-- ── Exposed connector called by E.rebuildSongs (UI_Main) ──
function E.connectSongCard(songId, card)
    -- play on click
    card.MouseButton1Click:Connect(function()
        local song
        for _, s in ipairs(E.MusicDatabase) do
            if s.id == songId then song = s break end
        end
        if song then
            E.playSong(song)
            E.openNowPlaying(song)
        end
    end)
    -- hold → context menu
    attachHold(songId, card)
end

-- Wire existing cards (Controls.lua already handled click; we add hold only)
for songId, card in pairs(UI.songCardMap) do
    attachHold(songId, card)
end

-- ============================================================
--  SECTION 3 – REPEAT & SHUFFLE  (enhanced)
--  Toggle = opacity only (not blue) — matches UI_NowPlaying pills
-- ============================================================
E.State.repeatMode  = false
E.State.shuffleMode = false

local TOGGLE_TRANS_OFF = 0.82
local TOGGLE_TRANS_ON  = 0.28

local function refreshRepeatUI()
    if UI.repPill then
        UI.repPill.BackgroundTransparency = E.State.repeatMode and TOGGLE_TRANS_ON or TOGGLE_TRANS_OFF
    end
end
local function refreshShuffleUI()
    if UI.shuPill then
        UI.shuPill.BackgroundTransparency = E.State.shuffleMode and TOGGLE_TRANS_ON or TOGGLE_TRANS_OFF
    end
end

UI.NPRepeatBtn.MouseButton1Click:Connect(function()
    E.State.repeatMode = not E.State.repeatMode
    refreshRepeatUI()
end)
UI.NPShuffleBtn.MouseButton1Click:Connect(function()
    E.State.shuffleMode = not E.State.shuffleMode
    refreshShuffleUI()
end)

-- Provide a getNextSong() that Controls.lua's auto-advance can call
function E.getNextSong()
    local db = E.MusicDatabase
    if #db == 0 then return nil end
    if not E.State.currentSong then return db[1] end

    if E.State.repeatMode then
        return E.State.currentSong
    end

    if E.State.shuffleMode and #db > 1 then
        local idx
        repeat idx = math.random(1, #db)
        until db[idx].id ~= E.State.currentSong.id
        return db[idx]
    end

    -- Default: sequential with wrap
    for i, s in ipairs(db) do
        if s.id == E.State.currentSong.id then
            return db[i + 1] or db[1]
        end
    end
    return db[1]
end

refreshRepeatUI()
refreshShuffleUI()

-- ============================================================
--  SECTION 4 – DATABASE EDITOR  PANEL
-- ============================================================
local DB_W, DB_H = 580, 470

local DBPanel = Instance.new("Frame", UI.ScreenGui)
DBPanel.Name             = "DBEditor"
DBPanel.Size             = UDim2.new(0, DB_W, 0, DB_H)
DBPanel.Position         = UDim2.new(0.5, -DB_W/2, 0.5, -DB_H/2)
DBPanel.BackgroundColor3 = C.bg
DBPanel.BorderSizePixel  = 0
DBPanel.ClipsDescendants = true
DBPanel.Visible          = false
DBPanel.ZIndex           = 400
Instance.new("UICorner", DBPanel).CornerRadius = UDim.new(0, 16)
local dbBorder = Instance.new("UIStroke", DBPanel)
dbBorder.Color = C.border; dbBorder.Thickness = 1.2

-- ── Header bar ──
local DBHeader = Instance.new("Frame", DBPanel)
DBHeader.Size             = UDim2.new(1, 0, 0, 50)
DBHeader.BackgroundColor3 = C.sidebar
DBHeader.BorderSizePixel  = 0
DBHeader.ZIndex           = 401
Instance.new("UICorner", DBHeader).CornerRadius = UDim.new(0, 16)
-- Square off bottom corners of header
local hFix = Instance.new("Frame", DBHeader)
hFix.Size             = UDim2.new(1, 0, 0, 16)
hFix.Position         = UDim2.new(0, 0, 1, -16)
hFix.BackgroundColor3 = C.sidebar
hFix.BorderSizePixel  = 0
hFix.ZIndex           = 401

local DBTitleLbl = Instance.new("TextLabel", DBHeader)
DBTitleLbl.Size             = UDim2.new(1, -100, 1, 0)
DBTitleLbl.Position         = UDim2.new(0, 16, 0, 0)
DBTitleLbl.BackgroundTransparency = 1
DBTitleLbl.Text             = "🎵  Music Database Editor"
DBTitleLbl.TextColor3       = C.text
DBTitleLbl.Font             = Enum.Font.GothamBold
DBTitleLbl.TextSize         = 14
DBTitleLbl.TextXAlignment   = Enum.TextXAlignment.Left
DBTitleLbl.ZIndex           = 402

local DBCloseBtn = Instance.new("TextButton", DBHeader)
DBCloseBtn.Size             = UDim2.new(0, 30, 0, 30)
DBCloseBtn.Position         = UDim2.new(1, -40, 0.5, -15)
DBCloseBtn.BackgroundColor3 = C.card
DBCloseBtn.Text             = "✕"
DBCloseBtn.TextColor3       = C.subText
DBCloseBtn.Font             = Enum.Font.GothamBold
DBCloseBtn.TextSize         = 12
DBCloseBtn.BorderSizePixel  = 0
DBCloseBtn.ZIndex           = 402
Instance.new("UICorner", DBCloseBtn).CornerRadius = UDim.new(1, 0)

-- ── Left panel: song list ──
local DBLeft = Instance.new("Frame", DBPanel)
DBLeft.Size             = UDim2.new(0, 200, 1, -50)
DBLeft.Position         = UDim2.new(0, 0, 0, 50)
DBLeft.BackgroundColor3 = C.sidebar
DBLeft.BorderSizePixel  = 0
DBLeft.ZIndex           = 401

local DBNewBtn = Instance.new("TextButton", DBLeft)
DBNewBtn.Size             = UDim2.new(1, -16, 0, 32)
DBNewBtn.Position         = UDim2.new(0, 8, 0, 8)
DBNewBtn.BackgroundColor3 = C.accentBlue
DBNewBtn.Text             = "+  New Song"
DBNewBtn.TextColor3       = Color3.new(1, 1, 1)
DBNewBtn.Font             = Enum.Font.GothamSemibold
DBNewBtn.TextSize         = 13
DBNewBtn.BorderSizePixel  = 0
DBNewBtn.ZIndex           = 402
Instance.new("UICorner", DBNewBtn).CornerRadius = UDim.new(0, 8)

local DBListSF = Instance.new("ScrollingFrame", DBLeft)
DBListSF.Size             = UDim2.new(1, 0, 1, -50)
DBListSF.Position         = UDim2.new(0, 0, 0, 50)
DBListSF.BackgroundTransparency = 1
DBListSF.BorderSizePixel  = 0
DBListSF.ScrollBarThickness = 2
DBListSF.ScrollBarImageColor3 = C.border
DBListSF.CanvasSize       = UDim2.new(0, 0, 0, 0)
pcall(function() DBListSF.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
DBListSF.ZIndex           = 402
Instance.new("UIListLayout", DBListSF).Padding = UDim.new(0, 1)

-- ── Right panel: form ──
local DBRight = Instance.new("ScrollingFrame", DBPanel)
DBRight.Size             = UDim2.new(1, -200, 1, -50)
DBRight.Position         = UDim2.new(0, 200, 0, 50)
DBRight.BackgroundTransparency = 1
DBRight.BorderSizePixel  = 0
DBRight.ScrollBarThickness = 2
DBRight.ScrollBarImageColor3 = C.border
DBRight.CanvasSize       = UDim2.new(0, 0, 0, 0)
pcall(function() DBRight.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
DBRight.ZIndex           = 401
local rfLayout = Instance.new("UIListLayout", DBRight)
rfLayout.Padding   = UDim.new(0, 6)
rfLayout.SortOrder = Enum.SortOrder.LayoutOrder
local rfPad = Instance.new("UIPadding", DBRight)
rfPad.PaddingLeft   = UDim.new(0, 14)
rfPad.PaddingRight  = UDim.new(0, 14)
rfPad.PaddingTop    = UDim.new(0, 10)
rfPad.PaddingBottom = UDim.new(0, 12)

-- ── Form field definitions ──
local FIELDS = {
    { key = "title",       label = "Title",               hint = "Song title" },
    { key = "artist",      label = "Artist",              hint = "Artist name" },
    { key = "album",       label = "Album",               hint = "Album name" },
    { key = "assetId",     label = "Sound Asset ID",      hint = "e.g.  1837849285" },
    { key = "cover",       label = "Cover Asset ID",      hint = "rbxassetid://000000000" },
    { key = "duration",    label = "Duration (seconds)",  hint = "e.g.  214" },
    { key = "genre",       label = "Genre",               hint = "Indie · Jazz · R&B …" },
    { key = "accentColor", label = "Accent Color  R,G,B", hint = "e.g.  80,140,255" },
}
local dbInputs = {}

for i, f in ipairs(FIELDS) do
    local row = Instance.new("Frame", DBRight)
    row.Size             = UDim2.new(1, 0, 0, 54)
    row.LayoutOrder      = i
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0
    row.ZIndex           = 402

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text             = f.label
    lbl.TextColor3       = C.subText
    lbl.Font             = Enum.Font.GothamSemibold
    lbl.TextSize         = 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 403

    local box = Instance.new("TextBox", row)
    box.Size             = UDim2.new(1, 0, 0, 33)
    box.Position         = UDim2.new(0, 0, 0, 17)
    box.BackgroundColor3 = C.card
    box.BorderSizePixel  = 0
    box.PlaceholderText  = f.hint
    box.PlaceholderColor3 = C.subText
    box.Text             = ""
    box.TextColor3       = C.text
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 12
    box.ClearTextOnFocus  = false
    box.ZIndex           = 403
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
    local bp = Instance.new("UIPadding", box)
    bp.PaddingLeft  = UDim.new(0, 10)
    bp.PaddingRight = UDim.new(0, 10)

    dbInputs[f.key] = box
end

-- ── Save / Delete buttons ──
local dbBtnRow = Instance.new("Frame", DBRight)
dbBtnRow.Size             = UDim2.new(1, 0, 0, 36)
dbBtnRow.LayoutOrder      = 99
dbBtnRow.BackgroundTransparency = 1
dbBtnRow.BorderSizePixel  = 0
dbBtnRow.ZIndex           = 402

local DBSaveBtn = Instance.new("TextButton", dbBtnRow)
DBSaveBtn.Size             = UDim2.new(0.5, -4, 1, 0)
DBSaveBtn.BackgroundColor3 = C.accentBlue
DBSaveBtn.Text             = "💾  Save"
DBSaveBtn.TextColor3       = Color3.new(1, 1, 1)
DBSaveBtn.Font             = Enum.Font.GothamSemibold
DBSaveBtn.TextSize         = 13
DBSaveBtn.BorderSizePixel  = 0
DBSaveBtn.ZIndex           = 403
Instance.new("UICorner", DBSaveBtn).CornerRadius = UDim.new(0, 8)

local DBDelBtn = Instance.new("TextButton", dbBtnRow)
DBDelBtn.Size             = UDim2.new(0.5, -4, 1, 0)
DBDelBtn.Position         = UDim2.new(0.5, 4, 0, 0)
DBDelBtn.BackgroundColor3 = C.red
DBDelBtn.Text             = "🗑  Delete"
DBDelBtn.TextColor3       = Color3.new(1, 1, 1)
DBDelBtn.Font             = Enum.Font.GothamSemibold
DBDelBtn.TextSize         = 13
DBDelBtn.BorderSizePixel  = 0
DBDelBtn.Visible          = false
DBDelBtn.ZIndex           = 403
Instance.new("UICorner", DBDelBtn).CornerRadius = UDim.new(0, 8)

local DBStatusLbl = Instance.new("TextLabel", DBRight)
DBStatusLbl.Size             = UDim2.new(1, 0, 0, 20)
DBStatusLbl.LayoutOrder      = 100
DBStatusLbl.BackgroundTransparency = 1
DBStatusLbl.Text             = ""
DBStatusLbl.TextColor3       = C.accentBlue
DBStatusLbl.Font             = Enum.Font.Gotham
DBStatusLbl.TextSize         = 12
DBStatusLbl.ZIndex           = 402

-- ── Editor helpers ──
local dbEditId = nil   -- nil = new song; number = id being edited

local function dbClear()
    for _, box in pairs(dbInputs) do box.Text = "" end
    dbEditId          = nil
    DBDelBtn.Visible  = false
    DBStatusLbl.Text  = ""
end

local function dbLoad(song)
    dbEditId               = song.id
    dbInputs.title.Text    = song.title or ""
    dbInputs.artist.Text   = song.artist or ""
    dbInputs.album.Text    = song.album or ""
    dbInputs.assetId.Text  = tostring(song.assetId or "")
    dbInputs.cover.Text    = song.cover or ""
    dbInputs.duration.Text = tostring(song.duration or "")
    dbInputs.genre.Text    = song.genre or ""
    if song.accentColor then
        local ac = song.accentColor
        dbInputs.accentColor.Text =
            math.floor(ac.R*255) .. "," ..
            math.floor(ac.G*255) .. "," ..
            math.floor(ac.B*255)
    else
        dbInputs.accentColor.Text = ""
    end
    DBDelBtn.Visible      = true
    DBStatusLbl.Text      = "Editing: " .. song.title
    DBStatusLbl.TextColor3 = C.subText
end

local function parseRGB(str)
    local r, g, b = str:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    if r then return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) end
    return nil
end

-- Rebuild left-panel song list
local function dbRebuildList()
    for _, ch in ipairs(DBListSF:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
    for _, song in ipairs(E.MusicDatabase) do
        local item = Instance.new("TextButton", DBListSF)
        item.Size             = UDim2.new(1, 0, 0, 44)
        item.BackgroundColor3 = C.sidebar
        item.BorderSizePixel  = 0
        item.Text             = ""
        item.ZIndex           = 403

        local t = Instance.new("TextLabel", item)
        t.Size             = UDim2.new(1, -12, 0, 16)
        t.Position         = UDim2.new(0, 10, 0, 6)
        t.BackgroundTransparency = 1
        t.Text             = song.title
        t.TextColor3       = C.text
        t.Font             = Enum.Font.GothamSemibold
        t.TextSize         = 12
        t.TextXAlignment   = Enum.TextXAlignment.Left
        t.TextTruncate     = Enum.TextTruncate.AtEnd
        t.ZIndex           = 404

        local a = Instance.new("TextLabel", item)
        a.Size             = UDim2.new(1, -12, 0, 12)
        a.Position         = UDim2.new(0, 10, 0, 24)
        a.BackgroundTransparency = 1
        a.Text             = song.artist
        a.TextColor3       = C.subText
        a.Font             = Enum.Font.Gotham
        a.TextSize         = 10
        a.TextXAlignment   = Enum.TextXAlignment.Left
        a.ZIndex           = 404

        item.MouseEnter:Connect(function() E.tween(item, {BackgroundColor3 = C.card},    0.1) end)
        item.MouseLeave:Connect(function() E.tween(item, {BackgroundColor3 = C.sidebar}, 0.1) end)
        local cap = song
        item.MouseButton1Click:Connect(function() dbLoad(cap) end)
    end
end

-- ── Save ──
DBSaveBtn.MouseButton1Click:Connect(function()
    local title  = dbInputs.title.Text
    local artist = dbInputs.artist.Text
    if title == "" or artist == "" then
        DBStatusLbl.Text       = "⚠  Title and Artist are required."
        DBStatusLbl.TextColor3 = C.red
        return
    end

    local assetId  = tonumber(dbInputs.assetId.Text)  or 0
    local duration = tonumber(dbInputs.duration.Text) or 0
    local cover    = dbInputs.cover.Text
    local acColor  = parseRGB(dbInputs.accentColor.Text)

    if dbEditId then
        -- Update existing entry
        for _, s in ipairs(E.MusicDatabase) do
            if s.id == dbEditId then
                s.title       = title
                s.artist      = artist
                s.album       = dbInputs.album.Text
                s.assetId     = assetId
                s.cover       = cover ~= "" and cover or s.cover
                s.duration    = duration
                s.genre       = dbInputs.genre.Text
                s.accentColor = acColor
                break
            end
        end
        DBStatusLbl.Text       = "✓  Song updated!"
        DBStatusLbl.TextColor3 = C.accentBlue
    else
        -- Insert new entry with auto-incrementing id
        local newId = 1
        for _, s in ipairs(E.MusicDatabase) do
            if s.id >= newId then newId = s.id + 1 end
        end
        table.insert(E.MusicDatabase, {
            id          = newId,
            title       = title,
            artist      = artist,
            album       = dbInputs.album.Text,
            assetId     = assetId,
            cover       = cover ~= "" and cover or "rbxassetid://6023426923",
            duration    = duration,
            genre       = dbInputs.genre.Text,
            accentColor = acColor,
        })
        DBStatusLbl.Text       = "✓  Song added!"
        DBStatusLbl.TextColor3 = C.accentBlue
        dbClear()
    end

    dbRebuildList()
    if E.rebuildSongs then E.rebuildSongs() end
end)

-- ── Delete ──
DBDelBtn.MouseButton1Click:Connect(function()
    if not dbEditId then return end
    for i, s in ipairs(E.MusicDatabase) do
        if s.id == dbEditId then
            table.remove(E.MusicDatabase, i)
            break
        end
    end
    DBStatusLbl.Text       = "Song deleted."
    DBStatusLbl.TextColor3 = C.red
    dbClear()
    dbRebuildList()
    if E.rebuildSongs then E.rebuildSongs() end
end)

DBNewBtn.MouseButton1Click:Connect(function()
    dbClear()
    DBStatusLbl.Text       = "Fill in the form to add a new song."
    DBStatusLbl.TextColor3 = C.subText
end)

DBCloseBtn.MouseButton1Click:Connect(function()
    E.tween(DBPanel, { BackgroundTransparency = 1 }, 0.15)
    task.delay(0.17, function()
        DBPanel.Visible              = false
        DBPanel.BackgroundTransparency = 0
    end)
end)

-- ── Drag the DB editor panel ──
local dbDragging, dbDragStart, dbPanelStart = false, nil, nil
DBHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dbDragging   = true
        dbDragStart  = inp.Position
        dbPanelStart = DBPanel.Position
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dbDragging = false
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dbDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dbDragStart
        DBPanel.Position = UDim2.new(
            dbPanelStart.X.Scale, dbPanelStart.X.Offset + d.X,
            dbPanelStart.Y.Scale, dbPanelStart.Y.Offset + d.Y
        )
    end
end)

-- ── Open button  (gear icon in TopBar) ──
-- Shift the existing CloseBtn (X) slightly left to make room
UI.CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)

local DBGearBtn = Instance.new("TextButton", UI.TopBar)
DBGearBtn.Name             = "DBGearBtn"
DBGearBtn.Size             = UDim2.new(0, 32, 0, 32)
DBGearBtn.Position         = UDim2.new(1, -82, 0.5, -16)
DBGearBtn.BackgroundColor3 = C.card
DBGearBtn.Text             = "⚙"
DBGearBtn.TextColor3       = C.subText
DBGearBtn.Font             = Enum.Font.GothamBold
DBGearBtn.TextSize         = 15
DBGearBtn.BorderSizePixel  = 0
DBGearBtn.ZIndex           = 13
Instance.new("UICorner", DBGearBtn).CornerRadius = UDim.new(1, 0)

DBGearBtn.MouseButton1Click:Connect(function()
    dbRebuildList()
    dbClear()
    DBPanel.Visible = true
end)
DBGearBtn.MouseEnter:Connect(function()
    E.tween(DBGearBtn, {BackgroundColor3 = C.cardHover}, 0.1)
end)
DBGearBtn.MouseLeave:Connect(function()
    E.tween(DBGearBtn, {BackgroundColor3 = C.card}, 0.1)
end)

-- Initial list build
dbRebuildList()

print("[Exvibe] UIEffect loaded")
