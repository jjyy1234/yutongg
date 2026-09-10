-- duck_builder.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA_BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/"
local N_BODY = 4
local N_HEAD = 4

local allData = nil
local dataLoaded = false

if not _G.DuckProgress then _G.DuckProgress = 0 end

local building = false
local painting = false

local old = CoreGui:FindFirstChild("DuckBuilderUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DuckBuilderUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 300)
frame.Position = UDim2.new(0.5, -160, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Active = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
titleBar.BorderSizePixel = 0
titleBar.Text = "Duck Builder"
titleBar.TextColor3 = Color3.fromRGB(30, 30, 35)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 18
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 46)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "点击 Load Data 加载数据"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 15
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local progBg = Instance.new("Frame")
progBg.Size = UDim2.new(1, -20, 0, 16)
progBg.Position = UDim2.new(0, 10, 0, 80)
progBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
progBg.BorderSizePixel = 0
progBg.Parent = frame
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 4)

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
progFill.BorderSizePixel = 0
progFill.Parent = progBg
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 4)

local function makeBtn(name, text, x, y, w, col)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, w, 0, 38)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = col
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 15
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local loadBtn  = makeBtn("LoadBtn",  "Load Data", 10,  106, 145, Color3.fromRGB(80, 120, 200))
local startBtn = makeBtn("StartBtn", "Start",     165, 106, 145, Color3.fromRGB(80, 200, 120))
local stopBtn  = makeBtn("StopBtn",  "Stop",      10,  154, 145, Color3.fromRGB(220, 80, 80))
local resetBtn = makeBtn("ResetBtn", "Reset",     165, 154, 145, Color3.fromRGB(200, 120, 60))
local paintBtn = makeBtn("PaintBtn", "Paint All", 10,  202, 145, Color3.fromRGB(160, 100, 200))
local closeBtn = makeBtn("CloseBtn", "Close",     165, 202, 145, Color3.fromRGB(100, 100, 100))

local function loadData()
    if dataLoaded then return allData end
    allData = {}
    for i = 1, N_BODY do
        statusLabel.Text = "加载 body " .. i .. "/" .. N_BODY .. "..."
        local ok, chunk = pcall(function()
            return loadstring(game:HttpGet(DATA_BASE .. "duck_body_" .. i .. ".lua"))()
        end)
        if ok and chunk then
            for _, v in ipairs(chunk) do table.insert(allData, v) end
        end
    end
    for i = 1, N_HEAD do
        statusLabel.Text = "加载 head " .. i .. "/" .. N_HEAD .. "..."
        local ok, chunk = pcall(function()
            return loadstring(game:HttpGet(DATA_BASE .. "duck_head_" .. i .. ".lua"))()
        end)
        if ok and chunk then
            for _, v in ipairs(chunk) do table.insert(allData, v) end
        end
    end
    statusLabel.Text = "加载 beak..."
    local ok1, beak = pcall(function() return loadstring(game:HttpGet(DATA_BASE .. "duck_beak.lua"))() end)
    if ok1 and beak then for _, v in ipairs(beak) do table.insert(allData, v) end end
    statusLabel.Text = "加载 eyes..."
    local ok2, eyes = pcall(function() return loadstring(game:HttpGet(DATA_BASE .. "duck_eyes.lua"))() end)
    if ok2 and eyes then for _, v in ipairs(eyes) do table.insert(allData, v) end end
    dataLoaded = true
    return allData
end

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
        progFill.Size = UDim2.new(math.clamp(done / total, 0, 1), 0, 1, 0)
    end
end

local buildThread = nil

local function startBuild()
    if not dataLoaded then statusLabel.Text = "请先 Load Data！" return end
    if building then return end
    building = true
    local total = #allData
    local startIdx = (_G.DuckProgress or 0) + 1
    buildThread = task.spawn(function()
        for i = startIdx, total do
            if not building then break end
            local v = allData[i]
            local cf = CFrame.new(v.x, v.y, v.z,
                v.r00 or 1, v.r01 or 0, v.r02 or 0,
                v.r10 or 0, v.r11 or 1, v.r12 or 0,
                v.r20 or 0, v.r21 or 0, v.r22 or 1)
            pcall(function() placeEvent:FireServer(v.n or "Floor1Tiny", cf, lp) end)
            _G.DuckProgress = i
            if i % 50 == 0 then updateStatus() end
            task.wait(0.01)
        end
        building = false
        updateStatus()
        if _G.DuckProgress >= total then
            statusLabel.Text = string.format("完成！共 %d 块", total)
        end
    end)
end

local function stopBuild()
    building = false
    if buildThread then task.cancel(buildThread) buildThread = nil end
    updateStatus()
end

local function resetProgress()
    building = false
    if buildThread then task.cancel(buildThread) buildThread = nil end
    _G.DuckProgress = 0
    updateStatus()
end

local paintThread = nil

local function paintAll()
    if not dataLoaded then statusLabel.Text = "请先 Load Data！" return end
    if painting then return end
    painting = true
    paintThread = task.spawn(function()
        local coordMap = {}
        for _, v in ipairs(allData) do
            local key = string.format("%.1f,%.1f,%.1f", v.x, v.y, v.z)
            coordMap[key] = v.color
        end
        local painted = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not painting then break end
            if obj:IsA("Model") then
                local cf = obj:GetPivot()
                if cf then
                    local pos = cf.Position
                    local key = string.format("%.1f,%.1f,%.1f", pos.X, pos.Y, pos.Z)
                    local color = coordMap[key]
                    if color then
                        pcall(function() paintRemote:FireServer(obj, color) end)
                        painted = painted + 1
                        if painted % 50 == 0 then
                            statusLabel.Text = string.format("喷漆中 %d", painted)
                            task.wait(0.01)
                        end
                    end
                end
            end
        end
        painting = false
        statusLabel.Text = string.format("喷漆完成 %d 块", painted)
    end)
end

loadBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        local ok, err = pcall(loadData)
        if ok then
            updateStatus()
        else
            statusLabel.Text = "加载失败: " .. tostring(err):sub(1, 60)
        end
    end)
end)

startBtn.MouseButton1Click:Connect(function() startBuild() end)
stopBtn.MouseButton1Click:Connect(function() stopBuild() end)
resetBtn.MouseButton1Click:Connect(function() resetProgress() end)
paintBtn.MouseButton1Click:Connect(function() paintAll() end)
closeBtn.MouseButton1Click:Connect(function()
    building = false
    painting = false
    if buildThread then task.cancel(buildThread) end
    if paintThread then task.cancel(paintThread) end
    gui:Destroy()
end)

updateStatus()
task.spawn(function()
    while gui.Parent do
        if building then updateStatus() end
        task.wait(1)
    end
end)

print("Duck Builder loaded.")
