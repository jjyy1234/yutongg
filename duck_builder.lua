-- ============================================================
-- duck_builder.lua
-- 3D 空心橡皮鸭建造脚本
-- 数据从 GitHub 远程加载，断点续建
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer

-- 发包用的 RemoteEvent
local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

-- ============================================================
-- 数据加载
-- ============================================================
local DATA_BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/"

local allData = nil
local dataLoaded = false

-- 分块数量
local N_BODY = 4  -- duck_body 分成 4 块
local N_HEAD = 3  -- duck_head 分成 3 块

local function loadAllData()
    if dataLoaded then return allData end
    allData = {}
    -- body 分块
    for i = 1, N_BODY do
        local chunk = loadstring(game:HttpGet(DATA_BASE .. "duck_body_" .. i .. ".lua"))()
        for _, v in ipairs(chunk) do table.insert(allData, v) end
    end
    -- head 分块
    for i = 1, N_HEAD do
        local chunk = loadstring(game:HttpGet(DATA_BASE .. "duck_head_" .. i .. ".lua"))()
        for _, v in ipairs(chunk) do table.insert(allData, v) end
    end
    -- beak
    local beakData = loadstring(game:HttpGet(DATA_BASE .. "duck_beak.lua"))()
    for _, v in ipairs(beakData) do table.insert(allData, v) end
    -- eyes
    local eyesData = loadstring(game:HttpGet(DATA_BASE .. "duck_eyes.lua"))()
    for _, v in ipairs(eyesData) do table.insert(allData, v) end
    dataLoaded = true
    return allData
end

-- ============================================================
-- 进度存储
-- ============================================================
if not _G.DuckProgress then
    _G.DuckProgress = 0
end

-- ============================================================
-- 建造状态
-- ============================================================
local building = false
local painting = false

-- ============================================================
-- UI 构建
-- ============================================================
-- 清理旧 UI
local old = CoreGui:FindFirstChild("DuckBuilderUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DuckBuilderUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- 主窗口 Frame（仅用于显示，不响应触摸）
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 320, 0, 360)
frame.Position = UDim2.new(0.5, -160, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Active = false  -- 不拦截触摸
frame.Draggable = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- 标题条（可拖动）
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
titleBar.BorderSizePixel = 0
titleBar.Text = "🦆 鸭子建造器"
titleBar.TextColor3 = Color3.fromRGB(30, 30, 35)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 18
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- 拖动逻辑（只绑定标题条）
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- 状态栏
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 46)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "点击 Load Data 加载数据"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- 进度条背景
local progBg = Instance.new("Frame")
progBg.Name = "ProgressBg"
progBg.Size = UDim2.new(1, -20, 0, 20)
progBg.Position = UDim2.new(0, 10, 0, 80)
progBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
progBg.BorderSizePixel = 0
progBg.Parent = frame

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 4)
progCorner.Parent = progBg

-- 进度条填充
local progFill = Instance.new("Frame")
progFill.Name = "ProgressFill"
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.Position = UDim2.new(0, 0, 0, 0)
progFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
progFill.BorderSizePixel = 0
progFill.Parent = progBg

local progFillCorner = Instance.new("UICorner")
progFillCorner.CornerRadius = UDim.new(0, 4)
progFillCorner.Parent = progFill

-- ============================================================
-- 按钮辅助函数（按钮直接挂 ScreenGui，不挂 Frame）
-- ============================================================
local function makeButton(name, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 140, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = gui  -- 直接挂 ScreenGui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

-- 按钮位置需要跟随 Frame 移动，所以用绑定
local function bindButtonToFrame(btn, offsetY)
    frame:GetPropertyChangedSignal("Position"):Connect(function()
        local fpos = frame.Position
        btn.Position = UDim2.new(fpos.X.Scale, fpos.X.Offset + 10, fpos.Y.Scale, fpos.Y.Offset + offsetY)
    end)
    -- 初始位置
    local fpos = frame.Position
    btn.Position = UDim2.new(fpos.X.Scale, fpos.X.Offset + 10, fpos.Y.Scale, fpos.Y.Offset + offsetY)
end

-- 右侧按钮
local function makeButtonRight(name, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 140, 0, 40)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

local function bindButtonRightToFrame(btn, offsetY)
    frame:GetPropertyChangedSignal("Position"):Connect(function()
        local fpos = frame.Position
        btn.Position = UDim2.new(fpos.X.Scale, fpos.X.Offset + 170, fpos.Y.Scale, fpos.Y.Offset + offsetY)
    end)
    local fpos = frame.Position
    btn.Position = UDim2.new(fpos.X.Scale, fpos.X.Offset + 170, fpos.Y.Scale, fpos.Y.Offset + offsetY)
end

-- ============================================================
-- 创建按钮
-- ============================================================
-- 第一行: Load Data / Start
local loadBtn = makeButton("LoadBtn", "Load Data", 110, Color3.fromRGB(80, 120, 200))
bindButtonToFrame(loadBtn, 110)

local startBtn = makeButtonRight("StartBtn", "Start", 110, Color3.fromRGB(80, 200, 120))
bindButtonRightToFrame(startBtn, 110)

-- 第二行: Stop / Reset
local stopBtn = makeButton("StopBtn", "Stop", 160, Color3.fromRGB(220, 80, 80))
bindButtonToFrame(stopBtn, 160)

local resetBtn = makeButtonRight("ResetBtn", "Reset", 160, Color3.fromRGB(200, 120, 60))
bindButtonRightToFrame(resetBtn, 160)

-- 第三行: Paint All
local paintBtn = makeButton("PaintBtn", "Paint All", 210, Color3.fromRGB(160, 100, 200))
bindButtonToFrame(paintBtn, 210)

-- 关闭按钮
local closeBtn = makeButtonRight("CloseBtn", "Close", 210, Color3.fromRGB(100, 100, 100))
bindButtonRightToFrame(closeBtn, 210)

-- ============================================================
-- 更新状态显示
-- ============================================================
local function updateStatus()
    if not dataLoaded then
        statusLabel.Text = "点击 Load Data 加载数据"
        progFill.Size = UDim2.new(0, 0, 1, 0)
        return
    end
    local total = #allData
    local done = _G.DuckProgress or 0
    statusLabel.Text = string.format("已建 %d / %d", done, total)
    if total > 0 then
        local pct = math.clamp(done / total, 0, 1)
        progFill.Size = UDim2.new(pct, 0, 1, 0)
    end
end

-- ============================================================
-- 建造逻辑
-- ============================================================
local buildThread = nil

local function startBuild()
    if not dataLoaded then
        statusLabel.Text = "请先加载数据！"
        return
    end
    if building then return end
    building = true
    
    local total = #allData
    local startIdx = (_G.DuckProgress or 0) + 1
    
    buildThread = task.spawn(function()
        for i = startIdx, total do
            if not building then break end
            local v = allData[i]
            -- 发包建造
            placeEvent:FireServer(
                "Floor1Tiny",
                CFrame.new(v.x, v.y, v.z, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                lp
            )
            _G.DuckProgress = i
            if i % 50 == 0 then
                updateStatus()
            end
            task.wait(0.01)
        end
        building = false
        updateStatus()
        if _G.DuckProgress >= total then
            statusLabel.Text = string.format("建造完成！共 %d 块", total)
        end
    end)
end

local function stopBuild()
    building = false
    if buildThread then
        task.cancel(buildThread)
        buildThread = nil
    end
    updateStatus()
end

local function resetProgress()
    building = false
    if buildThread then
        task.cancel(buildThread)
        buildThread = nil
    end
    _G.DuckProgress = 0
    updateStatus()
end

-- ============================================================
-- 喷漆逻辑
-- ============================================================
local paintThread = nil

local function paintAll()
    if not dataLoaded then
        statusLabel.Text = "请先加载数据！"
        return
    end
    if painting then return end
    painting = true
    
    local total = #allData
    paintThread = task.spawn(function()
        -- 获取所有已放置的 Floor1Tiny
        -- 遍历 workspace 中的结构
        local structures = {}
        
        -- 搜索 workspace 下所有模型
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name
                -- 尝试匹配 Floor1Tiny 相关
                if string.find(name:lower(), "floor") or string.find(name:lower(), "tiny") then
                    table.insert(structures, obj)
                end
            end
        end
        
        -- 按坐标匹配喷漆
        -- 建一个坐标->颜色的映射
        local coordMap = {}
        for _, v in ipairs(allData) do
            local key = string.format("%.1f,%.1f,%.1f", v.x, v.y, v.z)
            coordMap[key] = v.color
        end
        
        local painted = 0
        for _, obj in ipairs(structures) do
            if not painting then break end
            local cf = obj:GetPivot()
            if cf then
                local pos = cf.Position
                local key = string.format("%.1f,%.1f,%.1f", pos.X, pos.Y, pos.Z)
                local color = coordMap[key]
                if color then
                    pcall(function()
                        paintRemote:FireServer(obj, color)
                    end)
                    painted = painted + 1
                    if painted % 50 == 0 then
                        statusLabel.Text = string.format("喷漆中... %d", painted)
                        task.wait(0.01)
                    end
                end
            end
        end
        painting = false
        statusLabel.Text = string.format("喷漆完成 %d 块", painted)
    end)
end

-- ============================================================
-- 按钮事件
-- ============================================================
loadBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "加载中..."
    local ok, err = pcall(function()
        loadAllData()
    end)
    if ok then
        updateStatus()
    else
        statusLabel.Text = "加载失败: " .. tostring(err):sub(1, 40)
    end
end)

startBtn.MouseButton1Click:Connect(function()
    startBuild()
end)

stopBtn.MouseButton1Click:Connect(function()
    stopBuild()
end)

resetBtn.MouseButton1Click:Connect(function()
    resetProgress()
end)

paintBtn.MouseButton1Click:Connect(function()
    paintAll()
end)

closeBtn.MouseButton1Click:Connect(function()
    building = false
    painting = false
    if buildThread then task.cancel(buildThread) end
    if paintThread then task.cancel(paintThread) end
    gui:Destroy()
end)

-- 初始状态
updateStatus()

-- 每秒刷新状态
task.spawn(function()
    while gui.Parent do
        if building then
            updateStatus()
        end
        task.wait(1)
    end
end)

print("🦆 鸭子建造器已加载！点击 Load Data 加载数据，然后 Start 开始建造。")
