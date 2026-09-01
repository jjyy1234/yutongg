-- ===== 砍树调试 UI =====
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local speaker = Players.LocalPlayer
local PlayerGui = speaker:WaitForChild("PlayerGui")

-- 清理旧 UI
local old = PlayerGui:FindFirstChild("DebugUI")
if old then old:Destroy() end

local results = {}
local function log(s)
    table.insert(results, s)
    print("[Debug]", s)
end

local function runScan()
    results = {}

    -- 1. 斧头检测
    log("===== 斧头 =====")
    local axeCount = 0
    for _, v in pairs(speaker.Backpack:GetChildren()) do
        log("背包: " .. v.Name .. " (" .. v.ClassName .. ")")
        axeCount = axeCount + 1
    end
    if speaker.Character then
        for _, v in pairs(speaker.Character:GetChildren()) do
            if v:IsA("Tool") then
                log("手持: " .. v.Name)
                axeCount = axeCount + 1
            end
        end
    end
    if axeCount == 0 then log("!! 背包和手里都没有工具") end

    -- 2. AxeClasses 检测
    log("===== AxeClasses =====")
    local ac = RS:FindFirstChild("AxeClasses")
    if ac then
        log("AxeClasses 存在，子物体数: " .. #ac:GetChildren())
        for _, v in pairs(ac:GetChildren()) do
            log("  " .. v.Name)
        end
    else
        log("!! AxeClasses 不存在")
    end

    -- 3. TreeRegion 检测
    log("===== TreeRegion =====")
    local treeFound = 0
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "TreeRegion" then
            log("TreeRegion 子物体数: " .. #v:GetChildren())
            for _, t in pairs(v:GetChildren()) do
                local tc = t:FindFirstChild("TreeClass")
                local owner = t:FindFirstChild("Owner")
                local ws = t:FindFirstChild("WoodSection")
                if tc then
                    treeFound = treeFound + 1
                    local ownerStr = owner and tostring(owner.Value) or "nil"
                    local isMine = owner and (owner.Value == nil or tostring(owner.Value) == tostring(speaker))
                    log(string.format("树: %s | Owner: %s | 可砍: %s | WoodSection: %s",
                        tc.Value, ownerStr, tostring(isMine), tostring(ws ~= nil)))
                end
            end
        end
    end
    if treeFound == 0 then log("!! 没有找到任何树") end

    -- 4. LogModels 检测
    log("===== LogModels =====")
    local lm = workspace:FindFirstChild("LogModels")
    if lm then
        log("LogModels 存在，子物体数: " .. #lm:GetChildren())
    else
        log("!! LogModels 不存在")
    end

    -- 5. Interaction Remote 检测
    log("===== Interaction =====")
    local inter = RS:FindFirstChild("Interaction")
    if inter then
        log("Interaction 存在")
        local rp = inter:FindFirstChild("RemoteProxy")
        local drag = inter:FindFirstChild("ClientIsDragging")
        log("RemoteProxy: " .. tostring(rp ~= nil))
        log("ClientIsDragging: " .. tostring(drag ~= nil))
    else
        log("!! Interaction 不存在")
    end

    -- 6. PlayerModels 检测
    log("===== PlayerModels =====")
    local pm = workspace:FindFirstChild("PlayerModels")
    if pm then
        log("PlayerModels 存在，子物体数: " .. #pm:GetChildren())
    else
        log("!! PlayerModels 不存在")
    end

    log("===== 扫描完成 =====")
    return table.concat(results, "\n")
end

-- ===== UI =====
local S = math.clamp(math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y) / 500, 0.75, 1.35)
local function px(n) return math.floor(n * S + 0.5) end

local gui = Instance.new("ScreenGui")
gui.Name = "DebugUI"
gui.Parent = PlayerGui
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, px(320), 0, px(420))
frame.Position = UDim2.new(0.5, -px(160), 0.5, -px(210))
frame.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
frame.BorderSizePixel = 0
frame.ZIndex = 10
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, px(12))

local stroke = Instance.new("UIStroke")
stroke.Parent = frame
stroke.Color = Color3.fromRGB(145, 103, 134)
stroke.Thickness = 1.5

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Parent = frame
titleBar.Size = UDim2.new(1, 0, 0, px(32))
titleBar.BackgroundColor3 = Color3.fromRGB(50, 35, 55)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, px(12))

local titleFix = Instance.new("Frame")
titleFix.Parent = titleBar
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(50, 35, 55)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 11

local title = Instance.new("TextLabel")
title.Parent = titleBar
title.Size = UDim2.new(1, -px(32), 1, 0)
title.Position = UDim2.new(0, px(12), 0, 0)
title.BackgroundTransparency = 1
title.Text = "砍树调试"
title.TextColor3 = Color3.fromRGB(250, 238, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = px(11)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12

-- 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, px(24), 0, px(24))
closeBtn.Position = UDim2.new(1, -px(28), 0.5, -px(12))
closeBtn.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(146, 83, 101)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = px(10)
closeBtn.ZIndex = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, px(6))
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- 拖动
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMove) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- 按钮区
local btnFrame = Instance.new("Frame")
btnFrame.Parent = frame
btnFrame.Size = UDim2.new(1, -px(16), 0, px(30))
btnFrame.Position = UDim2.new(0, px(8), 0, px(38))
btnFrame.BackgroundTransparency = 1
btnFrame.ZIndex = 11

local scanBtn = Instance.new("TextButton")
scanBtn.Parent = btnFrame
scanBtn.Size = UDim2.new(0.48, 0, 1, 0)
scanBtn.Position = UDim2.new(0, 0, 0, 0)
scanBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
scanBtn.BorderSizePixel = 0
scanBtn.Text = "开始扫描"
scanBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = px(10)
scanBtn.ZIndex = 12
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, px(6))

local copyBtn = Instance.new("TextButton")
copyBtn.Parent = btnFrame
copyBtn.Size = UDim2.new(0.48, 0, 1, 0)
copyBtn.Position = UDim2.new(0.52, 0, 0, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
copyBtn.BorderSizePixel = 0
copyBtn.Text = "一键复制"
copyBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = px(10)
copyBtn.ZIndex = 12
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, px(6))

-- 结果滚动框
local scroll = Instance.new("ScrollingFrame")
scroll.Parent = frame
scroll.Size = UDim2.new(1, -px(16), 1, -px(80))
scroll.Position = UDim2.new(0, px(8), 0, px(74))
scroll.BackgroundColor3 = Color3.fromRGB(22, 18, 28)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = px(4)
scroll.ScrollBarImageColor3 = Color3.fromRGB(145, 103, 134)
scroll.ZIndex = 11
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, px(8))

local resultLabel = Instance.new("TextLabel")
resultLabel.Parent = scroll
resultLabel.Size = UDim2.new(1, -px(8), 0, 0)
resultLabel.Position = UDim2.new(0, px(4), 0, px(4))
resultLabel.AutomaticSize = Enum.AutomaticSize.Y
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "点「开始扫描」查看结果"
resultLabel.TextColor3 = Color3.fromRGB(200, 180, 210)
resultLabel.Font = Enum.Font.Code
resultLabel.TextSize = px(8)
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.TextWrapped = true
resultLabel.ZIndex = 12

local lastResult = ""

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "扫描中..."
    task.spawn(function()
        lastResult = runScan()
        resultLabel.Text = lastResult
        scroll.CanvasSize = UDim2.new(0, 0, 0, resultLabel.AbsoluteSize.Y + px(12))
        scanBtn.Text = "开始扫描"
    end)
end)

copyBtn.MouseButton1Click:Connect(function()
    if lastResult == "" then
        resultLabel.Text = "请先扫描！"
        return
    end
    pcall(function() setclipboard(lastResult) end)
    copyBtn.Text = "已复制!"
    task.delay(1.5, function() copyBtn.Text = "一键复制" end)
end)

-- 自动扫描一次
task.spawn(function()
    task.wait(0.3)
    lastResult = runScan()
    resultLabel.Text = lastResult
    scroll.CanvasSize = UDim2.new(0, 0, 0, resultLabel.AbsoluteSize.Y + px(12))
end)
