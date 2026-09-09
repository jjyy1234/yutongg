-- ============================================================
-- Sphere Emoji Builder  (腮红版)
-- 数据从 GitHub 远程加载，可开始/停止，断点续建，0.006s/块
-- ============================================================

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- ===== 远程数据 URL =====
local MAIN_URL   = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/sphere_emoji_data.lua"
local BLUSH_URL  = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/blush_data.lua"

-- ===== 颜色映射 =====
local COLOR_MAP = {
    Star       = Color3.fromRGB(255, 215, 0),    -- 金黄
    SpookyGhoul= Color3.fromRGB(30,  30,  30),   -- 黑
    LoneCave   = Color3.fromRGB(60,  40,  20),   -- 深棕
    Candy      = Color3.fromRGB(255, 182, 193),  -- 粉红腮红
}

-- ===== 进度存档 key =====
local SAVE_KEY = "SphereEmojiProgress"

-- ===== UI =====
pcall(function() CoreGui:FindFirstChild("SphereBuilderUI"):Destroy() end)

local S = math.clamp(math.min(
    workspace.CurrentCamera.ViewportSize.X,
    workspace.CurrentCamera.ViewportSize.Y
) / 500, 0.7, 1.3)
local function px(n) return math.floor(n * S + 0.5) end

local main = Instance.new("ScreenGui")
main.Name = "SphereBuilderUI"
main.ResetOnSpawn = false
main.IgnoreGuiInset = true
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, px(240), 0, px(200))
Frame.Position = UDim2.new(0.5, -px(120), 0.04, 0)
Frame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
Frame.BackgroundTransparency = 0.04
Frame.BorderSizePixel = 0
Frame.Active = false
Frame.Parent = main
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, px(14))
local fs = Instance.new("UIStroke", Frame)
fs.Color = Color3.fromRGB(225, 198, 215); fs.Thickness = math.max(1, S*1.2); fs.Transparency = 0.15

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.new(0, px(12), 0, px(6))
titleLbl.Size = UDim2.new(0, px(180), 0, px(26))
titleLbl.Text = "Sphere Emoji Builder"
titleLbl.TextColor3 = Color3.fromRGB(145, 103, 134)
titleLbl.Font = Enum.Font.Cartoon
titleLbl.TextSize = px(20)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 2
titleLbl.Parent = Frame

local lblStatus = Instance.new("TextLabel")
lblStatus.BackgroundTransparency = 1
lblStatus.Position = UDim2.new(0, px(12), 0, px(34))
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
lblProg.Position = UDim2.new(0, px(12), 0, px(50))
lblProg.Size = UDim2.new(1, -px(24), 0, px(13))
lblProg.Text = ""
lblProg.TextColor3 = Color3.fromRGB(173, 144, 163)
lblProg.Font = Enum.Font.Gotham
lblProg.TextSize = px(9)
lblProg.TextXAlignment = Enum.TextXAlignment.Left
lblProg.ZIndex = 2
lblProg.Parent = Frame

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -px(24), 0, px(5))
barBg.Position = UDim2.new(0, px(12), 0, px(65))
barBg.BackgroundColor3 = Color3.fromRGB(225, 198, 215)
barBg.BorderSizePixel = 0; barBg.Active = false; barBg.ZIndex = 2
barBg.Parent = Frame
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, px(3))

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(215, 153, 187)
barFill.BorderSizePixel = 0; barFill.Active = false; barFill.ZIndex = 3
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, px(3))

local lblSaved = Instance.new("TextLabel")
lblSaved.BackgroundTransparency = 1
lblSaved.Position = UDim2.new(0, px(12), 0, px(74))
lblSaved.Size = UDim2.new(1, -px(24), 0, px(13))
lblSaved.Text = ""
lblSaved.TextColor3 = Color3.fromRGB(200, 150, 170)
lblSaved.Font = Enum.Font.Gotham
lblSaved.TextSize = px(8)
lblSaved.TextXAlignment = Enum.TextXAlignment.Left
lblSaved.ZIndex = 2
lblSaved.Parent = Frame

-- 按钮全挂 main
local FX, FXO, FY = 0.5, -px(120), 0.04
local FH = px(200)

local function makeBtn(text, bg, fg, xOff, w, yAbs)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, px(30))
    b.Position = UDim2.new(FX, FXO + xOff, 0, FY * workspace.CurrentCamera.ViewportSize.Y + yAbs)
    b.BackgroundColor3 = bg; b.BorderSizePixel = 0
    b.Text = text; b.TextColor3 = fg
    b.Font = Enum.Font.GothamBold; b.TextSize = px(11)
    b.ZIndex = 20; b.AutoButtonColor = false; b.Active = true
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    return b
end

local btnStart = makeBtn("▶ Start",
    Color3.fromRGB(191,226,205), Color3.fromRGB(72,108,88), px(12), px(100), FH + px(6))
local btnStop = makeBtn("■ Stop",
    Color3.fromRGB(245,179,188), Color3.fromRGB(125,75,85), px(118), px(60), FH + px(6))
local btnReset = makeBtn("Reset",
    Color3.fromRGB(220,220,235), Color3.fromRGB(100,100,130), px(12), px(72), FH + px(42))
local btnClose = makeBtn("×",
    Color3.fromRGB(200,200,210), Color3.fromRGB(100,100,120), FX*2 + px(200), px(24), px(8))
btnClose.Position = UDim2.new(FX, FXO + px(240) - px(30), 0, FY * workspace.CurrentCamera.ViewportSize.Y + px(8))

-- ===== 状态 =====
local building = false
local allData = nil
local startIdx = 1

local function setStatus(t, color)
    lblStatus.Text = t
    if color then lblStatus.TextColor3 = color end
end

local function setProg(cur, tot)
    lblProg.Text = cur .. " / " .. tot
    barFill.Size = UDim2.new(tot > 0 and cur/tot or 0, 0, 1, 0)
end

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
    if ok and val then
        return tonumber(val) or 1
    end
    return 1
end

-- ===== 加载数据 =====
local function loadData()
    setStatus("Loading main data...")
    local ok1, res1 = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)
    if not ok1 then setStatus("ERROR: "..tostring(res1), Color3.fromRGB(200,60,60)) return nil end

    local ok2, res2 = pcall(function()
        return game:HttpGet(BLUSH_URL)
    end)
    if not ok2 then setStatus("ERROR blush: "..tostring(res2), Color3.fromRGB(200,60,60)) return nil end

    -- 解析主数据
    local mainOk = pcall(loadstring(res1))
    if not mainOk or not _G.MSGSphereEmojiData then
        setStatus("Parse error: main data", Color3.fromRGB(200,60,60)) return nil
    end

    -- 解析腮红数据
    local blushOk = pcall(loadstring(res2))
    if not blushOk or not _G.BlushData then
        setStatus("Parse error: blush data", Color3.fromRGB(200,60,60)) return nil
    end

    -- 合并
    local combined = {}
    for _, v in ipairs(_G.MSGSphereEmojiData) do
        table.insert(combined, {
            n = v.n, x = v.x, y = v.y, z = v.z,
            r00=v.r00,r01=v.r01,r02=v.r02,
            r10=v.r10,r11=v.r11,r12=v.r12,
            r20=v.r20,r21=v.r21,r22=v.r22
        })
    end
    for _, v in ipairs(_G.BlushData) do
        table.insert(combined, {
            n = "Candy", x = v.x, y = v.y, z = v.z,
            r00=1,r01=0,r02=0,r10=0,r11=1,r12=0,r20=0,r21=0,r22=1
        })
    end

    setStatus("Loaded " .. #combined .. " blocks")
    return combined
end

-- ===== 喷漆 =====
local function paintBlock(obj, colorName)
    local col = COLOR_MAP[colorName]
    if not col then return end
    local paintRemote = RS:FindFirstChild("Interaction") and
                        RS.Interaction:FindFirstChild("PaintObject")
    if paintRemote then
        pcall(function() paintRemote:FireServer(obj, col) end)
    else
        -- 直接改颜色
        pcall(function()
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") then p.Color = col end
            end
        end)
    end
end

-- ===== 建造单块 =====
local placeRemote = nil
local function getPlaceRemote()
    if placeRemote then return placeRemote end
    local ok, r = pcall(function()
        return RS:WaitForChild("Interaction",5):WaitForChild("PlaceBlueprint",5)
    end)
    if ok and r then placeRemote = r end
    return placeRemote
end

local function buildOne(entry)
    local remote = getPlaceRemote()
    if not remote then return false end
    local cf = CFrame.new(entry.x, entry.y, entry.z,
        entry.r00, entry.r01, entry.r02,
        entry.r10, entry.r11, entry.r12,
        entry.r20, entry.r21, entry.r22)
    local ok, result = pcall(function()
        return remote:InvokeServer(entry.n, cf)
    end)
    if ok and result then
        -- 喷漆
        task.spawn(function()
            task.wait(0.05)
            paintBlock(result, entry.n)
        end)
        return true
    end
    return false
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
    btnStart.BackgroundColor3 = Color3.fromRGB(210,210,220)
    setStatus("Building from #" .. startIdx)

    local total = #allData
    local i = startIdx

    while building and i <= total do
        local entry = allData[i]
        buildOne(entry)
        setProg(i, total)

        -- 每50块存一次进度
        if i % 50 == 0 then
            saveProgress(i)
        end

        i = i + 1
        task.wait(0.006)
    end

    if i > total then
        setStatus("Done! All " .. total .. " blocks placed", Color3.fromRGB(72,130,90))
        barFill.BackgroundColor3 = Color3.fromRGB(140,210,160)
        saveProgress(1)  -- 重置
    else
        saveProgress(i)
        setStatus("Stopped at #" .. i)
    end

    building = false
    btnStart.BackgroundColor3 = Color3.fromRGB(191,226,205)
end

-- ===== 按钮事件 =====
btnStart.MouseButton1Click:Connect(function() task.spawn(startBuild) end)
btnStart.TouchTap:Connect(function() task.spawn(startBuild) end)

btnStop.MouseButton1Click:Connect(function()
    building = false
    setStatus("Stopping...")
end)
btnStop.TouchTap:Connect(function()
    building = false
    setStatus("Stopping...")
end)

btnReset.MouseButton1Click:Connect(function()
    saveProgress(1)
    startIdx = 1
    lblSaved.Text = "Reset to #1"
    setStatus("Progress reset")
end)
btnReset.TouchTap:Connect(function()
    saveProgress(1)
    startIdx = 1
    lblSaved.Text = "Reset to #1"
    setStatus("Progress reset")
end)

btnClose.MouseButton1Click:Connect(function() main:Destroy() end)
btnClose.TouchTap:Connect(function() main:Destroy() end)

-- 启动时显示已存进度
local saved = loadProgress()
if saved > 1 then
    lblSaved.Text = "Resume from #" .. saved
    setStatus("Ready (saved: #" .. saved .. ")")
else
    setStatus("Ready")
end

print("[Sphere Builder] loaded. " .. (allData and #allData or "?") .. " blocks queued.")