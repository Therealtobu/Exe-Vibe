-- ============================================================
--  Controls.lua  |  Exvibe Music Player  (v8.2)
--  Changes:
--  - setNPPlayState() manages ImageLabel/text for play/pause btn
--  - playSong: when NP already open, openNowPlaying handles
--    content update without re-sliding (fixes stutter)
--  - animateCoverFly: no extra wait needed since sheet is stable
-- ============================================================

local E   = _G.Exvibe
local C   = E.COLORS
local UI  = E.UI
local Eng = E.Engine

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
--  PLAY/PAUSE BUTTON STATE HELPER
--  Manages the image icon (pause asset) vs text "▶" fallback
-- ============================================================
local function setNPPlayState(playing)
    if UI.NPBtnPlayImg then
        UI.NPBtnPlayImg.Visible = playing
    end
    UI.NPBtnPlay.Text = playing and "" or "▶"
end

-- ============================================================
--  COVER FLY-TO ANIMATION
--  Since openNowPlaying no longer re-slides when sheet is open,
--  NPArt.AbsolutePosition is always stable → no stutter.
-- ============================================================
function E.animateCoverFly(fromAbsPos, fromAbsSize, song, npAlreadyOpen)
    task.spawn(function()
        -- Wait for sheet to finish sliding in if it was just opened
        if not npAlreadyOpen then
            task.wait(0.32)
        end

        local npArt = UI.NPArt
        if not npArt then return end

        local toPos = npArt.AbsolutePosition
        local toSz  = npArt.AbsoluteSize
        if toSz.X < 10 or toSz.Y < 10 then return end

        local clone = Instance.new("ImageLabel", UI.ScreenGui)
        clone.Image            = song.cover or ""
        clone.Position         = UDim2.new(0, fromAbsPos.X, 0, fromAbsPos.Y)
        clone.Size             = UDim2.new(0, fromAbsSize.X, 0, fromAbsSize.Y)
        clone.BackgroundColor3 = C.card
        clone.BorderSizePixel  = 0
        clone.ZIndex           = 200
        clone.ScaleType        = Enum.ScaleType.Crop
        Instance.new("UICorner", clone).CornerRadius = UDim.new(0, 8)

        local t = E.tween(clone, {
            Position = UDim2.new(0, toPos.X, 0, toPos.Y),
            Size     = UDim2.new(0, toSz.X,  0, toSz.Y)
        }, 0.46, Enum.EasingStyle.Quint)

        t.Completed:Connect(function() clone:Destroy() end)
    end)
end

-- ============================================================
--  PLAY SONG
-- ============================================================
local function playSong(song)
    Eng:play(song)
    E.updatePlayerBar(song)
    UI.BtnPlay.Text = "▌▌"
    setNPPlayState(true)

    -- openNowPlaying now handles both "already open" (update only)
    -- and "fresh open" (slide in) cases
    if E.State.nowPlayingOpen then
        E.openNowPlaying(song)
    end
end
E.playSong = playSong

-- ============================================================
--  NEXT / PREV
-- ============================================================
local function nextSong()
    if not E.State.currentSong then return end
    local db = E.MusicDatabase
    if E.State.shuffleOn then
        local idx = math.random(1, #db)
        playSong(db[idx]) ; return
    end
    for i, s in ipairs(db) do
        if s.id == E.State.currentSong.id then
            playSong(db[i+1] or db[1]) ; return
        end
    end
end

local function prevSong()
    if not E.State.currentSong then return end
    if Eng:getPosition() > 3 then Eng:seekTo(0) return end
    local db = E.MusicDatabase
    for i, s in ipairs(db) do
        if s.id == E.State.currentSong.id then
            playSong(db[i-1] or db[#db]) ; return
        end
    end
end

-- ============================================================
--  SONG CARDS — click + fly animation
-- ============================================================
for songId, card in pairs(UI.songCardMap) do
    local capturedId = songId
    card.MouseButton1Click:Connect(function()
        local song
        for _, s in ipairs(E.MusicDatabase) do
            if s.id == capturedId then song = s break end
        end
        if not song then return end

        local artImg = card:FindFirstChildWhichIsA("ImageLabel")
        local fromPos = artImg and artImg.AbsolutePosition or Vector2.new(0,0)
        local fromSz  = artImg and artImg.AbsoluteSize    or Vector2.new(40,40)

        local wasOpen = E.State.nowPlayingOpen
        playSong(song)
        E.openNowPlaying(song)
        E.animateCoverFly(fromPos, fromSz, song, wasOpen)
    end)
end

-- ============================================================
--  PLAYER BAR CONTROLS
-- ============================================================
local function togglePlayPause()
    if E.State.isPlaying then
        Eng:pause()
        UI.BtnPlay.Text = "▶"
        setNPPlayState(false)
    elseif E.State.isPaused then
        Eng:resume()
        UI.BtnPlay.Text = "▌▌"
        setNPPlayState(true)
    elseif E.State.currentSong then
        playSong(E.State.currentSong)
    end
end

UI.BtnPlay.MouseButton1Click:Connect(togglePlayPause)
UI.BtnNext.MouseButton1Click:Connect(nextSong)
UI.BtnPrev.MouseButton1Click:Connect(prevSong)

UI.NPBtnPlay.MouseButton1Click:Connect(togglePlayPause)
UI.NPBtnNext.MouseButton1Click:Connect(nextSong)
UI.NPBtnPrev.MouseButton1Click:Connect(prevSong)

-- ============================================================
--  PLAYER BAR THUMBNAIL → open NowPlaying
-- ============================================================
UI.PlayerThumb.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    and E.State.currentSong then
        E.openNowPlaying(E.State.currentSong)
    end
end)

UI.BtnQueue.MouseButton1Click:Connect(function()
    if E.State.currentSong then E.openNowPlaying(E.State.currentSong) end
end)

-- ============================================================
--  WINDOW OPEN / CLOSE
-- ============================================================
local windowOpen = false
local FRAME_W  = E.FRAME_W or 760
local FRAME_H  = E.FRAME_H or 470
local Y_OFFSET = 40

local function openWindow()
    windowOpen = true
    UI.ToggleBtn.Visible = false
    UI.Backdrop.Visible  = true
    UI.Backdrop.BackgroundTransparency = 1
    E.tween(UI.Backdrop, {BackgroundTransparency = 0.45}, 0.30, Enum.EasingStyle.Quint)
    UI.MainFrame.Visible = true
    UI.MainFrame.BackgroundTransparency = 1
    UI.MainFrame.Position = UDim2.new(0.5,-FRAME_W/2, 0.5,-FRAME_H/2+Y_OFFSET+20)
    E.tween(UI.MainFrame, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5,-FRAME_W/2, 0.5,-FRAME_H/2+Y_OFFSET)
    }, 0.38, Enum.EasingStyle.Quint)
    E.tween(UI.navButtons["Discovery"] or next(UI.navButtons),
        {BackgroundColor3 = C.card, TextColor3 = C.text}, 0.15)
end

local function closeWindow()
    windowOpen = false
    UI.NowPlaying.Visible  = false
    E.State.nowPlayingOpen = false
    E.tween(UI.Backdrop, {BackgroundTransparency = 1}, 0.26, Enum.EasingStyle.Quint)
    local t = E.tween(UI.MainFrame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5,-FRAME_W/2, 0.5,-FRAME_H/2+Y_OFFSET+20)
    }, 0.28, Enum.EasingStyle.Quint)
    t.Completed:Connect(function()
        UI.MainFrame.Visible = false
        UI.Backdrop.Visible  = false
        UI.ToggleBtn.BackgroundTransparency = 1
        UI.ToggleBtn.Visible = true
        E.tween(UI.ToggleBtn, {BackgroundTransparency = 0}, 0.22, Enum.EasingStyle.Quint)
    end)
end

UI.ToggleBtn.MouseButton1Click:Connect(function()
    if windowOpen then closeWindow() else openWindow() end
end)
UI.CloseBtn.MouseButton1Click:Connect(closeWindow)

UI.ToggleBtn.MouseEnter:Connect(function()
    E.tween(UI.ToggleBtn, {BackgroundColor3 = Color3.fromRGB(110,160,255)}, 0.15)
end)
UI.ToggleBtn.MouseLeave:Connect(function()
    E.tween(UI.ToggleBtn, {BackgroundColor3 = C.accentBlue}, 0.15)
end)

-- ============================================================
--  HAMBURGER SIDEBAR TOGGLE
-- ============================================================
local BAR_H       = E.BAR_H    or 58
local SIDEBAR_W_F = E.SIDEBAR_W or math.floor(FRAME_W*0.26)

UI.HamBtn.MouseButton1Click:Connect(function()
    E.State.sidebarOpen = not E.State.sidebarOpen
    local newSbW = E.State.sidebarOpen and SIDEBAR_W_F or 0
    E.tween(UI.Sidebar,     {Size = UDim2.new(0,newSbW,1,0)}, 0.26)
    E.tween(UI.ContentArea, {
        Size     = UDim2.new(1,-newSbW,1,-BAR_H),
        Position = UDim2.new(0,newSbW,0,0)
    }, 0.26)
end)

-- ============================================================
--  SIDEBAR NAVIGATION
-- ============================================================
local function navigateTo(page)
    E.State.currentPage = page
    UI.PageTitle.Text   = page
    for name, btn in pairs(UI.navButtons) do
        if name == page then
            E.tween(btn, {BackgroundColor3 = C.card,    TextColor3 = C.text},    0.14)
        else
            E.tween(btn, {BackgroundColor3 = C.sidebar, TextColor3 = C.subText}, 0.14)
        end
    end
    local onDisc = (page == "Discovery")
    UI.SongsSec.Visible  = onDisc
    UI.ArtistSec.Visible = onDisc
end

for name, btn in pairs(UI.navButtons) do
    local n = name
    btn.MouseButton1Click:Connect(function() navigateTo(n) end)
end
navigateTo("Discovery")

-- ============================================================
--  DRAG MAIN WINDOW
-- ============================================================
local dragging, dragStart, frameStart = false

UI.TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true ; dragStart = inp.Position ; frameStart = UI.MainFrame.Position
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        UI.MainFrame.Position = UDim2.new(
            frameStart.X.Scale, frameStart.X.Offset + d.X,
            frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
    end
end)

-- ============================================================
--  PROGRESS BAR UPDATE
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not (E.State.isPlaying and E.State.currentSong) then return end
    local p = Eng:getProgress()
    E.tween(UI.ProgFill, {Size = UDim2.new(p,0,1,0)}, 0.5, Enum.EasingStyle.Linear)
    if E.State.nowPlayingOpen then
        E.tween(UI.NPProgFill, {Size = UDim2.new(p,0,1,0)}, 0.5, Enum.EasingStyle.Linear)
        if UI.NPProgDot then
            E.tween(UI.NPProgDot, {Position = UDim2.new(p,-6,0.5,-6)}, 0.5, Enum.EasingStyle.Linear)
        end
        UI.NPTimeCurrent.Text = E.formatTime(Eng:getPosition())
    end
end)

UI.ProgFill.Parent.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local bx = UI.ProgFill.Parent.AbsolutePosition.X
        local bw = UI.ProgFill.Parent.AbsoluteSize.X
        Eng:seekTo(math.clamp((inp.Position.X-bx)/bw, 0, 1))
    end
end)

UI.NPProgBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local bx = UI.NPProgBg.AbsolutePosition.X
        local bw = UI.NPProgBg.AbsoluteSize.X
        Eng:seekTo(math.clamp((inp.Position.X-bx)/bw, 0, 1))
    end
end)

-- ============================================================
--  AUTO-ADVANCE
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if E.State.isPlaying and E.State.currentSong then
            local dur = Eng:getDuration()
            if dur > 0 and Eng:getPosition() >= dur - 0.5 then
                if E.State.repeatOn then
                    Eng:seekTo(0)
                else
                    nextSong()
                end
            end
        end
    end
end)

-- ============================================================
--  KEYBOARD SHORTCUTS
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space then
        togglePlayPause()
    elseif inp.KeyCode == Enum.KeyCode.Right then
        if E.State.currentSong then Eng.sound.TimePosition = Eng:getPosition() + 5 end
    elseif inp.KeyCode == Enum.KeyCode.Left then
        if E.State.currentSong then Eng.sound.TimePosition = math.max(0, Eng:getPosition() - 5) end
    end
end)

print("[Exvibe] Controls loaded")
