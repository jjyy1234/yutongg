-- Duck Builder 4 - 3D像素鸭子建造脚本
-- 数据: duck_data.lua (4914块, 空心外壳1格厚)
-- 仓库: jjyy1234/yutongg
-- 2026-09-10
-- 结构参考: build_pyramid.lua / master_builder.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- ========== Remote 获取 ==========
local remote = ReplicatedStorage:FindFirstChild("PlaceStructure") and
               ReplicatedStorage.PlaceStructure:FindFirstChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:FindFirstChild("PlaceStructure") and
                    ReplicatedStorage.PlaceStructure:FindFirstChild("PaintTool")

if not remote then
    warn("[DuckBuilder4] ClientPlacedBlueprint Remote 未找到!")
end
if not paintRemote then
    warn("[DuckBuilder4] PaintTool Remote 未找到!")
end

-- ========== 数据 URL ==========
local DATA_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_data.lua"

-- ========== 状态变量 ==========
local allData = {}
local dataLoaded = false
local building = false
local buildThread = nil
local paintThread = nil
local currentIndex = 1
local totalBlocks = 0

-- ========== 断点续建 ==========
if not _G.DuckProgress then
    _G.DuckProgress = 0
end

-- ========== UI 创建 ==========
-- 清理旧 UI
local oldGui = CoreGui:FindFirstChild("DuckBuilder4")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckBuilder4"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui

-- 主窗口
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 280)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 70)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.2
mainStroke.Parent = mainFrame

-- 标题栏（可拖动）
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Text = "🦆 Duck Builder 4"
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 16
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- 拖动逻辑
local dragging = false
local dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- 状态标签
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 44)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "点击 Load Data 加载数据"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- 进度标签
local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "ProgressLabel"
progressLabel.Size = UDim2.new(1, -20, 0, 24)
progressLabel.Position = UDim2.new(0, 10, 0, 76)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "进度: 0 / 0"
progressLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextSize = 12
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = mainFrame

-- 进度条背景
local progBarBg = Instance.new("Frame")
progBarBg.Name = "ProgBarBg"
progBarBg.Size = UDim2.new(1, -20, 0, 6)
progBarBg.Position = UDim2.new(0, 10, 0, 102)
progBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
progBarBg.BorderSizePixel = 0
progBarBg.Parent = mainFrame
Instance.new("UICorner", progBarBg).CornerRadius = UDim.new(0, 3)

-- 进度条填充
local progBarFill = Instance.new("Frame")
progBarFill.Name = "ProgBarFill"
progBarFill.Size = UDim2.new(0, 0, 1, 0)
progBarFill.Position = UDim2.new(0, 0, 0, 0)
progBarFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
progBarFill.BorderSizePixel = 0
progBarFill.Parent = progBarBg
Instance.new("UICorner", progBarFill).CornerRadius = UDim.new(0, 3)

-- 按钮容器
local btnContainer = Instance.new("Frame")
btnContainer.Name = "BtnContainer"
btnContainer.Size = UDim2.new(1, -20, 0, 120)
btnContainer.Position = UDim2.new(0, 10, 0, 116)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = mainFrame

-- 按钮布局网格
local btnGrid = Instance.new("UIGridLayout")
btnGrid.CellSize = UDim2.new(0, 92, 0, 32)
btnGrid.CellPadding = UDim2.new(0, 6, 0, 6)
btnGrid.SortOrder = Enum.SortOrder.LayoutOrder
btnGrid.Parent = btnContainer

-- 创建按钮函数
local function createButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 92, 0, 32)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = true
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

local loadBtn = createButton("Load Data", Color3.fromRGB(60, 120, 200))
loadBtn.LayoutOrder = 1
loadBtn.Parent = btnContainer

local startBtn = createButton("Start", Color3.fromRGB(50, 160, 80))
startBtn.LayoutOrder = 2
startBtn.Parent = btnContainer

local stopBtn = createButton("Stop", Color3.fromRGB(200, 80, 60))
stopBtn.LayoutOrder = 3
stopBtn.Parent = btnContainer

local resetBtn = createButton("Reset", Color3.fromRGB(160, 120, 50))
resetBtn.LayoutOrder = 4
resetBtn.Parent = btnContainer

local paintBtn = createButton("Paint All", Color3.fromRGB(150, 80, 180))
paintBtn.LayoutOrder = 5
paintBtn.Parent = btnContainer

local closeBtn = createButton("Close", Color3.fromRGB(80, 80, 85))
closeBtn.LayoutOrder = 6
closeBtn.Parent = btnContainer

-- ========== 数据加载 ==========
local function loadData()
    if dataLoaded then
        statusLabel.Text = "数据已加载: " .. totalBlocks .. " 块"
        return allData
    end
    statusLabel.Text = "加载数据中..."
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(DATA_URL))()
    end)
    if ok and result then
        allData = result
        dataLoaded = true
        totalBlocks = #allData
        statusLabel.Text = "数据加载完成: " .. totalBlocks .. " 块"
        progressLabel.Text = "进度: " .. _G.DuckProgress .. " / " .. totalBlocks
        if totalBlocks > 0 then
            progBarFill.Size = UDim2.new(_G.DuckProgress / totalBlocks, 0, 1, 0)
        end
    else
        statusLabel.Text = "加载失败: " .. tostring(result)
    end
    return allData
end

-- ========== 建造函数 ==========
local function buildBlock(bp)
    local cf = CFrame.new(bp.x, bp.y, bp.z, bp.r00, bp.r01, bp.r02, bp.r10, bp.r11, bp.r12, bp.r20, bp.r21, bp.r22)
    pcall(function() remote:FireServer(bp.n, cf, lp) end)
    task.wait(0.01)
end

-- ========== 喷漆辅助 ==========
-- 构建模型索引: 遍历 workspace 找 Owner==lp 的 Model，按坐标匹配
local function buildModelIndex()
    local idx = {}
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") then
            local ownerVal = m:FindFirstChild("Owner")
            if ownerVal and ownerVal.Value == lp then
                local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                if pp then
                    local pos = pp.Position
                    local key = math.floor(pos.X + 0.5) .. "_" .. math.floor(pos.Y + 0.5) .. "_" .. math.floor(pos.Z + 0.5)
                    idx[key] = m
                end
            end
        end
    end
    return idx
end

-- 按坐标查找模型（带容差搜索）
local function findModel(idx, x, y, z)
    local key = math.floor(x + 0.5) .. "_" .. math.floor(y + 0.5) .. "_" .. math.floor(z + 0.5)
    if idx[key] then return idx[key] end
    -- 容差搜索 ±2 格
    for dx = -2, 2 do
        for dy = -2, 2 do
            for dz = -2, 2 do
                local k2 = (math.floor(x + 0.5) + dx) .. "_" .. (math.floor(y + 0.5) + dy) .. "_" .. (math.floor(z + 0.5) + dz)
                if idx[k2] then return idx[k2] end
            end
        end
    end
    return nil
end

-- ========== 建造循环 ==========
local function startBuild()
    if building then return end
    if not dataLoaded or #allData == 0 then
        statusLabel.Text = "请先加载数据!"
        return
    end

    -- 断点续建
    if _G.DuckProgress > 0 and _G.DuckProgress < totalBlocks then
        currentIndex = _G.DuckProgress + 1
        statusLabel.Text = "从断点续建: " .. currentIndex .. " / " .. totalBlocks
    else
        currentIndex = 1
        _G.DuckProgress = 0
    end

    building = true
    buildThread = task.spawn(function()
        for i = currentIndex, #allData do
            if not building then break end
            local bp = allData[i]
            local cf = CFrame.new(bp.x, bp.y, bp.z, bp.r00, bp.r01, bp.r02, bp.r10, bp.r11, bp.r12, bp.r20, bp.r21, bp.r22)
            pcall(function() remote:FireServer(bp.n, cf, lp) end)
            _G.DuckProgress = i
            progressLabel.Text = "进度: " .. i .. " / " .. totalBlocks
            statusLabel.Text = "建造中: " .. i .. " / " .. totalBlocks
            -- 更新进度条
            progBarFill.Size = UDim2.new(i / totalBlocks, 0, 1, 0)
            task.wait(0.01)
        end
        if building then
            building = false
            statusLabel.Text = "建造完成! 共 " .. totalBlocks .. " 块"
            progBarFill.Size = UDim2.new(1, 0, 1, 0)
        end
    end)
end

local function stopBuild()
    building = false
    if buildThread then
        task.cancel(buildThread)
        buildThread = nil
    end
    statusLabel.Text = "已停止 (断点: " .. _G.DuckProgress .. ")"
end

local function resetBuild()
    building = false
    if buildThread then
        task.cancel(buildThread)
        buildThread = nil
    end
    _G.DuckProgress = 0
    currentIndex = 1
    progressLabel.Text = "进度: 0 / " .. (totalBlocks > 0 and totalBlocks or 0)
    statusLabel.Text = "已重置"
    progBarFill.Size = UDim2.new(0, 0, 1, 0)
end

-- ========== Paint All ==========
local function paintAll()
    if not dataLoaded or #allData == 0 then
        statusLabel.Text = "请先加载数据!"
        return
    end

    paintThread = task.spawn(function()
        statusLabel.Text = "构建模型索引..."
        local idx = buildModelIndex()
        local painted = 0
        local total = #allData
        for i = 1, total do
            local bp = allData[i]
            local m = findModel(idx, bp.x, bp.y, bp.z)
            if m then
                pcall(function() paintRemote:FireServer(m, bp.color) end)
                painted = painted + 1
            end
            if i % 50 == 0 then
                progressLabel.Text = "喷漆: " .. i .. " / " .. total
                statusLabel.Text = "喷漆中: " .. painted .. " / " .. total
                progBarFill.Size = UDim2.new(i / total, 0, 1, 0)
                task.wait(0.01)
            end
        end
        progressLabel.Text = "喷漆完成: " .. painted .. " / " .. total
        statusLabel.Text = "喷漆完成! " .. painted .. " / " .. total .. " 块"
        progBarFill.Size = UDim2.new(1, 0, 1, 0)
    end)
end

-- ========== 按钮事件 ==========
loadBtn.MouseButton1Click:Connect(function()
    task.spawn(loadData)
end)

startBtn.MouseButton1Click:Connect(startBuild)
stopBtn.MouseButton1Click:Connect(stopBuild)
resetBtn.MouseButton1Click:Connect(resetBuild)
paintBtn.MouseButton1Click:Connect(paintAll)

closeBtn.MouseButton1Click:Connect(function()
    building = false
    if buildThread then task.cancel(buildThread) end
    if paintThread then task.cancel(paintThread) end
    screenGui:Destroy()
end)

-- ========== 初始化 ==========
statusLabel.Text = "Duck Builder 4 就绪 - 点击 Load Data"
print("[DuckBuilder4] 脚本已加载")
print("[DuckBuilder4] 数据URL: " .. DATA_URL)
print("[DuckBuilder4] 断点续建: " .. _G.DuckProgress)
