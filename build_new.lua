-- YUTONG-AutoBuild by YUTONGG
-- Uses ClientPlacedBlueprint to auto-build from blueprint data
-- Building data loaded from GitHub via HttpGet
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

-- 从 GitHub 加载白名单
local WHITELIST = {}
do
    local ok, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/whitelist.txt", true)
    end)
    if ok and result then
        for name in result:gmatch("[^\r\n]+") do
            name = name:match("^%s*(.-)%s*$")
            if #name > 0 then WHITELIST[name] = true end
        end
    end
end

if not WHITELIST[lp.Name] then
    lp:Kick("Unauthorized")
    return
end

local placeRemote = game:GetService("ReplicatedStorage").PlaceStructure.ClientPlacedBlueprint

-- 从 GitHub 加载建筑数据
local DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data_new.lua", true))()
local dataCount = #DATA

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3,
        })
    end)
end

local W = Color3.fromRGB(255,255,255)
local TEXT = Color3.fromRGB(0,0,0)
local SUBTEXT = Color3.fromRGB(60,60,60)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YUTONG_AutoBuild"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lp.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0,240,0,200)
main.Position = UDim2.new(0,10,0.5,-100)
main.BackgroundColor3 = W
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = W
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,12)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,0,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "YUTONG AutoBuild"
titleLbl.TextColor3 = TEXT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = titleBar

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,0,40)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Ready (" .. dataCount .. " blocks)"
statusLbl.TextColor3 = SUBTEXT
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

local progressLbl = Instance.new("TextLabel")
progressLbl.Size = UDim2.new(1,-16,0,18)
progressLbl.Position = UDim2.new(0,8,0,60)
progressLbl.BackgroundTransparency = 1
progressLbl.Text = "Progress: 0/" .. dataCount
progressLbl.TextColor3 = TEXT
progressLbl.TextSize = 11
progressLbl.Font = Enum.Font.GothamBold
progressLbl.TextXAlignment = Enum.TextXAlignment.Left
progressLbl.Parent = main

local function makeBtn(text,y,h)
    h = h or 30
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-16,0,h)
    btn.Position = UDim2.new(0,8,0,y)
    btn.BackgroundColor3 = W
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = TEXT
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = main
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    return btn
end

local buildBtn = makeBtn("Build",88)
local stopBtn  = makeBtn("Stop",126)

local running = false

buildBtn.MouseButton1Click:Connect(function()
    if running then
        notify("YUTONG","Already running, press Stop first",2)
        return
    end
    running = true
    buildBtn.Text = "Building..."

    statusLbl.Text = "Building..."
    notify("YUTONG","Build started: " .. dataCount .. " blocks",3)

    local cnt = 0
    task.spawn(function()
        for i, d in ipairs(DATA) do
            if not running then break end
            pcall(function()
                placeRemote:FireServer(d.n, CFrame.new(d.x,d.y,d.z, d.r00,d.r01,d.r02, d.r10,d.r11,d.r12, d.r20,d.r21,d.r22), lp)
            end)
            cnt = cnt + 1
            progressLbl.Text = "Progress: " .. cnt .. "/" .. dataCount
            task.wait(0.01)
        end
        statusLbl.Text = running and ("Done! " .. cnt .. "/" .. dataCount) or "Stopped at " .. cnt .. "/" .. dataCount
        if running then notify("YUTONG","Build complete: " .. cnt .. " blocks",4) end
        buildBtn.Text = "Build"
        running = false
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        statusLbl.Text = "Stopped"
        notify("YUTONG","Stopped",2)
    else
        notify("YUTONG","Not running",2)
    end
end)

notify("YUTONG","AutoBuild loaded: " .. dataCount .. " blocks",3)
print("[YUTONG-AutoBuild] Loaded, data entries: " .. dataCount)
