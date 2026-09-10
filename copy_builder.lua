-- copy_builder.lua
-- LT2 Blueprint Copy Builder
-- Auto-place blueprints with original coords + color + orientation
-- Updated: 2026-09-10 - data loaded from blueprint_data.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ========== AUTH ==========
local AUTHORIZED_USERS = {"gccgbxfnb0","hxa1010","gccgbxfnb4","gccgbxfnb3","xiguayyds","xiaojun1221","X8jone"}

local function isAuthorized()
    for _, u in ipairs(AUTHORIZED_USERS) do
        if LocalPlayer.Name == u then return true end
    end
    return false
end

if not isAuthorized() then
    LocalPlayer:Kick("Unauthorized")
    return
end

-- ========== DATA ==========
-- Load blueprint data from GitHub (blueprint_data.lua)
local DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"))()

local TOTAL = #DATA

-- ========== NOTIFY ==========
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3,
        })
    end)
end

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CopyBuilder"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Drag frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0, 20, 0.5, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(245, 248, 252)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(200, 210, 225)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(72, 132, 168)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Copy Builder"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Dragging
local dragging = false
local dragStart, startPos
local dragInput, dragPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Progress label
local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(1, -16, 0, 20)
ProgressLabel.Position = UDim2.new(0, 8, 0, 34)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "Ready: 0/" .. TOTAL
ProgressLabel.TextColor3 = Color3.fromRGB(60, 70, 85)
ProgressLabel.Font = Enum.Font.Gotham
ProgressLabel.TextSize = 11
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.Parent = MainFrame

-- Start Build button (green)
local BuildBtn = Instance.new("TextButton")
BuildBtn.Size = UDim2.new(1, -16, 0, 28)
BuildBtn.Position = UDim2.new(0, 8, 0, 58)
BuildBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
BuildBtn.BorderSizePixel = 0
BuildBtn.Text = "Start Build"
BuildBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BuildBtn.Font = Enum.Font.GothamBold
BuildBtn.TextSize = 12
BuildBtn.Parent = MainFrame

local BuildCorner = Instance.new("UICorner")
BuildCorner.CornerRadius = UDim.new(0, 6)
BuildCorner.Parent = BuildBtn

-- Paint All button (blue)
local PaintBtn = Instance.new("TextButton")
PaintBtn.Size = UDim2.new(0.5, -10, 0, 28)
PaintBtn.Position = UDim2.new(0, 8, 0, 92)
PaintBtn.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
PaintBtn.BorderSizePixel = 0
PaintBtn.Text = "Paint All"
PaintBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PaintBtn.Font = Enum.Font.GothamBold
PaintBtn.TextSize = 12
PaintBtn.Parent = MainFrame

local PaintCorner = Instance.new("UICorner")
PaintCorner.CornerRadius = UDim.new(0, 6)
PaintCorner.Parent = PaintBtn

-- Stop button (red)
local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.5, -10, 0, 28)
StopBtn.Position = UDim2.new(0.5, 2, 0, 92)
StopBtn.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
StopBtn.BorderSizePixel = 0
StopBtn.Text = "Stop"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
StopBtn.Parent = MainFrame

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 6)
StopCorner.Parent = StopBtn

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Position = UDim2.new(0, 8, 0, 126)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Idle"
StatusLabel.TextColor3 = Color3.fromRGB(120, 130, 145)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- ========== LOGIC ==========
local running = false
local mode = ""  -- "build" or "paint"

local function setProgress(text)
    ProgressLabel.Text = text
end

local function setStatus(text)
    StatusLabel.Text = text
end

-- Wood name -> Color3 mapping (LT2 wood colors)
local WOOD_COLORS = {
    ["Pine"] = Color3.fromRGB(160, 110, 60),
    ["Ember"] = Color3.fromRGB(255, 100, 30),
    ["Frost"] = Color3.fromRGB(120, 200, 255),
    ["Lava"] = Color3.fromRGB(255, 60, 0),
    ["Cave"] = Color3.fromRGB(80, 80, 90),
    ["Volcano"] = Color3.fromRGB(200, 50, 20),
    ["Gold"] = Color3.fromRGB(255, 215, 0),
    ["Swampy"] = Color3.fromRGB(90, 120, 50),
    ["Sinister"] = Color3.fromRGB(40, 20, 30),
    ["Spooky"] = Color3.fromRGB(60, 40, 60),
    ["Phantom"] = Color3.fromRGB(200, 200, 220),
    ["Biolume"] = Color3.fromRGB(100, 255, 150),
    ["Redwood"] = Color3.fromRGB(140, 60, 40),
    ["Midnight"] = Color3.fromRGB(20, 20, 40),
    ["Fire"] = Color3.fromRGB(255, 80, 20),
    ["Glowcap"] = Color3.fromRGB(180, 255, 100),
    ["Strange"] = Color3.fromRGB(150, 100, 200),
    ["Crystal"] = Color3.fromRGB(180, 220, 255),
    ["Magma"] = Color3.fromRGB(255, 120, 40),
    ["Plastic"] = Color3.fromRGB(220, 220, 220),
    ["Neon"] = Color3.fromRGB(255, 255, 100),
    ["Candy"] = Color3.fromRGB(255, 150, 200),
    ["Walnut"] = Color3.fromRGB(100, 70, 40),
    ["Cherry"] = Color3.fromRGB(200, 80, 60),
    ["Oak"] = Color3.fromRGB(170, 120, 70),
    ["Birch"] = Color3.fromRGB(220, 200, 170),
    ["Palm"] = Color3.fromRGB(180, 150, 80),
    ["Koa"] = Color3.fromRGB(120, 80, 50),
    ["Zombie"] = Color3.fromRGB(80, 100, 60),
    ["Glowing"] = Color3.fromRGB(150, 255, 120),
    ["Lemon"] = Color3.fromRGB(255, 230, 50),
    ["Green"] = Color3.fromRGB(80, 200, 60),
    ["Pink"] = Color3.fromRGB(255, 150, 180),
    ["Blue"] = Color3.fromRGB(80, 150, 255),
    ["Purple"] = Color3.fromRGB(160, 80, 220),
    ["Orange"] = Color3.fromRGB(255, 140, 30),
    ["Red"] = Color3.fromRGB(220, 50, 50),
    ["White"] = Color3.fromRGB(240, 240, 240),
    ["Black"] = Color3.fromRGB(30, 30, 30),
    ["Yellow"] = Color3.fromRGB(255, 220, 50),
    ["Teal"] = Color3.fromRGB(0, 180, 180),
    ["Brown"] = Color3.fromRGB(120, 80, 50),
    ["Silver"] = Color3.fromRGB(200, 200, 210),
    ["Marble"] = Color3.fromRGB(230, 230, 235),
    ["Void"] = Color3.fromRGB(50, 0, 80),
    ["Eldritch"] = Color3.fromRGB(100, 50, 120),
    ["Spectral"] = Color3.fromRGB(180, 180, 255),
    ["Cobalt"] = Color3.fromRGB(60, 100, 200),
    ["Amber"] = Color3.fromRGB(255, 180, 50),
    ["Jade"] = Color3.fromRGB(80, 200, 130),
    ["Ruby"] = Color3.fromRGB(220, 30, 50),
    ["Sapphire"] = Color3.fromRGB(50, 80, 220),
    ["Emerald"] = Color3.fromRGB(50, 200, 100),
    ["Topaz"] = Color3.fromRGB(255, 180, 50),
    ["Amethyst"] = Color3.fromRGB(150, 80, 220),
    ["Diamond"] = Color3.fromRGB(200, 240, 255),
    ["Goldwood"] = Color3.fromRGB(255, 200, 50),
    ["Brimstone"] = Color3.fromRGB(255, 80, 20),
    ["Phantomwood"] = Color3.fromRGB(200, 200, 220),
    ["Hellfire"] = Color3.fromRGB(255, 60, 0),
    ["Eternal"] = Color3.fromRGB(255, 255, 200),
    ["Doom"] = Color3.fromRGB(80, 20, 20),
    ["Bluesteel"] = Color3.fromRGB(60, 80, 120),
    ["Blurple"] = Color3.fromRGB(80, 80, 200),
    ["Glowwood"] = Color3.fromRGB(150, 255, 120),
    ["Lavawood"] = Color3.fromRGB(255, 80, 20),
    ["Frostwood"] = Color3.fromRGB(120, 200, 255),
    ["Cavewood"] = Color3.fromRGB(80, 80, 90),
    ["Volcanowood"] = Color3.fromRGB(200, 50, 20),
    ["Sinisterwood"] = Color3.fromRGB(40, 20, 30),
    ["Spookywood"] = Color3.fromRGB(60, 40, 60),
    ["Biolumewood"] = Color3.fromRGB(100, 255, 150),
    ["Redwoodwood"] = Color3.fromRGB(140, 60, 40),
    ["Midnightwood"] = Color3.fromRGB(20, 20, 40),
    ["Strange wood"] = Color3.fromRGB(150, 100, 200),
    ["Pumpkin"] = Color3.fromRGB(255, 140, 30),
    ["Snowglow"] = Color3.fromRGB(200, 230, 255),
    ["Festive"] = Color3.fromRGB(200, 50, 50),
    ["Giftwood"] = Color3.fromRGB(100, 200, 255),
    ["Lightwood"] = Color3.fromRGB(255, 255, 200),
    ["Darkwood"] = Color3.fromRGB(40, 30, 20),
    ["Rainbow"] = Color3.fromRGB(255, 100, 150),
    ["Mystery"] = Color3.fromRGB(150, 150, 150),
}

-- Build function
local function startBuild()
    if running then return end
    running = true
    mode = "build"
    setStatus("Building...")
    notify("Copy Builder", "Build started: " .. TOTAL .. " blueprints", 3)

    local placeRemote = ReplicatedStorage:FindFirstChild("PlaceStructure")
    if not placeRemote then
        notify("Copy Builder", "PlaceStructure not found!", 4)
        running = false
        mode = ""
        setStatus("Error: PlaceStructure not found")
        return
    end

    local placedBlueprint = placeRemote:FindFirstChild("ClientPlacedBlueprint")
    if not placedBlueprint then
        notify("Copy Builder", "ClientPlacedBlueprint not found!", 4)
        running = false
        mode = ""
        setStatus("Error: ClientPlacedBlueprint not found")
        return
    end

    local count = 0
    for i, d in ipairs(DATA) do
        if not running then break end
        if mode ~= "build" then break end

        local cf = CFrame.new(
            d.x, d.y, d.z,
            d.r00, d.r01, d.r02,
            d.r10, d.r11, d.r12,
            d.r20, d.r21, d.r22
        )
        pcall(function()
            placedBlueprint:FireServer(d.n, cf, LocalPlayer)
        end)

        count = count + 1
        setProgress("Place: " .. count .. "/" .. TOTAL)
        task.wait(0.05)
    end

    setProgress("Place: " .. count .. "/" .. TOTAL)
    if running and mode == "build" then
        setStatus("Build complete")
        notify("Copy Builder", "Build complete! " .. count .. "/" .. TOTAL, 4)
    else
        setStatus("Stopped")
        notify("Copy Builder", "Build stopped at " .. count, 3)
    end
    running = false
    mode = ""
end

-- Paint function
local function startPaint()
    if running then return end
    running = true
    mode = "paint"
    setStatus("Scanning models...")
    notify("Copy Builder", "Paint started", 3)

    local placeRemote = ReplicatedStorage:FindFirstChild("PlaceStructure")
    if not placeRemote then
        notify("Copy Builder", "PlaceStructure not found!", 4)
        running = false
        mode = ""
        setStatus("Error")
        return
    end

    local paintTool = placeRemote:FindFirstChild("PaintTool")
    if not paintTool then
        notify("Copy Builder", "PaintTool not found!", 4)
        running = false
        mode = ""
        setStatus("Error: PaintTool not found")
        return
    end

    -- Build index of all models owned by LocalPlayer
    setStatus("Indexing models...")
    local modelIndex = {}  -- {x, y, z, model}

    local function scanModels(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") then
                local owner = child:FindFirstChild("Owner")
                if owner and owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
                    local cf = child:GetPivot()
                    local pos = cf.Position
                    table.insert(modelIndex, {
                        x = pos.X, y = pos.Y, z = pos.Z,
                        model = child
                    })
                end
            end
            -- Recurse into folders
            if #child:GetChildren() > 0 and not child:IsA("BasePart") then
                scanModels(child)
            end
        end
    end

    pcall(function()
        scanModels(Workspace)
    end)

    setStatus("Models found: " .. #modelIndex)
    notify("Copy Builder", "Found " .. #modelIndex .. " models to paint", 3)

    -- Paint by matching coordinates
    local painted = 0
    local skipped = 0

    for i, d in ipairs(DATA) do
        if not running then break end
        if mode ~= "paint" then break end

        if d.color == "?" then
            skipped = skipped + 1
        else
            -- Find nearest model within distance 5
            local bestModel = nil
            local bestDist = 5
            for _, mi in ipairs(modelIndex) do
                local dx = mi.x - d.x
                local dy = mi.y - d.y
                local dz = mi.z - d.z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                if dist < bestDist then
                    bestDist = dist
                    bestModel = mi.model
                end
            end

            if bestModel then
                pcall(function()
                    paintTool:FireServer(bestModel, d.color)
                end)
                painted = painted + 1
            end
        end

        if i % 100 == 0 then
            setProgress("Paint: " .. i .. "/" .. TOTAL)
            setStatus("Painted: " .. painted .. " Skipped: " .. skipped)
            task.wait(0.005)
        end
    end

    setProgress("Paint: " .. TOTAL .. "/" .. TOTAL)
    if running and mode == "paint" then
        setStatus("Paint complete")
        notify("Copy Builder", "Paint complete! Painted: " .. painted .. " Skipped: " .. skipped, 4)
    else
        setStatus("Stopped")
        notify("Copy Builder", "Paint stopped. Painted: " .. painted, 3)
    end
    running = false
    mode = ""
end

-- Stop function
local function stopAll()
    running = false
    mode = ""
    setStatus("Stopped")
    notify("Copy Builder", "Stopped", 2)
end

-- ========== BUTTONS ==========
BuildBtn.MouseButton1Click:Connect(function()
    task.spawn(startBuild)
end)

PaintBtn.MouseButton1Click:Connect(function()
    task.spawn(startPaint)
end)

StopBtn.MouseButton1Click:Connect(stopAll)

-- Init
notify("Copy Builder", "Loaded " .. TOTAL .. " blueprints. Ready!", 3)
setStatus("Ready")
