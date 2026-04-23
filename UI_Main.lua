-- ============================================================
--  UI_Main.lua  |  Exvibe Music Player  (v4 – Search/Library)
-- ============================================================
local E  = _G.Exvibe
local C  = E.COLORS

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

E.UI = E.UI or {}
local UI = E.UI


local cam       = workspace.CurrentCamera
local vp        = cam.ViewportSize
local FRAME_W   = math.clamp(math.floor(vp.X * 0.82), 580, 900)
local raw_h     = math.floor(vp.Y * 0.52)
local safe_h    = vp.Y - 120
local FRAME_H   = math.max(320, math.min(raw_h, math.min(420, safe_h)))
local SIDEBAR_W = math.floor(FRAME_W * 0.26)
local BAR_H     = 58

E.FRAME_W   = FRAME_W
E.FRAME_H   = FRAME_H
E.SIDEBAR_W = SIDEBAR_W
E.BAR_H     = BAR_H

-- ============================================================
--  WAVEFORM ICON HELPER
-- ============================================================
local function makeWaveform(parent, color, zIdx, sz)
    sz = sz or 28
    local heights = {0.40, 0.80, 0.55, 1.0}
    local bW      = math.max(3, math.floor(sz * 0.12))
    local gap     = math.max(2, math.floor(sz * 0.09))
    local totalW  = #heights * bW + (#heights - 1) * gap
    local startX  = math.floor((sz - totalW) / 2)
    local maxH    = math.floor(sz * 0.68)
    for i, hR in ipairs(heights) do
        local bH  = math.floor(maxH * hR)
        local bar = Instance.new("Frame", parent)
        bar.Size             = UDim2.new(0, bW, 0, bH)
        bar.Position         = UDim2.new(0, startX + (i-1)*(bW+gap), 0.5, -math.floor(bH/2))
        bar.BackgroundColor3 = color
        bar.BorderSizePixel  = 0
        bar.ZIndex           = zIdx
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    end
end

-- ============================================================
--  ROOT SCREENGUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ExvibeUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui
UI.ScreenGui = ScreenGui

local Backdrop = Instance.new("Frame", ScreenGui)
Backdrop.Name                   = "Backdrop"
Backdrop.Size                   = UDim2.new(1,0,1,0)
Backdrop.BackgroundColor3       = Color3.new(0,0,0)
Backdrop.BackgroundTransparency = 1
Backdrop.BorderSizePixel        = 0
Backdrop.Visible                = false
Backdrop.ZIndex                 = 9
UI.Backdrop = Backdrop

-- ============================================================
--  TOGGLE BUTTON
-- ============================================================
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Name              = "ToggleBtn"
ToggleBtn.Size              = UDim2.new(0,46,0,46)
ToggleBtn.Position          = UDim2.new(1,-64,1,-72)
ToggleBtn.BackgroundColor3  = C.accentBlue
ToggleBtn.BorderSizePixel   = 0
ToggleBtn.Text              = ""
ToggleBtn.AutoButtonColor   = false
ToggleBtn.ZIndex            = 100
ToggleBtn.ClipsDescendants  = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1,0)
makeWaveform(ToggleBtn, Color3.new(1,1,1), 101, 46)
UI.ToggleBtn = ToggleBtn

-- ============================================================
--  MAIN FRAME
--  ClipsDescendants = false  →  PlayerBar not corner-clipped
-- ============================================================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0,FRAME_W,0,FRAME_H)
MainFrame.Position         = UDim2.new(0.5,-FRAME_W/2, 0.5,-FRAME_H/2 + 20)
MainFrame.BackgroundColor3 = C.bg
MainFrame.BorderSizePixel  = 0
MainFrame.ClipsDescendants = false
MainFrame.Visible          = false
MainFrame.ZIndex           = 10
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,28)
UI.MainFrame = MainFrame


-- ============================================================
--  CONTENT CLIP  (clips scroll content, never clips PlayerBar)
-- ============================================================
local ContentClip = Instance.new("Frame", MainFrame)
ContentClip.Name             = "ContentClip"
ContentClip.Size             = UDim2.new(1,0,1,-BAR_H)
ContentClip.BackgroundTransparency = 1
ContentClip.BorderSizePixel  = 0
ContentClip.ClipsDescendants = true
ContentClip.ZIndex           = 10
Instance.new("UICorner", ContentClip).CornerRadius = UDim.new(0,28)
UI.ContentClip = ContentClip

-- ============================================================
--  SIDEBAR
-- ============================================================
local Sidebar = Instance.new("Frame", ContentClip)
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0,SIDEBAR_W,1,0)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel  = 0
Sidebar.ClipsDescendants = true
Sidebar.ZIndex           = 11
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,28)
UI.Sidebar = Sidebar

local SbRCover = Instance.new("Frame", Sidebar)
SbRCover.Size             = UDim2.new(0,20,1,0)
SbRCover.Position         = UDim2.new(1,-20,0,0)
SbRCover.BackgroundColor3 = C.sidebar
SbRCover.BorderSizePixel  = 0
SbRCover.ZIndex           = 11

-- Logo image (standalone at top)
local LogoBadge = Instance.new("ImageLabel", Sidebar)
LogoBadge.Size                   = UDim2.new(0,30,0,30)
LogoBadge.Position               = UDim2.new(0,12,0,12)
LogoBadge.BackgroundTransparency = 1
LogoBadge.BorderSizePixel        = 0
LogoBadge.ZIndex                 = 13
LogoBadge.Image                  = "rbxassetid://77847099845882"
LogoBadge.ScaleType              = Enum.ScaleType.Fit

-- "Exvibe" brand name as section header (like image 2's "Masters")
local LogoText = Instance.new("TextLabel", Sidebar)
LogoText.Size             = UDim2.new(1,-18,0,14)
LogoText.Position         = UDim2.new(0,12,0,48)
LogoText.BackgroundTransparency = 1
LogoText.Text             = "Exvibe"
LogoText.TextColor3       = C.subText
LogoText.Font             = Enum.Font.GothamSemibold
LogoText.TextSize         = 9
LogoText.TextXAlignment   = Enum.TextXAlignment.Left
LogoText.ZIndex           = 13

local function sbLabel(text, y)
    local l = Instance.new("TextLabel", Sidebar)
    l.Size = UDim2.new(1,-18,0,14)
    l.Position = UDim2.new(0,12,0,y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.subText
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12
end

local function makeNavBtn(name, y)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name             = name
    btn.Size             = UDim2.new(1,-16,0,30)
    btn.Position         = UDim2.new(0,8,0,y)
    btn.BackgroundColor3 = C.sidebar
    btn.BorderSizePixel  = 0
    btn.Text             = name
    btn.TextColor3       = C.subText
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.AutoButtonColor  = false
    btn.ZIndex           = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0,10)
    return btn
end

local navButtons = {}
local navPages   = {"Discovery", "Search", "Library"}
local navY = 68
for _, name in ipairs(navPages) do
    navButtons[name] = makeNavBtn(name, navY)
    navY = navY + 34
end
UI.navButtons = navButtons

local SbDiv = Instance.new("Frame", Sidebar)
SbDiv.Size             = UDim2.new(1,-16,0,1)
SbDiv.Position         = UDim2.new(0,8,0,navY+4)
SbDiv.BackgroundTransparency = 1  -- divider hidden
SbDiv.BorderSizePixel  = 0
SbDiv.ZIndex           = 12

sbLabel("PINS", navY+12)
local PinBtn = makeNavBtn("Playlist", navY+32)
local PinIco = Instance.new("ImageLabel", PinBtn)
PinIco.Size                   = UDim2.new(0,18,0,18)
PinIco.Position               = UDim2.new(0,6,0.5,-9)
PinIco.BackgroundTransparency = 1
PinIco.BorderSizePixel        = 0
PinIco.ZIndex                 = 13
PinIco.Image                  = "rbxassetid://108651088623287"
PinIco.ScaleType              = Enum.ScaleType.Fit
-- Push text right so it doesn't overlap icon
PinBtn:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 28)

-- ============================================================
--  CONTENT AREA
-- ============================================================
local ContentArea = Instance.new("Frame", ContentClip)
ContentArea.Name             = "ContentArea"
ContentArea.Size             = UDim2.new(1,-SIDEBAR_W,1,0)
ContentArea.Position         = UDim2.new(0,SIDEBAR_W,0,0)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.ZIndex           = 11
UI.ContentArea = ContentArea

local TopBar = Instance.new("Frame", ContentArea)
TopBar.Size             = UDim2.new(1,0,0,46)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex           = 12
UI.TopBar = TopBar

local CloseBtn = Instance.new("ImageButton", TopBar)
CloseBtn.Size             = UDim2.new(0,28,0,28)
CloseBtn.Position         = UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image            = "rbxassetid://128680767530455"
CloseBtn.ScaleType        = Enum.ScaleType.Fit
CloseBtn.BorderSizePixel  = 0
CloseBtn.AutoButtonColor  = false
CloseBtn.ZIndex           = 13
UI.CloseBtn = CloseBtn

-- Hamburger replaces settings button: placed to the left of X, no background
local HamBtn = Instance.new("TextButton", TopBar)
HamBtn.Size             = UDim2.new(0,30,0,30)
HamBtn.Position         = UDim2.new(1,-70,0.5,-15)
HamBtn.BackgroundTransparency = 1
HamBtn.Text             = "≡"
HamBtn.TextColor3       = C.text
HamBtn.Font             = Enum.Font.GothamBold
HamBtn.TextSize         = 18
HamBtn.BorderSizePixel  = 0
HamBtn.AutoButtonColor  = false
HamBtn.ZIndex           = 13
UI.HamBtn = HamBtn

-- Page container (below TopBar)
local PageContainer = Instance.new("Frame", ContentArea)
PageContainer.Name             = "PageContainer"
PageContainer.Size             = UDim2.new(1,0,1,-46)
PageContainer.Position         = UDim2.new(0,0,0,46)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.ZIndex           = 11
UI.PageContainer = PageContainer

-- ============================================================
--  PAGE FACTORY
-- ============================================================
local function makePage(name)
    local page = Instance.new("Frame", PageContainer)
    page.Name             = name
    page.Size             = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel  = 0
    page.Visible          = false
    page.ZIndex           = 12
    -- UIScale child used by Controls.lua:popInPage via FindFirstChildOfClass
    local _sc = Instance.new("UIScale", page)
    _sc.Scale = 1

    local sf = Instance.new("ScrollingFrame", page)
    sf.Name             = "ScrollFrame"
    sf.Size             = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel  = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = C.border
    sf.CanvasSize       = UDim2.new(0,0,0,0)
    pcall(function() sf.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
    sf.ZIndex           = 12

    local layout = Instance.new("UIListLayout", sf)
    layout.Padding   = UDim.new(0,4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", sf)
    pad.PaddingLeft   = UDim.new(0,14)
    pad.PaddingRight  = UDim.new(0,8)
    pad.PaddingBottom = UDim.new(0,10)
    pad.PaddingTop    = UDim.new(0,4)

    return page, sf
end

-- ============================================================
--  DISCOVERY PAGE
-- ============================================================
local DiscoveryPage, DiscoveryScroll = makePage("DiscoveryPage")
UI.DiscoveryPage   = DiscoveryPage
UI.DiscoveryScroll = DiscoveryScroll

local function makeHSection(title, height, order, parent)
    local sec = Instance.new("Frame", parent)
    sec.Name = title.."Sec"
    sec.Size = UDim2.new(1,0,0,height)
    sec.BackgroundTransparency = 1
    sec.BorderSizePixel = 0
    sec.LayoutOrder = order
    sec.ZIndex = 12

    local tl = Instance.new("TextLabel", sec)
    tl.Size = UDim2.new(1,0,0,22)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.text
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 13

    local hs = Instance.new("ScrollingFrame", sec)
    hs.Name = "HScroll"
    hs.Size = UDim2.new(1,0,0,height-24)
    hs.Position = UDim2.new(0,0,0,24)
    hs.BackgroundTransparency = 1
    hs.BorderSizePixel = 0
    hs.ScrollBarThickness = 0
    hs.CanvasSize = UDim2.new(0,0,1,0)
    pcall(function() hs.AutomaticCanvasSize = Enum.AutomaticSize.X end)
    hs.ScrollingDirection = Enum.ScrollingDirection.X
    hs.ZIndex = 13

    local hl = Instance.new("UIListLayout", hs)
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.Padding = UDim.new(0,10)
    hl.SortOrder = Enum.SortOrder.LayoutOrder
    return sec, hs
end

local SongsSec,  SongsHScroll  = makeHSection("Songs",   162, 1, DiscoveryScroll)
local ArtistSec, ArtistHScroll = makeHSection("Artists", 142, 2, DiscoveryScroll)
UI.SongsSec      = SongsSec
UI.SongsHScroll  = SongsHScroll
UI.ArtistSec     = ArtistSec
UI.ArtistHScroll = ArtistHScroll

-- ============================================================
--  SHARED CARD BUILDERS
-- ============================================================
local function makeSongCard(song, parent, layoutOrder)
    local CW, CH = 120, 150
    local card = Instance.new("TextButton", parent)
    card.Name = "SongCard_"..song.id
    card.Size = UDim2.new(0,CW,0,CH)
    card.LayoutOrder = layoutOrder
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.ZIndex = 14

    local art = Instance.new("ImageLabel", card)
    art.Size = UDim2.new(1,-10,0,92)
    art.Position = UDim2.new(0,5,0,5)
    art.BackgroundColor3 = C.cardHover
    art.BorderSizePixel = 0
    art.Image = song.cover
    art.ZIndex = 15
    Instance.new("UICorner", art).CornerRadius = UDim.new(0,12)

    local tl = Instance.new("TextLabel", card)
    tl.Size = UDim2.new(1,-10,0,13)
    tl.Position = UDim2.new(0,5,0,100)
    tl.BackgroundTransparency = 1
    tl.Text = song.title
    tl.TextColor3 = C.text
    tl.Font = Enum.Font.GothamSemibold
    tl.TextSize = 11
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextTruncate = Enum.TextTruncate.AtEnd
    tl.ZIndex = 15

    local al = Instance.new("TextLabel", card)
    al.Size = UDim2.new(1,-10,0,11)
    al.Position = UDim2.new(0,5,0,114)
    al.BackgroundTransparency = 1
    al.Text = song.artist
    al.TextColor3 = C.subText
    al.Font = Enum.Font.Gotham
    al.TextSize = 9
    al.TextXAlignment = Enum.TextXAlignment.Left
    al.TextTruncate = Enum.TextTruncate.AtEnd
    al.ZIndex = 15

    return card
end
E.makeSongCard = makeSongCard

local function makeArtistCard(name, color, parent, layoutOrder)
    local card = Instance.new("TextButton", parent)
    card.Name = "ArtistCard_"..layoutOrder
    card.Size = UDim2.new(0,90,0,116)
    card.LayoutOrder = layoutOrder
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.ZIndex = 14

    local circle = Instance.new("Frame", card)
    circle.Size = UDim2.new(0,74,0,74)
    circle.Position = UDim2.new(0.5,-37,0,0)
    circle.BackgroundColor3 = color
    circle.BorderSizePixel = 0
    circle.ZIndex = 15
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

    local ini = Instance.new("TextLabel", circle)
    ini.Size = UDim2.new(1,0,1,0)
    ini.BackgroundTransparency = 1
    ini.Text = string.upper(string.sub(name,1,2))
    ini.TextColor3 = Color3.new(1,1,1)
    ini.Font = Enum.Font.GothamBold
    ini.TextSize = 20
    ini.ZIndex = 16

    local nl = Instance.new("TextLabel", card)
    nl.Size = UDim2.new(1,0,0,12)
    nl.Position = UDim2.new(0,0,0,78)
    nl.BackgroundTransparency = 1
    nl.Text = name
    nl.TextColor3 = C.text
    nl.Font = Enum.Font.GothamSemibold
    nl.TextSize = 10
    nl.ZIndex = 15

    local gl = Instance.new("TextLabel", card)
    gl.Size = UDim2.new(1,0,0,10)
    gl.Position = UDim2.new(0,0,0,92)
    gl.BackgroundTransparency = 1
    gl.Text = "Artist"
    gl.TextColor3 = C.subText
    gl.Font = Enum.Font.Gotham
    gl.TextSize = 9
    gl.ZIndex = 15

    return card
end

-- Populate Discovery
local songCardMap = {}
for i, song in ipairs(E.MusicDatabase) do
    songCardMap[song.id] = makeSongCard(song, SongsHScroll, i)
end
UI.songCardMap = songCardMap

local seenArtists = {}
local artistIdx = 0
for _, song in ipairs(E.MusicDatabase) do
    if not seenArtists[song.artist] then
        seenArtists[song.artist] = true
        artistIdx = artistIdx + 1
        local col = E.ARTIST_COLORS[((artistIdx-1)%#E.ARTIST_COLORS)+1]
        makeArtistCard(song.artist, col, ArtistHScroll, artistIdx)
    end
end

-- ============================================================
--  SEARCH PAGE
-- ============================================================
local SearchPage, SearchScroll = makePage("SearchPage")
UI.SearchPage   = SearchPage
UI.SearchScroll = SearchScroll

-- Fixed search bar row (outside scroll)
local SearchBarRow = Instance.new("Frame", SearchPage)
SearchBarRow.Name = "SearchBarRow"
SearchBarRow.Size = UDim2.new(1,0,0,56)
SearchBarRow.BackgroundTransparency = 1
SearchBarRow.ZIndex = 14

local SearchBar = Instance.new("Frame", SearchBarRow)
SearchBar.AnchorPoint      = Vector2.new(0.5,0.5)
SearchBar.Position         = UDim2.new(0.5,0,0.5,0)
SearchBar.Size             = UDim2.new(1,-28,0,38)
SearchBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
SearchBar.BackgroundTransparency = 0.55
SearchBar.BorderSizePixel  = 0
SearchBar.ZIndex           = 15
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(1,0)

-- Loader.lua-style focus gradient (blue → purple)
local SearchGrad = Instance.new("UIGradient", SearchBar)
SearchGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 59, 95)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 32, 124))
}
SearchGrad.Offset  = Vector2.new(-0.5, 0)
SearchGrad.Enabled = false
UI.SearchGrad = SearchGrad

-- Search icon (magnifier)
local SearchIcon = Instance.new("ImageLabel", SearchBar)
SearchIcon.AnchorPoint        = Vector2.new(0,0.5)
SearchIcon.Position           = UDim2.new(0,10,0.5,0)
SearchIcon.Size               = UDim2.fromOffset(16,16)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image              = "rbxassetid://11293977875"
SearchIcon.ImageColor3        = Color3.new(1,1,1)
SearchIcon.ImageTransparency  = 0.45
SearchIcon.ScaleType          = Enum.ScaleType.Fit
SearchIcon.ZIndex             = 16

-- TextBox
local SearchBox = Instance.new("TextBox", SearchBar)
SearchBox.Position        = UDim2.new(0,34,0,0)
SearchBox.Size            = UDim2.new(1,-70,1,0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Songs, artists, albums..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(155,155,170)
SearchBox.Text            = ""
SearchBox.TextColor3      = Color3.new(1,1,1)
SearchBox.Font            = Enum.Font.Gotham
SearchBox.TextSize        = 14
SearchBox.TextXAlignment  = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex          = 16
UI.SearchBox = SearchBox

-- Clear button
local SearchClearBtn = Instance.new("ImageButton", SearchBar)
SearchClearBtn.AnchorPoint = Vector2.new(1,0.5)
SearchClearBtn.Position    = UDim2.fromScale(1,0.5)
SearchClearBtn.Size        = UDim2.fromOffset(36,36)
SearchClearBtn.BackgroundTransparency = 1
SearchClearBtn.AutoButtonColor = false
SearchClearBtn.ZIndex      = 16
local SearchClearIco = Instance.new("ImageLabel", SearchClearBtn)
SearchClearIco.AnchorPoint = Vector2.new(0.5,0.5)
SearchClearIco.Position    = UDim2.fromScale(0.5,0.5)
SearchClearIco.Size        = UDim2.fromOffset(13,13)
SearchClearIco.BackgroundTransparency = 1
SearchClearIco.Image       = "rbxassetid://11293981586"
SearchClearIco.ImageColor3 = Color3.new(1,1,1)
SearchClearIco.ImageTransparency = 0.4
SearchClearIco.ScaleType   = Enum.ScaleType.Fit
local SearchClearScale = Instance.new("UIScale", SearchClearIco)
SearchClearScale.Scale = 0
UI.SearchClearScale = SearchClearScale

-- Scroll area starts below the search bar
assert(SearchScroll, "[Exvibe] SearchScroll is nil – makePage failed")
SearchScroll.Size     = UDim2.new(1,0,1,-56)
SearchScroll.Position = UDim2.new(0,0,0,56)

-- "Recommended for you" horizontal section
local RecoSec, RecoHScroll = makeHSection("Recommended for you", 162, 1, SearchScroll)
UI.RecoSec     = RecoSec
UI.RecoHScroll = RecoHScroll

-- Search results section (shown while typing)
local ResultsSec = Instance.new("Frame", SearchScroll)
ResultsSec.Name = "ResultsSec"
ResultsSec.Size = UDim2.new(1,0,0,0)
ResultsSec.BackgroundTransparency = 1
ResultsSec.BorderSizePixel = 0
ResultsSec.LayoutOrder = 2
ResultsSec.AutomaticSize = Enum.AutomaticSize.Y
ResultsSec.Visible = false
ResultsSec.ZIndex = 12

local ResultsTitle = Instance.new("TextLabel", ResultsSec)
ResultsTitle.Size = UDim2.new(1,0,0,24)
ResultsTitle.BackgroundTransparency = 1
ResultsTitle.Text = "Results"
ResultsTitle.TextColor3 = C.text
ResultsTitle.Font = Enum.Font.GothamBold
ResultsTitle.TextSize = 14
ResultsTitle.TextXAlignment = Enum.TextXAlignment.Left
ResultsTitle.ZIndex = 13

local ResultsList = Instance.new("Frame", ResultsSec)
ResultsList.Name = "ResultsList"
ResultsList.Position = UDim2.new(0,0,0,28)
ResultsList.Size = UDim2.new(1,0,0,0)
ResultsList.BackgroundTransparency = 1
ResultsList.AutomaticSize = Enum.AutomaticSize.Y
ResultsList.ZIndex = 12
local RLL = Instance.new("UIListLayout", ResultsList)
RLL.Padding = UDim.new(0,6)
RLL.SortOrder = Enum.SortOrder.LayoutOrder
UI.ResultsSec  = ResultsSec
UI.ResultsList = ResultsList

-- Populate "Recommended for you" with DB songs
local recoCardMap = {}
for i, song in ipairs(E.MusicDatabase) do
    recoCardMap[song.id] = makeSongCard(song, RecoHScroll, i)
end
UI.recoCardMap = recoCardMap

-- Focus gradient animation (Loader.lua style – sliding shift)
local searchGradTween = nil
SearchBox.Focused:Connect(function()
    SearchGrad.Enabled = true
    SearchGrad.Offset  = Vector2.new(-0.5,0)
    if searchGradTween then searchGradTween:Cancel() end
    searchGradTween = TweenService:Create(
        SearchGrad,
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.5,0) }
    )
    searchGradTween:Play()
    TweenService:Create(SearchBar, TweenInfo.new(0.25), {
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.new(1,1,1)
    }):Play()
end)
SearchBox.FocusLost:Connect(function()
    if searchGradTween then searchGradTween:Cancel(); searchGradTween = nil end
    SearchGrad.Enabled = false
    TweenService:Create(SearchBar, TweenInfo.new(0.25), {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.55
    }):Play()
end)

-- Clear button
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local has = SearchBox.Text ~= ""
    TweenService:Create(SearchClearScale, TweenInfo.new(0.15), { Scale = has and 1.0 or 0 }):Play()
end)
SearchClearBtn.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    SearchBox:ReleaseFocus()
end)

-- Live search
local function makeResultRow(song, parent, order)
    local row = Instance.new("TextButton", parent)
    row.Name = "ResRow_"..song.id
    row.Size = UDim2.new(1,0,0,52)
    row.LayoutOrder = order
    row.BackgroundColor3 = C.card
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.ZIndex = 13
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0,40,0,40)
    thumb.Position = UDim2.new(0,6,0.5,-20)
    thumb.BackgroundColor3 = C.cardHover
    thumb.BorderSizePixel = 0
    thumb.Image = song.cover
    thumb.ZIndex = 14
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(0,6)

    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-100,0,14)
    tl.Position = UDim2.new(0,54,0.5,-15)
    tl.BackgroundTransparency = 1
    tl.Text = song.title
    tl.TextColor3 = C.text
    tl.Font = Enum.Font.GothamSemibold
    tl.TextSize = 12
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextTruncate = Enum.TextTruncate.AtEnd
    tl.ZIndex = 14

    local al = Instance.new("TextLabel", row)
    al.Size = UDim2.new(1,-100,0,11)
    al.Position = UDim2.new(0,54,0.5,2)
    al.BackgroundTransparency = 1
    al.Text = song.artist .. "  •  " .. (song.genre or "")
    al.TextColor3 = C.subText
    al.Font = Enum.Font.Gotham
    al.TextSize = 10
    al.TextXAlignment = Enum.TextXAlignment.Left
    al.TextTruncate = Enum.TextTruncate.AtEnd
    al.ZIndex = 14

    row.MouseEnter:Connect(function() E.tween(row,{BackgroundColor3=C.cardHover},0.12) end)
    row.MouseLeave:Connect(function() E.tween(row,{BackgroundColor3=C.card},0.12) end)
    row.MouseButton1Click:Connect(function()
        local wasOpen = E.State.nowPlayingOpen
        if E.playSong then E.playSong(song) end
        if E.openNowPlaying then
            E.openNowPlaying(song)
            if E.animateCoverFly then
                E.animateCoverFly(thumb.AbsolutePosition, thumb.AbsoluteSize, song, wasOpen)
            end
        end
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(SearchBox.Text)
    for _, ch in ipairs(ResultsList:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    if q == "" then
        ResultsSec.Visible = false
        RecoSec.Visible    = true
        return
    end
    ResultsSec.Visible = true
    RecoSec.Visible    = false
    local idx = 0
    for _, song in ipairs(E.MusicDatabase) do
        local m = string.find(string.lower(song.title),  q, 1, true)
               or string.find(string.lower(song.artist), q, 1, true)
               or (song.genre and string.find(string.lower(song.genre), q, 1, true))
        if m then
            idx = idx + 1
            makeResultRow(song, ResultsList, idx)
        end
    end
    if idx == 0 then
        local nl = Instance.new("TextLabel", ResultsList)
        nl.Size = UDim2.new(1,0,0,36)
        nl.BackgroundTransparency = 1
        nl.Text = "No results for \"" .. SearchBox.Text .. "\""
        nl.TextColor3 = C.subText
        nl.Font = Enum.Font.Gotham
        nl.TextSize = 12
        nl.ZIndex = 13
    end
end)

-- ============================================================
--  LIBRARY PAGE
-- ============================================================
local LibraryPage, LibraryScroll = makePage("LibraryPage")
UI.LibraryPage   = LibraryPage
UI.LibraryScroll = LibraryScroll

local LibHeaderRow = Instance.new("Frame", LibraryScroll)
LibHeaderRow.Size = UDim2.new(1,0,0,30)
LibHeaderRow.BackgroundTransparency = 1
LibHeaderRow.LayoutOrder = 0
LibHeaderRow.ZIndex = 12

local LibHeaderLbl = Instance.new("TextLabel", LibHeaderRow)
LibHeaderLbl.Size = UDim2.new(1,0,1,0)
LibHeaderLbl.BackgroundTransparency = 1
LibHeaderLbl.Text = "Your Library"
LibHeaderLbl.TextColor3 = C.text
LibHeaderLbl.Font = Enum.Font.GothamBold
LibHeaderLbl.TextSize = 14
LibHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
LibHeaderLbl.ZIndex = 13
UI.LibHeaderLbl = LibHeaderLbl

local LibList = Instance.new("Frame", LibraryScroll)
LibList.Name = "LibList"
LibList.Size = UDim2.new(1,0,0,0)
LibList.BackgroundTransparency = 1
LibList.BorderSizePixel = 0
LibList.AutomaticSize = Enum.AutomaticSize.Y
LibList.LayoutOrder = 1
LibList.ZIndex = 12
local LibLL = Instance.new("UIListLayout", LibList)
LibLL.Padding = UDim.new(0,6)
LibLL.SortOrder = Enum.SortOrder.LayoutOrder
UI.LibList = LibList

local LibEmptyLbl = Instance.new("TextLabel", LibraryScroll)
LibEmptyLbl.Name = "LibEmptyLbl"
LibEmptyLbl.Size = UDim2.new(1,0,0,100)
LibEmptyLbl.BackgroundTransparency = 1
LibEmptyLbl.LayoutOrder = 2
LibEmptyLbl.Text = "Your library is empty.\nAdd songs via the context menu."
LibEmptyLbl.TextColor3 = C.subText
LibEmptyLbl.Font = Enum.Font.Gotham
LibEmptyLbl.TextSize = 12
LibEmptyLbl.TextWrapped = true
LibEmptyLbl.ZIndex = 13
UI.LibEmptyLbl = LibEmptyLbl

-- Library row builder
local function makeLibRow(song, layoutOrder)
    local row = Instance.new("TextButton", LibList)
    row.Name = "LibRow_"..song.id
    row.Size = UDim2.new(1,0,0,54)
    row.LayoutOrder = layoutOrder
    row.BackgroundColor3 = C.card
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.ZIndex = 13
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0,42,0,42)
    thumb.Position = UDim2.new(0,6,0.5,-21)
    thumb.BackgroundColor3 = C.cardHover
    thumb.BorderSizePixel = 0
    thumb.Image = song.cover
    thumb.ZIndex = 14
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(0,6)

    local titleLbl = Instance.new("TextLabel", row)
    titleLbl.Size = UDim2.new(1,-100,0,14)
    titleLbl.Position = UDim2.new(0,56,0.5,-16)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = song.title
    titleLbl.TextColor3 = C.text
    titleLbl.Font = Enum.Font.GothamSemibold
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.ZIndex = 14

    local artistLbl = Instance.new("TextLabel", row)
    artistLbl.Size = UDim2.new(1,-100,0,11)
    artistLbl.Position = UDim2.new(0,56,0.5,2)
    artistLbl.BackgroundTransparency = 1
    artistLbl.Text = song.artist
    artistLbl.TextColor3 = C.subText
    artistLbl.Font = Enum.Font.Gotham
    artistLbl.TextSize = 10
    artistLbl.TextXAlignment = Enum.TextXAlignment.Left
    artistLbl.TextTruncate = Enum.TextTruncate.AtEnd
    artistLbl.ZIndex = 14

    local durLbl = Instance.new("TextLabel", row)
    durLbl.Size = UDim2.new(0,40,1,0)
    durLbl.Position = UDim2.new(1,-46,0,0)
    durLbl.BackgroundTransparency = 1
    durLbl.Text = E.formatTime(song.duration)
    durLbl.TextColor3 = C.subText
    durLbl.Font = Enum.Font.Gotham
    durLbl.TextSize = 10
    durLbl.ZIndex = 14

    row.MouseEnter:Connect(function() E.tween(row,{BackgroundColor3=C.cardHover},0.12) end)
    row.MouseLeave:Connect(function() E.tween(row,{BackgroundColor3=C.card},0.12) end)
    row.MouseButton1Click:Connect(function()
        local wasOpen = E.State.nowPlayingOpen
        if E.playSong then E.playSong(song) end
        if E.openNowPlaying then
            E.openNowPlaying(song)
            if E.animateCoverFly then
                E.animateCoverFly(thumb.AbsolutePosition, thumb.AbsoluteSize, song, wasOpen)
            end
        end
    end)
    return row
end
E.makeLibRow = makeLibRow

function E.rebuildLibrary()
    for _, ch in ipairs(LibList:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local count = #E.State.library
    LibEmptyLbl.Visible = (count == 0)
    LibHeaderLbl.Text   = "Your Library" .. (count > 0 and ("  (" .. count .. ")") or "")
    for i, song in ipairs(E.State.library) do
        makeLibRow(song, i)
    end
end
E.rebuildLibrary()

-- ============================================================
--  PLAYER BAR
-- ============================================================
local PlayerBar = Instance.new("Frame", MainFrame)
PlayerBar.Name             = "PlayerBar"
PlayerBar.Size             = UDim2.new(1,0,0,BAR_H)
PlayerBar.Position         = UDim2.new(0,0,1,-BAR_H)
PlayerBar.BackgroundColor3 = C.playerBg
PlayerBar.BorderSizePixel  = 0
PlayerBar.ZIndex           = 20
-- Bottom corners rounded by adding UICorner – top covered by ContentClip
local PBCorner = Instance.new("UICorner", PlayerBar)
PBCorner.CornerRadius = UDim.new(0,20)
-- Square off top corners with a fill strip
local PBTopFill = Instance.new("Frame", PlayerBar)
PBTopFill.Size             = UDim2.new(1,0,0,22)
PBTopFill.BackgroundColor3 = C.playerBg
PBTopFill.BorderSizePixel  = 0
PBTopFill.ZIndex           = 20
UI.PlayerBar = PlayerBar

local ProgBg = Instance.new("Frame", PlayerBar)
ProgBg.Size             = UDim2.new(1,0,0,2)
ProgBg.BackgroundColor3 = C.border
ProgBg.BorderSizePixel  = 0
ProgBg.ZIndex           = 15
local ProgFill = Instance.new("Frame", ProgBg)
ProgFill.Size             = UDim2.new(0,0,1,0)
ProgFill.BackgroundColor3 = Color3.new(1,1,1)
ProgFill.BorderSizePixel  = 0
ProgFill.ZIndex           = 16
Instance.new("UICorner", ProgFill).CornerRadius = UDim.new(1,0)
UI.ProgFill = ProgFill

local ProfileAvatar = Instance.new("ImageLabel", PlayerBar)
ProfileAvatar.Size             = UDim2.new(0,26,0,26)
ProfileAvatar.Position         = UDim2.new(0,10,0.5,-13)
ProfileAvatar.BackgroundColor3 = C.accentBlue
ProfileAvatar.BorderSizePixel  = 0
ProfileAvatar.ZIndex           = 15
Instance.new("UICorner", ProfileAvatar).CornerRadius = UDim.new(1,0)

local ProfileName = Instance.new("TextLabel", PlayerBar)
ProfileName.Size             = UDim2.new(0,SIDEBAR_W-46,0,14)
ProfileName.Position         = UDim2.new(0,42,0.5,-7)
ProfileName.BackgroundTransparency = 1
ProfileName.Text             = LocalPlayer.DisplayName
ProfileName.TextColor3       = C.text
ProfileName.Font             = Enum.Font.GothamSemibold
ProfileName.TextSize         = 10
ProfileName.TextXAlignment   = Enum.TextXAlignment.Left
ProfileName.TextTruncate     = Enum.TextTruncate.AtEnd
ProfileName.ZIndex           = 15

task.spawn(function()
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100)
    end)
    if ok and thumb then ProfileAvatar.Image = thumb end
end)

local PlayerThumb = Instance.new("ImageLabel", PlayerBar)
PlayerThumb.Size             = UDim2.new(0,34,0,34)
PlayerThumb.Position         = UDim2.new(0,SIDEBAR_W+8,0.5,-17)
PlayerThumb.BackgroundColor3 = C.card
PlayerThumb.BorderSizePixel  = 0
PlayerThumb.ZIndex           = 15
Instance.new("UICorner", PlayerThumb).CornerRadius = UDim.new(0,6)
UI.PlayerThumb = PlayerThumb

local PlayerTitle = Instance.new("TextLabel", PlayerBar)
PlayerTitle.Size             = UDim2.new(0,118,0,14)
PlayerTitle.Position         = UDim2.new(0,SIDEBAR_W+48,0.5,-9)
PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Text             = "Not Playing"
PlayerTitle.TextColor3       = C.text
PlayerTitle.Font             = Enum.Font.GothamSemibold
PlayerTitle.TextSize         = 11
PlayerTitle.TextXAlignment   = Enum.TextXAlignment.Left
PlayerTitle.TextTruncate     = Enum.TextTruncate.AtEnd
PlayerTitle.ZIndex           = 15
UI.PlayerTitle = PlayerTitle

local PlayerArtist = Instance.new("TextLabel", PlayerBar)
PlayerArtist.Size             = UDim2.new(0,118,0,12)
PlayerArtist.Position         = UDim2.new(0,SIDEBAR_W+48,0.5,5)
PlayerArtist.BackgroundTransparency = 1
PlayerArtist.Text             = "-"
PlayerArtist.TextColor3       = C.subText
PlayerArtist.Font             = Enum.Font.Gotham
PlayerArtist.TextSize         = 9
PlayerArtist.TextXAlignment   = Enum.TextXAlignment.Left
PlayerArtist.ZIndex           = 15
UI.PlayerArtist = PlayerArtist

local CTRL_CX = SIDEBAR_W + math.floor((FRAME_W - SIDEBAR_W) * 0.5)

local PBAR_ASSET_PREV  = "rbxassetid://72693785960426"
local PBAR_ASSET_PAUSE = "rbxassetid://97751235710224"
local PBAR_ASSET_PLAY  = "rbxassetid://72396954315758"
local PBAR_ASSET_NEXT  = "rbxassetid://111765560089071"

local function makeCtrlImg(assetId, absXOff, sz)
    sz = sz or 32
    local b = Instance.new("TextButton", PlayerBar)
    b.Size = UDim2.new(0,sz,0,sz)
    b.Position = UDim2.new(0, CTRL_CX + absXOff - math.floor(sz/2), 0.5, -math.floor(sz/2))
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Text = ""
    b.ZIndex = 15
    local img = Instance.new("ImageLabel", b)
    img.Size = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.Image = assetId
    img.ImageColor3 = C.text
    img.ZIndex = 16
    b.MouseButton1Down:Connect(function() E.tween(img,{ImageTransparency=0.45},0.07) end)
    b.MouseButton1Up:Connect(function()   E.tween(img,{ImageTransparency=0},0.12)    end)
    return b, img
end

local BtnPrev, _             = makeCtrlImg(PBAR_ASSET_PREV,  -56, 32)
local BtnPlay, BtnPlayImg    = makeCtrlImg(PBAR_ASSET_PLAY,    0, 36)  -- starts as Play icon
local BtnNext, _             = makeCtrlImg(PBAR_ASSET_NEXT,   56, 32)

-- Second image on BtnPlay for pause state (hidden by default)
local BtnPlayPauseImg = Instance.new("ImageLabel", BtnPlay)
BtnPlayPauseImg.Size = UDim2.new(1,0,1,0)
BtnPlayPauseImg.BackgroundTransparency = 1
BtnPlayPauseImg.Image = PBAR_ASSET_PAUSE
BtnPlayPauseImg.ImageColor3 = C.text
BtnPlayPauseImg.ZIndex = 17
BtnPlayPauseImg.Visible = false

UI.BtnPrev = BtnPrev
UI.BtnPlay = BtnPlay
UI.BtnPlayImg = BtnPlayImg          -- play/resume icon
UI.BtnPlayPauseImg = BtnPlayPauseImg -- pause icon
UI.BtnNext = BtnNext

function E.updatePlayerBar(song)
    if not song then return end
    UI.PlayerTitle.Text  = song.title
    UI.PlayerArtist.Text = song.artist
    UI.PlayerThumb.Image = song.cover or ""
    -- Switch to pause icon (song just started playing)
    if UI.BtnPlayImg then UI.BtnPlayImg.Visible = false end
    if UI.BtnPlayPauseImg then UI.BtnPlayPauseImg.Visible = true end
end

function E.rebuildSongs()
    for _, ch in ipairs(UI.SongsHScroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    UI.songCardMap = {}
    for i, song in ipairs(E.MusicDatabase) do
        local card = makeSongCard(song, UI.SongsHScroll, i)
        UI.songCardMap[song.id] = card
    end
    if E.connectSongCard then
        for songId, card in pairs(UI.songCardMap) do
            E.connectSongCard(songId, card)
        end
    end
end

print("[Exvibe] UI_Main loaded")
