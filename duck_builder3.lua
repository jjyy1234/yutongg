-- Duck Builder 3 - 巨型橡皮鸭建造脚本
-- 数据: duck_data.lua (5134块, Candy/Gold/SpookyGhoul)
-- 仓库: jjyy1234/yutongg
-- 2026-09-10

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer

-- Remote 获取
local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

-- 数据 URL
local DATA_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_data.lua"

-- 状态变量
local allData = {}
local dataLoaded = false
local building = false
local buildThread = nil
local paintThread = nil
local currentIndex = 1
local totalBlocks = 0

-- 断点续建
if not _G.DuckProgress then
    _G.DuckProgress = 0
end

-- ============ UI 创建 ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckBuilder3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- 挂 CoreGui
local parent = CoreGui
if CoreGui:FindFirstChild("DuckBuilder3") then
    CoreGui.DuckBuilder3:Destroy()
end
screenGui.Parent = parent

-- 主窗口
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 260)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- 标题栏
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Text = "🦆 Duck Builder 3"
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 16
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

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

-- 按钮容器
local btnContainer = Instance.new("Frame")
btnContainer.Name = "BtnContainer"
btnContainer.Size = UDim2.new(1, -20, 0, 120)
btnContainer.Position = UDim2.new(0, 10, 0, 106)
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

-- ============ 数据加载 ============
local function loadData()
    if dataLoaded then return allData end
    statusLabel.Text = "加载数据..."
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(DATA_URL))()
    end)
    if ok and result then
        allData = result
        dataLoaded = true
        totalBlocks = #allData
        statusLabel.Text = "数据加载完成: " .. totalBlocks .. " 块"
        progressLabel.Text = "进度: 0 / " .. totalBlocks
    else
        statusLabel.Text = "加载失败: " .. tostring(result)
    end
    return allData
end

-- ============ 建造函数 ============
local function buildBlock(v)
    placeEvent:FireServer(v.n, CFrame.new(v.x, v.y, v.z, v.r00, v.r01, v.r02, v.r10, v.r11, v.r12, v.r20, v.r21, v.r22), lp)
end

local function paintBlock(obj, color)
    paintRemote:FireServer(obj, color)
end

-- 查找已放置的方块对象（用于喷漆）
local function findPlacedBlock(v)
    -- 在 workspace 中查找匹配 CFrame 的方块
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == v.n then
            local cf = obj.CFrame
            if math.abs(cf.X - v.x) < 0.1 and math.abs(cf.Y - v.y) < 0.1 and math.abs(cf.Z - v.z) < 0.1 then
                return obj
            end
        end
    end
    return nil
end

-- ============ 建造循环 ============
local function startBuild()
    if building then return end
    if not dataLoaded or #allData == 0 then
        statusLabel.Text = "请先加载数据!"
        return
    end

    -- 断点续建
    if _G.DuckProgress > 0 and _G.DuckProgress < totalBlocks then
        currentIndex = _G.DuckProgress + 1
        statusLabel.Text = "从断点续建: " .. currentIndex
    else
        currentIndex = 1
    end

    building = true
    buildThread = task.spawn(function()
        for i = currentIndex, #allData do
            if not building then break end
            local v = allData[i]
            buildBlock(v)
            _G.DuckProgress = i
            progressLabel.Text = "进度: " .. i .. " / " .. totalBlocks
            statusLabel.Text = "建造中: " .. i .. "/" .. totalBlocks
            task.wait(0.01)
        end
        if building then
            building = false
            statusLabel.Text = "建造完成! 共 " .. totalBlocks .. " 块"
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
end

-- ============ 喷漆循环 ============
local function paintAll()
    if not dataLoaded or #allData == 0 then
        statusLabel.Text = "请先加载数据!"
        return
    end

    paintThread = task.spawn(function()
        local painted = 0
        for i = 1, #allData do
            local v = allData[i]
            local obj = findPlacedBlock(v)
            if obj then
                paintBlock(obj, v.color)
                painted = painted + 1
                progressLabel.Text = "喷漆: " .. painted .. " / " .. totalBlocks
                statusLabel.Text = "喷漆中: " .. painted .. "/" .. totalBlocks
                task.wait(0.01)
            end
        end
        statusLabel.Text = "喷漆完成! 共 " .. painted .. " 块"
    end)
end

-- ============ 按钮事件 ============
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

-- 初始化
statusLabel.Text = "Duck Builder 3 就绪 - 点击 Load Data"
print("[DuckBuilder3] 脚本已加载, 数据URL: " .. DATA_URL)
