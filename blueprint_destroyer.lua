-- YUTONG-炸基地 by YUTONGG
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

-- 从 GitHub 加载白名单
local WHITELIST = {}
task.spawn(function()
    local ok, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/whitelist.txt", true)
    end)
    if ok and result then
        for name in result:gmatch("[^\r\n]+") do
            name = name:match("^%s*(.-)%s*$")
            if #name > 0 then
                WHITELIST[name] = true
            end
        end
    end
end)

local destroyRemote = game:GetService("ReplicatedStorage").Interaction.DestroyStructure

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3,
        })
    end)
end

local W = Color3.fromRGB(255,255,255)
local TEXT = Color3.fromRGB(0, 0, 0)
local SUBTEXT = Color3.fromRGB(60, 60, 60)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YUTONG炸基地"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lp.PlayerGui

-- 主框
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 310)
main.Position = UDim2.new(0, 10, 0.5, -155)
main.BackgroundColor3 = W
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = W
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "YUTONG"
titleLbl.TextColor3 = TEXT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = titleBar

-- 状态栏
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,0,40)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "就绪"
statusLbl.TextColor3 = SUBTEXT
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

-- Owner 标签
local ownerLabel = Instance.new("TextLabel")
ownerLabel.Size = UDim2.new(1,-16,0,16)
ownerLabel.Position = UDim2.new(0,8,0,61)
ownerLabel.BackgroundTransparency = 1
ownerLabel.Text = "目标：全部"
ownerLabel.TextColor3 = TEXT
ownerLabel.Font = Enum.Font.GothamBold
ownerLabel.TextSize = 11
ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
ownerLabel.Parent = main

-- Owner 滚动列表
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
Instance.new("UICorner", ownerScroll).CornerRadius = UDim.new(0, 6)
local listLayout = Instance.new("UIListLayout", ownerScroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local selectedOwner = nil

local function makeBtn(text, y, h)
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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    return btn
end

local scanOwnerBtn = makeBtn("扫描玩家", 148)
local deleteBtn    = makeBtn("炸基地",   186)
local stopBtn      = makeBtn("停止",      224)

local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(1,-16,0,18)
countLbl.Position = UDim2.new(0,8,0,262)
countLbl.BackgroundTransparency = 1
countLbl.Text = "已删除：0"
countLbl.TextColor3 = TEXT
countLbl.TextSize = 11
countLbl.Font = Enum.Font.Gotham
countLbl.TextXAlignment = Enum.TextXAlignment.Left
countLbl.Parent = main

local modeLbl = Instance.new("TextLabel")
modeLbl.Size = UDim2.new(1,-16,0,16)
modeLbl.Position = UDim2.new(0,8,0,282)
modeLbl.BackgroundTransparency = 1
modeLbl.Text = "模式：全部删除"
modeLbl.TextColor3 = SUBTEXT
modeLbl.TextSize = 10
modeLbl.Font = Enum.Font.Gotham
modeLbl.TextXAlignment = Enum.TextXAlignment.Left
modeLbl.Parent = main

local function getOwnerPlayer(model)
    local ow = model:FindFirstChild("Owner")
    local ok, val = pcall(function() return ow and ow.Value end)
    if ok and val and val:IsA("Player") then return val end
    return nil
end

-- 扫描玩家
local function refreshOwners()
    for _, c in ipairs(ownerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1,0,0,22)
    allBtn.BackgroundColor3 = W
    allBtn.BackgroundTransparency = selectedOwner == nil and 0.1 or 0.5
    allBtn.BorderSizePixel = 0
    allBtn.Text = "全部"
    allBtn.TextColor3 = TEXT
    allBtn.Font = Enum.Font.GothamBold
    allBtn.TextSize = 11
    allBtn.LayoutOrder = 0
    allBtn.Parent = ownerScroll
    Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 4)
    allBtn.MouseButton1Click:Connect(function()
        selectedOwner = nil
        ownerLabel.Text = "目标：全部"
        modeLbl.Text = "模式：全部删除"
        for _, c in ipairs(ownerScroll:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundTransparency = c == allBtn and 0.1 or 0.5
            end
        end
        notify("YUTONG", "目标切换为：全部", 2)
    end)

    local seen = {}
    local order = 1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getOwnerPlayer(obj)
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
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                -- 头像
                local avatar = Instance.new("ImageLabel")
                avatar.Size = UDim2.new(0,22,0,22)
                avatar.Position = UDim2.new(0,3,0.5,-11)
                avatar.BackgroundTransparency = 1
                avatar.Image = ""
                avatar.Parent = btn
                Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)
                task.spawn(function()
                    local ok2, img = pcall(function()
                        return game:GetService("Players"):GetUserThumbnailAsync(
                            capturedP.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size48x48
                        )
                    end)
                    if ok2 then avatar.Image = img end
                end)

                -- 名字
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
                    ownerLabel.Text = "目标：" .. capturedP.Name
                    modeLbl.Text = "模式：指定玩家"
                    for _, c in ipairs(ownerScroll:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.BackgroundTransparency = c == btn and 0.1 or 0.5
                        end
                    end
                    notify("YUTONG", "目标锁定：" .. capturedP.Name, 2)
                end)
                order = order + 1
            end
        end
    end
    ownerScroll.CanvasSize = UDim2.new(0,0,0,(order+1)*28)
    statusLbl.Text = "扫描完成，发现 " .. (order-1) .. " 名玩家"
    notify("YUTONG", "扫描完成，发现 " .. (order-1) .. " 名玩家", 3)
end

scanOwnerBtn.MouseButton1Click:Connect(function()
    statusLbl.Text = "扫描中..."
    notify("YUTONG", "正在扫描玩家...", 2)
    refreshOwners()
end)

-- 删除
local running = false

deleteBtn.MouseButton1Click:Connect(function()
    if running then
        notify("YUTONG", "正在执行中，请先停止", 2)
        return
    end
    running = true
    deleteBtn.Text = "炸中..."

    local targets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getOwnerPlayer(obj)
            if p and WHITELIST[p.Name] then continue end
            if selectedOwner == nil then
                table.insert(targets, obj)
            else
                if p == selectedOwner then
                    table.insert(targets, obj)
                end
            end
        end
    end

    local targetName = selectedOwner and selectedOwner.Name or "全部"
    statusLbl.Text = "发现 " .. #targets .. " 个目标"
    notify("YUTONG", "开始炸！目标：" .. targetName .. "，共 " .. #targets .. " 个", 3)

    local deleted = 0
    for _, obj in ipairs(targets) do
        task.spawn(function()
            pcall(function()
                destroyRemote:FireServer(obj)
            end)
            deleted = deleted + 1
            countLbl.Text = "已删除：" .. deleted .. " / " .. #targets
        end)
    end

    task.wait(1)
    statusLbl.Text = "完成！共发包 " .. #targets .. " 次"
    notify("YUTONG", "炸完了！共发包 " .. #targets .. " 次", 4)
    deleteBtn.Text = "炸基地"
    running = false
end)

stopBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        statusLbl.Text = "已停止"
        notify("YUTONG", "已停止操作", 2)
    else
        notify("YUTONG", "当前没有在执行", 2)
    end
end)

notify("YUTONG", "脚本加载成功", 3)
print("[YUTONG-炸基地] Loaded")
