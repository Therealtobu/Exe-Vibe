-- ============================================================
--  UIEffect.lua  |  Exvibe Music Player
--
--  SECTION 1 – Now Playing blur / accent-tint background
--  SECTION 2 – Song card context menu (hold gesture, 2s)
--  SECTION 3 – Repeat & Shuffle enhanced logic
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
local HOLD_TIME = 2.0   -- seconds before menu appears

-- ── Build the menu frame (single instance, repositioned per card) ──
local CM = Instance.new("Frame", UI.ScreenGui)
CM.Name             = "ContextMenu"
CM.BackgroundColor3 = C.contextBg
CM.Size             = UDim2.new(0, 200, 0, CM_FULL_H or 260)
CM.BorderSizePixel  = 0
CM.ClipsDescendants = true   -- masks CMInner slide-in
CM.Visible          = false
CM.ZIndex           = 500
Instance.new("UICorner", CM).CornerRadius = UDim.new(0, 20)  -- bolder corners
local cmStroke = Instance.new("UIStroke", CM)
cmStroke.Color = C.border; cmStroke.Thickness = 1

-- UIScale for spring-open animation (origin: AnchorPoint 0.5,0.5 set in openCM)
local CMScale = Instance.new("UIScale", CM)
CMScale.Scale = 0.85

-- Inner content container — slides from above on open
local CMInner = Instance.new("Frame", CM)
CMInner.Name                = "CMInner"
CMInner.Size                = UDim2.new(1, 0, 1, 0)
CMInner.Position            = UDim2.new(0, 0, 0, 0)
CMInner.BackgroundTransparency = 1
CMInner.BorderSizePixel     = 0
CMInner.ZIndex              = 500

-- Title (song name)
local CMTitle = Instance.new("TextLabel", CMInner)
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
local CMTopRow = Instance.new("Frame", CMInner)
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
local CMDiv = Instance.new("Frame", CMInner)
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
    local btn = Instance.new("TextButton", CMInner)
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
local lastCardOriginX, lastCardOriginY = 0, 0  -- used by closeCM to shrink back

local function openCM(song, card)
    cmSong       = song
    CMTitle.Text = song.title

    local scrW = UI.ScreenGui.AbsoluteSize.X
    local scrH = UI.ScreenGui.AbsoluteSize.Y
    local cPos = card.AbsolutePosition
    local cSz  = card.AbsoluteSize

    -- Final resting position (clamped to screen)
    local mx = cPos.X + cSz.X * 0.2
    local my = cPos.Y + cSz.Y * 0.6
    mx = math.clamp(mx, 8, scrW - 208)
    my = math.clamp(my, 8, scrH - CM_FULL_H - 8)

    -- Origin = center of the card cover (where the menu "grows from")
    local ox = math.clamp(cPos.X + cSz.X * 0.5 - 100, 8, scrW - 208)
    local oy = math.clamp(cPos.Y + cSz.Y * 0.5 - CM_FULL_H * 0.5, 8, scrH - CM_FULL_H - 8)
    lastCardOriginX = ox
    lastCardOriginY = oy

    -- Reset inner content to above-clip position
    CMInner.Position = UDim2.new(0, 0, 0, -28)

    CM.Size           = UDim2.new(0, 200, 0, CM_FULL_H)
    CM.Position       = UDim2.new(0, ox, 0, oy)  -- start at card origin
    CM.BackgroundTransparency = 0.08
    CM.Visible        = true

    -- Scale spring: 0.25 → 1.0 (Back Out for satisfying pop)
    CMScale.Scale = 0.25
    TS:Create(CMScale,
        TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1.0 }
    ):Play()

    -- Slide to final position
    TS:Create(CM,
        TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, mx, 0, my) }
    ):Play()

    -- Inner content drifts down from above (ClipsDescendants on CM masks the overshoot)
    TS:Create(CMInner,
        TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }
    ):Play()
end

local function closeCM()
    if not CM.Visible then return end

    -- Content drifts back up
    TS:Create(CMInner,
        TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { Position = UDim2.new(0, 0, 0, -20) }
    ):Play()
    -- Scale shrinks back toward card origin
    TS:Create(CMScale,
        TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
        { Scale = 0.2 }
    ):Play()
    TS:Create(CM,
        TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, lastCardOriginX, 0, lastCardOriginY),
        }
    ):Play()

    task.delay(0.24, function()
        CM.Visible = false
        CM.BackgroundTransparency = 0.08
        CMScale.Scale = 0.85
        CMInner.Position = UDim2.new(0, 0, 0, 0)
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
        hideHoldFlare()
    end
end)

-- ── Hold flare overlay (accent color bloom, clipped inside the main UI frame) ──
local HoldFlare = Instance.new("Frame", UI.MainFrame)
HoldFlare.Name                = "HoldFlare"
HoldFlare.Size                = UDim2.new(1, 0, 0.55, 0)   -- top 55% of MainFrame
HoldFlare.Position            = UDim2.new(0, 0, 0, 0)
HoldFlare.BackgroundColor3    = C.accentBlue
HoldFlare.BackgroundTransparency = 1
HoldFlare.BorderSizePixel     = 0
HoldFlare.ZIndex              = 18   -- above content (11-14) but below Sheet (20)
HoldFlare.Visible             = false
-- Gradient: opaque at top → fully transparent at bottom
local hfGrad = Instance.new("UIGradient", HoldFlare)
hfGrad.Rotation = 90
hfGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,    0.35),
    NumberSequenceKeypoint.new(0.45, 0.72),
    NumberSequenceKeypoint.new(1,    1.0),
})

local hfActiveCard = nil   -- card currently being held

local function showHoldFlare(song, card)
    hfActiveCard = card
    local color = (song and song.accentColor) or C.accentBlue
    HoldFlare.BackgroundColor3   = color
    HoldFlare.BackgroundTransparency = 1
    HoldFlare.Visible = true
    TS:Create(HoldFlare,
        TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    ):Play()
    -- Scale the card up slightly (press-to-zoom effect)
    local sc = card:FindFirstChildOfClass("UIScale")
    if not sc then sc = Instance.new("UIScale", card) ; sc.Scale = 1.0 end
    TS:Create(sc,
        TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Scale = 1.10 }
    ):Play()
end

local function hideHoldFlare()
    TS:Create(HoldFlare,
        TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
    ):Play()
    task.delay(0.24, function() HoldFlare.Visible = false end)
    -- Scale the card back down
    if hfActiveCard then
        local sc = hfActiveCard:FindFirstChildOfClass("UIScale")
        if sc then
            TS:Create(sc,
                TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Scale = 1.0 }
            ):Play()
        end
        hfActiveCard = nil
    end
end

-- ── Attach hold detection to one card ──
local function attachHold(songId, card)
    local thread  = nil
    local holding = false

    card.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        -- Block hold gesture when NowPlaying is open
        if E.State.nowPlayingOpen then return end
        holding = true
        thread  = task.delay(HOLD_TIME, function()
            if not holding then return end
            local song
            for _, s in ipairs(E.MusicDatabase) do
                if s.id == songId then song = s break end
            end
            if song then
                showHoldFlare(song, card)
                openCM(song, card)
            end
        end)
    end)

    card.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        holding = false
        if thread then task.cancel(thread); thread = nil end
        hideHoldFlare()
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


print("[Exvibe] UIEffect loaded")
