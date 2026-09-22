local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- 白名单从 GitHub 远程加载
local WHITELIST = {}
pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/whitelist.txt", true)
    for name in raw:gmatch("[^\r\n]+") do
        name = name:match("^%s*(.-)%s*$")
        if name ~= "" then WHITELIST[name] = true end
    end
end)
if not WHITELIST[lp.Name] then
    lp:Kick("Not whitelisted")
    return
end

local placeRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA = nil
pcall(function()
    DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"))()
end)
if not DATA then warn("Failed to load blueprint_data") return end
local TOTAL = #DATA

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=duration or 3})
    end)
end

local W       = Color3.fromRGB(255,255,255)
local TEXT    = Color3.fromRGB(0,0,0)
local SUBTEXT = Color3.fromRGB(60,60,60)

local old = lp.PlayerGui:FindFirstChild("CBGui")
if old then old:Destroy() end
local sg = Instance.new("ScreenGui", lp.PlayerGui)
sg.Name = "CBGui"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0,240,0,340)
main.Position = UDim2.new(0,10,0.5,-170)
main.BackgroundColor3 = W
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = W
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,12)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1,0,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "YUTONG"
titleLbl.TextColor3 = TEXT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold

local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,0,40)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Ready"
statusLbl.TextColor3 = SUBTEXT
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local ownerLabel = Instance.new("TextLabel", main)
ownerLabel.Size = UDim2.new(1,-16,0,16)
ownerLabel.Position = UDim2.new(0,8,0,61)
ownerLabel.BackgroundTransparency = 1
ownerLabel.Text = "Target: (none)"
ownerLabel.TextColor3 = TEXT
ownerLabel.Font = Enum.Font.GothamBold
ownerLabel.TextSize = 11
ownerLabel.TextXAlignment = Enum.TextXAlignment.Left

local ownerScroll = Instance.new("ScrollingFrame", main)
ownerScroll.Size = UDim2.new(1,-16,0,60)
ownerScroll.Position = UDim2.new(0,8,0,80)
ownerScroll.BackgroundColor3 = W
ownerScroll.BackgroundTransparency = 0.4
ownerScroll.BorderSizePixel = 0
ownerScroll.ScrollBarThickness = 3
ownerScroll.ScrollBarImageColor3 = SUBTEXT
ownerScroll.CanvasSize = UDim2.new(0,0,0,0)
Instance.new("UICorner",ownerScroll).CornerRadius = UDim.new(0,6)
local listLayout = Instance.new("UIListLayout", ownerScroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local selectedOwner = nil

local function makeBtn(text, y, h)
    h = h or 30
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(1,-16,0,h)
    btn.Position = UDim2.new(0,8,0,y)
    btn.BackgroundColor3 = W
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = TEXT
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    return btn
end

local scanOwnerBtn = makeBtn("Scan Players", 148)
local startBtn     = makeBtn("Build",        186)
local paintBtn     = makeBtn("Paint",        224)

local chaosBtn = Instance.new("TextButton", main)
chaosBtn.Size = UDim2.new(0,140,0,30)
chaosBtn.Position = UDim2.new(0,8,0,262)
chaosBtn.BackgroundColor3 = W
chaosBtn.BackgroundTransparency = 0.3
chaosBtn.BorderSizePixel = 0
chaosBtn.Text = "Chaos"
chaosBtn.TextColor3 = TEXT
chaosBtn.TextSize = 12
chaosBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner",chaosBtn).CornerRadius = UDim.new(0,7)

local chaosInput = Instance.new("TextBox", main)
chaosInput.Size = UDim2.new(0,72,0,30)
chaosInput.Position = UDim2.new(0,156,0,262)
chaosInput.BackgroundColor3 = W
chaosInput.BackgroundTransparency = 0.4
chaosInput.BorderSizePixel = 0
chaosInput.Text = "500"
chaosInput.TextColor3 = TEXT
chaosInput.Font = Enum.Font.GothamBold
chaosInput.TextSize = 12
chaosInput.ClearTextOnFocus = false
Instance.new("UICorner",chaosInput).CornerRadius = UDim.new(0,7)

local stopBtn = makeBtn("Stop", 300)

local countLbl = Instance.new("TextLabel", main)
countLbl.Size = UDim2.new(1,-16,0,18)
countLbl.Position = UDim2.new(0,8,0,300)
countLbl.BackgroundTransparency = 1
countLbl.Text = "Progress: 0"
countLbl.TextColor3 = TEXT
countLbl.TextSize = 11
countLbl.Font = Enum.Font.Gotham
countLbl.TextXAlignment = Enum.TextXAlignment.Left

local modeLbl = Instance.new("TextLabel", main)
modeLbl.Size = UDim2.new(1,-16,0,16)
modeLbl.Position = UDim2.new(0,8,0,320)
modeLbl.BackgroundTransparency = 1
modeLbl.Text = "Mode: Build"
modeLbl.TextColor3 = SUBTEXT
modeLbl.TextSize = 10
modeLbl.Font = Enum.Font.Gotham
modeLbl.TextXAlignment = Enum.TextXAlignment.Left

local running = false

local BLUEPRINT_NAMES = {
    "Floor1Tiny","Floor2Tiny","Floor3Tiny","Floor4Tiny","Floor5Tiny",
    "Wall1Short","Wall2Short","Wall2ShortThin","Wall3Short",
    "Ramp1","Ramp2","Ramp3","Stair1","Stair2","Roof1","Roof2","Roof3",
    "Floor1Large","Floor2Large","Floor3Large",
}

local ROTATIONS = {
    {1,0,0, 0,1,0, 0,0,1},
    {0,0,1, 0,1,0,-1,0,0},
    {-1,0,0,0,1,0, 0,0,-1},
    {0,0,-1,0,1,0, 1,0,0},
    {1,0,0, 0,0,-1, 0,1,0},
    {1,0,0, 0,0,1, 0,-1,0},
    {0,1,0,-1,0,0, 0,0,1},
    {0,-1,0,1,0,0, 0,0,1},
    {1,0,0, 0,-1,0, 0,0,-1},
    {-1,0,0,0,-1,0, 0,0,1},
    {0,0,1, 0,-1,0,-1,0,0},
    {0,0,-1,0,-1,0, 1,0,0},
}

scanOwnerBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(ownerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local seen = {}
    local order = 1
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ov = obj:FindFirstChild("Owner")
            local ok, val = pcall(function() return ov and ov.Value end)
            if ok and val and typeof(val)=="Instance" and val:IsA("Player") then
                local p = val
                if not seen[p.Name] then
                    seen[p.Name] = true
                    local capturedP = p
                    local btn = Instance.new("TextButton", ownerScroll)
                    btn.Size = UDim2.new(1,0,0,28)
                    btn.BackgroundColor3 = W
                    btn.BackgroundTransparency = 0.5
                    btn.BorderSizePixel = 0
                    btn.Text = ""
                    btn.LayoutOrder = order
                    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
                    local avatar = Instance.new("ImageLabel", btn)
                    avatar.Size = UDim2.new(0,22,0,22)
                    avatar.Position = UDim2.new(0,3,0.5,-11)
                    avatar.BackgroundTransparency = 1
                    avatar.Image = ""
                    Instance.new("UICorner",avatar).CornerRadius = UDim.new(1,0)
                    task.spawn(function()
                        local ok2, img = pcall(function()
                            return Players:GetUserThumbnailAsync(capturedP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        end)
                        if ok2 then avatar.Image = img end
                    end)
                    local nameLbl = Instance.new("TextLabel", btn)
                    nameLbl.Size = UDim2.new(1,-30,1,0)
                    nameLbl.Position = UDim2.new(0,28,0,0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = capturedP.Name
                    nameLbl.TextColor3 = TEXT
                    nameLbl.Font = Enum.Font.Gotham
                    nameLbl.TextSize = 11
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    btn.MouseButton1Click:Connect(function()
                        selectedOwner = capturedP
                        ownerLabel.Text = "Target: " .. capturedP.Name
                        for _,c2 in ipairs(ownerScroll:GetChildren()) do
                            if c2:IsA("TextButton") then
                                c2.BackgroundTransparency = c2 == btn and 0.1 or 0.5
                            end
                        end
                        notify("YUTONG", "Target: " .. capturedP.Name, 2)
                    end)
                    order = order + 1
                end
            end
        end
    end
    ownerScroll.CanvasSize = UDim2.new(0,0,0,order*28)
    statusLbl.Text = "Found " .. (order-1) .. " players"
    notify("YUTONG", "Found " .. (order-1) .. " players", 3)
end)

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    if not selectedOwner then statusLbl.Text="Select a target first" return end
    running = true
    modeLbl.Text = "Mode: Build"
    statusLbl.Text = "Building..."
    notify("YUTONG", "Building " .. TOTAL .. " blocks")
    task.spawn(function()
        local cnt = 0
        for i,d in ipairs(DATA) do
            if not running then break end
            if d.n ~= "Property" then
                local cf = CFrame.new(d.x,d.y,d.z,d.r00,d.r01,d.r02,d.r10,d.r11,d.r12,d.r20,d.r21,d.r22)
                pcall(function() placeRemote:FireServer(d.n,cf,lp) end)
                cnt = cnt + 1
                countLbl.Text = "Progress: " .. cnt .. "/" .. TOTAL
                task.wait(0.01)
            end
        end
        statusLbl.Text = running and ("Done: "..cnt) or ("Stopped: "..cnt)
        if running then notify("YUTONG","Build done! "..cnt) end
        running = false
    end)
end)

paintBtn.MouseButton1Click:Connect(function()
    if running then return end
    if not selectedOwner then statusLbl.Text="Select a target first" return end
    running = true
    modeLbl.Text = "Mode: Paint"
    statusLbl.Text = "Indexing..."
    notify("YUTONG","Painting...")
    task.spawn(function()
        local idx = {}
        local ownerName = selectedOwner and selectedOwner.Name or ""
        for _,m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") then
                local ov = m:FindFirstChild("Owner")
                local match = false
                if ov then
                    if typeof(ov.Value)=="Instance" and ov.Value:IsA("Player") and ov.Value.Name==ownerName then match=true
                    elseif typeof(ov.Value)=="string" and ov.Value==ownerName then match=true end
                end
                if match then
                    local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        local pos = pp.Position
                        local k = math.floor(pos.X+0.5).."_"..math.floor(pos.Y+0.5).."_"..math.floor(pos.Z+0.5)
                        idx[k] = m
                    end
                end
            end
        end
        local idxCount = 0; for _ in pairs(idx) do idxCount=idxCount+1 end
        statusLbl.Text = "Indexed: " .. idxCount
        task.wait(0.5)
        local painted, skip = 0, 0
        for i,d in ipairs(DATA) do
            if not running then break end
            if d.n ~= "Property" and d.wood and d.wood ~= "?" then
                local k = math.floor(d.x+0.5).."_"..math.floor(d.y+0.5).."_"..math.floor(d.z+0.5)
                local m = idx[k]
                if not m then
                    for dx=-2,2 do for dy=-2,2 do for dz=-2,2 do
                        local k2=(math.floor(d.x+0.5)+dx).."_"..(math.floor(d.y+0.5)+dy).."_"..(math.floor(d.z+0.5)+dz)
                        if idx[k2] then m=idx[k2] break end
                    end if m then break end end if m then break end end
                end
                if m then pcall(function() paintRemote:FireServer(m,d.wood) end) painted=painted+1
                else skip=skip+1 end
                task.wait(0.01)
            end
            if i%100==0 then
                countLbl.Text = "Paint: " .. i .. "/" .. TOTAL
                statusLbl.Text = "Painted:"..painted.." Skip:"..skip
            end
        end
        countLbl.Text = "Paint: " .. TOTAL .. "/" .. TOTAL
        statusLbl.Text = running and ("Paint done: "..painted) or "Stopped"
        if running then notify("YUTONG","Paint done! "..painted) end
        running = false
    end)
end)

chaosBtn.MouseButton1Click:Connect(function()
    if running then statusLbl.Text="Stop current first" return end
    if not selectedOwner then statusLbl.Text="Select a target first" return end

    local minX,maxX,minZ,maxZ = math.huge,-math.huge,math.huge,-math.huge
    local found = 0
    for _,m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") then
            local ov = m:FindFirstChild("Owner")
            if ov and typeof(ov.Value)=="Instance" and ov.Value==selectedOwner then
                local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                if pp then
                    local pos = pp.Position
                    if pos.X<minX then minX=pos.X end
                    if pos.X>maxX then maxX=pos.X end
                    if pos.Z<minZ then minZ=pos.Z end
                    if pos.Z>maxZ then maxZ=pos.Z end
                    found = found + 1
                end
            end
        end
    end

    if found == 0 then statusLbl.Text="No blocks found" return end

    local pad = 30
    minX=minX-pad; maxX=maxX+pad; minZ=minZ-pad; maxZ=maxZ+pad

    local count = tonumber(chaosInput.Text) or 500
    if count < 1 then count=1 end
    if count > 9999 then count=9999 end

    running = true
    modeLbl.Text = "Mode: Chaos"
    statusLbl.Text = "Chaos firing..."
    notify("YUTONG","Chaos: "..count.." blocks")

    task.spawn(function()
        local packets = {}
        for i = 1, count do
            local rx = minX + math.random()*(maxX-minX)
            local ry = 0.2 + math.random()*150
            local rz = minZ + math.random()*(maxZ-minZ)
            local bpName = math.random()<0.9 and "Floor1Tiny" or BLUEPRINT_NAMES[math.random(#BLUEPRINT_NAMES)]
            local rot = ROTATIONS[math.random(#ROTATIONS)]
            local cf = CFrame.new(rx,ry,rz, rot[1],rot[2],rot[3], rot[4],rot[5],rot[6], rot[7],rot[8],rot[9])
            packets[i] = {bpName, cf}
        end
        local placed = 0
        for _,pkt in ipairs(packets) do
            task.spawn(function()
                pcall(function() placeRemote:FireServer(pkt[1],pkt[2],lp) end)
            end)
            placed = placed + 1
        end
        countLbl.Text = "Chaos: " .. placed .. "/" .. count
        statusLbl.Text = "Chaos done: " .. placed
        notify("YUTONG","Chaos done! "..placed)
        running = false
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    statusLbl.Text = "Stopped"
    notify("YUTONG","Stopped", 2)
end)

notify("YUTONG","Loaded "..TOTAL.." blocks", 3)
statusLbl.Text = "Ready: " .. TOTAL .. " blocks"
