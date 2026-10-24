--[[
    Sterling Engine BETA
    Ride A Pet menu
    - Gray / white pulsing gradient
    - Phone friendly drag + resize
    - Opens in the center, then auto-saves menu and icon position
    - Minimize becomes an S icon
    - Menu cannot leave the screen
    Main: Speed, Auto Volcanic Dip, egg ESP, Fly / Instant Steal
]]

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local OWNER_IDS = {
    -- [8605387982] = true,
}
local IS_OWNER = OWNER_IDS[LocalPlayer.UserId] == true

local TITLE_PREFIX = "Sterling Engine BETA"
local PLACE_NAME = "Place"

--========================= UNLOAD OLD =========================--
if _G.SterlingEngine and _G.SterlingEngine.Unload then
    pcall(_G.SterlingEngine.Unload)
end

local Alive = true
local Connections = {}
local function on(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Connections, conn)
    return conn
end

--========================= SAVE =========================--
local SAVE_DIR = "SterlingEngine"
local LAYOUT_FILE = SAVE_DIR .. "/layout.json"
local CHAT_FILE = SAVE_DIR .. "/chat.json"
local OLD_LAYOUT = "SterlingEngine_layout.json"

local function hasFileApi()
    return writefile ~= nil and readfile ~= nil and isfile ~= nil
end

local function ensureDir()
    if not hasFileApi() then return end
    if isfolder and makefolder then
        pcall(function()
            if not isfolder(SAVE_DIR) then
                makefolder(SAVE_DIR)
            end
        end)
    end
end

local function readJson(path)
    if not hasFileApi() or not isfile(path) then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local function writeJson(path, data)
    if not hasFileApi() then return end
    ensureDir()
    pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
end

local function saveLayout(data)
    writeJson(LAYOUT_FILE, data)
end

local function loadLayout()
    local data = readJson(LAYOUT_FILE)
    if data then return data end
    data = readJson(OLD_LAYOUT)
    if data then
        saveLayout(data)
    end
    return data
end

--========================= EGG DATA =========================--
local EGG_DB = {
    ["White Egg"]    = { Rarity = "Common",    Luck = 1 },
    ["Brown Egg"]    = { Rarity = "Common",    Luck = 5 },
    ["Cracked Egg"]  = { Rarity = "Rare",      Luck = 30 },
    ["Easter Egg"]   = { Rarity = "Rare",      Luck = 50 },
    ["Stone Egg"]    = { Rarity = "Rare",      Luck = 100 },
    ["Leaf Egg"]     = { Rarity = "Rare",      Luck = 200 },
    ["Mushroom Egg"] = { Rarity = "Epic",      Luck = 500 },
    ["Flower Egg"]   = { Rarity = "Epic",      Luck = 750 },
    ["Slime Egg"]    = { Rarity = "Epic",      Luck = 1000 },
    ["Ice Egg"]      = { Rarity = "Epic",      Luck = 3000 },
    ["Glass Egg"]    = { Rarity = "Legendary", Luck = 10000 },
    ["Golden Egg"]   = { Rarity = "Legendary", Luck = 30000 },
    ["Diamond Egg"]  = { Rarity = "Mythic",    Luck = 90000 },
    ["Crystal Egg"]  = { Rarity = "Mythic",    Luck = 150000 },
    ["Skull Egg"]    = { Rarity = "Mythic",    Luck = 250000 },
    ["Asteroid Egg"] = { Rarity = "Mythic",    Luck = 500000 },
    ["Dominus Egg"]  = { Rarity = "Mythic",    Luck = 700000 },
    ["Flaming Egg"]  = { Rarity = "Mythic",    Luck = 1000000 },
    ["Sinister Egg"] = { Rarity = "Mythic",    Luck = 3000000 },
    ["Soul Egg"]     = { Rarity = "Mythic",    Luck = 7000000 },
    ["Tidal Egg"]    = { Rarity = "Mythic",    Luck = 8000000 },
    ["Aurora Egg"]   = { Rarity = "Divine",    Luck = 300000000 },
    ["Galaxy Egg"]   = { Rarity = "Divine",    Luck = 1500000000 },
    ["Bloom Egg"]    = { Rarity = "Divine",    Luck = 2000000000 },
    ["Black Hole Egg"] = { Rarity = "Ethereal", Luck = 210000000000 },
    ["Blackhole Egg"]  = { Rarity = "Ethereal", Luck = 210000000000 },
    ["Solaris Egg"]    = { Rarity = "Ethereal", Luck = 363000000000 },
    ["Cherub Egg"]     = { Rarity = "Ethereal", Luck = 1000000000000 },
    ["Volcanic Egg"]   = { Rarity = "Ethereal", Luck = 2500000000000 },
    ["Halloween Egg"]  = { Rarity = "Event",    Luck = 0 },
}

local RARITY_ORDER = {
    Common = 1, Rare = 2, Epic = 3, Legendary = 4,
    Mythic = 5, Divine = 6, Ethereal = 7, Event = 8, Unknown = 0,
}

local RARITY_COLOR = {
    Common    = Color3.fromRGB(214, 214, 214),
    Rare      = Color3.fromRGB(150, 196, 230),
    Epic      = Color3.fromRGB(196, 170, 230),
    Legendary = Color3.fromRGB(230, 214, 160),
    Mythic    = Color3.fromRGB(230, 170, 186),
    Divine    = Color3.fromRGB(236, 230, 196),
    Ethereal  = Color3.fromRGB(176, 230, 214),
    Event     = Color3.fromRGB(255, 255, 255),
    Unknown   = Color3.fromRGB(180, 180, 180),
}

local EggsData, GeneralData, PetsData, PetAging, FoodData
local GameRemotes
local ActiveEggs
local EggPickup
local BasketDrop

task.spawn(function()
    local gameData = ReplicatedStorage:WaitForChild("GameData", 12)
    local gameServices = ReplicatedStorage:FindFirstChild("GameServices")
    if gameData then
        pcall(function() EggsData = require(gameData:WaitForChild("Eggs", 8)) end)
        pcall(function() GeneralData = require(gameData:WaitForChild("General", 8)) end)
        pcall(function() PetsData = require(gameData:WaitForChild("Pets", 8)) end)
        for _, foodName in ipairs({ "Food", "Foods", "FoodData", "Items" }) do
            local foodModule = gameData:FindFirstChild(foodName)
            if foodModule and foodModule:IsA("ModuleScript") then
                local ok, data = pcall(require, foodModule)
                if ok and type(data) == "table" then
                    FoodData = data
                    break
                end
            end
        end
    end
    if gameServices then
        pcall(function() PetAging = require(gameServices:WaitForChild("PetAging", 8)) end)
    end
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 12)
    if remotes then
        GameRemotes = remotes:WaitForChild("Game", 8)
        if GameRemotes then
            EggPickup = GameRemotes:FindFirstChild("EggPickup")
            BasketDrop = GameRemotes:FindFirstChild("BasketDrop")
        end
    end
    ActiveEggs = ReplicatedStorage:WaitForChild("ServerData", 12)
    ActiveEggs = ActiveEggs and ActiveEggs:FindFirstChild("ActiveEggs") or ActiveEggs
end)

--========================= GUI ROOT =========================--
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = PlayerGui:FindFirstChild("SterlingEngineGui")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SterlingEngineGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 500
ScreenGui.Parent = PlayerGui

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(180, 180, 180)
    s.Thickness = thickness or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft = UDim.new(0, px)
    p.PaddingRight = UDim.new(0, px)
    p.Parent = parent
    return p
end

local function getScreenSize()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1280, 720)
end

--========================= WINDOW =========================--
local DEFAULT_SIZE = Vector2.new(640, 420)
local MIN_SIZE = Vector2.new(390, 280)
local menuPos = Vector2.new(0, 0)
local iconPos = Vector2.new(18, 80)
local menuSize = DEFAULT_SIZE

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0, 0)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Size = UDim2.fromOffset(DEFAULT_SIZE.X, DEFAULT_SIZE.Y)
Main.Position = UDim2.fromOffset(0, 0)
Main.Parent = ScreenGui
corner(Main, 16)

local mainStroke = stroke(Main, Color3.fromRGB(210, 210, 210), 1.6, 0.15)
local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
strokeGradient.Parent = mainStroke

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 14)),
})
bgGradient.Rotation = 90
bgGradient.Parent = Main

local function applyMenuPos(x, y)
    local vp = getScreenSize()
    local size = Main.AbsoluteSize
    local w = size.X > 20 and size.X or menuSize.X
    local h = size.Y > 20 and size.Y or menuSize.Y
    x = math.clamp(x, 0, math.max(0, vp.X - w))
    y = math.clamp(y, 0, math.max(0, vp.Y - h))
    menuPos = Vector2.new(x, y)
    Main.Position = UDim2.fromOffset(x, y)
end

local function applyMenuSize(w, h)
    local vp = getScreenSize()
    w = math.clamp(w, math.min(MIN_SIZE.X, vp.X), vp.X)
    h = math.clamp(h, math.min(MIN_SIZE.Y, vp.Y), vp.Y)
    w = math.min(w, math.max(MIN_SIZE.X, vp.X - menuPos.X))
    h = math.min(h, math.max(MIN_SIZE.Y, vp.Y - menuPos.Y))
    menuSize = Vector2.new(w, h)
    Main.Size = UDim2.fromOffset(w, h)
end

--========================= TOP BAR =========================--
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
TopBar.BackgroundTransparency = 0.15
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.ClipsDescendants = true
TopBar.Active = true
TopBar.Parent = Main
corner(TopBar, 16)

local topFix = Instance.new("Frame")
topFix.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
topFix.BackgroundTransparency = 0.15
topFix.BorderSizePixel = 0
topFix.Size = UDim2.new(1, 0, 0, 16)
topFix.Position = UDim2.new(0, 0, 1, -16)
topFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Size = UDim2.new(1, -250, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = TITLE_PREFIX .. "  |  " .. PLACE_NAME
Title.Active = false
Title.Parent = TopBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
titleGradient.Parent = Title

local DragZone = Instance.new("TextButton")
DragZone.Name = "DragZone"
DragZone.BackgroundTransparency = 1
DragZone.Text = ""
DragZone.AutoButtonColor = false
DragZone.Size = UDim2.new(1, -250, 1, 0)
DragZone.ZIndex = 2
DragZone.Parent = TopBar

local Search = Instance.new("TextBox")
Search.AnchorPoint = Vector2.new(1, 0.5)
Search.Position = UDim2.new(1, -92, 0.5, 0)
Search.Size = UDim2.fromOffset(140, 30)
Search.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
Search.BorderSizePixel = 0
Search.Font = Enum.Font.Gotham
Search.PlaceholderText = "Search"
Search.Text = ""
Search.TextColor3 = Color3.fromRGB(230, 230, 230)
Search.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
Search.TextSize = 14
Search.TextXAlignment = Enum.TextXAlignment.Left
Search.ClearTextOnFocus = false
Search.ClipsDescendants = true
Search.ZIndex = 3
Search.Parent = TopBar
corner(Search, 8)
pad(Search, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.AnchorPoint = Vector2.new(1, 0.5)
MinBtn.Position = UDim2.new(1, -50, 0.5, 0)
MinBtn.Size = UDim2.fromOffset(30, 30)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinBtn.TextSize = 24
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
CloseBtn.TextSize = 16
CloseBtn.ZIndex = 4
CloseBtn.Parent = TopBar

--========================= BODY / FOOTER =========================--
local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Position = UDim2.new(0, 0, 0, 50)
Body.Size = UDim2.new(1, 0, 1, -90)
Body.ClipsDescendants = true
Body.Parent = Main

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Sidebar.BackgroundTransparency = 0.35
Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 168, 1, 0)
Sidebar.CanvasSize = UDim2.new()
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.ScrollBarThickness = 3
Sidebar.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
Sidebar.ClipsDescendants = true
Sidebar.Parent = Body

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 6)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = Sidebar
pad(Sidebar, 10)

local Divider = Instance.new("Frame")
Divider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Divider.BackgroundTransparency = 0.35
Divider.BorderSizePixel = 0
Divider.Position = UDim2.new(0, 168, 0, 8)
Divider.Size = UDim2.new(0, 1, 1, -16)
Divider.Parent = Body

local Content = Instance.new("ScrollingFrame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 176, 0, 0)
Content.Size = UDim2.new(1, -184, 1, 0)
Content.CanvasSize = UDim2.new()
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
Content.ClipsDescendants = true
Content.Parent = Body

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = Content
pad(Content, 12)

local Footer = Instance.new("Frame")
Footer.BackgroundTransparency = 1
Footer.Position = UDim2.new(0, 0, 1, -40)
Footer.Size = UDim2.new(1, 0, 0, 40)
Footer.ClipsDescendants = true
Footer.Parent = Main

local Avatar = Instance.new("ImageLabel")
Avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
Avatar.AnchorPoint = Vector2.new(0, 0.5)
Avatar.Position = UDim2.new(0, 12, 0.5, 0)
Avatar.Size = UDim2.fromOffset(26, 26)
Avatar.Parent = Footer
corner(Avatar, 13)
task.spawn(function()
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and Avatar.Parent then
        Avatar.Image = thumb
    end
end)

local Welcome = Instance.new("TextLabel")
Welcome.BackgroundTransparency = 1
Welcome.Position = UDim2.new(0, 46, 0, 0)
Welcome.Size = UDim2.new(1, -250, 1, 0)
Welcome.Font = Enum.Font.Gotham
Welcome.TextSize = 14
Welcome.TextXAlignment = Enum.TextXAlignment.Left
Welcome.TextTruncate = Enum.TextTruncate.AtEnd
Welcome.TextColor3 = Color3.fromRGB(220, 220, 220)
Welcome.Text = "Welcome, " .. LocalPlayer.DisplayName
Welcome.Parent = Footer

local FpsLabel = Instance.new("TextLabel")
FpsLabel.AnchorPoint = Vector2.new(1, 0.5)
FpsLabel.Position = UDim2.new(1, -112, 0.5, 0)
FpsLabel.Size = UDim2.fromOffset(78, 26)
FpsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
FpsLabel.Font = Enum.Font.GothamSemibold
FpsLabel.TextSize = 13
FpsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
FpsLabel.Text = "0 FPS"
FpsLabel.Parent = Footer
corner(FpsLabel, 8)

local TagLabel = Instance.new("TextLabel")
TagLabel.AnchorPoint = Vector2.new(1, 0.5)
TagLabel.Position = UDim2.new(1, -28, 0.5, 0)
TagLabel.Size = UDim2.fromOffset(76, 26)
TagLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
TagLabel.Font = Enum.Font.GothamSemibold
TagLabel.TextSize = 13
TagLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TagLabel.Text = IS_OWNER and "Owner" or "Free"
TagLabel.Parent = Footer
corner(TagLabel, 8)

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.AnchorPoint = Vector2.new(1, 1)
ResizeHandle.Position = UDim2.new(1, -2, 1, -2)
ResizeHandle.Size = UDim2.fromOffset(22, 22)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text = "//"
ResizeHandle.TextColor3 = Color3.fromRGB(150, 150, 150)
ResizeHandle.TextSize = 14
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.AutoButtonColor = false
ResizeHandle.ZIndex = 6
ResizeHandle.Parent = Main

--========================= S ICON =========================--
local Icon = Instance.new("TextButton")
Icon.Name = "SterlingIcon"
Icon.AnchorPoint = Vector2.new(0, 0)
Icon.Size = UDim2.fromOffset(56, 56)
Icon.Position = UDim2.fromOffset(18, 80)
Icon.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Icon.AutoButtonColor = false
Icon.Font = Enum.Font.GothamBold
Icon.Text = "S"
Icon.TextSize = 26
Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
Icon.Visible = false
Icon.ZIndex = 20
Icon.Parent = ScreenGui
corner(Icon, 16)
local iconStroke = stroke(Icon, Color3.fromRGB(220, 220, 220), 1.6, 0.1)
local iconGradient = Instance.new("UIGradient")
iconGradient.Color = titleGradient.Color
iconGradient.Parent = Icon

local Note = Instance.new("Frame")
Note.Name = "SterlingNote"
Note.AnchorPoint = Vector2.new(0.5, 0)
Note.Position = UDim2.new(0.5, 0, 0, 6)
Note.Size = UDim2.new(0.72, 0, 0, 70)
Note.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
Note.BorderSizePixel = 0
Note.Visible = false
Note.Active = false
Note.ClipsDescendants = true
Note.ZIndex = 40
Note.Parent = ScreenGui
corner(Note, 14)
local noteStroke = stroke(Note, Color3.fromRGB(220, 220, 220), 1.5, 0.08)
local noteGrad = Instance.new("UIGradient")
noteGrad.Color = titleGradient.Color
noteGrad.Parent = noteStroke
local noteCap = Instance.new("UISizeConstraint")
noteCap.MaxSize = Vector2.new(270, 74)
noteCap.Parent = Note

local NoteTitle = Instance.new("TextLabel")
NoteTitle.BackgroundTransparency = 1
NoteTitle.Position = UDim2.fromOffset(8, 3)
NoteTitle.Size = UDim2.new(1, -16, 0, 12)
NoteTitle.Font = Enum.Font.GothamBold
NoteTitle.TextSize = 10
NoteTitle.TextXAlignment = Enum.TextXAlignment.Left
NoteTitle.TextTruncate = Enum.TextTruncate.AtEnd
NoteTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
NoteTitle.Text = TITLE_PREFIX .. "  |  " .. PLACE_NAME
NoteTitle.ZIndex = 41
NoteTitle.Parent = Note
local noteTitleGrad = Instance.new("UIGradient")
noteTitleGrad.Color = titleGradient.Color
noteTitleGrad.Parent = NoteTitle

local NoteView = Instance.new("ViewportFrame")
NoteView.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
NoteView.Position = UDim2.fromOffset(8, 18)
NoteView.Size = UDim2.fromOffset(22, 22)
NoteView.BorderSizePixel = 0
NoteView.Visible = false
NoteView.ZIndex = 41
NoteView.Parent = Note
corner(NoteView, 8)

local NoteIcon = Instance.new("ImageLabel")
NoteIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
NoteIcon.Position = UDim2.fromOffset(8, 18)
NoteIcon.Size = UDim2.fromOffset(22, 22)
NoteIcon.BorderSizePixel = 0
NoteIcon.ScaleType = Enum.ScaleType.Fit
NoteIcon.ZIndex = 42
NoteIcon.Parent = Note
corner(NoteIcon, 8)

local NoteLetter = Instance.new("TextLabel")
NoteLetter.BackgroundTransparency = 1
NoteLetter.Size = UDim2.fromScale(1, 1)
NoteLetter.Font = Enum.Font.GothamBold
NoteLetter.TextSize = 11
NoteLetter.TextColor3 = Color3.fromRGB(20, 20, 20)
NoteLetter.Text = "E"
NoteLetter.ZIndex = 43
NoteLetter.Parent = NoteIcon

local NoteName = Instance.new("TextLabel")
NoteName.BackgroundTransparency = 1
NoteName.Position = UDim2.fromOffset(36, 16)
NoteName.Size = UDim2.new(1, -44, 0, 14)
NoteName.Font = Enum.Font.GothamBold
NoteName.TextSize = 11
NoteName.TextXAlignment = Enum.TextXAlignment.Left
NoteName.TextTruncate = Enum.TextTruncate.AtEnd
NoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
NoteName.Text = ""
NoteName.ZIndex = 41
NoteName.Parent = Note

local NoteMeta = Instance.new("TextLabel")
NoteMeta.BackgroundTransparency = 1
NoteMeta.Position = UDim2.fromOffset(36, 30)
NoteMeta.Size = UDim2.new(1, -44, 0, 12)
NoteMeta.Font = Enum.Font.Gotham
NoteMeta.TextSize = 10
NoteMeta.TextXAlignment = Enum.TextXAlignment.Left
NoteMeta.TextTruncate = Enum.TextTruncate.AtEnd
NoteMeta.TextColor3 = Color3.fromRGB(210, 210, 210)
NoteMeta.Text = ""
NoteMeta.ZIndex = 41
NoteMeta.Parent = Note

local NoteMut = Instance.new("TextLabel")
NoteMut.BackgroundTransparency = 1
NoteMut.Visible = false
NoteMut.Position = UDim2.fromOffset(36, 42)
NoteMut.Size = UDim2.new(1, -44, 0, 12)
NoteMut.Font = Enum.Font.Gotham
NoteMut.TextSize = 12
NoteMut.TextXAlignment = Enum.TextXAlignment.Left
NoteMut.TextTruncate = Enum.TextTruncate.AtEnd
NoteMut.TextColor3 = Color3.fromRGB(185, 185, 185)
NoteMut.Text = ""
NoteMut.ZIndex = 41
NoteMut.Parent = Note

local NoteTraits = Instance.new("TextLabel")
NoteTraits.BackgroundTransparency = 1
NoteTraits.Visible = false
NoteTraits.Position = UDim2.fromOffset(36, 42)
NoteTraits.Size = UDim2.new(1, -44, 0, 12)
NoteTraits.Font = Enum.Font.Gotham
NoteTraits.TextSize = 12
NoteTraits.TextXAlignment = Enum.TextXAlignment.Left
NoteTraits.TextTruncate = Enum.TextTruncate.AtEnd
NoteTraits.TextColor3 = Color3.fromRGB(175, 175, 175)
NoteTraits.Text = ""
NoteTraits.ZIndex = 41
NoteTraits.Parent = Note

local NoteDist = Instance.new("TextLabel")
NoteDist.BackgroundTransparency = 1
NoteDist.Position = UDim2.fromOffset(36, 42)
NoteDist.Size = UDim2.new(1, -44, 0, 12)
NoteDist.Font = Enum.Font.GothamSemibold
NoteDist.TextSize = 10
NoteDist.TextXAlignment = Enum.TextXAlignment.Left
NoteDist.TextTruncate = Enum.TextTruncate.AtEnd
NoteDist.TextColor3 = Color3.fromRGB(230, 230, 230)
NoteDist.Text = "Distance: 0"
NoteDist.ZIndex = 41
NoteDist.Parent = Note

local NoteStatus = Instance.new("TextLabel")
NoteStatus.BackgroundTransparency = 1
NoteStatus.Position = UDim2.fromOffset(36, 54)
NoteStatus.Size = UDim2.new(1, -44, 0, 12)
NoteStatus.Font = Enum.Font.GothamBold
NoteStatus.TextSize = 10
NoteStatus.TextXAlignment = Enum.TextXAlignment.Left
NoteStatus.TextTruncate = Enum.TextTruncate.AtEnd
NoteStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
NoteStatus.Text = "Status: Idle"
NoteStatus.ZIndex = 41
NoteStatus.Parent = Note

local function applyIconPos(x, y)
    local vp = getScreenSize()
    local s = 56
    x = math.clamp(x, 0, math.max(0, vp.X - s))
    y = math.clamp(y, 0, math.max(0, vp.Y - s))
    iconPos = Vector2.new(x, y)
    Icon.Position = UDim2.fromOffset(x, y)
end

local function currentLayout()
    return {
        x = menuPos.X,
        y = menuPos.Y,
        w = menuSize.X,
        h = menuSize.Y,
        ix = iconPos.X,
        iy = iconPos.Y,
    }
end

local function doSave()
    saveLayout(currentLayout())
end

--========================= TABS =========================--
local Tabs = {
    "Admin Abuse",
    "Main",
    "Auto",
    "Private Server",
    "Misc",
    "Live Chat",
    "Config",
}
if IS_OWNER then
    table.insert(Tabs, "Panel (Only Owner)")
end

local tabButtons = {}
local tabPages = {}
local activeTab = nil

local function selectTab(name)
    for tabName, page in pairs(tabPages) do
        page.Visible = tabName == name
    end
    for tabName, btn in pairs(tabButtons) do
        local bar = btn:FindFirstChild("ActiveBar")
        if tabName == name then
            btn.BackgroundTransparency = 0
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            if bar then bar.Visible = true end
        else
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Color3.fromRGB(185, 185, 185)
            if bar then bar.Visible = false end
        end
    end
    activeTab = name
end

for i, tabName in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Name = tabName
    btn.LayoutOrder = i
    btn.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. tabName
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.TextColor3 = Color3.fromRGB(185, 185, 185)
    btn.TextSize = 14
    btn.ClipsDescendants = true
    btn.Parent = Sidebar
    corner(btn, 8)

    local bar = Instance.new("Frame")
    bar.Name = "ActiveBar"
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Position = UDim2.new(0, 2, 0.5, 0)
    bar.Size = UDim2.fromOffset(3, 18)
    bar.Visible = false
    bar.Parent = btn
    corner(bar, 2)

    local page = Instance.new("Frame")
    page.Name = tabName
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = Content

    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 8)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Parent = page

    tabButtons[tabName] = btn
    tabPages[tabName] = page

    on(btn.MouseButton1Click, function()
        selectTab(tabName)
    end)
end

on(Search:GetPropertyChangedSignal("Text"), function()
    local q = string.lower(Search.Text)
    for name, btn in pairs(tabButtons) do
        btn.Visible = q == "" or string.find(string.lower(name), q, 1, true) ~= nil
    end
end)

--========================= MAIN CONTROLS =========================--
local SpeedValue = 800
local AutoDip = false
local WorldEsp = true
local NotifyOn = true
local VOLCANO_POS = Vector3.new(-5112.81, 41441.30, -3445.27)
local Job = { busy = false, eggId = nil, status = "Idle", token = 0, row = nil }
local refreshNote
local showEggModel
local Modes = {}
local Cards = {}
local EspMarks = {}
local LastPickup = nil
local LastDipResult = nil
local Flight = nil

local mainPage = tabPages["Main"]

local function header(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Text = text
    lbl.LayoutOrder = order or 1
    lbl.Parent = parent
    return lbl
end

header(mainPage, "Main", 1)

local speedHolder = Instance.new("Frame")
speedHolder.BackgroundTransparency = 1
speedHolder.Size = UDim2.new(1, 0, 0, 58)
speedHolder.LayoutOrder = 2
speedHolder.Parent = mainPage

local speedName = Instance.new("TextLabel")
speedName.BackgroundTransparency = 1
speedName.Size = UDim2.new(0.62, 0, 0, 18)
speedName.Font = Enum.Font.GothamSemibold
speedName.TextSize = 14
speedName.TextXAlignment = Enum.TextXAlignment.Left
speedName.TextColor3 = Color3.fromRGB(235, 235, 235)
speedName.Text = "Speed"
speedName.Parent = speedHolder

local speedHint = Instance.new("TextLabel")
speedHint.BackgroundTransparency = 1
speedHint.Position = UDim2.new(0, 0, 0, 16)
speedHint.Size = UDim2.new(0.62, 0, 0, 14)
speedHint.Font = Enum.Font.Gotham
speedHint.TextSize = 11
speedHint.TextXAlignment = Enum.TextXAlignment.Left
speedHint.TextColor3 = Color3.fromRGB(140, 140, 140)
speedHint.Text = "TweenService flight  100 - 3000"
speedHint.Parent = speedHolder

local speedValueLabel = Instance.new("TextLabel")
speedValueLabel.BackgroundTransparency = 1
speedValueLabel.AnchorPoint = Vector2.new(1, 0)
speedValueLabel.Position = UDim2.new(1, 0, 0, 0)
speedValueLabel.Size = UDim2.new(0.38, 0, 0, 18)
speedValueLabel.Font = Enum.Font.GothamSemibold
speedValueLabel.TextSize = 14
speedValueLabel.TextXAlignment = Enum.TextXAlignment.Right
speedValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValueLabel.Text = "800"
speedValueLabel.Parent = speedHolder

local speedTrack = Instance.new("TextButton")
speedTrack.AutoButtonColor = false
speedTrack.Text = ""
speedTrack.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
speedTrack.Position = UDim2.new(0, 0, 0, 38)
speedTrack.Size = UDim2.new(1, 0, 0, 8)
speedTrack.Parent = speedHolder
corner(speedTrack, 4)

local speedFill = Instance.new("Frame")
speedFill.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
speedFill.Size = UDim2.new(0, 0, 1, 0)
speedFill.Parent = speedTrack
corner(speedFill, 4)

local speedKnob = Instance.new("Frame")
speedKnob.AnchorPoint = Vector2.new(0.5, 0.5)
speedKnob.Position = UDim2.new(0, 0, 0.5, 0)
speedKnob.Size = UDim2.fromOffset(16, 16)
speedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedKnob.Parent = speedTrack
corner(speedKnob, 8)

local function setSpeed(v)
    SpeedValue = math.clamp(math.floor(v + 0.5), 100, 3000)
    local alpha = (SpeedValue - 100) / (3000 - 100)
    speedFill.Size = UDim2.new(alpha, 0, 1, 0)
    speedKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
    speedValueLabel.Text = tostring(SpeedValue)
end
setSpeed(800)

local slidingSpeed = false
local function speedFromX(x)
    local left = speedTrack.AbsolutePosition.X
    local width = math.max(1, speedTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    setSpeed(100 + (3000 - 100) * alpha)
end

on(speedTrack.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        slidingSpeed = true
        speedFromX(input.Position.X)
    end
end)

local function makeToggle(parent, text, order, default, callback)
    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    holder.BackgroundTransparency = 0.15
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.LayoutOrder = order
    holder.ClipsDescendants = true
    holder.Parent = parent
    corner(holder, 10)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(1, -72, 1, 0)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.Text = text
    lbl.Parent = holder

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -12, 0.5, 0)
    track.Size = UDim2.fromOffset(46, 24)
    track.AutoButtonColor = false
    track.Text = ""
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 64)
    track.Parent = holder
    corner(track, 12)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    knob.Parent = track
    corner(knob, 9)

    local state = default and true or false
    local function refresh()
        if state then
            track.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            knob.Position = UDim2.new(1, -21, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        else
            track.BackgroundColor3 = Color3.fromRGB(60, 60, 64)
            knob.Position = UDim2.new(0, 3, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        end
    end
    refresh()
    on(track.MouseButton1Click, function()
        state = not state
        refresh()
        if callback then callback(state) end
    end)
    return holder
end

makeToggle(mainPage, "Auto Volcanic Dip", 3, false, function(v)
    AutoDip = v
end)
makeToggle(mainPage, "World ESP", 4, true, function(v)
    WorldEsp = v
    if not v then
        for _, mark in pairs(EspMarks) do
            if mark.part then mark.part:Destroy() end
        end
        table.clear(EspMarks)
    end
end)
makeToggle(tabPages["Config"], "Notification", 2, true, function(v)
    NotifyOn = v
    if refreshNote then
        refreshNote()
    end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, 0, 0, 18)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
StatusLabel.Text = "Status: Idle"
StatusLabel.LayoutOrder = 5
StatusLabel.Parent = mainPage

header(mainPage, "Eggs", 6)

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Size = UDim2.new(1, 0, 0, 22)
EmptyLabel.Font = Enum.Font.Gotham
EmptyLabel.TextSize = 13
EmptyLabel.TextXAlignment = Enum.TextXAlignment.Left
EmptyLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
EmptyLabel.Text = "No eggs found"
EmptyLabel.LayoutOrder = 7
EmptyLabel.Parent = mainPage

local EggList = Instance.new("Frame")
EggList.BackgroundTransparency = 1
EggList.Size = UDim2.new(1, 0, 0, 0)
EggList.AutomaticSize = Enum.AutomaticSize.Y
EggList.LayoutOrder = 8
EggList.Parent = mainPage

local eggLayout = Instance.new("UIListLayout")
eggLayout.Padding = UDim.new(0, 8)
eggLayout.SortOrder = Enum.SortOrder.LayoutOrder
eggLayout.Parent = EggList

for _, tabName in ipairs(Tabs) do
    if tabName ~= "Main" and tabName ~= "Auto" and tabName ~= "Live Chat" and tabName ~= "Private Server" then
        header(tabPages[tabName], tabName, 1)
    end
end

local function buildAutoPage()
    local page = tabPages["Auto"]
    header(page, "Auto", 1)
    local opener = Instance.new("TextButton")
    opener.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
    opener.AutoButtonColor = false
    opener.Size = UDim2.new(1, 0, 0, 40)
    opener.Font = Enum.Font.GothamSemibold
    opener.TextSize = 14
    opener.TextXAlignment = Enum.TextXAlignment.Left
    opener.TextColor3 = Color3.fromRGB(235, 235, 235)
    opener.Text = "  Halloween Event    >"
    opener.LayoutOrder = 2
    opener.Parent = page
    corner(opener, 10)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = false
    body.LayoutOrder = 3
    body.Parent = page
    local bodyList = Instance.new("UIListLayout")
    bodyList.Padding = UDim.new(0, 8)
    bodyList.SortOrder = Enum.SortOrder.LayoutOrder
    bodyList.Parent = body

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1, 0, 0, 32)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextColor3 = Color3.fromRGB(180, 180, 180)
    status.Text = "Off - Candy 0 | carrying 0 | not on the island"
    status.LayoutOrder = 1
    status.Parent = body

    local order = 2
    local function addToggle(text)
        makeToggle(body, text, order, false, function() end)
        order = order + 1
    end
    addToggle("Auto Collect Candy")
    addToggle("Auto Halloween Ritual")
    addToggle("Auto Search Pumpkins")
    addToggle("Auto Buy Halloween Egg")
    addToggle("Collect Rare Eggs First")

    local rarityChoices = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal", "Event" }
    local rarityValue = "Rare"
    local rarityOpen = false
    local rarityBtn = Instance.new("TextButton")
    rarityBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    rarityBtn.AutoButtonColor = false
    rarityBtn.Size = UDim2.new(1, 0, 0, 42)
    rarityBtn.Font = Enum.Font.GothamSemibold
    rarityBtn.TextSize = 13
    rarityBtn.TextXAlignment = Enum.TextXAlignment.Left
    rarityBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    rarityBtn.Text = "  Rare Egg Min Rarity    " .. rarityValue
    rarityBtn.LayoutOrder = order
    rarityBtn.Parent = body
    corner(rarityBtn, 10)
    order = order + 1

    local rarityList = Instance.new("Frame")
    rarityList.BackgroundTransparency = 1
    rarityList.Size = UDim2.new(1, 0, 0, 0)
    rarityList.AutomaticSize = Enum.AutomaticSize.Y
    rarityList.Visible = false
    rarityList.LayoutOrder = order
    rarityList.Parent = body
    local rarityLayout = Instance.new("UIListLayout")
    rarityLayout.Padding = UDim.new(0, 4)
    rarityLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rarityLayout.Parent = rarityList
    for i, rarityName in ipairs(rarityChoices) do
        local choice = Instance.new("TextButton")
        choice.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
        choice.AutoButtonColor = false
        choice.Size = UDim2.new(1, 0, 0, 32)
        choice.Font = Enum.Font.Gotham
        choice.TextSize = 13
        choice.TextColor3 = RARITY_COLOR[rarityName] or Color3.fromRGB(220, 220, 220)
        choice.Text = rarityName
        choice.LayoutOrder = i
        choice.Parent = rarityList
        corner(choice, 8)
        on(choice.MouseButton1Click, function()
            rarityValue = rarityName
            rarityBtn.Text = "  Rare Egg Min Rarity    " .. rarityValue
            rarityOpen = false
            rarityList.Visible = false
        end)
    end
    on(rarityBtn.MouseButton1Click, function()
        rarityOpen = not rarityOpen
        rarityList.Visible = rarityOpen
    end)
    local opened = false
    on(opener.MouseButton1Click, function()
        opened = not opened
        body.Visible = opened
        opener.Text = opened and "  Halloween Event    v" or "  Halloween Event    >"
        if not opened then
            status.Text = "Off - Candy 0 | carrying 0 | not on the island"
        end
    end)
end

local function buildChatPage()
    local page = tabPages["Live Chat"]
    header(page, "Live Chat", 1)
    local log = Instance.new("ScrollingFrame")
    log.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    log.BorderSizePixel = 0
    log.Size = UDim2.new(1, 0, 0, 220)
    log.CanvasSize = UDim2.new()
    log.AutomaticCanvasSize = Enum.AutomaticSize.Y
    log.ScrollBarThickness = 3
    log.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
    log.LayoutOrder = 2
    log.Parent = page
    corner(log, 10)
    local logList = Instance.new("UIListLayout")
    logList.Padding = UDim.new(0, 6)
    logList.SortOrder = Enum.SortOrder.LayoutOrder
    logList.Parent = log
    pad(log, 8)

    local empty = Instance.new("TextLabel")
    empty.BackgroundTransparency = 1
    empty.Size = UDim2.new(1, 0, 0, 24)
    empty.Font = Enum.Font.Gotham
    empty.TextSize = 12
    empty.TextXAlignment = Enum.TextXAlignment.Left
    empty.TextColor3 = Color3.fromRGB(140, 140, 140)
    empty.Text = "No messages yet"
    empty.LayoutOrder = 1
    empty.Parent = log

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 36)
    row.LayoutOrder = 3
    row.Parent = page
    local box = Instance.new("TextBox")
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
    box.Size = UDim2.new(1, -78, 1, 0)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.PlaceholderText = "Message"
    box.Text = ""
    box.ClearTextOnFocus = false
    box.TextColor3 = Color3.fromRGB(235, 235, 235)
    box.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = row
    corner(box, 8)
    pad(box, 8)
    local send = Instance.new("TextButton")
    send.AnchorPoint = Vector2.new(1, 0)
    send.Position = UDim2.new(1, 0, 0, 0)
    send.Size = UDim2.new(0, 70, 1, 0)
    send.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    send.AutoButtonColor = false
    send.Font = Enum.Font.GothamBold
    send.TextSize = 13
    send.TextColor3 = Color3.fromRGB(18, 18, 18)
    send.Text = "Send"
    send.Parent = row
    corner(send, 8)

    local messages = readJson(CHAT_FILE) or {}
    local seen = {}
    local function remember(msg)
        local id = tostring(msg.id or (tostring(msg.userId) .. ":" .. tostring(msg.at) .. ":" .. tostring(msg.text)))
        if seen[id] then
            return false
        end
        seen[id] = true
        msg.id = id
        return true
    end
    for _, msg in ipairs(messages) do
        remember(msg)
    end
    local function paint()
        for _, child in ipairs(log:GetChildren()) do
            if child:IsA("Frame") or child == empty then
                if child ~= empty then
                    child:Destroy()
                end
            end
        end
        empty.Visible = #messages == 0
        for i, msg in ipairs(messages) do
            local mine = tostring(msg.userId) == tostring(LocalPlayer.UserId)
            local bubble = Instance.new("Frame")
            bubble.BackgroundColor3 = mine and Color3.fromRGB(48, 48, 54) or Color3.fromRGB(28, 28, 32)
            bubble.Size = UDim2.new(1, 0, 0, 0)
            bubble.AutomaticSize = Enum.AutomaticSize.Y
            bubble.LayoutOrder = i + 1
            bubble.Parent = log
            corner(bubble, 8)
            local name = Instance.new("TextLabel")
            name.BackgroundTransparency = 1
            name.Size = UDim2.new(1, -12, 0, 16)
            name.Position = UDim2.fromOffset(6, 4)
            name.Font = Enum.Font.GothamSemibold
            name.TextSize = 11
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.TextColor3 = Color3.fromRGB(210, 210, 210)
            name.Text = tostring(msg.name or "User") .. "  " .. tostring(msg.clock or "")
            name.Parent = bubble
            local text = Instance.new("TextLabel")
            text.BackgroundTransparency = 1
            text.Position = UDim2.fromOffset(6, 20)
            text.Size = UDim2.new(1, -12, 0, 0)
            text.AutomaticSize = Enum.AutomaticSize.Y
            text.Font = Enum.Font.Gotham
            text.TextSize = 13
            text.TextWrapped = true
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.TextYAlignment = Enum.TextYAlignment.Top
            text.TextColor3 = Color3.fromRGB(240, 240, 240)
            text.Text = tostring(msg.text or "")
            text.Parent = bubble
            local spacer = Instance.new("Frame")
            spacer.BackgroundTransparency = 1
            spacer.Size = UDim2.new(1, 0, 0, 6)
            spacer.Position = UDim2.new(0, 0, 1, -6)
            spacer.Parent = bubble
        end
        task.defer(function()
            if log.Parent then
                log.CanvasPosition = Vector2.new(0, math.max(0, log.AbsoluteCanvasSize.Y))
            end
        end)
    end
    local function addMessage(msg, clearBox)
        if type(msg) ~= "table" or not remember(msg) then
            return
        end
        table.insert(messages, msg)
        while #messages > 200 do
            table.remove(messages, 1)
        end
        writeJson(CHAT_FILE, messages)
        if clearBox then
            box.Text = ""
        end
        paint()
    end
    local function push(text)
        text = string.gsub(text or "", "^%s+", "")
        text = string.gsub(text, "%s+$", "")
        if text == "" then return end
        if #text > 180 then
            text = string.sub(text, 1, 180)
        end
        local msg = {
            id = tostring(LocalPlayer.UserId) .. "-" .. tostring(os.clock()),
            userId = LocalPlayer.UserId,
            name = LocalPlayer.DisplayName,
            text = text,
            clock = os.date("%H:%M"),
            at = os.time(),
        }
        addMessage(msg, true)
        pcall(function()
            LocalPlayer:SetAttribute("SterlingChat", HttpService:JSONEncode(msg))
        end)
    end
    local function readAttr(player)
        local raw = player:GetAttribute("SterlingChat")
        if type(raw) ~= "string" or raw == "" then return end
        local ok, msg = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if ok then
            addMessage(msg, false)
        end
    end
    local function watch(player)
        on(player:GetAttributeChangedSignal("SterlingChat"), function()
            readAttr(player)
        end)
        readAttr(player)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        watch(player)
    end
    on(Players.PlayerAdded, watch)
    on(send.MouseButton1Click, function()
        push(box.Text)
    end)
    on(box.FocusLost, function(enter)
        if enter then
            push(box.Text)
        end
    end)
    paint()
end

local function httpGet(url)
    local requester = request or http_request or (syn and syn.request)
    if requester then
        local ok, res = pcall(function()
            return requester({ Url = url, Method = "GET" })
        end)
        if ok and type(res) == "table" then
            return res.Body or res.body
        end
    end
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then
        return body
    end
    return nil
end

local function publicServers()
    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
    local body = httpGet(url)
    if not body then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if ok and type(data) == "table" and type(data.data) == "table" then
        return data.data
    end
    return nil
end

local function teleportServer(jobId)
    local TeleportService = game:GetService("TeleportService")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
end

local function buildPrivatePage()
    local page = tabPages["Private Server"]
    header(page, "Private Server", 1)
    local hopStatus = Instance.new("TextLabel")
    hopStatus.BackgroundTransparency = 1
    hopStatus.Size = UDim2.new(1, 0, 0, 18)
    hopStatus.Font = Enum.Font.Gotham
    hopStatus.TextSize = 12
    hopStatus.TextXAlignment = Enum.TextXAlignment.Left
    hopStatus.TextTruncate = Enum.TextTruncate.AtEnd
    hopStatus.TextColor3 = Color3.fromRGB(170, 170, 170)
    hopStatus.Text = "Idle"
    hopStatus.LayoutOrder = 5
    hopStatus.Parent = page

    local running = { normal = false, private = false }
    local function makeHop(label, order, kind, picker)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.TextColor3 = Color3.fromRGB(230, 230, 230)
        btn.LayoutOrder = order
        btn.Parent = page
        corner(btn, 10)
        local function paint()
            btn.Text = "  " .. label .. "    " .. (running[kind] and "stop" or "run")
        end
        paint()
        on(btn.MouseButton1Click, function()
            running[kind] = not running[kind]
            paint()
            if not running[kind] then
                hopStatus.Text = "Stopped"
                return
            end
            task.spawn(function()
                while Alive and running[kind] do
                    hopStatus.Text = "Searching"
                    local servers = publicServers()
                    if not servers then
                        hopStatus.Text = "Server list failed"
                        task.wait(3)
                    else
                        local pick = picker(servers)
                        if pick and running[kind] then
                            hopStatus.Text = "Hopping  " .. tostring(pick.playing or 0) .. " players"
                            pcall(function()
                                teleportServer(pick.id)
                            end)
                            task.wait(8)
                        else
                            hopStatus.Text = "No matching server"
                            task.wait(3)
                        end
                    end
                end
            end)
        end)
    end

    makeHop("Server Hop Normal Ping", 2, "normal", function(servers)
        local best, bestScore
        for _, server in ipairs(servers) do
            local ping = tonumber(server.ping)
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 1
            if server.id ~= game.JobId and playing < maxPlayers and playing > 0 then
                local score
                if ping then
                    score = math.abs(ping - 90)
                    if ping < 20 or ping > 180 then
                        score = score + 500
                    end
                else
                    score = 200
                end
                if not bestScore or score < bestScore then
                    best, bestScore = server, score
                end
            end
        end
        return best
    end)

    makeHop("Private Server Hop (1 people server)", 3, "private", function(servers)
        for _, server in ipairs(servers) do
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 1
            if server.id ~= game.JobId and playing == 1 and playing < maxPlayers then
                return server
            end
        end
        return nil
    end)

    local rejoin = Instance.new("TextButton")
    rejoin.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    rejoin.AutoButtonColor = false
    rejoin.Size = UDim2.new(1, 0, 0, 42)
    rejoin.Font = Enum.Font.GothamBold
    rejoin.TextSize = 14
    rejoin.TextColor3 = Color3.fromRGB(18, 18, 18)
    rejoin.Text = "Rejoin Server"
    rejoin.LayoutOrder = 4
    rejoin.Parent = page
    corner(rejoin, 10)
    on(rejoin.MouseButton1Click, function()
        hopStatus.Text = "Rejoining"
        pcall(function()
            teleportServer(game.JobId)
        end)
    end)
end

buildAutoPage()
buildChatPage()
buildPrivatePage()
selectTab("Main")

--========================= DRAG / RESIZE =========================--
local drag = { active = false, input = nil, offset = Vector2.zero, pointer = Vector2.zero, origin = Vector2.zero, kind = nil }
local resize = { active = false, input = nil, start = Vector2.zero, size = DEFAULT_SIZE, pointer = Vector2.zero }

local function pointerOf(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function livePointer(input)
    if not input then return nil end
    local p = pointerOf(input)
    if p.X == 0 and p.Y == 0 then
        return nil
    end
    return p
end

local function beginMenuDrag(input)
    local p = pointerOf(input)
    drag.active = true
    drag.kind = "menu"
    drag.input = input
    drag.pointer = p
    drag.origin = p
    drag.offset = p - menuPos
end

local function beginIconDrag(input)
    local p = pointerOf(input)
    drag.active = true
    drag.kind = "icon"
    drag.input = input
    drag.pointer = p
    drag.origin = p
    drag.offset = p - iconPos
end

local function beginResize(input)
    resize.active = true
    resize.input = input
    resize.pointer = pointerOf(input)
    resize.start = resize.pointer
    resize.size = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
end

on(DragZone.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginMenuDrag(input)
    end
end)

on(Icon.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginIconDrag(input)
    end
end)

on(ResizeHandle.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginResize(input)
    end
end)

on(UserInputService.InputChanged, function(input)
    if slidingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        speedFromX(input.Position.X)
    end
    if resize.active and resize.input then
        local mouseMove = resize.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
        if input == resize.input or mouseMove then
            local p = pointerOf(input)
            if p.X ~= 0 or p.Y ~= 0 then
                resize.pointer = p
            end
        end
    end
end)

on(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if slidingSpeed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == nil) then
            slidingSpeed = false
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            slidingSpeed = false
        end
    end
    if drag.active and input == drag.input then
        local moved = (drag.pointer - drag.origin).Magnitude
        local kind = drag.kind
        drag.active = false
        drag.input = nil
        doSave()
        if kind == "icon" and moved < 8 then
            Icon.Visible = false
            Main.Visible = true
        end
    end
    if resize.active and input == resize.input then
        resize.active = false
        resize.input = nil
        menuSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        doSave()
    end
end)

on(UserInputService.WindowFocusReleased, function()
    if drag.active or resize.active then
        drag.active = false
        drag.input = nil
        resize.active = false
        resize.input = nil
        doSave()
    end
    slidingSpeed = false
end)

local function stepDrag()
    if drag.active and drag.input then
        local live = livePointer(drag.input)
        if live then
            drag.pointer = live
        end
        local p = drag.pointer - drag.offset
        if drag.kind == "icon" then
            applyIconPos(p.X, p.Y)
        else
            applyMenuPos(p.X, p.Y)
        end
    end
    if resize.active and resize.input then
        local live = livePointer(resize.input)
        if live then
            resize.pointer = live
        end
        local delta = resize.pointer - resize.start
        applyMenuSize(resize.size.X + delta.X, resize.size.Y + delta.Y)
    end
end

-- Icon click vs drag: if the press never moved, InputEnded above opens the menu.
-- A pure click has pointer == start, moved ~ 0, so it opens. Good.

local function minimizeToIcon()
    if drag.active or resize.active then return end
    menuSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
    doSave()
    Main.Visible = false
    Icon.Visible = true
end

on(MinBtn.MouseButton1Click, minimizeToIcon)

--========================= FORMAT / SCAN =========================--
local function formatNumber(n)
    n = tonumber(n) or 0
    local sign = n < 0 and "-" or ""
    n = math.abs(n)
    local units = {
        { 1e12, "T" },
        { 1e9, "B" },
        { 1e6, "M" },
        { 1e3, "K" },
    }
    for _, unit in ipairs(units) do
        if n >= unit[1] then
            return string.format("%s%.2f%s", sign, n / unit[1], unit[2])
        end
    end
    if n >= 100 then
        return sign .. string.format("%.0f", n)
    end
    return sign .. string.format("%.2f", n):gsub("%.?0+$", "")
end

local function isHalloween(name)
    local n = string.lower(tostring(name))
    return string.find(n, "halloween", 1, true) ~= nil
        or string.find(n, "hallow", 1, true) ~= nil
        or string.find(n, "pumpkin", 1, true) ~= nil
        or string.find(n, "spooky", 1, true) ~= nil
end

local function eggDef(name)
    if EggsData and EggsData[name] then
        return EggsData[name]
    end
    return nil
end

local function eggMeta(name)
    local data = eggDef(name)
    local db = EGG_DB[name]
    local rarity = (data and data.Rarity) or (db and db.Rarity) or "Unknown"
    local luck = (data and data.Luck) or (db and db.Luck) or 0
    if isHalloween(name) then
        rarity = "Event"
    end
    return rarity, luck, data
end

local function readMutation(obj)
    if not obj then return "None" end
    local mutation = obj:GetAttribute("Mutation")
    local spawn = obj:GetAttribute("SpawnMutation")
    local label = (type(mutation) == "string" and mutation ~= "" and mutation) or "None"
    if type(spawn) == "string" and spawn ~= "" and spawn ~= mutation then
        if label == "None" then
            label = spawn
        else
            label = label .. " + " .. spawn
        end
    end
    return label
end

local function readTraits(obj)
    if not obj then return "-" end
    local direct = obj:GetAttribute("Traits") or obj:GetAttribute("Trait")
    if type(direct) == "string" and direct ~= "" then
        return direct
    end
    local parts = {}
    for name, value in pairs(obj:GetAttributes()) do
        local lower = string.lower(name)
        if string.find(lower, "trait", 1, true) and tostring(value) ~= "" and string.lower(name) ~= "mutation" then
            table.insert(parts, name .. ": " .. tostring(value))
        end
    end
    if #parts == 0 then
        return "-"
    end
    return table.concat(parts, ", ")
end

local function readKG(obj)
    local raw = obj:GetAttribute("Weight") or obj:GetAttribute("KG") or 1
    if GeneralData and GeneralData.ShownEggKG then
        local ok, shown = pcall(GeneralData.ShownEggKG, GeneralData, raw)
        if not ok then
            ok, shown = pcall(GeneralData.ShownEggKG, raw)
        end
        if ok and shown ~= nil then
            return shown
        end
    end
    return raw
end

local function iconFor(name, data)
    if type(data) == "table" then
        for _, key in ipairs({ "Icon", "Image", "Thumbnail", "ImageId", "IconId" }) do
            local v = data[key]
            if type(v) == "string" and v ~= "" then
                return v
            elseif type(v) == "number" then
                return "rbxassetid://" .. tostring(v)
            end
        end
    end
    return nil
end

local claimCache = { raw = nil, map = {} }
local function claimedCycles()
    local raw = LocalPlayer:GetAttribute("CollectedEggCycles")
    if claimCache.raw ~= raw then
        claimCache.raw = raw
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(raw or "{}")
        end)
        claimCache.map = (ok and type(decoded) == "table") and decoded or {}
    end
    return claimCache.map
end

local function eggClaimed(obj, name)
    if obj:GetAttribute("AdminSpawn") == true then
        local id = obj:GetAttribute("AdminEggId")
        local list = LocalPlayer:GetAttribute("CollectedAdminEggs")
        if type(id) == "string" and type(list) == "string" then
            return string.find(list, "," .. id .. ",", 1, true) ~= nil
        end
        return false
    end
    local cycle = tonumber(obj:GetAttribute("Cycle"))
    local claimed = tonumber(claimedCycles()[name])
    if cycle and claimed then
        return cycle <= claimed
    end
    local list = LocalPlayer:GetAttribute("CollectedEggs")
    if type(list) == "string" and name ~= "" then
        return string.find(list, name .. ",", 1, true) ~= nil or string.find("," .. list .. ",", "," .. name .. ",", 1, true) ~= nil
    end
    return false
end

local function setStatus(text, eggId)
    Job.status = text
    if eggId then
        Job.eggId = eggId
    end
    StatusLabel.Text = "Status: " .. text
    local id = eggId or Job.eggId
    local card = id and Cards[id]
    if card and card.status then
        card.status.Text = text
    end
    if refreshNote then
        refreshNote()
    end
end

local function scanEggs()
    local folder = ActiveEggs
    if not folder or not folder.Parent then
        local serverData = ReplicatedStorage:FindFirstChild("ServerData")
        folder = serverData and serverData:FindFirstChild("ActiveEggs")
        ActiveEggs = folder
    end
    if not folder then
        return {}
    end
    local now = workspace:GetServerTimeNow()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rows = {}
    for _, obj in ipairs(folder:GetChildren()) do
        local name = tostring(obj:GetAttribute("Egg") or obj.Name)
        local pos = obj:GetAttribute("Position")
        if typeof(pos) == "Vector3" then
            local priv = obj:GetAttribute("PrivateTo")
            local privOk = priv == nil or priv == LocalPlayer.UserId or tostring(priv) == tostring(LocalPlayer.UserId)
            if privOk and not eggClaimed(obj, name) then
                local rarity, luck, data = eggMeta(name)
                local dropEnd = tonumber(obj:GetAttribute("DropEndsAt")) or 0
                local admin = obj:GetAttribute("AdminSpawn") == true
                local rarityText = rarity
                if admin and not isHalloween(name) then
                    rarityText = rarity .. " / Admin"
                elseif admin or isHalloween(name) then
                    rarityText = "Event"
                    rarity = "Event"
                end
                table.insert(rows, {
                    Id = obj.Name,
                    Object = obj,
                    Name = name,
                    Position = pos,
                    Rarity = rarity,
                    RarityText = rarityText,
                    Luck = luck,
                    KG = readKG(obj),
                    Mutation = readMutation(obj),
                    Traits = readTraits(obj),
                    Icon = iconFor(name, data),
                    Distance = root and (root.Position - pos).Magnitude or 0,
                    Spawning = dropEnd > now,
                    Admin = admin,
                })
            end
        end
    end
    table.sort(rows, function(a, b)
        local ra = RARITY_ORDER[a.Rarity] or 0
        local rb = RARITY_ORDER[b.Rarity] or 0
        if ra ~= rb then
            return ra > rb
        end
        if a.Luck ~= b.Luck then
            return a.Luck > b.Luck
        end
        return a.Name < b.Name
    end)
    return rows
end

--========================= MOVEMENT / STEAL =========================--
local function character()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return char, hum, root
    end
    return nil, nil, nil
end

local function mountRoot()
    local _, _, root = character()
    if not root then return nil end
    local joint = root:FindFirstChild("PetMountJoint")
    if joint and joint.Part1 and joint.Part1.Parent then
        local model = joint.Part1:FindFirstAncestorOfClass("Model") or joint.Part1.Parent
        local part = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or joint.Part1)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return root
end

local function stopFlight()
    if Flight then
        if Flight.tween then
            pcall(function() Flight.tween:Cancel() end)
        end
        if Flight.conn then
            Flight.conn:Disconnect()
        end
        if Flight.bv and Flight.bv.Parent then
            Flight.bv:Destroy()
        end
        if Flight.alpha and Flight.alpha.Parent then
            Flight.alpha:Destroy()
        end
        if Flight.humanoid and Flight.humanoid.Parent then
            Flight.humanoid.PlatformStand = Flight.platform
            Flight.humanoid.AutoRotate = Flight.auto
            pcall(function()
                Flight.humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
        for part, can in pairs(Flight.collisions or {}) do
            if part and part.Parent then
                part.CanCollide = can
            end
        end
        Flight = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d.Name == "SterlingFly" or d.Name == "SterlingAlpha" then
                d:Destroy()
            end
        end
    end
end

local function collectPhysics(extra)
    local collisions = {}
    local char = LocalPlayer.Character
    local function take(inst)
        if not inst then return end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("BasePart") and collisions[d] == nil then
                collisions[d] = d.CanCollide
            end
        end
    end
    take(char)
    take(extra)
    return collisions
end

local function applyFlightCF(hrp, cf)
    pcall(function()
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        local mount = mountRoot()
        if mount and mount ~= hrp and mount.Parent then
            mount.AssemblyLinearVelocity = Vector3.zero
            mount.AssemblyAngularVelocity = Vector3.zero
            mount.CFrame = cf
        end
    end)
end

local function moveTo(position, mode, exact)
    if not Alive or Job.token == 0 then return false end
    local char, hum, hrp = character()
    if not hrp then return false end
    local lift = exact and 0 or 3
    local goal = position + Vector3.new(0, lift, 0)
    if mode == "Instant" then
        applyFlightCF(hrp, CFrame.new(goal))
        task.wait(0.3)
        return true
    end
    stopFlight()
    local oldPlatform = hum.PlatformStand
    local oldAuto = hum.AutoRotate
    local collisions = collectPhysics(char)
    hum.PlatformStand = true
    hum.AutoRotate = false
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    local bv = Instance.new("BodyVelocity")
    bv.Name = "SterlingFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local alpha = Instance.new("NumberValue")
    alpha.Name = "SterlingAlpha"
    alpha.Value = 0
    alpha.Parent = hrp
    local startPos = hrp.Position
    local dist = (startPos - goal).Magnitude
    local duration = math.max(0.08, dist / math.clamp(SpeedValue, 100, 3000))
    local tween = TweenService:Create(alpha, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = 1 })
    Flight = {
        humanoid = hum,
        platform = oldPlatform,
        auto = oldAuto,
        collisions = collisions,
        tween = tween,
        conn = nil,
        bv = bv,
        alpha = alpha,
    }
    tween:Play()
    local t0 = os.clock()
    Flight.conn = RunService.Heartbeat:Connect(function()
        if not hrp.Parent or not Alive then return end
        for part in pairs(collisions) do
            if part.Parent then
                part.CanCollide = false
            end
        end
        local along = alpha.Value
        if along < 0.01 then
            along = math.clamp((os.clock() - t0) / duration, 0, 1)
        end
        applyFlightCF(hrp, CFrame.new(startPos:Lerp(goal, math.clamp(along, 0, 1))))
        if bv.Parent then
            bv.Velocity = Vector3.zero
        end
    end)
    local deadline = os.clock() + duration + 1.2
    while Alive and hrp.Parent and os.clock() < deadline do
        if alpha.Value >= 0.985 or (os.clock() - t0) >= duration then
            break
        end
        task.wait(0.03)
    end
    applyFlightCF(hrp, CFrame.new(goal))
    stopFlight()
    return true
end

local function basketFolder()
    return LocalPlayer:FindFirstChild("Basket")
end

local function basketHas(eggName, configName)
    local basket = basketFolder()
    if not basket then return false end
    for _, child in ipairs(basket:GetChildren()) do
        local n = tostring(child:GetAttribute("Egg") or child.Name)
        local id = tostring(child:GetAttribute("Config") or child:GetAttribute("ConfigName") or child:GetAttribute("Source") or "")
        if n == eggName or child.Name == configName or id == configName then
            return true
        end
    end
    return false
end

local function isRiding()
    if LocalPlayer:GetAttribute("IsRiding") == true then
        return true
    end
    local _, _, root = character()
    return root ~= nil and root:FindFirstChild("PetMountJoint") ~= nil
end

local function petScore(obj)
    local speed = tonumber(obj:GetAttribute("Speed")) or tonumber(obj:GetAttribute("DisplaySpeed"))
    if speed then return speed end
    local name = obj:GetAttribute("PetName") or obj.Name
    local weight = tonumber(obj:GetAttribute("Weight")) or 10
    local data = PetsData and PetsData[name]
    if data and PetAging and PetAging.DisplaySpeedFor then
        local ok, value = pcall(PetAging.DisplaySpeedFor, data.Speed or 0, weight)
        if ok and type(value) == "number" then
            return value
        end
    end
    if data then
        return (data.Speed or 0) * 1000 + (data.Income or 0)
    end
    return 0
end

local FOOD_WORDS = {
    "food", "grass", "bone", "berry", "meat", "apple", "carrot", "feed", "fruit",
    "seed", "treat", "cookie", "bait", "wheat", "corn", "fish", "bread", "candy",
    "snack", "meal", "pellet", "hay", "bamboo", "melon", "potion", "kibble",
}

local function isFood(tool)
    if not tool then return false end
    local name = string.lower(tool.Name)
    local itemType = string.lower(tostring(tool:GetAttribute("ItemType") or tool:GetAttribute("Type") or tool:GetAttribute("Category") or ""))
    if tool:GetAttribute("FoodKey") or tool:GetAttribute("IsFood") or tool:HasTag("Food") then
        return true
    end
    if string.find(itemType, "food", 1, true) then
        return true
    end
    if FoodData and FoodData[tool.Name] then
        return true
    end
    for _, word in ipairs(FOOD_WORDS) do
        if string.find(name, word, 1, true) then
            return true
        end
    end
    return false
end

local function isPetTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if isFood(tool) then return false end
    if tool:HasTag("Egg") or tool:GetAttribute("EggKey") or tool:GetAttribute("EggInventoryId") then
        return false
    end
    if EGG_DB[tool.Name] or (EggsData and EggsData[tool.Name]) then
        return false
    end
    local key = tool:GetAttribute("PetKey")
    if type(key) == "string" and key ~= "" then return true end
    if type(key) == "number" then return true end
    local petName = tool:GetAttribute("PetName")
    if type(petName) == "string" and petName ~= "" and PetsData and type(PetsData[petName]) == "table" then
        return true
    end
    if PetsData and type(PetsData[tool.Name]) == "table" and PetsData[tool.Name].Speed then
        return true
    end
    return false
end

local function bestInventoryPet()
    local best, bestScore
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if isPetTool(tool) then
                local score = petScore(tool)
                if not bestScore or score > bestScore then
                    best, bestScore = tool, score
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return best
end

local function buttonBlob(btn)
    local blob = string.lower(btn.Name or "")
    if btn:IsA("TextButton") or btn:IsA("TextLabel") then
        blob = blob .. " " .. string.lower(btn.Text or "")
    end
    for _, child in ipairs(btn:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            blob = blob .. " " .. string.lower(child.Text or "")
        end
    end
    return blob
end

local function guiRoots()
    local roots = {}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        table.insert(roots, playerGui)
    end
    if gethui then
        pcall(function()
            local hidden = gethui()
            if hidden then
                table.insert(roots, hidden)
            end
        end)
    end
    return roots
end

local function findScreenButton(phrases)
    for _, phrase in ipairs(phrases) do
        for _, root in ipairs(guiRoots()) do
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("GuiButton") and inst.Visible and inst.AbsoluteSize.X > 4 and not inst:IsDescendantOf(ScreenGui) then
                    if string.find(buttonBlob(inst), phrase, 1, true) then
                        return inst
                    end
                end
            end
        end
    end
    return nil
end

local function clickGui(btn)
    if not btn or not btn.Parent then return false end
    if getconnections then
        pcall(function()
            for _, signal in ipairs({ btn.MouseButton1Click, btn.Activated, btn.MouseButton1Down }) do
                for _, conn in ipairs(getconnections(signal)) do
                    pcall(function()
                        if conn.Function then
                            conn.Function()
                        elseif conn.Fire then
                            conn:Fire()
                        end
                    end)
                end
            end
        end)
    end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Down) end)
    end
    pcall(function()
        if btn.Activate then
            btn:Activate()
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local inset = game:GetService("GuiService"):GetGuiInset()
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2) + inset
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.04)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    return true
end

local function findNamed(name)
    local lower = string.lower(name)
    local roots = { ReplicatedStorage, workspace }
    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if string.lower(d.Name) == lower then
                return d
            end
        end
    end
    return nil
end

local function findPrompt(root, words)
    if not root then return nil end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local blob = string.lower((d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name)
            for _, word in ipairs(words) do
                if string.find(blob, word, 1, true) then
                    return d
                end
            end
        end
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, prompt.HoldDuration > 0 and 1 or 0)
        else
            prompt:InputHoldBegin()
            task.wait((prompt.HoldDuration or 0) + 0.05)
            prompt:InputHoldEnd()
        end
    end)
end

local function pressRideButton(seconds)
    local t0 = os.clock()
    while os.clock() - t0 < seconds do
        if isRiding() then
            return true
        end
        local btn = findScreenButton({ "ride pet", "ridepet", "ride" })
        if btn then
            clickGui(btn)
        end
        local prompt = findPrompt(LocalPlayer.Character, { "ride pet", "ride" })
        if not prompt then
            local plot = myPlot()
            prompt = plot and findPrompt(plot, { "ride pet", "ride" })
        end
        if prompt then
            firePrompt(prompt)
        end
        task.wait(0.2)
    end
    return isRiding()
end

local function rideBestPet()
    if isRiding() then
        return true
    end
    local _, hum = character()
    if not hum then return false end
    pcall(function()
        hum:UnequipTools()
    end)
    task.wait(0.15)
    local pet = bestInventoryPet()
    if pet and not isFood(pet) then
        pcall(function()
            hum:EquipTool(pet)
        end)
        task.wait(0.35)
    end
    if pressRideButton(4) then
        return true
    end
    local plot = myPlot()
    if plot and Job.token ~= 0 then
        local base = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
        local pos = base and base:IsA("BasePart") and base.Position or plot:GetPivot().Position
        moveTo(pos + Vector3.new(0, 4, 0), "Instant", true)
        task.wait(0.3)
        if pressRideButton(3) then
            return true
        end
    end
    local key = pet and pet:GetAttribute("PetKey")
    local remotes = GameRemotes or (ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game"))
    if remotes and key then
        for _, remoteName in ipairs({ "PetRide", "RidePet", "MountPet", "PetMount" }) do
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteEvent") then
                pcall(function()
                    remote:FireServer(key)
                end)
                task.wait(0.25)
                if isRiding() then
                    return true
                end
            end
        end
    end
    return isRiding()
end

function myPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local data = plot:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner then
            local mine = false
            if owner:IsA("ObjectValue") then
                mine = owner.Value == LocalPlayer
            elseif owner:IsA("StringValue") then
                mine = owner.Value == LocalPlayer.Name or owner.Value == tostring(LocalPlayer.UserId)
            else
                mine = tostring(owner.Value) == LocalPlayer.Name
            end
            if mine then
                return plot
            end
        end
    end
    return nil
end

local function goToRanch(mode)
    local plot = myPlot()
    if not plot then
        return false
    end
    local base = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
    local pos
    if base and base:IsA("BasePart") then
        pos = base.Position
    else
        pos = plot:GetPivot().Position
    end
    return moveTo(pos + Vector3.new(0, 4, 0), mode)
end

local function ensureRemotes()
    if not GameRemotes or not GameRemotes.Parent then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 8)
        GameRemotes = remotes and (remotes:FindFirstChild("Game") or remotes:WaitForChild("Game", 8))
    end
    if GameRemotes and not EggPickup then
        EggPickup = GameRemotes:FindFirstChild("EggPickup") or GameRemotes:WaitForChild("EggPickup", 5)
    end
    if GameRemotes and not BasketDrop then
        BasketDrop = GameRemotes:FindFirstChild("BasketDrop")
    end
end

if not _G.SterlingPickupHook then
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
        local gameFolder = remotes and remotes:WaitForChild("Game", 10)
        local pickup = gameFolder and gameFolder:WaitForChild("EggPickup", 10)
        if pickup then
            _G.SterlingPickupHook = pickup.OnClientEvent:Connect(function(status, name, id)
                LastPickup = {
                    status = tostring(status),
                    name = tostring(name),
                    id = id and tostring(id) or nil,
                    t = os.clock(),
                }
            end)
        end
        local dipResult = findNamed("VolcanoDipResult")
        if dipResult and dipResult:IsA("RemoteEvent") then
            on(dipResult.OnClientEvent, function(...)
                local args = { ... }
                local bits = {}
                for i, v in ipairs(args) do
                    bits[i] = tostring(v)
                end
                LastDipResult = table.concat(bits, " ")
            end)
        end
    end)
end

local function holdingEgg(eggName, configName)
    if basketHas(eggName, configName) then
        return true
    end
    local function scan(container)
        if not container then return false end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tostring(tool:GetAttribute("Egg") or tool.Name)
                if n == eggName or tool.Name == configName then
                    return true
                end
            end
        end
        return false
    end
    return scan(LocalPlayer.Character) or scan(LocalPlayer:FindFirstChild("Backpack"))
end

local function holdAtEgg(pos)
    local _, _, hrp = character()
    if hrp and typeof(pos) == "Vector3" then
        applyFlightCF(hrp, CFrame.new(pos + Vector3.new(0, 3, 0)))
    end
end

local function pickupConfirmed(row, beforeCount, start)
    if basketHas(row.Name, row.Id) or holdingEgg(row.Name, row.Id) then
        return true
    end
    local basket = basketFolder()
    if basket and #basket:GetChildren() > beforeCount then
        return true
    end
    if LastPickup and LastPickup.t >= start and LastPickup.status == "PickedUp" then
        if LastPickup.id == row.Id or LastPickup.name == row.Name then
            return true
        end
    end
    return false
end

local function pickupEgg(row)
    ensureRemotes()
    local start = os.clock()
    LastPickup = nil
    local pos = row.Object and row.Object:GetAttribute("Position") or row.Position
    if typeof(pos) ~= "Vector3" then
        pos = row.Position
    end
    local basket = basketFolder()
    local beforeCount = basket and #basket:GetChildren() or 0
    local deadline = os.clock() + 8
    while Alive and os.clock() < deadline do
        if row.Object and row.Object.Parent then
            local fresh = row.Object:GetAttribute("Position")
            if typeof(fresh) == "Vector3" then
                pos = fresh
            end
        end
        holdAtEgg(pos)
        if row.Object then
            firePrompt(findPrompt(row.Object, { "pick up", "pickup" }))
        end
        if EggPickup then
            pcall(function()
                EggPickup:FireServer(row.Id)
            end)
        end
        local waitUntil = os.clock() + 0.55
        while Alive and os.clock() < waitUntil do
            holdAtEgg(pos)
            if pickupConfirmed(row, beforeCount, start) then
                local stick = os.clock() + 0.7
                while Alive and os.clock() < stick do
                    holdAtEgg(pos)
                    task.wait(0.1)
                end
                if pickupConfirmed(row, beforeCount, start) then
                    return true
                end
            end
            if LastPickup and LastPickup.t >= start and LastPickup.status == "BasketFull" then
                return false, "BasketFull"
            end
            task.wait(0.1)
        end
    end
    if pickupConfirmed(row, beforeCount, start) then
        return true
    end
    return false, "no egg"
end

local function doVolcanoDip(row, mode)
    if AutoDip ~= true then
        return
    end
    if mode == "Instant" then
        setStatus("Teleporting to volcano", row.Id)
    else
        setStatus("Flying to volcano", row.Id)
    end
    moveTo(VOLCANO_POS, mode, true)
    setStatus("Drop in volcano", row.Id)
    local t0 = os.clock()
    while Alive and os.clock() - t0 < 14 do
        local btn = findScreenButton({ "drop in volcano", "drop in" })
        if btn then
            clickGui(btn)
        end
        if not holdingEgg(row.Name, row.Id) and not basketHas(row.Name, row.Id) then
            break
        end
        task.wait(0.3)
    end
    setStatus("Waiting for egg return", row.Id)
    local t1 = os.clock()
    while Alive and os.clock() - t1 < 18 do
        if basketHas(row.Name, row.Id) or holdingEgg(row.Name, row.Id) then
            setStatus("Egg in hands", row.Id)
            return
        end
        task.wait(0.2)
    end
    setStatus("Egg return timeout", row.Id)
end

local function deliverHome(mode)
    if mode == "Instant" then
        setStatus("Teleporting to My Ranch", Job.eggId)
    else
        setStatus("Flying to My Ranch", Job.eggId)
    end
    local ok = goToRanch(mode)
    if not ok then
        setStatus("Ranch not found", Job.eggId)
        return
    end
    local t0 = os.clock()
    while os.clock() - t0 < 8 do
        local locked = false
        local basket = basketFolder()
        local now = workspace:GetServerTimeNow()
        if basket then
            for _, child in ipairs(basket:GetChildren()) do
                local untilTime = tonumber(child:GetAttribute("VolcanoUntil"))
                if untilTime and now < untilTime then
                    locked = true
                end
            end
        end
        if not locked then break end
        setStatus("Waiting for egg return", Job.eggId)
        task.wait(0.25)
    end
    ensureRemotes()
    if BasketDrop and basketFolder() and #basketFolder():GetChildren() > 0 then
        pcall(function()
            BasketDrop:FireServer()
        end)
        task.wait(0.4)
    end
    setStatus("At My Ranch", Job.eggId)
end

local function runSteal(row, mode)
    Job.busy = true
    Job.token = Job.token + 1
    local token = Job.token
    Job.eggId = row.Id
    Job.row = row
    local useDip = AutoDip == true
    local function cancelled()
        return (not Alive) or Job.token ~= token
    end
    local function finish()
        stopFlight()
        Job.busy = false
        if refreshNote then
            refreshNote()
        end
    end
    if showEggModel then
        showEggModel(row)
    end
    setStatus(mode == "Instant" and "Instant" or "FLY", row.Id)
    if not character() then
        setStatus("No character", row.Id)
        finish()
        return
    end
    setStatus("Riding best pet", row.Id)
    rideBestPet()
    if cancelled() then finish() return end
    if row.Spawning then
        setStatus("Waiting for spawn", row.Id)
        local t0 = os.clock()
        while os.clock() - t0 < 20 do
            if cancelled() then finish() return end
            local fresh = row.Object
            local dropEnd = fresh and tonumber(fresh:GetAttribute("DropEndsAt")) or 0
            if not fresh or not fresh.Parent or dropEnd <= workspace:GetServerTimeNow() then
                break
            end
            task.wait(0.2)
        end
    end
    if mode == "Instant" then
        setStatus("Teleporting to egg", row.Id)
    else
        setStatus("Flying to egg", row.Id)
    end
    local pos = row.Object and row.Object:GetAttribute("Position") or row.Position
    moveTo(pos, mode, false)
    task.wait(0.35)
    if cancelled() then finish() return end
    setStatus("Picking up", row.Id)
    local picked, reason = pickupEgg(row)
    if not picked then
        if row.Object and row.Object.Parent then
            local fresh = row.Object:GetAttribute("Position")
            if typeof(fresh) == "Vector3" then
                pos = fresh
            end
        end
        moveTo(pos, "Instant", true)
        task.wait(0.25)
        setStatus("Picking up", row.Id)
        picked, reason = pickupEgg(row)
    end
    if not picked and not basketHas(row.Name, row.Id) and not holdingEgg(row.Name, row.Id) then
        setStatus("Pickup failed" .. (reason and (": " .. reason) or ""), row.Id)
        finish()
        return
    end
    setStatus("Egg in hands", row.Id)
    task.wait(0.35)
    if not basketHas(row.Name, row.Id) and not holdingEgg(row.Name, row.Id) then
        setStatus("Pickup lost", row.Id)
        finish()
        return
    end
    if useDip then
        local okDip, dipErr = pcall(doVolcanoDip, row, mode)
        if not okDip then
            warn("[Sterling] dip " .. tostring(dipErr))
            setStatus("Dip failed", row.Id)
        end
    end
    if cancelled() then finish() return end
    deliverHome(mode)
    setStatus(Job.status, row.Id)
    finish()
end

--========================= CARDS + ESP =========================--
local function shortStatus(id)
    if Job.busy and Job.eggId == id and Job.status ~= "Idle" then
        return Job.status
    end
    return "Idle"
end

local function makeCard(row)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    card.BackgroundTransparency = 0.08
    card.Size = UDim2.new(1, 0, 0, 132)
    card.ClipsDescendants = true
    card.Parent = EggList
    corner(card, 10)

    local icon = Instance.new("ImageLabel")
    icon.BackgroundColor3 = RARITY_COLOR[row.Rarity] or Color3.fromRGB(70, 70, 70)
    icon.Position = UDim2.fromOffset(8, 8)
    icon.Size = UDim2.fromOffset(36, 36)
    icon.Image = row.Icon or ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card
    corner(icon, 8)

    local letter = Instance.new("TextLabel")
    letter.BackgroundTransparency = 1
    letter.Size = UDim2.fromScale(1, 1)
    letter.Font = Enum.Font.GothamBold
    letter.TextSize = 16
    letter.TextColor3 = Color3.fromRGB(20, 20, 20)
    letter.Text = string.upper(string.sub(row.Name, 1, 1))
    letter.Visible = row.Icon == nil
    letter.Parent = icon

    local function line(y, size, color, bold)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.fromOffset(52, y)
        lbl.Size = UDim2.new(1, -60, 0, size)
        lbl.Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham
        lbl.TextSize = size >= 16 and 13 or 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.TextColor3 = color
        lbl.Text = ""
        lbl.Parent = card
        return lbl
    end

    local name = line(6, 16, Color3.fromRGB(255, 255, 255), true)
    local rarity = line(24, 14, RARITY_COLOR[row.Rarity] or Color3.fromRGB(200, 200, 200), false)
    local stats = line(40, 14, Color3.fromRGB(200, 200, 200), false)
    local mutation = line(54, 14, Color3.fromRGB(180, 180, 180), false)
    local traits = line(68, 14, Color3.fromRGB(170, 170, 170), false)
    local status = line(82, 14, Color3.fromRGB(235, 235, 235), true)

    local flyBtn = Instance.new("TextButton")
    flyBtn.Position = UDim2.new(0, 8, 1, -30)
    flyBtn.Size = UDim2.new(0.28, -6, 0, 24)
    flyBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    flyBtn.AutoButtonColor = false
    flyBtn.Font = Enum.Font.GothamSemibold
    flyBtn.TextSize = 12
    flyBtn.Text = "Fly"
    flyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    flyBtn.Parent = card
    corner(flyBtn, 6)

    local instantBtn = Instance.new("TextButton")
    instantBtn.Position = UDim2.new(0.28, 4, 1, -30)
    instantBtn.Size = UDim2.new(0.30, -6, 0, 24)
    instantBtn.BackgroundColor3 = Color3.fromRGB(46, 46, 50)
    instantBtn.AutoButtonColor = false
    instantBtn.Font = Enum.Font.GothamSemibold
    instantBtn.TextSize = 12
    instantBtn.Text = "Instant"
    instantBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    instantBtn.Parent = card
    corner(instantBtn, 6)

    local stealBtn = Instance.new("TextButton")
    stealBtn.Position = UDim2.new(0.58, 4, 1, -30)
    stealBtn.Size = UDim2.new(0.42, -12, 0, 24)
    stealBtn.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
    stealBtn.AutoButtonColor = false
    stealBtn.Font = Enum.Font.GothamBold
    stealBtn.TextSize = 12
    stealBtn.Text = "Steal"
    stealBtn.TextColor3 = Color3.fromRGB(16, 16, 16)
    stealBtn.Parent = card
    corner(stealBtn, 6)

    local rec = {
        frame = card,
        icon = icon,
        letter = letter,
        name = name,
        rarity = rarity,
        stats = stats,
        mutation = mutation,
        traits = traits,
        status = status,
        fly = flyBtn,
        instant = instantBtn,
        steal = stealBtn,
        row = row,
    }

    local function paintMode()
        local mode = Modes[row.Id] or "Fly"
        if mode == "Fly" then
            flyBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            flyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
            instantBtn.BackgroundColor3 = Color3.fromRGB(46, 46, 50)
            instantBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
        else
            instantBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            instantBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
            flyBtn.BackgroundColor3 = Color3.fromRGB(46, 46, 50)
            flyBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
        end
    end
    paintMode()

    on(flyBtn.MouseButton1Click, function()
        Modes[row.Id] = "Fly"
        paintMode()
    end)
    on(instantBtn.MouseButton1Click, function()
        Modes[row.Id] = "Instant"
        paintMode()
    end)
    on(stealBtn.MouseButton1Click, function()
        if Job.busy then
            setStatus("Busy", Job.eggId)
            return
        end
        local mode = Modes[row.Id] or "Fly"
        task.spawn(function()
            local ok, err = xpcall(function()
                runSteal(rec.row, mode)
            end, debug.traceback)
            if not ok then
                warn("[Sterling] " .. tostring(err))
                setStatus("Error", row.Id)
                stopFlight()
                Job.busy = false
            end
        end)
    end)
    rec.paintMode = paintMode
    return rec
end

local function updateCard(rec, row, order)
    rec.row = row
    rec.frame.LayoutOrder = order
    rec.frame.Visible = true
    rec.name.Text = row.Name
    rec.rarity.Text = row.RarityText
    rec.rarity.TextColor3 = RARITY_COLOR[row.Rarity] or Color3.fromRGB(200, 200, 200)
    rec.stats.Text = "Luck " .. formatNumber(row.Luck) .. "   |   " .. formatNumber(row.KG) .. " kg"
    rec.mutation.Text = "Mutation: " .. row.Mutation
    rec.traits.Text = "Traits: " .. row.Traits
    if Job.eggId == row.Id and Job.busy then
        rec.status.Text = Job.status
    elseif row.Spawning then
        rec.status.Text = "Spawning"
    else
        rec.status.Text = "Idle"
    end
    rec.icon.BackgroundColor3 = RARITY_COLOR[row.Rarity] or Color3.fromRGB(70, 70, 70)
    if row.Icon and row.Icon ~= "" then
        rec.icon.Image = row.Icon
        rec.letter.Visible = false
    else
        rec.icon.Image = ""
        rec.letter.Visible = true
        rec.letter.Text = string.upper(string.sub(row.Name, 1, 1))
    end
    rec.steal.Text = (Job.busy and Job.eggId == row.Id) and "..." or "Steal"
end

local espFolder = Instance.new("Folder")
espFolder.Name = "SterlingESP"
espFolder.Parent = workspace.CurrentCamera or workspace

local function updateEsp(rows)
    if not WorldEsp then
        for id, mark in pairs(EspMarks) do
            if mark.part then mark.part:Destroy() end
            EspMarks[id] = nil
        end
        return
    end
    if espFolder.Parent == nil then
        espFolder = Instance.new("Folder")
        espFolder.Name = "SterlingESP"
    end
    espFolder.Parent = workspace.CurrentCamera or workspace
    local seen = {}
    for _, row in ipairs(rows) do
        seen[row.Id] = true
        local mark = EspMarks[row.Id]
        if not mark or not mark.part or not mark.part.Parent then
            local part = Instance.new("Part")
            part.Name = "EggMark"
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Transparency = 1
            part.Size = Vector3.new(2, 2, 2)
            part.Parent = espFolder
            local bill = Instance.new("BillboardGui")
            bill.Size = UDim2.fromOffset(180, 78)
            bill.StudsOffset = Vector3.new(0, 3.2, 0)
            bill.AlwaysOnTop = true
            bill.MaxDistance = 12000
            bill.Parent = part
            local bg = Instance.new("Frame")
            bg.Size = UDim2.fromScale(1, 1)
            bg.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
            bg.BackgroundTransparency = 0.25
            bg.Parent = bill
            corner(bg, 8)
            stroke(bg, Color3.fromRGB(200, 200, 200), 1, 0.25)
            local text = Instance.new("TextLabel")
            text.BackgroundTransparency = 1
            text.Size = UDim2.new(1, -8, 1, -6)
            text.Position = UDim2.fromOffset(4, 3)
            text.Font = Enum.Font.Gotham
            text.TextSize = 11
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.TextYAlignment = Enum.TextYAlignment.Top
            text.TextColor3 = Color3.fromRGB(235, 235, 235)
            text.TextWrapped = true
            text.Text = ""
            text.Parent = bg
            mark = { part = part, text = text }
            EspMarks[row.Id] = mark
        end
        mark.part.Position = row.Position + Vector3.new(0, 2, 0)
        local state = shortStatus(row.Id)
        if row.Spawning and state == "Idle" then
            state = "Spawning"
        end
        mark.text.Text = table.concat({
            row.Name,
            row.RarityText .. "  Luck " .. formatNumber(row.Luck),
            formatNumber(row.KG) .. " kg",
            "Mutation: " .. row.Mutation,
            "Traits: " .. row.Traits,
            state,
        }, "\n")
    end
    for id, mark in pairs(EspMarks) do
        if not seen[id] then
            if mark.part then mark.part:Destroy() end
            EspMarks[id] = nil
        end
    end
end

local function refreshEggs()
    local rows = scanEggs()
    EmptyLabel.Visible = #rows == 0
    local seen = {}
    for i, row in ipairs(rows) do
        seen[row.Id] = true
        local rec = Cards[row.Id]
        if not rec or not rec.frame.Parent then
            rec = makeCard(row)
            Cards[row.Id] = rec
        end
        updateCard(rec, row, i)
    end
    for id, rec in pairs(Cards) do
        if not seen[id] then
            rec.frame:Destroy()
            Cards[id] = nil
            Modes[id] = nil
        end
    end
    updateEsp(rows)
    if Job.eggId and Job.busy then
        StatusLabel.Text = "Status: " .. Job.status
    elseif not Job.busy and Job.status == "Idle" then
        StatusLabel.Text = "Status: Idle"
    end
end

local TemplateCache = {}
local templatesScanned = false

local function findEggTemplate(name)
    if TemplateCache[name] and TemplateCache[name].Parent then
        return TemplateCache[name]
    end
    if not templatesScanned then
        templatesScanned = true
        pcall(function()
            for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
                if (inst:IsA("Model") or inst:IsA("BasePart")) and not TemplateCache[inst.Name] then
                    local parts = 0
                    for _, d in ipairs(inst:GetDescendants()) do
                        if d:IsA("BasePart") then
                            parts = parts + 1
                            if parts > 80 then
                                break
                            end
                        end
                    end
                    if parts > 0 and parts <= 80 then
                        TemplateCache[inst.Name] = inst
                    end
                end
            end
        end)
    end
    return TemplateCache[name]
end

showEggModel = function(row)
    if not row then return end
    NoteView:ClearAllChildren()
    local template = findEggTemplate(row.Name)
    if not template then
        NoteView.Visible = false
        NoteIcon.Visible = true
        return
    end
    local ok = pcall(function()
        local clone = template:Clone()
        for _, s in ipairs(clone:GetDescendants()) do
            if s:IsA("Script") or s:IsA("LocalScript") or s:IsA("ModuleScript") then
                s:Destroy()
            end
        end
        local world = Instance.new("WorldModel")
        world.Parent = NoteView
        clone.Parent = world
        local cam = Instance.new("Camera")
        cam.Parent = NoteView
        NoteView.CurrentCamera = cam
        local cf, size
        if clone:IsA("Model") then
            cf, size = clone:GetBoundingBox()
        else
            cf, size = clone.CFrame, clone.Size
        end
        local dist = math.max((size and size.Magnitude) or 4, 2) * 1.7
        cam.CFrame = CFrame.new(cf.Position + Vector3.new(dist * 0.35, dist * 0.2, dist), cf.Position)
        NoteView.Visible = true
        NoteIcon.Visible = false
    end)
    if not ok then
        NoteView.Visible = false
        NoteIcon.Visible = true
    end
end

refreshNote = function()
    if not NotifyOn or not Job.busy or not Job.row then
        Note.Visible = false
        return
    end
    local row = Job.row
    if row.Object and row.Object.Parent then
        local pos = row.Object:GetAttribute("Position")
        if typeof(pos) == "Vector3" then
            row.Position = pos
        end
    end
    Note.Visible = true
    NoteTitle.Text = TITLE_PREFIX .. "  |  " .. PLACE_NAME
    NoteName.Text = row.Name
    NoteName.TextColor3 = RARITY_COLOR[row.Rarity] or Color3.fromRGB(255, 255, 255)
    NoteMeta.Text = tostring(row.RarityText) .. "  " .. formatNumber(row.Luck) .. "  " .. formatNumber(row.KG) .. "kg  " .. tostring(row.Mutation or "None")
    NoteMut.Text = ""
    NoteTraits.Text = tostring(row.Traits or "-")
    local _, _, hrp = character()
    local eggDist = (hrp and row.Position) and (hrp.Position - row.Position).Magnitude or 0
    local targetDist = eggDist
    local lower = string.lower(Job.status or "")
    if string.find(lower, "volcano", 1, true) or string.find(lower, "dip", 1, true) or string.find(lower, "drop in", 1, true) then
        targetDist = hrp and (hrp.Position - VOLCANO_POS).Magnitude or 0
    elseif string.find(lower, "ranch", 1, true) then
        local plot = myPlot()
        if plot and hrp then
            local base = plot:FindFirstChild("Baseplate")
            local pos = base and base:IsA("BasePart") and base.Position or plot:GetPivot().Position
            targetDist = (hrp.Position - pos).Magnitude
        end
    end
    NoteDist.Text = formatNumber(eggDist) .. " studs  |  " .. tostring(row.Traits or "-")
    NoteStatus.Text = tostring(Job.status or "Idle")
    NoteIcon.BackgroundColor3 = RARITY_COLOR[row.Rarity] or Color3.fromRGB(70, 70, 70)
    if row.Icon and row.Icon ~= "" then
        NoteIcon.Image = row.Icon
        NoteLetter.Visible = false
    else
        NoteIcon.Image = ""
        NoteLetter.Visible = true
        NoteLetter.Text = string.upper(string.sub(row.Name, 1, 1))
    end
    if not NoteView.Visible then
        NoteIcon.Visible = true
    end
end

--========================= PULSE / FPS =========================--
local frames = 0
local fpsTick = os.clock()
local eggTick = 0

on(RunService.RenderStepped, function()
    if not Alive or not ScreenGui.Parent then return end
    local t = os.clock()
    local offset = (math.sin(t * 1.5) + 1) / 2
    local pulse = (math.sin(t * 2) + 1) / 2
    strokeGradient.Offset = Vector2.new(offset, 0)
    titleGradient.Offset = Vector2.new(offset, 0)
    iconGradient.Offset = Vector2.new(offset, 0)
    noteGrad.Offset = Vector2.new(offset, 0)
    noteTitleGrad.Offset = Vector2.new(offset, 0)
    mainStroke.Thickness = 1.4 + pulse * 1.2
    mainStroke.Transparency = 0.08 + (1 - pulse) * 0.28
    iconStroke.Thickness = 1.3 + pulse
    noteStroke.Thickness = 1.2 + pulse
    local v = 145 + math.floor(pulse * 110)
    mainStroke.Color = Color3.fromRGB(v, v, v)
    iconStroke.Color = Color3.fromRGB(v, v, v)
    noteStroke.Color = Color3.fromRGB(v, v, v)
    if NotifyOn and Job.busy and refreshNote then
        pcall(refreshNote)
    end
    stepDrag()
    frames = frames + 1
    if t - fpsTick >= 1 then
        FpsLabel.Text = frames .. " FPS"
        frames = 0
        fpsTick = t
    end
    if t - eggTick >= 0.55 then
        eggTick = t
        local ok, err = pcall(refreshEggs)
        if not ok then
            warn("[Sterling] scan " .. tostring(err))
        end
    end
end)

--========================= OPEN / CLOSE =========================--
local function unload()
    if not Alive then return end
    Alive = false
    Job.token = Job.token + 1
    stopFlight()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    if _G.SterlingPickupHook then
        pcall(function() _G.SterlingPickupHook:Disconnect() end)
        _G.SterlingPickupHook = nil
    end
    if espFolder then
        espFolder:Destroy()
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
    if _G.SterlingEngine and _G.SterlingEngine.Unload == unload then
        _G.SterlingEngine = nil
    end
end

on(CloseBtn.MouseButton1Click, function()
    unload()
end)

local function bindCamera()
    local cam = workspace.CurrentCamera
    if not cam then return end
    on(cam:GetPropertyChangedSignal("ViewportSize"), function()
        applyMenuPos(menuPos.X, menuPos.Y)
        applyIconPos(iconPos.X, iconPos.Y)
        doSave()
    end)
end
on(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)
bindCamera()

task.spawn(function()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name and Title.Parent then
        PLACE_NAME = info.Name
        Title.Text = TITLE_PREFIX .. "  |  " .. PLACE_NAME
        if NoteTitle then
            NoteTitle.Text = TITLE_PREFIX .. "  |  " .. PLACE_NAME
        end
    end
end)

-- Activation always centers the menu, then saves menu + icon.
local saved = loadLayout()
local vp = getScreenSize()
local w = DEFAULT_SIZE.X
local h = DEFAULT_SIZE.Y
if saved and tonumber(saved.w) and tonumber(saved.h) then
    w = tonumber(saved.w)
    h = tonumber(saved.h)
end
w = math.clamp(w, math.min(MIN_SIZE.X, vp.X), vp.X)
h = math.clamp(h, math.min(MIN_SIZE.Y, vp.Y), vp.Y)
menuSize = Vector2.new(w, h)
Main.Size = UDim2.fromOffset(w, h)
applyMenuPos((vp.X - w) / 2, (vp.Y - h) / 2)

local ix = saved and tonumber(saved.ix) or 18
local iy = saved and tonumber(saved.iy) or (vp.Y - 78)
11applyIconPos(ix, iy)
Icon.Visible = false
Main.Visible = true
doSave()

_G.SterlingEngine = {
    Unload = unload,
}

print("[Sterling Engine BETA] Loaded | centered")
