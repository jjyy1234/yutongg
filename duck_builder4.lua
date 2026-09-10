-- Duck Builder v4
-- 修正比例后的鸭子建造脚本
-- 坐标数据从 GitHub 远程加载 duck_data.lua
-- 2026-09-10

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- ============ UI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckBuilder"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 210, 0, 200)
main.Position = UDim2.new(0.5, -105, 0, 10)
main.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 0, 28)
titleLbl.BackgroundColor3 = Color3.fromRGB(112, 91, 145)
titleLbl.BorderSizePixel = 0
titleLbl.Text = "Duck Builder v4"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.Parent = main
Instance.new("UICorner", titleLbl).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -10, 0, 20)
statusLbl.Position = UDim2.new(0, 5, 0, 32)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "状态: 等待加载"
statusLbl.TextColor3 = Color3.fromRGB(80, 60, 100)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

local progressLbl = Instance.new("TextLabel")
progressLbl.Size = UDim2.new(1, -10, 0, 20)
progressLbl.Position = UDim2.new(0, 5, 0, 52)
progressLbl.BackgroundTransparency = 1
progressLbl.Text = "进度: 0 / 0"
progressLbl.TextColor3 = Color3.fromRGB(80, 60, 100)
progressLbl.Font = Enum.Font.Gotham
progressLbl.TextSize = 11
progressLbl.TextXAlignment = Enum.TextXAlignment.Left
progressLbl.Parent = main

-- 按钮辅助函数
local function makeBtn(text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.46, -2, 0, 24)
    btn.Position = UDim2.new(0.02, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local loadBtn = makeBtn("Load Data", 76, Color3.fromRGB(100, 130, 200))
local startBtn = makeBtn("Start", 76, Color3.fromRGB(80, 160, 80))
startBtn.Position = UDim2.new(0.52, 0, 0, 76)
local stopBtn = makeBtn("Stop", 104, Color3.fromRGB(200, 80, 80))
local resetBtn = makeBtn("Reset", 104, Color3.fromRGB(180, 130, 60))
resetBtn.Position = UDim2.new(0.52, 0, 0, 104)
local paintBtn = makeBtn("Paint All", 132, Color3.fromRGB(160, 100, 180))
local closeBtn = makeBtn("Close", 132, Color3.fromRGB(120, 120, 120))
closeBtn.Position = UDim2.new(0.52, 0, 0, 132)

-- ============ 数据加载 ============
local BLUEPRINTS = {}
local DATA_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_data.lua"
local running = false
local total = 0

_G.DuckProgress = _G.DuckProgress or 0

loadBtn.MouseButton1Click:Connect(function()
    statusLbl.Text = "状态: 加载中..."
    local success, result = pcall(function()
        local data = game:HttpGet(DATA_URL)
        local fn = loadstring(data)
        if fn then
            return fn()
        end
        return nil
    end)
    if success and result and type(result) == "table" then
        BLUEPRINTS = result
        total = #BLUEPRINTS
        statusLbl.Text = "状态: 已加载 " .. total .. " 块"
        progressLbl.Text = "进度: " .. _G.DuckProgress .. " / " .. total
    else
        statusLbl.Text = "状态: 加载失败"
    end
end)

-- ============ Remote ============
local function getRemote()
    local placeStructure = ReplicatedStorage:FindFirstChild("PlaceStructure")
    if placeStructure then
        return placeStructure:FindFirstChild("ClientPlacedBlueprint")
    end
    return nil
end

local function getPaintRemote()
    local placeStructure = ReplicatedStorage:FindFirstChild("PlaceStructure")
    if placeStructure then
        return placeStructure:FindFirstChild("PaintTool")
    end
    return nil
end

-- ============ 建造循环 ============
startBtn.MouseButton1Click:Connect(function()
    local remote = getRemote()
    if not remote then
        statusLbl.Text = "状态: 找不到 ClientPlacedBlueprint"
        return
    end
    if #BLUEPRINTS == 0 then
        statusLbl.Text = "状态: 请先 Load Data"
        return
    end
    running = true
    statusLbl.Text = "状态: 建造中..."
    local startIdx = _G.DuckProgress + 1
    for i = startIdx, total do
        if not running then break end
        local bp = BLUEPRINTS[i]
        local cf = CFrame.new(bp.x, bp.y, bp.z, bp.r00, bp.r01, bp.r02, bp.r10, bp.r11, bp.r12, bp.r20, bp.r21, bp.r22)
        pcall(function() remote:FireServer(bp.n, cf, lp) end)
        _G.DuckProgress = i
        progressLbl.Text = "进度: " .. i .. " / " .. total
        if i % 50 == 0 then
            task.wait(0.02)
        else
            task.wait(0.01)
        end
    end
    if running then
        statusLbl.Text = "状态: 建造完成!"
    else
        statusLbl.Text = "状态: 已停止"
    end
    running = false
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    statusLbl.Text = "状态: 已停止"
end)

resetBtn.MouseButton1Click:Connect(function()
    _G.DuckProgress = 0
    progressLbl.Text = "进度: 0 / " .. total
    statusLbl.Text = "状态: 已重置"
end)

-- ============ Paint All ============
paintBtn.MouseButton1Click:Connect(function()
    local paintRemote = getPaintRemote()
    if not paintRemote then
        statusLbl.Text = "状态: 找不到 PaintTool"
        return
    end
    statusLbl.Text = "状态: 喷漆中..."
    local painted = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("Owner") == lp.Name then
            local color = obj:GetAttribute("Color")
            if color then
                pcall(function() paintRemote:FireServer(obj, color, lp) end)
                painted = painted + 1
                if painted % 50 == 0 then
                    task.wait(0.02)
                end
            end
        end
    end
    statusLbl.Text = "状态: 喷漆完成 " .. painted .. " 块"
end)

-- ============ Close ============
closeBtn.MouseButton1Click:Connect(function()
    running = false
    screenGui:Destroy()
end)
