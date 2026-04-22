-- ============================================================
--  UI_NowPlaying.lua  |  Exvibe Music Player  (v3 fixed)
--  Dynamic sizing based on E.FRAME_W / E.FRAME_H.
--  No X button — drag handle only to dismiss.
--  Repeat/Shuffle: icon-only pill buttons (↻ / ⇌).
-- ============================================================

local E   = _G.Exvibe
local C   = E.COLORS
local UI  = E.UI
local UIS = game:GetService("UserInputService")

-- ============================================================
--  DYNAMIC SIZING  (all values derived from frame dimensions)
-- ============================================================
local FW = E.FRAME_W or 760
local FH = E.FRAME_H or 470

local LEFT_X   = 20
local LEFT_W   = math.floor(FW * 0.43)          -- left panel width
local PANEL_Y  = 22                               -- top offset (below drag handle)
local DIVIDER_X = LEFT_X + LEFT_W + 14
local RIGHT_X  = DIVIDER_X + 8
local RIGHT_W  = FW - RIGHT_X - 14

-- Art: square, but shrinks if frame is short
local ART_PAD  = 28
local ART_W    = LEFT_W - ART_PAD
local ART_H    = math.min(ART_W, math.floor((FH - PANEL_Y) * 0.50))

-- Vertical positions inside LeftPanel (y from LeftPanel top)
local ART_Y    = 14
local TITLE_Y  = ART_Y + ART_H + 12
local ARTIST_Y = TITLE_Y + 22
local PROG_Y   = ARTIST_Y + 18
local TIME_Y   = PROG_Y + 8
local CTRL_Y   = PROG_Y + 30
local VOL_Y    = CTRL_Y + 58

local LEFT_CX  = math.floor(LEFT_W / 2)          -- horizontal center of left panel

-- ============================================================
--  SHEET FRAME  (covers full MainFrame, slides up from bottom)
-- ============================================================
local Sheet = Instance.new("Frame", UI.MainFrame)
Sheet.Name             = "NowPlayingSheet"
Sheet.Size             = UDim2.new(1,0,1,0)
Sheet.Position         = UDim2.new(0,0,1,0)
Sheet.BackgroundColor3 = C.nowPlayBg
Sheet.BorderSizePixel  = 0
Sheet.ClipsDescendants = true
Sheet.Visible          = false
Sheet.ZIndex           = 20
Instance.new("UICorner", Sheet).CornerRadius = UDim.new(0,18)
UI.NowPlaying = Sheet

-- ============================================================
--  DRAG HANDLE  (pill — drag down to dismiss, no X button)
-- ============================================================
local DragHandle = Instance.new("Frame", Sheet)
DragHandle.Size             = UDim2.new(0,44,0,5)
DragHandle.Position         = UDim2.new(0.5,-22,0,8)
DragHandle.BackgroundColor3 = C.pill
DragHandle.BorderSizePixel  = 0
DragHandle.ZIndex           = 21
Instance.new("UICorner", DragHandle).CornerRadius = UDim.new(1,0)

-- Invisible wide hit area for drag gesture
local DragHit = Instance.new("TextButton", Sheet)
DragHit.Size             = UDim2.new(1,0,0,24)
DragHit.Position         = UDim2.new(0,0,0,0)
DragHit.BackgroundTransparency = 1
DragHit.Text             = ""
DragHit.ZIndex           = 22

-- ============================================================
--  VERTICAL DIVIDER
-- ============================================================
local Divider = Instance.new("Frame", Sheet)
Divider.Size             = UDim2.new(0,1,1,-48)
Divider.Position         = UDim2.new(0,DIVIDER_X,0,24)
Divider.BackgroundColor3 = C.border
Divider.BorderSizePixel  = 0
Divider.ZIndex           = 21

-- ============================================================
--  LEFT PANEL
-- ============================================================
local LeftPanel = Instance.new("Frame", Sheet)
LeftPanel.Size             = UDim2.new(0,LEFT_W,1,-PANEL_Y)
LeftPanel.Position         = UDim2.new(0,LEFT_X,0,PANEL_Y)
LeftPanel.BackgroundTransparency = 1
LeftPanel.ZIndex           = 21

-- Album art  (square-ish, with border like image 2)
local NPArt = Instance.new("ImageLabel", LeftPanel)
NPArt.Size             = UDim2.new(0,ART_W,0,ART_H)
NPArt.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,ART_Y)
NPArt.BackgroundColor3 = C.card
NPArt.BorderSizePixel  = 0
NPArt.ZIndex           = 22
Instance.new("UICorner", NPArt).CornerRadius = UDim.new(0,14)
local ArtStroke = Instance.new("UIStroke", NPArt)
ArtStroke.Color     = C.border
ArtStroke.Thickness = 1.5

-- Title
local NPTitle = Instance.new("TextLabel", LeftPanel)
NPTitle.Size             = UDim2.new(1,-ART_PAD,0,22)
NPTitle.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,TITLE_Y)
NPTitle.BackgroundTransparency = 1
NPTitle.Text             = "Not Playing"
NPTitle.TextColor3       = C.text
NPTitle.Font             = Enum.Font.GothamBold
NPTitle.TextSize         = 17
NPTitle.TextXAlignment   = Enum.TextXAlignment.Left
NPTitle.TextTruncate     = Enum.TextTruncate.AtEnd
NPTitle.ZIndex           = 22

-- Artist
local NPArtist = Instance.new("TextLabel", LeftPanel)
NPArtist.Size             = UDim2.new(1,-ART_PAD,0,16)
NPArtist.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,ARTIST_Y)
NPArtist.BackgroundTransparency = 1
NPArtist.Text             = "-"
NPArtist.TextColor3       = C.subText
NPArtist.Font             = Enum.Font.Gotham
NPArtist.TextSize         = 13
NPArtist.TextXAlignment   = Enum.TextXAlignment.Left
NPArtist.ZIndex           = 22

-- Progress bar track
local NPProgBg = Instance.new("Frame", LeftPanel)
NPProgBg.Size             = UDim2.new(1,-ART_PAD,0,4)
NPProgBg.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,PROG_Y)
NPProgBg.BackgroundColor3 = Color3.fromRGB(60,60,72)
NPProgBg.BorderSizePixel  = 0
NPProgBg.ZIndex           = 22
Instance.new("UICorner", NPProgBg).CornerRadius = UDim.new(1,0)

local NPProgFill = Instance.new("Frame", NPProgBg)
NPProgFill.Size             = UDim2.new(0,0,1,0)
NPProgFill.BackgroundColor3 = C.accent
NPProgFill.BorderSizePixel  = 0
NPProgFill.ZIndex           = 23
Instance.new("UICorner", NPProgFill).CornerRadius = UDim.new(1,0)

-- Scrubber dot
local NPProgDot = Instance.new("Frame", NPProgBg)
NPProgDot.Size             = UDim2.new(0,12,0,12)
NPProgDot.Position         = UDim2.new(0,-6,0.5,-6)
NPProgDot.BackgroundColor3 = Color3.new(1,1,1)
NPProgDot.BorderSizePixel  = 0
NPProgDot.ZIndex           = 24
Instance.new("UICorner", NPProgDot).CornerRadius = UDim.new(1,0)

-- Time labels  (below progress bar)
local NPTimeCurrent = Instance.new("TextLabel", LeftPanel)
NPTimeCurrent.Size             = UDim2.new(0,44,0,14)
NPTimeCurrent.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,TIME_Y)
NPTimeCurrent.BackgroundTransparency = 1
NPTimeCurrent.Text             = "0:00"
NPTimeCurrent.TextColor3       = C.subText
NPTimeCurrent.Font             = Enum.Font.Gotham
NPTimeCurrent.TextSize         = 11
NPTimeCurrent.TextXAlignment   = Enum.TextXAlignment.Left
NPTimeCurrent.ZIndex           = 22

local NPTimeTotal = Instance.new("TextLabel", LeftPanel)
NPTimeTotal.Size             = UDim2.new(0,44,0,14)
NPTimeTotal.Position         = UDim2.new(1,-ART_PAD-44,0,TIME_Y)
NPTimeTotal.BackgroundTransparency = 1
NPTimeTotal.Text             = "0:00"
NPTimeTotal.TextColor3       = C.subText
NPTimeTotal.Font             = Enum.Font.Gotham
NPTimeTotal.TextSize         = 11
NPTimeTotal.TextXAlignment   = Enum.TextXAlignment.Right
NPTimeTotal.ZIndex           = 22

-- ============================================================
--  PLAYBACK CONTROLS  (◀◀  ▶  ▶▶  centered in left panel)
-- ============================================================
local function makeNPCtrl(icon, absX, sz)
    sz = sz or 42
    local b = Instance.new("TextButton", LeftPanel)
    b.Size                   = UDim2.new(0,sz,0,sz)
    b.Position               = UDim2.new(0, absX - math.floor(sz/2), 0, CTRL_Y)
    b.BackgroundTransparency = 1
    b.AutoButtonColor        = false
    b.Text                   = icon
    b.TextColor3             = C.text
    b.Font                   = Enum.Font.GothamBold
    b.TextSize               = 24
    b.ZIndex                 = 22
    return b
end

local NPBtnPrev = makeNPCtrl("◀◀", LEFT_CX - 62)
local NPBtnPlay = makeNPCtrl("▶",  LEFT_CX,     52)
NPBtnPlay.TextSize = 32
local NPBtnNext = makeNPCtrl("▶▶", LEFT_CX + 62)

-- ============================================================
--  VOLUME ROW  (- slider +)
-- ============================================================
local NPVolLow = Instance.new("TextLabel", LeftPanel)
NPVolLow.Size             = UDim2.new(0,18,0,18)
NPVolLow.Position         = UDim2.new(0,math.floor(ART_PAD/2),0,VOL_Y)
NPVolLow.BackgroundTransparency = 1
NPVolLow.Text             = "-"
NPVolLow.TextSize         = 17
NPVolLow.Font             = Enum.Font.GothamBold
NPVolLow.TextColor3       = C.subText
NPVolLow.ZIndex           = 22

local NPVolBg = Instance.new("Frame", LeftPanel)
NPVolBg.Size             = UDim2.new(1,-ART_PAD-44,0,4)
NPVolBg.Position         = UDim2.new(0,ART_PAD+4,0,VOL_Y+8)
NPVolBg.BackgroundColor3 = Color3.fromRGB(60,60,72)
NPVolBg.BorderSizePixel  = 0
NPVolBg.ZIndex           = 22
Instance.new("UICorner", NPVolBg).CornerRadius = UDim.new(1,0)

local NPVolFill = Instance.new("Frame", NPVolBg)
NPVolFill.Size             = UDim2.new(E.State.volume or 0.8, 0, 1, 0)
NPVolFill.BackgroundColor3 = C.accent
NPVolFill.BorderSizePixel  = 0
NPVolFill.ZIndex           = 23
Instance.new("UICorner", NPVolFill).CornerRadius = UDim.new(1,0)

local NPVolHigh = Instance.new("TextLabel", LeftPanel)
NPVolHigh.Size             = UDim2.new(0,18,0,18)
NPVolHigh.Position         = UDim2.new(1,-ART_PAD,0,VOL_Y)
NPVolHigh.BackgroundTransparency = 1
NPVolHigh.Text             = "+"
NPVolHigh.TextSize         = 17
NPVolHigh.Font             = Enum.Font.GothamBold
NPVolHigh.TextColor3       = C.subText
NPVolHigh.ZIndex           = 22

-- Store refs
UI.NPArt         = NPArt
UI.NPTitle       = NPTitle
UI.NPArtist      = NPArtist
UI.NPProgFill    = NPProgFill
UI.NPProgBg      = NPProgBg
UI.NPProgDot     = NPProgDot
UI.NPTimeCurrent = NPTimeCurrent
UI.NPTimeTotal   = NPTimeTotal
UI.NPBtnPrev     = NPBtnPrev
UI.NPBtnPlay     = NPBtnPlay
UI.NPBtnNext     = NPBtnNext
UI.NPVolFill     = NPVolFill
UI.NPVolBg       = NPVolBg

-- Volume drag
local npVolDrag = false
NPVolBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then npVolDrag = true end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then npVolDrag = false end
end)
UIS.InputChanged:Connect(function(inp)
    if not npVolDrag then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
        local mx   = UIS:GetMouseLocation().X
        local bx   = NPVolBg.AbsolutePosition.X
        local bw   = NPVolBg.AbsoluteSize.X
        local frac = math.clamp((mx - bx) / bw, 0, 1)
        E.Engine:setVolume(frac)
        NPVolFill.Size = UDim2.new(frac, 0, 1, 0)
    end
end)

-- ============================================================
--  RIGHT PANEL
-- ============================================================
local RightPanel = Instance.new("Frame", Sheet)
RightPanel.Size             = UDim2.new(0,RIGHT_W,1,-PANEL_Y)
RightPanel.Position         = UDim2.new(0,RIGHT_X,0,PANEL_Y)
RightPanel.BackgroundTransparency = 1
RightPanel.ZIndex           = 21

-- Top row: back `<`  |  ↻ (repeat pill)  ⇌ (shuffle pill)
-- Back button — circular, far left
local NPBackBtn = Instance.new("TextButton", RightPanel)
NPBackBtn.Size             = UDim2.new(0,36,0,36)
NPBackBtn.Position         = UDim2.new(0,0,0,0)
NPBackBtn.BackgroundColor3 = C.card
NPBackBtn.Text             = "<"
NPBackBtn.TextColor3       = C.text
NPBackBtn.Font             = Enum.Font.GothamBold
NPBackBtn.TextSize         = 18
NPBackBtn.BorderSizePixel  = 0
NPBackBtn.AutoButtonColor  = false
NPBackBtn.ZIndex           = 22
Instance.new("UICorner", NPBackBtn).CornerRadius = UDim.new(1,0)

-- Repeat button — icon-only pill (↻)
local NPRepeatBtn = Instance.new("TextButton", RightPanel)
NPRepeatBtn.Size             = UDim2.new(0,92,0,36)
NPRepeatBtn.Position         = UDim2.new(0.5,-98,0,0)
NPRepeatBtn.BackgroundColor3 = C.card
NPRepeatBtn.Text             = "↻"
NPRepeatBtn.TextColor3       = C.subText
NPRepeatBtn.Font             = Enum.Font.GothamBold
NPRepeatBtn.TextSize         = 22
NPRepeatBtn.BorderSizePixel  = 0
NPRepeatBtn.AutoButtonColor  = false
NPRepeatBtn.ZIndex           = 22
Instance.new("UICorner", NPRepeatBtn).CornerRadius = UDim.new(0,18)

-- Shuffle button — icon-only pill (⇌)
local NPShuffleBtn = Instance.new("TextButton", RightPanel)
NPShuffleBtn.Size             = UDim2.new(0,92,0,36)
NPShuffleBtn.Position         = UDim2.new(0.5,4,0,0)
NPShuffleBtn.BackgroundColor3 = C.card
NPShuffleBtn.Text             = "⇌"
NPShuffleBtn.TextColor3       = C.subText
NPShuffleBtn.Font             = Enum.Font.GothamBold
NPShuffleBtn.TextSize         = 22
NPShuffleBtn.BorderSizePixel  = 0
NPShuffleBtn.AutoButtonColor  = false
NPShuffleBtn.ZIndex           = 22
Instance.new("UICorner", NPShuffleBtn).CornerRadius = UDim.new(0,18)

UI.NPRepeatBtn  = NPRepeatBtn
UI.NPShuffleBtn = NPShuffleBtn

-- "Continue Playing" header
local CPHeader = Instance.new("TextLabel", RightPanel)
CPHeader.Size             = UDim2.new(1,0,0,19)
CPHeader.Position         = UDim2.new(0,0,0,48)
CPHeader.BackgroundTransparency = 1
CPHeader.Text             = "Continue Playing"
CPHeader.TextColor3       = C.text
CPHeader.Font             = Enum.Font.GothamBold
CPHeader.TextSize         = 15
CPHeader.TextXAlignment   = Enum.TextXAlignment.Left
CPHeader.ZIndex           = 22

local CPSub = Instance.new("TextLabel", RightPanel)
CPSub.Size             = UDim2.new(1,0,0,14)
CPSub.Position         = UDim2.new(0,0,0,69)
CPSub.BackgroundTransparency = 1
CPSub.Text             = "From Library"
CPSub.TextColor3       = C.subText
CPSub.Font             = Enum.Font.Gotham
CPSub.TextSize         = 12
CPSub.TextXAlignment   = Enum.TextXAlignment.Left
CPSub.ZIndex           = 22

-- Queue scroll list
local QueueScroll = Instance.new("ScrollingFrame", RightPanel)
QueueScroll.Size             = UDim2.new(1,0,1,-138)
QueueScroll.Position         = UDim2.new(0,0,0,90)
QueueScroll.BackgroundTransparency = 1
QueueScroll.BorderSizePixel  = 0
QueueScroll.ScrollBarThickness = 2
QueueScroll.ScrollBarImageColor3 = C.border
QueueScroll.CanvasSize       = UDim2.new(0,0,0,0)
QueueScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
QueueScroll.ZIndex           = 22
UI.QueueScroll = QueueScroll

local QLayout = Instance.new("UIListLayout", QueueScroll)
QLayout.Padding   = UDim.new(0,4)
QLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Queue item builder
local function makeQueueItem(song, order)
    local item = Instance.new("TextButton", QueueScroll)
    item.Size             = UDim2.new(1,-4,0,52)
    item.LayoutOrder      = order
    item.BackgroundTransparency = 1
    item.Text             = ""
    item.BorderSizePixel  = 0
    item.ZIndex           = 23

    local thumb = Instance.new("ImageLabel", item)
    thumb.Size             = UDim2.new(0,42,0,42)
    thumb.Position         = UDim2.new(0,0,0.5,-21)
    thumb.BackgroundColor3 = C.card
    thumb.BorderSizePixel  = 0
    thumb.Image            = song.cover or ""
    thumb.ZIndex           = 24
    Instance.new("UICorner",thumb).CornerRadius = UDim.new(0,8)

    local tLbl = Instance.new("TextLabel", item)
    tLbl.Size             = UDim2.new(1,-52,0,17)
    tLbl.Position         = UDim2.new(0,50,0,8)
    tLbl.BackgroundTransparency = 1
    tLbl.Text             = song.title
    tLbl.TextColor3       = C.text
    tLbl.Font             = Enum.Font.GothamSemibold
    tLbl.TextSize         = 13
    tLbl.TextXAlignment   = Enum.TextXAlignment.Left
    tLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    tLbl.ZIndex           = 24

    local aLbl = Instance.new("TextLabel", item)
    aLbl.Size             = UDim2.new(1,-52,0,14)
    aLbl.Position         = UDim2.new(0,50,0,27)
    aLbl.BackgroundTransparency = 1
    aLbl.Text             = song.artist
    aLbl.TextColor3       = C.subText
    aLbl.Font             = Enum.Font.Gotham
    aLbl.TextSize         = 11
    aLbl.TextXAlignment   = Enum.TextXAlignment.Left
    aLbl.ZIndex           = 24

    item.MouseEnter:Connect(function()
        E.tween(item, {BackgroundTransparency = 0.88}, 0.1)
        item.BackgroundColor3 = C.card
    end)
    item.MouseLeave:Connect(function()
        E.tween(item, {BackgroundTransparency = 1}, 0.1)
    end)

    return item
end

-- Build / rebuild queue
function E.buildQueue()
    for _, ch in ipairs(QueueScroll:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
    local startIdx = 1
    if E.State.currentSong then
        for i, s in ipairs(E.MusicDatabase) do
            if s.id == E.State.currentSong.id then startIdx = i + 1 break end
        end
    end
    local order = 1
    for i = startIdx, #E.MusicDatabase do
        makeQueueItem(E.MusicDatabase[i], order) ; order = order + 1
    end
    for i = 1, startIdx - 2 do
        makeQueueItem(E.MusicDatabase[i], order) ; order = order + 1
    end
end

E.buildQueue()

-- Bottom action buttons  (>_ social ...)
local function makeActionBtn(icon, xOff)
    local b = Instance.new("TextButton", RightPanel)
    b.Size             = UDim2.new(0,38,0,38)
    b.Position         = UDim2.new(0,xOff,1,-44)
    b.BackgroundTransparency = 1
    b.Text             = icon
    b.TextColor3       = C.subText
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 18
    b.ZIndex           = 22
    return b
end
makeActionBtn(">_",   0)
makeActionBtn("=+",  50)
makeActionBtn("...", 100)

-- ============================================================
--  OPEN / CLOSE ANIMATIONS
-- ============================================================
function E.openNowPlaying(song)
    if song then
        UI.NPArt.Image        = song.cover or ""
        UI.NPTitle.Text       = song.title
        UI.NPArtist.Text      = song.artist
        UI.NPTimeTotal.Text   = E.formatTime(song.duration)
        UI.NPTimeCurrent.Text = "0:00"
        UI.NPProgFill.Size    = UDim2.new(0,0,1,0)
        if UI.NPProgDot then
            UI.NPProgDot.Position = UDim2.new(0,-6,0.5,-6)
        end
        E.buildQueue()
    end
    UI.NPBtnPlay.Text = E.State.isPlaying and "▌▌" or "▶"
    E.State.nowPlayingOpen = true
    Sheet.Visible = true
    Sheet.Position = UDim2.new(0,0,1,0)
    E.tween(Sheet, {Position = UDim2.new(0,0,0,0)}, 0.42, Enum.EasingStyle.Quint)
end

function E.closeNowPlaying()
    E.State.nowPlayingOpen = false
    local t = E.tween(Sheet, {Position = UDim2.new(0,0,1,0)}, 0.34, Enum.EasingStyle.Quint)
    t.Completed:Connect(function() Sheet.Visible = false end)
end

-- ============================================================
--  DRAG-DOWN TO DISMISS  (no X button — drag handle is enough)
-- ============================================================
local dragging   = false
local dragStartY = 0

DragHit.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        dragStartY = inp.Position.Y
    end
end)

UIS.InputEnded:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if Sheet.Position.Y.Offset > 70 then
            E.closeNowPlaying()
        else
            E.tween(Sheet, {Position = UDim2.new(0,0,0,0)}, 0.22)
        end
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position.Y - dragStartY
        if delta > 0 then Sheet.Position = UDim2.new(0,0,0,delta) end
    end
end)

-- Back button closes sheet
NPBackBtn.MouseButton1Click:Connect(E.closeNowPlaying)

print("[Exvibe] UI_NowPlaying loaded")
