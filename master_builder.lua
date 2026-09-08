--[[
    master_builder.lua
    整合建筑脚本：金字塔 + JuroShop + 蓝图扫描
    UI 风格：照抄 v8_axefix.lua
    尺寸：250x200
]]

-- ========== 授权检测 ==========
local AUTHORIZED_USERS = {
    ["gccgbxfnb0"]=true,["hxa1010"]=true,["gccgbxfnb4"]=true,
    ["gccgbxfnb3"]=true,["xiguayyds"]=true,["xiaojun1221"]=true,["X8jone"]=true
}
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
if not AUTHORIZED_USERS[lp.Name] then
    lp:Kick("非授权用户")
    return
end

-- ========== 基础服务 ==========
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local placeRemote = RS:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = RS:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

-- ========== 数据 URL ==========
local PYRAMID_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/pyramid_data.lua"
local JUROSHOP_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"

-- ========== UI 缩放 ==========
local function getUIScale()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
    if not viewport then return 1 end
    local short = math.min(viewport.X, viewport.Y)
    return math.clamp(short / 500, 0.75, 1.35)
end

local S = getUIScale()
local function px(n)
    return math.floor(n * S + 0.5)
end

-- ========== 颜色定义 ==========
local COL_BG = Color3.fromRGB(250, 238, 245)
local COL_STROKE = Color3.fromRGB(225, 198, 215)
local COL_TITLE = Color3.fromRGB(145, 103, 134)
local COL_SUBTITLE = Color3.fromRGB(173, 144, 163)
local COL_TAB_SEL = Color3.fromRGB(191, 226, 205)
local COL_TAB_SEL_TEXT = Color3.fromRGB(72, 108, 88)
local COL_TAB_UNSEL = Color3.fromRGB(220, 210, 230)
local COL_TAB_UNSEL_TEXT = Color3.fromRGB(120, 100, 130)
local COL_GREEN_BG = Color3.fromRGB(191, 226, 205)
local COL_GREEN_TEXT = Color3.fromRGB(72, 108, 88)
local COL_RED_BG = Color3.fromRGB(247, 202, 211)
local COL_RED_TEXT = Color3.fromRGB(146, 83, 101)
local COL_BLUE_BG = Color3.fromRGB(190, 224, 242)
local COL_BLUE_TEXT = Color3.fromRGB(76, 116, 140)
local COL_PURPLE_BG = Color3.fromRGB(210, 201, 239)
local COL_PURPLE_TEXT = Color3.fromRGB(112, 91, 145)
local COL_MIN_BG = Color3.fromRGB(215, 202, 232)
local COL_MIN_TEXT = Color3.fromRGB(110, 91, 130)
local COL_CLOSE_BG = Color3.fromRGB(245, 179, 188)
local COL_CLOSE_TEXT = Color3.fromRGB(125, 75, 85)
local COL_NOTIFY_BG = Color3.fromRGB(255, 255, 255)
local COL_LABEL = Color3.fromRGB(130, 110, 140)

-- ========== 通知系统 ==========
local notifyGui
local function notify(text, kind)
    kind = kind or "info"
    if not notifyGui then
        notifyGui = Instance.new("ScreenGui")
        notifyGui.Name = "MasterBuilderNotify"
        notifyGui.ResetOnSpawn = false
        notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifyGui.Parent = game:GetService("CoreGui")
    end

    local notifColor = {
        success = Color3.fromRGB(191, 226, 205),
        error = Color3.fromRGB(247, 202, 211),
        warn = Color3.fromRGB(255, 230, 180),
        info = Color3.fromRGB(190, 224, 242),
    }
    local notifText = {
        success = Color3.fromRGB(72, 108, 88),
        error = Color3.fromRGB(146, 83, 101),
        warn = Color3.fromRGB(160, 110, 40),
        info = Color3.fromRGB(76, 116, 140),
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, px(180), 0, px(36))
    frame.Position = UDim2.new(1, px(-200), 1, px(-50))
    frame.BackgroundColor3 = COL_NOTIFY_BG
    frame.BackgroundTransparency = 0.05
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.ZIndex = 100

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px(10))
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = notifColor[kind] or notifColor.info
    stroke.Thickness = math.max(1, S * 1.2)
    stroke.Transparency = 0.2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, px(-16), 1, 0)
    label.Position = UDim2.new(0, px(8), 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = px(12)
    label.TextColor3 = notifText[kind] or notifText.info
    label.Text = text
    label.TextWrapped = true
    label.ZIndex = 101
    label.Parent = frame

    frame.Parent = notifyGui

    -- 滑入动画
    frame.Position = UDim2.new(1, px(10), 1, px(-50))
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, px(-200), 1, px(-50))
    })
    tweenIn:Play()

    -- 2秒后淡出
    task.delay(2, function()
        local tweenOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        local tweenOut2 = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
        local tweenOut3 = TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 })
        tweenOut:Play()
        tweenOut2:Play()
        tweenOut3:Play()
        task.wait(0.5)
        frame:Destroy()
    end)
end

-- ========== 主 GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterBuilder"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

local FRAME_W = px(250)
local FRAME_H = px(200)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
mainFrame.Position = UDim2.new(0.08, 0, 0.38, 0)
mainFrame.BackgroundColor3 = COL_BG
mainFrame.BackgroundTransparency = 0.04
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, px(14))
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COL_STROKE
mainStroke.Thickness = math.max(1, S * 1.2)
mainStroke.Transparency = 0.15
mainStroke.Parent = mainFrame

-- 拖动逻辑
do
    local dragging = false
    local dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ========== 标题行 ==========
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, px(32))
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, px(80), 1, 0)
titleLabel.Position = UDim2.new(0, px(10), 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.Cartoon
titleLabel.TextSize = px(16)
titleLabel.TextColor3 = COL_TITLE
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Text = "Builder"
titleLabel.Parent = titleBar

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new(Color3.fromRGB(157, 112, 145), Color3.fromRGB(215, 153, 187))
titleGrad.Rotation = 90
titleGrad.Parent = titleLabel

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(0, px(100), 0, px(14))
subtitleLabel.Position = UDim2.new(0, px(10), 0, px(18))
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.TextSize = px(9)
subtitleLabel.TextColor3 = COL_SUBTITLE
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
subtitleLabel.Text = "BUILD • SCAN"
subtitleLabel.Parent = titleBar

-- 最小化按钮
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, px(20), 0, px(20))
minBtn.Position = UDim2.new(1, px(-50), 0, px(6))
minBtn.BackgroundColor3 = COL_MIN_BG
minBtn.Text = "−"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = px(14)
minBtn.TextColor3 = COL_MIN_TEXT
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = minBtn

-- 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, px(20), 0, px(20))
closeBtn.Position = UDim2.new(1, px(-26), 0, px(6))
closeBtn.BackgroundColor3 = COL_CLOSE_BG
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = px(14)
closeBtn.TextColor3 = COL_CLOSE_TEXT
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if notifyGui then notifyGui:Destroy() end
end)

-- ========== 选项卡行 ==========
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, px(-12), 0, px(24))
tabBar.Position = UDim2.new(0, px(6), 0, px(34))
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, px(4))
tabLayout.Parent = tabBar

local tabNames = {"Pyramid", "JuroShop", "Scanner"}
local tabButtons = {}
local contentFrames = {}

local function switchTab(idx)
    for i, btn in ipairs(tabButtons) do
        if i == idx then
            btn.BackgroundColor3 = COL_TAB_SEL
            btn.TextColor3 = COL_TAB_SEL_TEXT
        else
            btn.BackgroundColor3 = COL_TAB_UNSEL
            btn.TextColor3 = COL_TAB_UNSEL_TEXT
        end
    end
    for i, frame in ipairs(contentFrames) do
        frame.Visible = (i == idx)
    end
end

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, px(74), 1, 0)
    btn.BackgroundColor3 = COL_TAB_UNSEL
    btn.TextColor3 = COL_TAB_UNSEL_TEXT
    btn.Text = name
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = px(11)
    btn.BorderSizePixel = 0
    btn.Parent = tabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px(8))
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)

    tabButtons[i] = btn
end

-- 内容区容器
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, px(-12), 1, px(-66))
contentArea.Position = UDim2.new(0, px(6), 0, px(62))
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

-- ========== Pyramid 内容区 ==========
local pyramidFrame = Instance.new("Frame")
pyramidFrame.Size = UDim2.new(1, 0, 1, 0)
pyramidFrame.BackgroundTransparency = 1
pyramidFrame.Parent = contentArea

-- Color 行
local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0, px(40), 0, px(20))
colorLabel.Position = UDim2.new(0, px(4), 0, px(4))
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.TextSize = px(11)
colorLabel.TextColor3 = COL_LABEL
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Text = "Color:"
colorLabel.Parent = pyramidFrame

local colorInput = Instance.new("TextBox")
colorInput.Size = UDim2.new(0, px(80), 0, px(20))
colorInput.Position = UDim2.new(0, px(46), 0, px(4))
colorInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
colorInput.BackgroundTransparency = 0.1
colorInput.Text = "Birch"
colorInput.Font = Enum.Font.GothamMedium
colorInput.TextSize = px(11)
colorInput.TextColor3 = Color3.fromRGB(80, 60, 80)
colorInput.ClearTextOnFocus = false
colorInput.BorderSizePixel = 0
colorInput.Parent = pyramidFrame

local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, px(6))
colorCorner.Parent = colorInput

local colorStroke = Instance.new("UIStroke")
colorStroke.Color = COL_STROKE
colorStroke.Thickness = 1
colorStroke.Transparency = 0.3
colorStroke.Parent = colorInput

-- 进度标签
local pyramidProgress = Instance.new("TextLabel")
pyramidProgress.Size = UDim2.new(1, px(-8), 0, px(20))
pyramidProgress.Position = UDim2.new(0, px(4), 0, px(30))
pyramidProgress.BackgroundTransparency = 1
pyramidProgress.Font = Enum.Font.GothamMedium
pyramidProgress.TextSize = px(11)
pyramidProgress.TextColor3 = COL_LABEL
pyramidProgress.TextXAlignment = Enum.TextXAlignment.Left
pyramidProgress.Text = "Place: 0/3681"
pyramidProgress.Parent = pyramidFrame

-- 按钮行
local pyramidStartBtn = Instance.new("TextButton")
pyramidStartBtn.Size = UDim2.new(0, px(60), 0, px(24))
pyramidStartBtn.Position = UDim2.new(0, px(4), 0, px(56))
pyramidStartBtn.BackgroundColor3 = COL_GREEN_BG
pyramidStartBtn.TextColor3 = COL_GREEN_TEXT
pyramidStartBtn.Text = "Start"
pyramidStartBtn.Font = Enum.Font.GothamMedium
pyramidStartBtn.TextSize = px(11)
pyramidStartBtn.BorderSizePixel = 0
pyramidStartBtn.Parent = pyramidFrame

local psCorner = Instance.new("UICorner")
psCorner.CornerRadius = UDim.new(0, px(9))
psCorner.Parent = pyramidStartBtn

local pyramidStopBtn = Instance.new("TextButton")
pyramidStopBtn.Size = UDim2.new(0, px(60), 0, px(24))
pyramidStopBtn.Position = UDim2.new(0, px(68), 0, px(56))
pyramidStopBtn.BackgroundColor3 = COL_RED_BG
pyramidStopBtn.TextColor3 = COL_RED_TEXT
pyramidStopBtn.Text = "Stop"
pyramidStopBtn.Font = Enum.Font.GothamMedium
pyramidStopBtn.TextSize = px(11)
pyramidStopBtn.BorderSizePixel = 0
pyramidStopBtn.Parent = pyramidFrame

local pstCorner = Instance.new("UICorner")
pstCorner.CornerRadius = UDim.new(0, px(9))
pstCorner.Parent = pyramidStopBtn

local pyramidPaintBtn = Instance.new("TextButton")
pyramidPaintBtn.Size = UDim2.new(0, px(60), 0, px(24))
pyramidPaintBtn.Position = UDim2.new(0, px(132), 0, px(56))
pyramidPaintBtn.BackgroundColor3 = COL_BLUE_BG
pyramidPaintBtn.TextColor3 = COL_BLUE_TEXT
pyramidPaintBtn.Text = "Paint"
pyramidPaintBtn.Font = Enum.Font.GothamMedium
pyramidPaintBtn.TextSize = px(11)
pyramidPaintBtn.BorderSizePixel = 0
pyramidPaintBtn.Parent = pyramidFrame

local ppCorner = Instance.new("UICorner")
ppCorner.CornerRadius = UDim.new(0, px(9))
ppCorner.Parent = pyramidPaintBtn

-- ========== JuroShop 内容区 ==========
local juroFrame = Instance.new("Frame")
juroFrame.Size = UDim2.new(1, 0, 1, 0)
juroFrame.BackgroundTransparency = 1
juroFrame.Visible = false
juroFrame.Parent = contentArea

local juroProgress = Instance.new("TextLabel")
juroProgress.Size = UDim2.new(1, px(-8), 0, px(20))
juroProgress.Position = UDim2.new(0, px(4), 0, px(4))
juroProgress.BackgroundTransparency = 1
juroProgress.Font = Enum.Font.GothamMedium
juroProgress.TextSize = px(11)
juroProgress.TextColor3 = COL_LABEL
juroProgress.TextXAlignment = Enum.TextXAlignment.Left
juroProgress.Text = "Place: 0/2678"
juroProgress.Parent = juroFrame

local juroStartBtn = Instance.new("TextButton")
juroStartBtn.Size = UDim2.new(0, px(60), 0, px(24))
juroStartBtn.Position = UDim2.new(0, px(4), 0, px(30))
juroStartBtn.BackgroundColor3 = COL_GREEN_BG
juroStartBtn.TextColor3 = COL_GREEN_TEXT
juroStartBtn.Text = "Start"
juroStartBtn.Font = Enum.Font.GothamMedium
juroStartBtn.TextSize = px(11)
juroStartBtn.BorderSizePixel = 0
juroStartBtn.Parent = juroFrame

local jsCorner = Instance.new("UICorner")
jsCorner.CornerRadius = UDim.new(0, px(9))
jsCorner.Parent = juroStartBtn

local juroStopBtn = Instance.new("TextButton")
juroStopBtn.Size = UDim2.new(0, px(60), 0, px(24))
juroStopBtn.Position = UDim2.new(0, px(68), 0, px(30))
juroStopBtn.BackgroundColor3 = COL_RED_BG
juroStopBtn.TextColor3 = COL_RED_TEXT
juroStopBtn.Text = "Stop"
juroStopBtn.Font = Enum.Font.GothamMedium
juroStopBtn.TextSize = px(11)
juroStopBtn.BorderSizePixel = 0
juroStopBtn.Parent = juroFrame

local jstCorner = Instance.new("UICorner")
jstCorner.CornerRadius = UDim.new(0, px(9))
jstCorner.Parent = juroStopBtn

local juroPaintBtn = Instance.new("TextButton")
juroPaintBtn.Size = UDim2.new(0, px(60), 0, px(24))
juroPaintBtn.Position = UDim2.new(0, px(132), 0, px(30))
juroPaintBtn.BackgroundColor3 = COL_BLUE_BG
juroPaintBtn.TextColor3 = COL_BLUE_TEXT
juroPaintBtn.Text = "Paint"
juroPaintBtn.Font = Enum.Font.GothamMedium
juroPaintBtn.TextSize = px(11)
juroPaintBtn.BorderSizePixel = 0
juroPaintBtn.Parent = juroFrame

local jpCorner = Instance.new("UICorner")
jpCorner.CornerRadius = UDim.new(0, px(9))
jpCorner.Parent = juroPaintBtn

-- ========== Scanner 内容区 ==========
local scanFrame = Instance.new("Frame")
scanFrame.Size = UDim2.new(1, 0, 1, 0)
scanFrame.BackgroundTransparency = 1
scanFrame.Visible = false
scanFrame.Parent = contentArea

-- Owner 标签
local ownerLabel = Instance.new("TextLabel")
ownerLabel.Size = UDim2.new(0, px(40), 0, px(16))
ownerLabel.Position = UDim2.new(0, px(4), 0, 0)
ownerLabel.BackgroundTransparency = 1
ownerLabel.Font = Enum.Font.GothamMedium
ownerLabel.TextSize = px(11)
ownerLabel.TextColor3 = COL_LABEL
ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
ownerLabel.Text = "Owner:"
ownerLabel.Parent = scanFrame

-- Owner ScrollingFrame
local ownerScroll = Instance.new("ScrollingFrame")
ownerScroll.Size = UDim2.new(1, px(-8), 0, px(50))
ownerScroll.Position = UDim2.new(0, px(4), 0, px(16))
ownerScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ownerScroll.BackgroundTransparency = 0.15
ownerScroll.BorderSizePixel = 0
ownerScroll.ScrollBarThickness = px(4)
ownerScroll.ScrollBarImageColor3 = COL_STROKE
ownerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ownerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ownerScroll.Parent = scanFrame

local osCorner = Instance.new("UICorner")
osCorner.CornerRadius = UDim.new(0, px(6))
osCorner.Parent = ownerScroll

local osStroke = Instance.new("UIStroke")
osStroke.Color = COL_STROKE
osStroke.Thickness = 1
osStroke.Transparency = 0.3
osStroke.Parent = ownerScroll

local ownerListLayout = Instance.new("UIListLayout")
ownerListLayout.Padding = UDim.new(0, px(2))
ownerListLayout.Parent = ownerScroll

-- Scan Owners 按钮
local scanOwnersBtn = Instance.new("TextButton")
scanOwnersBtn.Size = UDim2.new(0, px(120), 0, px(20))
scanOwnersBtn.Position = UDim2.new(0, px(4), 0, px(70))
scanOwnersBtn.BackgroundColor3 = COL_BLUE_BG
scanOwnersBtn.TextColor3 = COL_BLUE_TEXT
scanOwnersBtn.Text = "Scan Owners"
scanOwnersBtn.Font = Enum.Font.GothamMedium
scanOwnersBtn.TextSize = px(10)
scanOwnersBtn.BorderSizePixel = 0
scanOwnersBtn.Parent = scanFrame

local soCorner = Instance.new("UICorner")
soCorner.CornerRadius = UDim.new(0, px(9))
soCorner.Parent = scanOwnersBtn

-- 分割线
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, px(-8), 0, 1)
divider.Position = UDim2.new(0, px(4), 0, px(94))
divider.BackgroundColor3 = COL_STROKE
divider.BackgroundTransparency = 0.3
divider.BorderSizePixel = 0
divider.Parent = scanFrame

-- Scan Blueprints 按钮
local scanBpBtn = Instance.new("TextButton")
scanBpBtn.Size = UDim2.new(0, px(100), 0, px(20))
scanBpBtn.Position = UDim2.new(0, px(4), 0, px(100))
scanBpBtn.BackgroundColor3 = COL_BLUE_BG
scanBpBtn.TextColor3 = COL_BLUE_TEXT
scanBpBtn.Text = "Scan Blueprints"
scanBpBtn.Font = Enum.Font.GothamMedium
scanBpBtn.TextSize = px(10)
scanBpBtn.BorderSizePixel = 0
scanBpBtn.Parent = scanFrame

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, px(9))
sbCorner.Parent = scanBpBtn

-- Copy Result 按钮
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, px(80), 0, px(20))
copyBtn.Position = UDim2.new(0, px(108), 0, px(100))
copyBtn.BackgroundColor3 = COL_PURPLE_BG
copyBtn.TextColor3 = COL_PURPLE_TEXT
copyBtn.Text = "Copy Result"
copyBtn.Font = Enum.Font.GothamMedium
copyBtn.TextSize = px(10)
copyBtn.BorderSizePixel = 0
copyBtn.Parent = scanFrame

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, px(9))
cpCorner.Parent = copyBtn

-- 结果标签
local scanResultLabel = Instance.new("TextLabel")
scanResultLabel.Size = UDim2.new(1, px(-8), 0, px(16))
scanResultLabel.Position = UDim2.new(0, px(4), 0, px(124))
scanResultLabel.BackgroundTransparency = 1
scanResultLabel.Font = Enum.Font.GothamMedium
scanResultLabel.TextSize = px(10)
scanResultLabel.TextColor3 = COL_LABEL
scanResultLabel.TextXAlignment = Enum.TextXAlignment.Left
scanResultLabel.Text = "No scan yet"
scanResultLabel.Parent = scanFrame

-- ========== 状态变量 ==========
local running = false
local selectedOwner = nil
local scanResult = ""
local ownerButtons = {}

-- ========== 最小化逻辑 ==========
local minimized = false
local miniBtn2 = Instance.new("TextButton")
miniBtn2.Size = UDim2.new(0, px(60), 0, px(28))
miniBtn2.Position = UDim2.new(0.08, 0, 0.38, 0)
miniBtn2.BackgroundColor3 = COL_BG
miniBtn2.BackgroundTransparency = 0.04
miniBtn2.Text = "Builder"
miniBtn2.Font = Enum.Font.Cartoon
miniBtn2.TextSize = px(12)
miniBtn2.TextColor3 = COL_TITLE
miniBtn2.BorderSizePixel = 0
miniBtn2.Visible = false
miniBtn2.Parent = screenGui

local mini2Corner = Instance.new("UICorner")
mini2Corner.CornerRadius = UDim.new(0, px(10))
mini2Corner.Parent = miniBtn2

local mini2Stroke = Instance.new("UIStroke")
mini2Stroke.Color = COL_STROKE
mini2Stroke.Thickness = math.max(1, S * 1.2)
mini2Stroke.Transparency = 0.15
mini2Stroke.Parent = miniBtn2

minBtn.MouseButton1Click:Connect(function()
    minimized = true
    mainFrame.Visible = false
    miniBtn2.Visible = true
end)

miniBtn2.MouseButton1Click:Connect(function()
    minimized = false
    mainFrame.Visible = true
    miniBtn2.Visible = false
end)

-- ========== 建造函数 ==========
local function buildPyramid()
    if running then return end
    running = true

    notify("Loading pyramid data...", "info")
    local ok, err = pcall(function()
        loadstring(game:HttpGet(PYRAMID_URL))()
    end)
    if not ok then
        notify("Load failed: " .. tostring(err), "error")
        running = false
        return
    end

    local data = _G.PyramidData
    if not data then
        notify("No PyramidData found", "error")
        running = false
        return
    end

    notify("Building pyramid: " .. #data .. " items", "info")
    local count = 0
    for i, item in ipairs(data) do
        if not running then break end
        local cf = CFrame.new(item.x, item.y, item.z,
            item.r00, item.r01, item.r02,
            item.r10, item.r11, item.r12,
            item.r20, item.r21, item.r22)
        placeRemote:FireServer(item.n, cf, lp)
        count = count + 1
        pyramidProgress.Text = "Place: " .. count .. "/" .. #data
        if count % 50 == 0 then
            task.wait(0.005)
        end
    end
    running = false
    notify("Pyramid done: " .. count .. " placed", "success")
end

local function buildJuroShop()
    if running then return end
    running = true

    notify("Loading blueprint data...", "info")
    local ok, err = pcall(function()
        loadstring(game:HttpGet(JUROSHOP_URL))()
    end)
    if not ok then
        notify("Load failed: " .. tostring(err), "error")
        running = false
        return
    end

    local data = _G.BlueprintData
    if not data then
        notify("No BlueprintData found", "error")
        running = false
        return
    end

    notify("Building JuroShop: " .. (#data - 1) .. " items", "info")
    local count = 0
    for i = 2, #data do -- 跳过第1条 Property
        if not running then break end
        local item = data[i]
        local cf = CFrame.new(item.x, item.y, item.z,
            item.r00, item.r01, item.r02,
            item.r10, item.r11, item.r12,
            item.r20, item.r21, item.r22)
        placeRemote:FireServer(item.n, cf, lp)
        count = count + 1
        juroProgress.Text = "Place: " .. count .. "/" .. (#data - 1)
        task.wait(0.01)
    end
    running = false
    notify("JuroShop done: " .. count .. " placed", "success")
end

-- ========== 涂色函数 ==========
local function paintStructures(data, colorKey, label)
    if running then return end
    running = true
    notify("Painting...", "info")

    -- 扫描 workspace 所有 Owner==lp 的 Model，建坐标索引
    local modelIndex = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
            local ownerName = nil
            if typeof(owner) == "string" then
                ownerName = owner
            elseif owner and owner:IsA("StringValue") then
                ownerName = owner.Value
            end
            if ownerName == lp.Name then
                local pos = obj:GetPivot().Position
                table.insert(modelIndex, {model = obj, pos = pos})
            end
        end
    end

    notify("Found " .. #modelIndex .. " models", "info")

    local painted = 0
    for i, item in ipairs(data) do
        if not running then break end
        local targetColor = item[colorKey]
        if targetColor and targetColor ~= "?" then
            local itemPos = Vector3.new(item.x, item.y, item.z)
            for _, mi in ipairs(modelIndex) do
                local dist = (mi.pos - itemPos).Magnitude
                if dist < 5 then
                    pcall(function()
                        paintRemote:FireServer(mi.model, targetColor)
                    end)
                    painted = painted + 1
                    break
                end
            end
        end
        if i % 100 == 0 then
            task.wait(0.005)
        end
    end
    running = false
    notify(label .. " painted: " .. painted, "success")
end

-- ========== 按钮绑定 ==========
pyramidStartBtn.MouseButton1Click:Connect(buildPyramid)
pyramidStopBtn.MouseButton1Click:Connect(function()
    running = false
    notify("Stopped", "warn")
end)
pyramidPaintBtn.MouseButton1Click:Connect(function()
    if not _G.PyramidData then
        notify("Load data first (Start)", "warn")
        return
    end
    paintStructures(_G.PyramidData, "color", "Pyramid")
end)

juroStartBtn.MouseButton1Click:Connect(buildJuroShop)
juroStopBtn.MouseButton1Click:Connect(function()
    running = false
    notify("Stopped", "warn")
end)
juroPaintBtn.MouseButton1Click:Connect(function()
    if not _G.BlueprintData then
        notify("Load data first (Start)", "warn")
        return
    end
    paintStructures(_G.BlueprintData, "wood", "JuroShop")
end)

-- ========== Scanner 逻辑 ==========
scanOwnersBtn.MouseButton1Click:Connect(function()
    -- 清空旧按钮
    for _, btn in ipairs(ownerButtons) do
        btn:Destroy()
    end
    ownerButtons = {}

    local ownerSet = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
            local ownerName = nil
            if typeof(owner) == "string" then
                ownerName = owner
            elseif owner and owner:IsA("StringValue") then
                ownerName = owner.Value
            end
            if ownerName and ownerName ~= "" then
                ownerSet[ownerName] = true
            end
        end
    end

    local count = 0
    for name, _ in pairs(ownerSet) do
        count = count + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, px(18))
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.1
        btn.Text = name
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = px(10)
        btn.TextColor3 = Color3.fromRGB(80, 60, 80)
        btn.BorderSizePixel = 0
        btn.Parent = ownerScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, px(4))
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectedOwner = name
            for _, b in ipairs(ownerButtons) do
                b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                b.BackgroundTransparency = 0.1
                b.TextColor3 = Color3.fromRGB(80, 60, 80)
            end
            btn.BackgroundColor3 = COL_TAB_SEL
            btn.BackgroundTransparency = 0
            btn.TextColor3 = COL_TAB_SEL_TEXT
        end)

        table.insert(ownerButtons, btn)
    end

    scanResultLabel.Text = "Found " .. count .. " owners"
    notify("Scanned " .. count .. " owners", "success")
end)

scanBpBtn.MouseButton1Click:Connect(function()
    if not selectedOwner then
        notify("Select an owner first", "warn")
        return
    end

    local results = {}
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local owner = obj:GetAttribute("Owner") or obj:FindFirstChild("Owner")
            local ownerName = nil
            if typeof(owner) == "string" then
                ownerName = owner
            elseif owner and owner:IsA("StringValue") then
                ownerName = owner.Value
            end

            local objType = obj:GetAttribute("Type") or (obj:FindFirstChild("Type") and obj:FindFirstChild("Type").Value)
            if ownerName == selectedOwner and objType == "Blueprint" then
                count = count + 1
                local itemName = obj:GetAttribute("ItemName") or obj.Name
                local woodVal = ""
                local bpWood = obj:FindFirstChild("BlueprintWoodClass")
                if bpWood then woodVal = tostring(bpWood.Value) end
                local pos = obj:GetPivot().Position
                local line = string.format("[%d] \"%s\" | Wood: %s | pos(%.1f, %.1f, %.1f)",
                    count, itemName, woodVal, pos.X, pos.Y, pos.Z)
                table.insert(results, line)
            end
        end
    end

    scanResult = table.concat(results, "\n")
    scanResultLabel.Text = "Found " .. count .. " blueprints"
    notify("Scanned " .. count .. " blueprints", "success")
end)

copyBtn.MouseButton1Click:Connect(function()
    if scanResult == "" then
        notify("No result to copy", "warn")
        return
    end
    pcall(function()
        setclipboard(scanResult)
    end)
    notify("Copied to clipboard", "success")
end)

-- ========== 初始化 ==========
switchTab(1)
notify("Master Builder loaded", "success")
