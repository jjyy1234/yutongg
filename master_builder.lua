-- master_builder.lua
-- 整合建筑脚本：金字塔 + JuroShop + Scanner
-- UI 风格照抄 YutongFly

-- ========== 授权检测 ==========
local AUTHORIZED_USERS = {"gccgbxfnb0","hxa1010","gccgbxfnb4","gccgbxfnb3","xiguayyds","xiaojun1221","X8jone"}
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local authorized = false
for _, u in ipairs(AUTHORIZED_USERS) do
    if lp.Name == u then authorized = true break end
end
if not authorized then
    lp:Kick("Unauthorized")
    return
end

-- ========== 服务 ==========
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local placeRemote = ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint
local paintRemote = ReplicatedStorage.PlaceStructure.PaintTool

-- ========== 数据 URL ==========
local PYRAMID_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/pyramid_data.lua"
local JUROSHOP_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"

-- ========== 状态 ==========
local pyramidData = nil
local juroshopData = nil
local selectedBuild = "Pyramid"
local selectedOwner = nil
local scanResults = {}
local building = false
local painting = false
local scanning = false
local ownerList = {}

-- ========== UI 缩放 ==========
local function getUIScale()
    local short = math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y)
    return math.clamp(short / 500, 0.75, 1.35)
end

local S = getUIScale()
local function px(n)
    return math.floor(n * S + 0.5)
end

-- ========== 通知 ==========
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Builder", Text=text, Duration=3})
    end)
end

-- ========== UI 创建 ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MasterBuilder"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, px(220), 0, px(420))
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
MainFrame.BackgroundTransparency = 0.04
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, px(14))
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(225, 198, 215)
MainStroke.Thickness = S * 1.2
MainStroke.Parent = MainFrame

-- ========== 拖动逻辑 ==========
local dragging = false
local dragStart, startPos
local dragInput
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ========== 标题行 ==========
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(0, px(120), 0, px(28))
TitleLabel.Position = UDim2.new(0, px(10), 0, px(8))
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.Cartoon
TitleLabel.Text = "Builder"
TitleLabel.TextScaled = true
TitleLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
TitleLabel.Parent = MainFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new(Color3.fromRGB(157, 112, 145), Color3.fromRGB(215, 153, 187))
TitleGradient.Parent = TitleLabel

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Name = "SubTitle"
SubTitleLabel.Size = UDim2.new(0, px(100), 0, px(14))
SubTitleLabel.Position = UDim2.new(0, px(10), 0, px(36))
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Font = Enum.Font.GothamMedium
SubTitleLabel.Text = "BUILD • SCAN"
SubTitleLabel.TextScaled = true
SubTitleLabel.TextColor3 = Color3.fromRGB(173, 144, 163)
SubTitleLabel.Parent = MainFrame

-- ========== 最小化 & 关闭按钮 ==========
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, px(22), 0, px(22))
MinBtn.Position = UDim2.new(1, px(-58), 0, px(10))
MinBtn.BackgroundColor3 = Color3.fromRGB(215, 202, 232)
MinBtn.Text = "−"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextScaled = true
MinBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
MinBtn.BorderSizePixel = 0
MinBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, px(22), 0, px(22))
CloseBtn.Position = UDim2.new(1, px(-30), 0, px(10))
CloseBtn.BackgroundColor3 = Color3.fromRGB(245, 179, 188)
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true
CloseBtn.TextColor3 = Color3.fromRGB(125, 75, 85)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ========== 最小化逻辑 ==========
local minimized = false
local MinFrame = Instance.new("Frame")
MinFrame.Name = "MinFrame"
MinFrame.Size = UDim2.new(0, px(50), 0, px(50))
MinFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MinFrame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
MinFrame.BackgroundTransparency = 0.04
MinFrame.BorderSizePixel = 0
MinFrame.Visible = false
MinFrame.Parent = ScreenGui

local MinFrameCorner = Instance.new("UICorner")
MinFrameCorner.CornerRadius = UDim.new(0, px(14))
MinFrameCorner.Parent = MinFrame

local MinFrameStroke = Instance.new("UIStroke")
MinFrameStroke.Color = Color3.fromRGB(225, 198, 215)
MinFrameStroke.Thickness = S * 1.2
MinFrameStroke.Parent = MinFrame

local MinExpandBtn = Instance.new("TextButton")
MinExpandBtn.Size = UDim2.new(1, 0, 1, 0)
MinExpandBtn.BackgroundTransparency = 1
MinExpandBtn.Text = "Builder"
MinExpandBtn.Font = Enum.Font.Cartoon
MinExpandBtn.TextScaled = true
MinExpandBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
MinExpandBtn.Parent = MinFrame

MinBtn.MouseButton1Click:Connect(function()
    minimized = true
    MainFrame.Visible = false
    MinFrame.Visible = true
end)
MinExpandBtn.MouseButton1Click:Connect(function()
    minimized = false
    MainFrame.Visible = true
    MinFrame.Visible = false
end)

-- 拖动 MinFrame
local mDrag = false
local mStart, mPos, mInput
MinFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mDrag = true
        mStart = input.Position
        mPos = MinFrame.Position
    end
end)
MinFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        mInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == mInput and mDrag then
        local delta = input.Position - mStart
        MinFrame.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + delta.X, mPos.Y.Scale, mPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mDrag = false
    end
end)

-- ========== 辅助函数 ==========
local function makeButton(parent, text, bgColor, textColor, posY, sizeX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, px(sizeX or 60), 0, px(26))
    btn.Position = UDim2.new(0, px(10), 0, px(posY))
    btn.BackgroundColor3 = bgColor
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.TextColor3 = textColor
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px(9))
    corner.Parent = btn
    return btn
end

local function makeLabel(parent, text, posY, font, color, sizeX)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, px(sizeX or 200), 0, px(18))
    lbl.Position = UDim2.new(0, px(10), 0, px(posY))
    lbl.BackgroundTransparency = 1
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextScaled = true
    lbl.TextColor3 = color or Color3.fromRGB(173, 144, 163)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function makeDivider(parent, posY)
    local div = Instance.new("Frame")
    div.Size = UDim2.new(0, px(200), 0, 1)
    div.Position = UDim2.new(0, px(10), 0, px(posY))
    div.BackgroundColor3 = Color3.fromRGB(200, 180, 210)
    div.BorderSizePixel = 0
    div.Parent = parent
    return div
end

-- ========== Owner 选择区 ==========
makeLabel(MainFrame, "Owner:", 58, Enum.Font.GothamMedium, Color3.fromRGB(173, 144, 163))

local OwnerScroll = Instance.new("ScrollingFrame")
OwnerScroll.Name = "OwnerScroll"
OwnerScroll.Size = UDim2.new(0, px(200), 0, px(60))
OwnerScroll.Position = UDim2.new(0, px(10), 0, px(78))
OwnerScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
OwnerScroll.BackgroundTransparency = 0.5
OwnerScroll.BorderSizePixel = 0
OwnerScroll.ScrollBarThickness = px(3)
OwnerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
OwnerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
OwnerScroll.Parent = MainFrame

local OwnerCorner = Instance.new("UICorner")
OwnerCorner.CornerRadius = UDim.new(0, px(6))
OwnerCorner.Parent = OwnerScroll

local OwnerLayout = Instance.new("UIListLayout")
OwnerLayout.Padding = UDim.new(0, px(2))
OwnerLayout.Parent = OwnerScroll

local ScanOwnersBtn = makeButton(MainFrame, "Scan Owners", Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140), 142, 200)

-- ========== 分割线 ==========
makeDivider(MainFrame, 174)

-- ========== 建筑选择区 ==========
makeLabel(MainFrame, "Build:", 180, Enum.Font.GothamMedium, Color3.fromRGB(173, 144, 163))

local PyramidBtn = Instance.new("TextButton")
PyramidBtn.Size = UDim2.new(0, px(92), 0, px(26))
PyramidBtn.Position = UDim2.new(0, px(10), 0, px(200))
PyramidBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
PyramidBtn.Text = "Pyramid"
PyramidBtn.Font = Enum.Font.GothamBold
PyramidBtn.TextScaled = true
PyramidBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
PyramidBtn.BorderSizePixel = 0
PyramidBtn.Parent = MainFrame
local PyramidCorner = Instance.new("UICorner")
PyramidCorner.CornerRadius = UDim.new(0, px(9))
PyramidCorner.Parent = PyramidBtn

local JuroBtn = Instance.new("TextButton")
JuroBtn.Size = UDim2.new(0, px(92), 0, px(26))
JuroBtn.Position = UDim2.new(0, px(108), 0, px(200))
JuroBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
JuroBtn.Text = "JuroShop"
JuroBtn.Font = Enum.Font.GothamBold
JuroBtn.TextScaled = true
JuroBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
JuroBtn.BorderSizePixel = 0
JuroBtn.Parent = MainFrame
local JuroCorner = Instance.new("UICorner")
JuroCorner.CornerRadius = UDim.new(0, px(9))
JuroCorner.Parent = JuroBtn

local function updateBuildSelection()
    if selectedBuild == "Pyramid" then
        PyramidBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        PyramidBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        JuroBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        JuroBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    else
        JuroBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        JuroBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        PyramidBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        PyramidBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    end
end

PyramidBtn.MouseButton1Click:Connect(function()
    selectedBuild = "Pyramid"
    updateBuildSelection()
end)
JuroBtn.MouseButton1Click:Connect(function()
    selectedBuild = "JuroShop"
    updateBuildSelection()
end)

-- ========== 颜色输入框 ==========
makeLabel(MainFrame, "Color:", 232, Enum.Font.GothamMedium, Color3.fromRGB(173, 144, 163))

local ColorBox = Instance.new("TextBox")
ColorBox.Size = UDim2.new(0, px(80), 0, px(24))
ColorBox.Position = UDim2.new(0, px(60), 0, px(230))
ColorBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ColorBox.BackgroundTransparency = 0.3
ColorBox.Text = "Birch"
ColorBox.Font = Enum.Font.GothamMedium
ColorBox.TextScaled = true
ColorBox.TextColor3 = Color3.fromRGB(80, 80, 80)
ColorBox.PlaceholderText = "Birch"
ColorBox.BorderSizePixel = 0
ColorBox.Parent = MainFrame
local ColorCorner = Instance.new("UICorner")
ColorCorner.CornerRadius = UDim.new(0, px(6))
ColorCorner.Parent = ColorBox

-- ========== 按钮行 ==========
local StartBtn = makeButton(MainFrame, "Start", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88), 262, 60)
local StopBtn = makeButton(MainFrame, "Stop", Color3.fromRGB(245, 179, 188), Color3.fromRGB(125, 75, 85), 262, 60)
StopBtn.Position = UDim2.new(0, px(75), 0, px(262))
local PaintBtn = makeButton(MainFrame, "Paint", Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140), 262, 60)
PaintBtn.Position = UDim2.new(0, px(140), 0, px(262))

-- ========== 进度标签 ==========
local ProgressLabel = makeLabel(MainFrame, "Place: 0/0", 294, Enum.Font.GothamMedium, Color3.fromRGB(145, 103, 134), 200)

-- ========== 分割线 ==========
makeDivider(MainFrame, 316)

-- ========== Scanner 区域 ==========
local ScannerLabel = Instance.new("TextLabel")
ScannerLabel.Size = UDim2.new(0, px(200), 0, px(18))
ScannerLabel.Position = UDim2.new(0, px(10), 0, px(322))
ScannerLabel.BackgroundTransparency = 1
ScannerLabel.Font = Enum.Font.GothamBold
ScannerLabel.Text = "Scanner"
ScannerLabel.TextScaled = true
ScannerLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
ScannerLabel.TextXAlignment = Enum.TextXAlignment.Left
ScannerLabel.Parent = MainFrame

local ScanBPBtn = makeButton(MainFrame, "Scan Blueprints", Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140), 344, 200)
local CopyBtn = makeButton(MainFrame, "Copy Result", Color3.fromRGB(210, 201, 239), Color3.fromRGB(112, 91, 145), 374, 200)

local ScanResultLabel = makeLabel(MainFrame, "Scan: ready", 404, Enum.Font.GothamMedium, Color3.fromRGB(145, 103, 134), 200)

-- ========== Owner 列表刷新 ==========
local function refreshOwnerList()
    -- 清空旧
    for _, child in ipairs(OwnerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, name in ipairs(ownerList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, px(20))
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.5
        btn.Text = name
        btn.Font = Enum.Font.GothamMedium
        btn.TextScaled = true
        btn.TextColor3 = Color3.fromRGB(80, 80, 80)
        btn.BorderSizePixel = 0
        btn.Parent = OwnerScroll
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, px(4))
        c.Parent = btn
        btn.MouseButton1Click:Connect(function()
            selectedOwner = name
            for _, ch in ipairs(OwnerScroll:GetChildren()) do
                if ch:IsA("TextButton") then
                    if ch.Text == name then
                        ch.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
                        ch.TextColor3 = Color3.fromRGB(72, 108, 88)
                    else
                        ch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        ch.TextColor3 = Color3.fromRGB(80, 80, 80)
                    end
                end
            end
        end)
    end
end

-- ========== Scan Owners 逻辑 ==========
ScanOwnersBtn.MouseButton1Click:Connect(function()
    ownerList = {}
    local seen = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
            if owner then
                local name
                if type(owner) == "string" then
                    name = owner
                elseif typeof(owner) == "Instance" and owner:IsA("ObjectValue") then
                    if owner.Value and owner.Value:IsA("Player") then
                        name = owner.Value.Name
                    end
                elseif typeof(owner) == "Instance" and owner:IsA("StringValue") then
                    name = owner.Value
                end
                if name and name ~= "" and not seen[name] then
                    seen[name] = true
                    table.insert(ownerList, name)
                end
            end
        end
    end
    refreshOwnerList()
    notify("Found " .. #ownerList .. " owners")
end)

-- ========== 数据加载 ==========
local function loadPyramidData()
    if pyramidData then return pyramidData end
    local ok = pcall(function()
        loadstring(game:HttpGet(PYRAMID_URL))()
    end)
    if ok and _G.PyramidData then
        pyramidData = _G.PyramidData
    end
    return pyramidData
end

local function loadJuroshopData()
    if juroshopData then return juroshopData end
    local ok = pcall(function()
        loadstring(game:HttpGet(JUROSHOP_URL))()
    end)
    if ok and _G.BlueprintData then
        juroshopData = _G.BlueprintData
    end
    return juroshopData
end

-- ========== Start Build 逻辑 ==========
StartBtn.MouseButton1Click:Connect(function()
    if building then return end
    building = true
    notify("Start building " .. selectedBuild)

    local data, delay, colorField
    if selectedBuild == "Pyramid" then
        data = loadPyramidData()
        delay = 0.005
        colorField = "color"
    else
        data = loadJuroshopData()
        delay = 0.01
        colorField = "wood"
    end

    if not data then
        notify("Failed to load data")
        building = false
        return
    end

    local total = #data
    ProgressLabel.Text = "Place: 0/" .. total

    task.spawn(function()
        for i, entry in ipairs(data) do
            if not building then break end
            -- JuroShop 第1条是 Property 跳过
            if selectedBuild == "JuroShop" and i == 1 then
                ProgressLabel.Text = "Place: 0/" .. (total - 1)
            else
                local cf = CFrame.new(
                    entry.x, entry.y, entry.z,
                    entry.r00, entry.r01, entry.r02,
                    entry.r10, entry.r11, entry.r12,
                    entry.r20, entry.r21, entry.r22
                )
                pcall(function()
                    placeRemote:FireServer(entry.n, cf, lp)
                end)
                local placed = i
                if selectedBuild == "JuroShop" then placed = i - 1 end
                ProgressLabel.Text = "Place: " .. placed .. "/" .. (selectedBuild == "JuroShop" and (total - 1) or total)
                task.wait(delay)
            end
        end
        building = false
        notify("Build complete")
        ProgressLabel.Text = "Place: done"
    end)
end)

-- ========== Stop 逻辑 ==========
StopBtn.MouseButton1Click:Connect(function()
    building = false
    painting = false
    notify("Stopped")
end)

-- ========== Paint 逻辑 ==========
PaintBtn.MouseButton1Click:Connect(function()
    if painting then return end
    painting = true
    notify("Start painting")

    local data, colorField
    if selectedBuild == "Pyramid" then
        data = loadPyramidData()
        colorField = "color"
    else
        data = loadJuroshopData()
        colorField = "wood"
    end

    if not data then
        notify("Failed to load data")
        painting = false
        return
    end

    local colorInput = ColorBox.Text
    if colorInput == "" then colorInput = "Birch" end

    task.spawn(function()
        -- 一次性扫所有 Owner==lp 的 Model 建索引
        local models = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
                local isOwner = false
                if type(owner) == "string" and owner == lp.Name then
                    isOwner = true
                elseif typeof(owner) == "Instance" and owner:IsA("ObjectValue") and owner.Value == lp then
                    isOwner = true
                end
                if isOwner then
                    local p = obj:GetPivot()
                    table.insert(models, {model = obj, pos = p.Position})
                end
            end
        end

        local total = #data
        local painted = 0
        ProgressLabel.Text = "Paint: 0/" .. total

        for i, entry in ipairs(data) do
            if not painting then break end
            -- JuroShop 第1条 Property 跳过
            if selectedBuild == "JuroShop" and i == 1 then
                ProgressLabel.Text = "Paint: 0/" .. (total - 1)
            else
                local entryPos = Vector3.new(entry.x, entry.y, entry.z)
                local colorName
                if selectedBuild == "Pyramid" then
                    colorName = entry.color or colorInput
                else
                    colorName = entry.wood
                    if colorName == "?" or colorName == "" then
                        -- 跳过
                        local painted2 = i - 1
                        ProgressLabel.Text = "Paint: " .. painted2 .. "/" .. (total - 1)
                        if i % 100 == 0 then task.wait(0.005) end
                    end
                end

                if colorName and colorName ~= "?" and colorName ~= "" then
                    -- 按坐标匹配（距离<5）
                    for _, m in ipairs(models) do
                        if (m.pos - entryPos).Magnitude < 5 then
                            pcall(function()
                                paintRemote:FireServer(m.model, colorName)
                            end)
                            painted = painted + 1
                            break
                        end
                    end
                end

                local shown = i
                if selectedBuild == "JuroShop" then shown = i - 1 end
                ProgressLabel.Text = "Paint: " .. shown .. "/" .. (selectedBuild == "JuroShop" and (total - 1) or total)
                if i % 100 == 0 then task.wait(0.005) end
            end
        end
        painting = false
        notify("Paint complete: " .. painted .. " painted")
        ProgressLabel.Text = "Paint: done"
    end)
end)

-- ========== Scan Blueprints 逻辑 ==========
ScanBPBtn.MouseButton1Click:Connect(function()
    if not selectedOwner then
        notify("Select an owner first")
        return
    end
    scanning = true
    scanResults = {}

    task.spawn(function()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                -- 检查 Owner 是否匹配
                local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
                local isOwner = false
                if type(owner) == "string" and owner == selectedOwner then
                    isOwner = true
                elseif typeof(owner) == "Instance" and owner:IsA("ObjectValue") and owner.Value and owner.Value.Name == selectedOwner then
                    isOwner = true
                elseif typeof(owner) == "Instance" and owner:IsA("StringValue") and owner.Value == selectedOwner then
                    isOwner = true
                end

                if isOwner then
                    local name = obj.Name
                    -- 读 BlueprintWoodClass.Value 作为 Wood
                    local wood = "?"
                    local woodClass = obj:FindFirstChild("BlueprintWoodClass")
                    if woodClass and woodClass:IsA("StringValue") then
                        wood = woodClass.Value
                    elseif woodClass and woodClass:IsA("ValueBase") then
                        wood = tostring(woodClass.Value)
                    end

                    local cf = obj:GetPivot()
                    local pos = cf.Position
                    local r = cf.Rotation
                    local r00, r01, r02 = r:ToEulerAnglesXYZ()
                    -- 用完整 CFrame 序列化
                    local cfStr = string.format(
                        "CFrame.new(%.2f, %.2f, %.2f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",
                        pos.X, pos.Y, pos.Z,
                        r.X, r.Y, r.Z, 0, 0, 0, 0, 0, 0
                    )
                    -- 更准确：直接取 CFrame 组件
                    local components = {obj:GetPivot():GetComponents()}
                    if #components >= 12 then
                        cfStr = string.format(
                            "CFrame.new(%.2f, %.2f, %.2f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",
                            components[1], components[2], components[3],
                            components[4], components[5], components[6],
                            components[7], components[8], components[9],
                            components[10], components[11], components[12]
                        )
                    end

                    count = count + 1
                    local line = string.format('[%d] "%s" | Wood: %s | %s', count, name, wood, cfStr)
                    table.insert(scanResults, line)
                end
            end
        end
        scanning = false
        ScanResultLabel.Text = "Scan: " .. count .. " found"
        notify("Scan complete: " .. count .. " blueprints")
    end)
end)

-- ========== Copy Result 逻辑 ==========
CopyBtn.MouseButton1Click:Connect(function()
    if #scanResults == 0 then
        notify("No results to copy")
        return
    end
    local text = table.concat(scanResults, "\n")
    pcall(function()
        if setclipboard then
            setclipboard(text)
        end
    end)
    notify("Copied " .. #scanResults .. " results")
end)

-- ========== 初始化 ==========
updateBuildSelection()
notify("Builder loaded")

-- ========== UI 缩放自适应 ==========
RunService.RenderStepped:Connect(function()
    local newS = getUIScale()
    if math.abs(newS - S) > 0.05 then
        S = newS
    end
end)
