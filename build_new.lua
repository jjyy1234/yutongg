-- YUTONG-炸基地 v2 by YUTONGG
-- Uses ClientPlacedBlueprint to move target blocks to high altitude
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
local BUILD_DATA = {}
local DATA_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data_new.lua"
local dataLoaded = false
local dataCount = 0

local function loadData()
    local ok, result = pcall(function()
        return game:HttpGet(DATA_URL, true)
    end)
    if ok and result then
        local fn, err = loadstring(result)
        if fn then
            local success, data = pcall(fn)
            if success and type(data) == "table" then
                BUILD_DATA = data
                dataCount = #data
                dataLoaded = true
                return true
            end
        end
    end
    return false
end

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
screenGui.Name = "YUTONG_Destroyer"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lp.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0,240,0,340)
main.Position = UDim2.new(0,10,0.5,-170)
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
titleLbl.Text = "YUTONG"
titleLbl.TextColor3 = TEXT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = titleBar

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,0,40)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Loading data..."
statusLbl.TextColor3 = SUBTEXT
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

local ownerLabel = Instance.new("TextLabel")
ownerLabel.Size = UDim2.new(1,-16,0,16)
ownerLabel.Position = UDim2.new(0,8,0,61)
ownerLabel.BackgroundTransparency = 1
ownerLabel.Text = "Target: All"
ownerLabel.TextColor3 = TEXT
ownerLabel.Font = Enum.Font.GothamBold
ownerLabel.TextSize = 11
ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
ownerLabel.Parent = main

local ownerScroll = Instance.new("ScrollingFrame")
ownerScroll.Size = UDim2.new(1,-16,0,60)
ownerScroll.Position = UDim2.new(0,8,0,80)
ownerScroll.BackgroundColor3 = W
ownerScroll.BackgroundTransparency = 0.4
ownerScroll.BorderSizePixel = 0
ownerScroll.ScrollBarThickness = 3
ownerScroll.ScrollBarImageColor3 = SUBTEXT
ownerScroll.CanvasSize = UDim2.new(0,0,0,0)
ownerScroll.Parent = main
Instance.new("UICorner",ownerScroll).CornerRadius = UDim.new(0,6)
local listLayout = Instance.new("UIListLayout",ownerScroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local selectedOwner = nil

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

local scanOwnerBtn = makeBtn("Scan Players",148)
local deleteBtn    = makeBtn("Move to Sky",186)
local stopBtn      = makeBtn("Stop",224)

local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(1,-16,0,18)
countLbl.Position = UDim2.new(0,8,0,262)
countLbl.BackgroundTransparency = 1
countLbl.Text = "Moved: 0"
countLbl.TextColor3 = TEXT
countLbl.TextSize = 11
countLbl.Font = Enum.Font.Gotham
countLbl.TextXAlignment = Enum.TextXAlignment.Left
countLbl.Parent = main

local modeLbl = Instance.new("TextLabel")
modeLbl.Size = UDim2.new(1,-16,0,16)
modeLbl.Position = UDim2.new(0,8,0,282)
modeLbl.BackgroundTransparency = 1
modeLbl.Text = "Mode: Move All to Sky"
modeLbl.TextColor3 = SUBTEXT
modeLbl.TextSize = 10
modeLbl.Font = Enum.Font.Gotham
modeLbl.TextXAlignment = Enum.TextXAlignment.Left
modeLbl.Parent = main

local dataLbl = Instance.new("TextLabel")
dataLbl.Size = UDim2.new(1,-16,0,16)
dataLbl.Position = UDim2.new(0,8,0,300)
dataLbl.BackgroundTransparency = 1
dataLbl.Text = "Data: not loaded"
dataLbl.TextColor3 = SUBTEXT
dataLbl.TextSize = 10
dataLbl.Font = Enum.Font.Gotham
dataLbl.TextXAlignment = Enum.TextXAlignment.Left
dataLbl.Parent = main

local heightBox = Instance.new("TextBox")
heightBox.Size = UDim2.new(0,60,0,20)
heightBox.Position = UDim2.new(1,-68,0,300)
heightBox.BackgroundColor3 = W
heightBox.BackgroundTransparency = 0.3
heightBox.BorderSizePixel = 0
heightBox.Text = "2000"
heightBox.TextColor3 = TEXT
heightBox.TextSize = 10
heightBox.Font = Enum.Font.Gotham
heightBox.PlaceholderText = "Height"
heightBox.Parent = main
Instance.new("UICorner",heightBox).CornerRadius = UDim.new(0,4)

local function getOwnerPlayer(model)
    local ow = model:FindFirstChild("Owner")
    local ok, val = pcall(function() return ow and ow.Value end)
    if ok and val and typeof(val)=="Instance" and val:IsA("Player") then return val end
    return nil
end

local function refreshOwners()
    for _, c in ipairs(ownerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1,0,0,22)
    allBtn.BackgroundColor3 = W
    allBtn.BackgroundTransparency = selectedOwner == nil and 0.1 or 0.5
    allBtn.BorderSizePixel = 0
    allBtn.Text = "All"
    allBtn.TextColor3 = TEXT
    allBtn.Font = Enum.Font.GothamBold
    allBtn.TextSize = 11
    allBtn.LayoutOrder = 0
    allBtn.Parent = ownerScroll
    Instance.new("UICorner",allBtn).CornerRadius = UDim.new(0,4)
    allBtn.MouseButton1Click:Connect(function()
        selectedOwner = nil
        ownerLabel.Text = "Target: All"
        modeLbl.Text = "Mode: Move All to Sky"
        for _, c in ipairs(ownerScroll:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundTransparency = c == allBtn and 0.1 or 0.5
            end
        end
        notify("YUTONG","Target: All",2)
    end)

    local seen = {}
    local order = 1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getOwnerPlayer(obj)
            if p and WHITELIST[p.Name] and p.Name ~= lp.Name then continue end
            if p and not seen[p.Name] then
                seen[p.Name] = true
                local capturedP = p
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,28)
                btn.BackgroundColor3 = W
                btn.BackgroundTransparency = 0.5
                btn.BorderSizePixel = 0
                btn.Text = ""
                btn.LayoutOrder = order
                btn.Parent = ownerScroll
                Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)

                local avatar = Instance.new("ImageLabel")
                avatar.Size = UDim2.new(0,22,0,22)
                avatar.Position = UDim2.new(0,3,0.5,-11)
                avatar.BackgroundTransparency = 1
                avatar.Image = ""
                avatar.Parent = btn
                Instance.new("UICorner",avatar).CornerRadius = UDim.new(1,0)
                task.spawn(function()
                    local ok2, img = pcall(function()
                        return Players:GetUserThumbnailAsync(
                            capturedP.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size48x48
                        )
                    end)
                    if ok2 then avatar.Image = img end
                end)

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1,-30,1,0)
                nameLbl.Position = UDim2.new(0,28,0,0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = capturedP.Name
                nameLbl.TextColor3 = TEXT
                nameLbl.Font = Enum.Font.Gotham
                nameLbl.TextSize = 11
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    selectedOwner = capturedP
                    ownerLabel.Text = "Target: " .. capturedP.Name
                    modeLbl.Text = "Mode: Specific Player"
                    for _, c in ipairs(ownerScroll:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.BackgroundTransparency = c == btn and 0.1 or 0.5
                        end
                    end
                    notify("YUTONG","Target: " .. capturedP.Name,2)
                end)
                order = order + 1
            end
        end
    end
    ownerScroll.CanvasSize = UDim2.new(0,0,0,(order+1)*28)
    statusLbl.Text = "Scan done, found " .. (order-1) .. " players"
    notify("YUTONG","Scan done, found " .. (order-1) .. " players",3)
end

scanOwnerBtn.MouseButton1Click:Connect(function()
    statusLbl.Text = "Scanning..."
    notify("YUTONG","Scanning players...",2)
    refreshOwners()
end)

local running = false

deleteBtn.MouseButton1Click:Connect(function()
    if running then
        notify("YUTONG","Running, please stop first",2)
        return
    end
    if not dataLoaded then
        notify("YUTONG","Data not loaded, loading now...",2)
        statusLbl.Text = "Loading data..."
        local ok = loadData()
        if ok then
            dataLbl.Text = "Data: " .. dataCount .. " entries"
            statusLbl.Text = "Data loaded: " .. dataCount .. " entries"
            notify("YUTONG","Data loaded: " .. dataCount .. " entries",3)
        else
            statusLbl.Text = "Data load failed!"
            notify("YUTONG","Data load failed!",3)
            return
        end
    end

    running = true
    deleteBtn.Text = "Moving..."

    local height = tonumber(heightBox.Text) or 2000

    local targets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getOwnerPlayer(obj)
            if p and WHITELIST[p.Name] and p.Name ~= lp.Name then continue end
            if selectedOwner == nil or p == selectedOwner then
                local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if pp then
                    table.insert(targets, {model=obj, part=pp, name=obj.Name})
                end
            end
        end
    end

    local targetName = selectedOwner and selectedOwner.Name or "All"
    statusLbl.Text = "Found " .. #targets .. " targets"
    notify("YUTONG","Start! Target: " .. targetName .. ", " .. #targets .. " blocks",3)

    local moved = 0
    for _, t in ipairs(targets) do
        if not running then break end
        task.spawn(function()
            local origPos = t.part.Position
            local highCFrame = CFrame.new(origPos.X, height, origPos.Z)

            local destroyRemote = game:GetService("ReplicatedStorage").Interaction.DestroyStructure
            pcall(function() destroyRemote:FireServer(t.model) end)

            task.wait(0.05)

            local nilObj = nil
            for _, obj in getnilinstances() do
                if obj.Name == t.name then
                    local ok, id = pcall(function() return obj:GetDebugId() end)
                    if ok then
                        nilObj = obj
                        break
                    end
                end
            end

            if nilObj then
                pcall(function()
                    placeRemote:FireServer(
                        t.name,
                        highCFrame,
                        lp,
                        nilObj,
                        true
                    )
                end)
            end

            moved = moved + 1
            countLbl.Text = "Moved: " .. moved .. " / " .. #targets
        end)
    end

    task.wait(2)
    statusLbl.Text = running and ("Done! " .. #targets .. " blocks") or "Stopped"
    if running then notify("YUTONG","Done! " .. #targets .. " blocks moved",4) end
    deleteBtn.Text = "Move to Sky"
    running = false
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

-- Async load data on startup
task.spawn(function()
    statusLbl.Text = "Loading building data..."
    local ok = loadData()
    if ok then
        dataLbl.Text = "Data: " .. dataCount .. " entries"
        statusLbl.Text = "Ready (" .. dataCount .. " entries)"
        notify("YUTONG","Data loaded: " .. dataCount .. " entries",3)
    else
        dataLbl.Text = "Data: load failed"
        statusLbl.Text = "Ready (data load failed)"
        notify("YUTONG","Data load failed, will retry on use",3)
    end
end)

notify("YUTONG","Script loaded",3)
print("[YUTONG-Destroyer] Loaded, data entries: " .. dataCount)
