-- ============================================================
-- Sphere Emoji Builder v2
-- 可拖动 UI，Start/Stop/Reset/Paint All 按钮
-- 断点续建，0.006s/块
-- ============================================================

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- ===== 远程数据 URL =====
local MAIN_URL  = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/msg_sphere_emoji_max_hollow.lua"
local BLUSH_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/blush_data.lua"

-- ===== 颜色映射 =====
local COLOR_MAP = {
    Star        = Color3.fromRGB(255, 215, 0),
    SpookyGhoul = Color3.fromRGB(30,  30,  30),
    LoneCave    = Color3.fromRGB(60,  40,  20),
    Candy       = Color3.fromRGB(255, 182, 193),
}

local SAVE_KEY = "SphereEmojiProgress"

-- ===== 清理旧 UI =====
pcall(function() CoreGui:FindFirstChild("SphereBuilderUI"):Destroy() end)

-- ===== 缩放 =====
local S = math.clamp(math.min(
    workspace.CurrentCamera.ViewportSize.X,
    workspace.CurrentCamera.ViewportSize.Y
) / 500, 0.7, 1.3)
local function px(n) return math.floor(n * S + 0.5) end

-- ===== 主 ScreenGui =====
local main = Instance.new("ScreenGui")
main.Name = "SphereBuilderUI"
main.ResetOnSpawn = false
main.IgnoreGuiInset = true
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.Parent = CoreGui

-- ===== Frame =====
local FW, FH = px(240), px(230)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, FW, 0, FH)
Frame.Position = UDim2.new(0.5, -FW/2, 0.04, 0)
Frame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
Frame.BackgroundTransparency = 0.04
Frame.BorderSizePixel = 0
Frame.Active = false
Frame.ClipsDescendants = false
Frame.Parent = main
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, px(14))
local fs = Instance.new("UIStroke", Frame)
fs.Color = Color3.fromRGB(225, 198, 215)
fs.Thickness = math.max(1, S * 1.2)
fs.Transparency = 0.15

-- ===== 标题条（拖动区域）=====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, px(32))
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Active = true
titleBar.ZIndex = 10
titleBar.Parent = Frame

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.new(0, px(12), 0, px(6))
titleLbl.Size = UDim2.new(0, px(180), 0, px(22))
titleLbl.Text = "Sphere Builder"
titleLbl.TextColor3 = Color3.fromRGB(145, 103, 134)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = px(13)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 11
titleLbl.Parent = Frame

-- ===== 拖动逻辑 =====
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== 状态标签 =====
local lblStatus = Instance.new("TextLabel")
lblStatus.BackgroundTransparency = 1
lblStatus.Position = UDim2.new(0, px(12), 0, px(36))
lblStatus.Size = UDim2.new(1, -px(24), 0, px(14))
lblStatus.Text = "Ready"
lblStatus.TextColor3 = Color3.fromRGB(145, 103, 134)
lblStatus.Font = Enum.Font.GothamMedium
lblStatus.TextSize = px(9)
lblStatus.TextXAlignment = Enum.TextXAlignment.Left
lblStatus.ZIndex = 2
lblStatus.Parent = Frame

local lblProg = Instance.new("TextLabel")
lblProg.BackgroundTransparency = 1
lblProg.Position = UDim2.new(0, px(12), 0, px(52))
lblProg.Size = UDim2.new(1, -px(24), 0, px(13))
lblProg.Text = ""
lblProg.TextColor3 = Color3.fromRGB(173, 144, 163)
lblProg.Font = Enum.Font.Gotham
lblProg.TextSize = px(9)
lblProg.TextXAlignment = Enum.TextXAlignment.Left
lblProg.ZIndex = 2
lblProg.Parent = Frame

-- ===== 进度条 =====
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -px(24), 0, px(5))
barBg.Position = UDim2.new(0, px(12), 0, px(67))
barBg.BackgroundColor3 = Color3.fromRGB(225, 198, 215)
barBg.BorderSizePixel = 0
barBg.Active = false
barBg.ZIndex = 2
barBg.Parent = Frame
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, px(3))

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(215, 153, 187)
barFill.BorderSizePixel = 0
barFill.ZIndex = 3
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, px(3))

local lblSaved = Instance.new("TextLabel")
lblSaved.BackgroundTransparency = 1
lblSaved.Position = UDim2.new(0, px(12), 0, px(75))
lblSaved.Size = UDim2.new(1, -px(24), 0, px(12))
lblSaved.Text = ""
lblSaved.TextColor3 = Color3.fromRGB(180, 150, 170)
lblSaved.Font = Enum.Font.Gotham
lblSaved.TextSize = px(8)
lblSaved.TextXAlignment = Enum.TextXAlignment.Left
lblSaved.ZIndex = 2
lblSaved.Parent = Frame

-- ===== 按钮工厂 =====
local function makeBtn(text, x, y, w, h, bg)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, px(w), 0, px(h))
    btn.Position = UDim2.new(0, px(x), 0, px(y))
    btn.BackgroundColor3 = bg
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = px(9)
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Active = true
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, px(6))
    return btn
end

local btnStart = makeBtn("Start",    12,  92, 106, 28, Color3.fromRGB(191, 226, 205))
local btnStop  = makeBtn("Stop",    126,  92, 102, 28, Color3.fromRGB(226, 191, 191))
local btnReset = makeBtn("Reset",    12, 128, 106, 28, Color3.fromRGB(191, 210, 240))
local btnPaint = makeBtn("Paint All",126, 128, 102, 28, Color3.fromRGB(240, 210, 191))

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, px(22), 0, px(22))
btnClose.Position = UDim2.new(1, -px(28), 0, px(5))
btnClose.BackgroundColor3 = Color3.fromRGB(220, 180, 200)
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = px(10)
btnClose.BorderSizePixel = 0
btnClose.ZIndex = 12
btnClose.Active = true
btnClose.Parent = Frame
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0, px(11))

-- ===== 状态函数 =====
local function setStatus(msg, col)
    lblStatus.Text = msg
    lblStatus.TextColor3 = col or Color3.fromRGB(145, 103, 134)
end

local function setProg(cur, total)
    if total > 0 then
        barFill.Size = UDim2.new(cur / total, 0, 1, 0)
    end
    lblProg.Text = cur .. " / " .. total
end

-- ===== 状态变量 =====
local building = false
local painting = false
local allData = nil
local startIdx = 1
local placedObjects = {}

-- ===== 进度存档 =====
local function saveProgress(idx)
    pcall(function()
        if writefile then writefile(SAVE_KEY..".txt", tostring(idx)) end
    end)
    lblSaved.Text = "Saved at #" .. idx
end

local function loadProgress()
    local ok, val = pcall(function()
        if readfile then return readfile(SAVE_KEY..".txt") end
        return "1"
    end)
    if ok and val then return tonumber(val) or 1 end
    return 1
end

-- ===== 加载数据 =====
local function loadData()
    setStatus("Loading main data...")
    local ok1, res1 = pcall(function() return game:HttpGet(MAIN_URL) end)
    if not ok1 then
        setStatus("ERROR: "..tostring(res1), Color3.fromRGB(200,60,60))
        return nil
    end

    local ok2, res2 = pcall(function() return game:HttpGet(BLUSH_URL) end)
    if not ok2 then
        setStatus("ERROR blush: "..tostring(res2), Color3.fromRGB(200,60,60))
        return nil
    end

    local mainOk = pcall(loadstring(res1))
    if not mainOk or not _G.MSGSphereEmojiData then
        setStatus("Parse error: main data", Color3.fromRGB(200,60,60))
        return nil
    end

    local blushOk = pcall(loadstring(res2))
    if not blushOk or not _G.BlushData then
        setStatus("Parse error: blush data", Color3.fromRGB(200,60,60))
        return nil
    end

    local combined = {}
    for _, v in ipairs(_G.MSGSphereEmojiData) do
        table.insert(combined, {
            n=v.n, x=v.x, y=v.y, z=v.z,
            r00=v.r00,r01=v.r01,r02=v.r02,
            r10=v.r10,r11=v.r11,r12=v.r12,
            r20=v.r20,r21=v.r21,r22=v.r22
        })
    end
    for _, v in ipairs(_G.BlushData) do
        table.insert(combined, {
            n="Candy", x=v.x, y=v.y, z=v.z,
            r00=1,r01=0,r02=0,r10=0,r11=1,r12=0,r20=0,r21=0,r22=1
        })
    end

    setStatus("Loaded " .. #combined .. " blocks")
    return combined
end

-- ===== 喷漆 =====
local function paintOne(obj, colorName)
    local col = COLOR_MAP[colorName]
    if not col or not obj then return end
    local paintRemote = RS:FindFirstChild("Interaction") and
                        RS.Interaction:FindFirstChild("PaintObject")
    if paintRemote then
        pcall(function() paintRemote:FireServer(obj, col) end)
    else
        pcall(function()
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") then p.Color = col end
            end
        end)
    end
end

-- ===== PlaceBlueprint Remote =====
local placeRemote = nil
local function getPlaceRemote()
    if placeRemote then return placeRemote end
    local ok, r = pcall(function()
        return RS:WaitForChild("Interaction",5):WaitForChild("PlaceBlueprint",5)
    end)
    if ok and r then placeRemote = r end
    return placeRemote
end

-- ===== 建造单块 =====
local function buildOne(entry)
    local remote = getPlaceRemote()
    if not remote then return nil end
    local cf = CFrame.new(entry.x, entry.y, entry.z,
        entry.r00, entry.r01, entry.r02,
        entry.r10, entry.r11, entry.r12,
        entry.r20, entry.r21, entry.r22)
    local ok, result = pcall(function()
        return remote:InvokeServer(entry.n, cf)
    end)
    if ok and result then
        task.spawn(function()
            task.wait(0.05)
            paintOne(result, entry.n)
        end)
        return result
    end
    return nil
end

-- ===== 主建造循环 =====
local function startBuild()
    if building then return end
    if not allData then
        setStatus("Loading data...")
        allData = loadData()
        if not allData then return end
    end

    startIdx = loadProgress()
    building = true
    btnStart.BackgroundColor3 = Color3.fromRGB(160, 200, 175)
    setStatus("Building from #" .. startIdx)

    local total = #allData
    local i = startIdx

    while building and i <= total do
        local entry = allData[i]
        local obj = buildOne(entry)
        if obj then placedObjects[i] = obj end
        setProg(i, total)
        if i % 50 == 0 then saveProgress(i) end
        i = i + 1
        task.wait(0.006)
    end

    if i > total then
        setStatus("Done! All " .. total .. " blocks placed", Color3.fromRGB(72,130,90))
        barFill.BackgroundColor3 = Color3.fromRGB(140,210,160)
        saveProgress(1)
    else
        saveProgress(i)
        setStatus("Stopped at #" .. i)
    end

    building = false
    btnStart.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
end

-- ===== Paint All =====
local function paintAll()
    if painting then return end
    if not allData then
        setStatus("No data, build first")
        return
    end
    painting = true
    btnPaint.BackgroundColor3 = Color3.fromRGB(200, 160, 130)
    setStatus("Painting all blocks...")

    local total = #allData
    for i, obj in pairs(placedObjects) do
        if not painting then break end
        local entry = allData[i]
        if entry then paintOne(obj, entry.n) end
        if i % 100 == 0 then
            setStatus("Painting " .. i .. "/" .. total)
            task.wait(0.01)
        end
    end

    setStatus("Paint done")
    painting = false
    btnPaint.BackgroundColor3 = Color3.fromRGB(240, 210, 191)
end

-- ===== 按钮事件 =====
local function bind(btn, fn)
    btn.MouseButton1Click:Connect(fn)
    btn.TouchTap:Connect(fn)
    btn.Activated:Connect(fn)
end

bind(btnStart, function() task.spawn(startBuild) end)
bind(btnStop,  function()
    building = false
    painting = false
    setStatus("Stopping...")
end)
bind(btnReset, function()
    saveProgress(1)
    startIdx = 1
    lblSaved.Text = "Reset to #1"
    setStatus("Progress reset")
end)
bind(btnPaint, function() task.spawn(paintAll) end)
bind(btnClose, function() main:Destroy() end)

-- ===== 启动 =====
local saved = loadProgress()
if saved > 1 then
    lblSaved.Text = "Resume from #" .. saved
    setStatus("Ready (saved: #" .. saved .. ")")
else
    setStatus("Ready")
end

print("[Sphere Builder v2] loaded.")
