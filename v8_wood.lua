-- v8_wood.lua — 木头功能页（自动砍树、木头相关）
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Workspace = V8.Workspace
local ReplicatedStorage = V8.ReplicatedStorage
local RunService = V8.RunService
local UserInputService = V8.UserInputService
local Mouse = V8.Mouse
local getBestSword = V8.getBestSword
local isOwnedByMe = V8.isOwnedByMe
local Players = V8.Players
local Lighting = V8.Lighting
local TeleportService = V8.TeleportService
local VirtualUser = V8.VirtualUser

local bai
local lp
local tp
local getPosition
local getMouseTarget
local getBestAxe
local cutPart
local bringTree
local autofarm
local getPlanks
local sellwood
local PlankToBlueprint
local lumbsmasher_legitpaint
local shuaxinlb
do
-- ===== [移植自青脚本] 木头功能 开始 =====

-- 木头功能状态表
bai = {
    cuttreeselect = "Generic",
    autofarm = false,
    autofarm1 = false,
    bringamount = 1,
    bringtree = false,
    treecutset = nil,
    modwood = false,
    tptree = "",
    zlmt = nil,
    mtwjia = nil,
    shuzhe = false,
    tchonmt = nil,
    cskais = false,
    itemset = nil,
    cswjia = nil,
    xzemuban = false,
    zlwjia = "",
    zix = 1,
    zlz = 3,
    dxmz = "",
    stopcar = false,
    car = nil,
    autobuyset = nil,
    autobuystop = false,
    autocsdx = nil,
    boxOpenConnection = nil,
    axeFling = nil,
    whthmose = false,
    farAxeEquip = nil,
    PlankToBlueprint = nil,
    blueprintModel = nil,
    plankModel = nil,
    kuangxiu = nil,
    openItem = nil,
    itemtoopen = "",
    moneyaoumt = 1,
    moneytoplayername = "",
    donationRecipient = tostring(speaker),
    autodropae = false,
    autopick = false,
    loaddupeaxewaittime = 3.1,
    walkspeed = 16,
    JumpPower = 50,
    pickupaxeamount = 1,
    soltnumber = "1",
    waterwalk = false,
    awaysday = false,
    awaysdnight = false,
    nofog = false,
    saymege = "",
    autosay = false,
    saymount = 1,
    sayfast = false,
    dropdown = {},
    wood = 7,
}

lp = speaker
local mouse = Mouse

-- 木头功能所需工具函数
local function droptool(Position)
    local aQ = speaker.Character;
    if aQ:FindFirstChildOfClass "Tool" then
        local y = aQ:FindFirstChildOfClass "Tool"
        if y:FindFirstChild("ToolName") then
            ReplicatedStorage.Interaction.ClientInteracted:FireServer(y, "Drop tool", Position or
                speaker.Character.Head.CFrame)
        end
    end
    for a, b in pairs(speaker.Backpack:GetChildren()) do
        if b.Name == "Tool" and b.ClassName == "Tool" then
            ReplicatedStorage.Interaction.ClientInteracted:FireServer(b, "Drop tool", Position or
                speaker.Character.Head.CFrame)
        end
    end
end

DragModel = function(...)
    local d = {...}
    pcall(function()
        local _r = ReplicatedStorage.Interaction.ClientIsDragging
        _r:FireServer("Begin", d[1], 5)
        _r:FireServer("Refresh", d[1], 5)
        _r:FireServer("End", d[1], 5)
    end)
    d[1]:PivotTo(d[2])
    return d
end

DragModelmain = function(...)
    local d = {...}
    pcall(function()
        local _r = ReplicatedStorage.Interaction.ClientIsDragging
        _r:FireServer("Begin", d[1], 5)
        _r:FireServer("Refresh", d[1], 5)
        _r:FireServer("End", d[1], 5)
    end)
    d[1].Main.CFrame = d[2]
    return d
end

DragModel2 = function(...)
    local d = {...}
    pcall(function()
        local _r = ReplicatedStorage.Interaction.ClientIsDragging
        _r:FireServer("Begin", d[1], 5)
        _r:FireServer("Refresh", d[1], 5)
        _r:FireServer("End", d[1], 5)
    end)
    d[1]:SetPrimaryPartCFrame(d[2])
    return d
end

DragModel1 = function(...)
    local d = {...}
    pcall(function()
        local _r = ReplicatedStorage.Interaction.ClientIsDragging
        _r:FireServer("Begin", d[1], 5)
        _r:FireServer("Refresh", d[1], 5)
        _r:FireServer("End", d[1], 5)
    end)
    d[1]:MoveTo(d[2])
    d[1]:MoveTo(d[2])
    return d
end

local function table_foreach(tbl, callback)
    for i = 1, #tbl do
        callback(i, tbl[i])
    end
end

local function getCFrame(part)
    local part = part or (speaker.Character and speaker.Character.HumanoidRootPart)
    if not part then return end
    return part.CFrame
end

tp = function(pos)
    local pos = pos or Mouse.Hit + Vector3.new(0, speaker.Character.HumanoidRootPart.Size.Y, 0)
    if typeof(pos) == "CFrame" then
        speaker.Character:SetPrimaryPartCFrame(pos)
    elseif typeof(pos) == "Vector3" then
        speaker.Character:MoveTo(pos)
    end
end

getPosition = function(part)
    return getCFrame(part).Position
end

getMouseTarget = function()
    local b2 = UserInputService:GetMouseLocation()
    return workspace:FindPartOnRayWithIgnoreList(Ray.new(workspace.CurrentCamera.CFrame.p,
        workspace.CurrentCamera:ViewportPointToRay(b2.x, b2.y, 0).Direction * 1000),
        speaker.Character:GetDescendants())
end

function getTieredAxe()
    return {
        ['Beesaxe'] = 13, ['AxeAmber'] = 12, ['ManyAxe'] = 15, ['BasicHatchet'] = 0,
        ['RustyAxe'] = -1, ['Axe1'] = 2, ['Axe2'] = 3, ['AxeAlphaTesters'] = 9,
        ['Rukiryaxe'] = 8, ['Axe3'] = 4, ['AxeBetaTesters'] = 10, ['FireAxe'] = 11,
        ['SilverAxe'] = 5, ['EndTimesAxe'] = 16, ['AxeChicken'] = 6,
        ['CandyCaneAxe'] = 1, ['AxeTwitter'] = 7, ['CandyCornAxe'] = 14
    }
end

function getAxeList()
    local aP = {}
    for J, v in pairs(speaker.Backpack:GetChildren()) do
        table.insert(aP, v)
    end
    local aQ = speaker.Character;
    if aQ:FindFirstChildOfClass "Tool" then
        table.insert(aP, aQ:FindFirstChildOfClass("Tool"))
    end
    return aP
end

function getWorstAxe()
    local aQ = speaker.Character;
    if aQ:FindFirstChildOfClass "Tool" then
        local y = aQ:FindFirstChildOfClass "Tool"
        if y:FindFirstChild("ToolName") then return y end
    end
    local aR = 9999; local aS = nil; local aT = getTieredAxe()
    for J, v in pairs(getAxeList()) do
        if v:FindFirstChild("ToolName") then
            if aT[v.ToolName.Value] < aR then aS = v; aR = aT[v.ToolName.Value] end
        end
    end
    return aS
end

local function barkgetBestAxe()
    local aQ = speaker.Character;
    if aQ:FindFirstChildOfClass "Tool" then
        local y = aQ:FindFirstChildOfClass "Tool"
        if y:FindFirstChild("ToolName") then return y end
    end
    local aU = -1; local aV = nil; local aT = getTieredAxe()
    for J, v in pairs(getAxeList()) do
        if v:FindFirstChild("ToolName") then
            if aT[v.ToolName.Value] > aU then aV = v; aU = aT[v.ToolName.Value] end
        end
    end
    return aV
end

function getHitPointsTbl()
    return {
        ['Beesaxe'] = 1.4, ['AxeAmber'] = 3.39, ['ManyAxe'] = 10.2, ['BasicHatchet'] = 0.2,
        ['Axe1'] = 0.55, ['Axe2'] = 0.93, ['AxeAlphaTesters'] = 1.5, ['Rukiryaxe'] = 1.68,
        ['Axe3'] = 1.45, ['AxeBetaTesters'] = 1.45, ['FireAxe'] = 0.6, ['SilverAxe'] = 1.6,
        ['EndTimesAxe'] = 1.58, ['AxeChicken'] = 0.9, ['CandyCaneAxe'] = 0,
        ['AxeTwitter'] = 1.65, ['CandyCornAxe'] = 1.75, ["CaveAxe"] = 0.4
    }
end

local function get_axe_damage(tool, tree)
    local ok, result = pcall(function()
        local axe_class = require(ReplicatedStorage.AxeClasses['AxeClass_' .. tool.ToolName.Value])
        local axe_table = axe_class.new()
        if axe_table["SpecialTrees"] and axe_table["SpecialTrees"][tree] then
            return axe_table["SpecialTrees"][tree].Damage
        else
            return axe_table.Damage
        end
    end)
    if ok and result then return result end
    return 1.5
end

function get_axe_cooldown(tool)
    local success, return_value = pcall(function()
        local axe_class = require(ReplicatedStorage.AxeClasses['AxeClass_' .. tool.ToolName.Value])
        local axe_table = axe_class.new()
        return axe_table.SwingCooldown
    end)
    if success then return return_value else return 1 end
end

function get_axe_swingdelay(tool)
    local axe_cooldown = get_axe_cooldown(tool)
    local start = tick()
    ReplicatedStorage.TestPing:InvokeServer()
    local ping = (tick() - start) / 2
    local swing_delay = 0.65 * axe_cooldown - ping
    return swing_delay
end

function getBestSawmill()
    local best = nil
    for i, v in pairs(Workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v:FindFirstChild("ItemName") and v.Owner.Value == speaker and
            v.ItemName.Value:sub(1, 7) == "Sawmill" then
            if not best then best = v
            else
                if #v.ItemName.Value > #best.ItemName.Value then best = v
                elseif tonumber(v.ItemName.Value:sub(8, 8)) > tonumber(best.ItemName.Value:sub(8, 8)) then best = v end
            end
        end
    end
    return best
end

function barkgetBestAxe2()
    local pc = speaker.Character
    local axe_damage, best_axe
    for i, v in pairs(getAxeList()) do
        if v.name == "Tool" then
            local damage = get_axe_damage(v, "Generic")
            if best_axe == nil then best_axe = v; axe_damage = damage
            elseif get_axe_damage(best_axe, "Generic") < damage then best_axe = v; axe_damage = damage end
        end
    end
    return best_axe
end

local function getTools()
    local tools = {}
    table_foreach(speaker.Backpack:GetChildren(), function(_, v)
        if v.Name ~= "BlueprintTool" then tools[#tools + 1] = v end
    end)
    return tools
end

local function getToolStats(toolObj)
    local toolName
    if typeof(toolObj) == "string" then
        toolName = toolObj
    elseif typeof(toolObj) == "Instance" then
        -- 剑 Model：用 ItemName.Value
        local itemName = toolObj:FindFirstChild("ItemName")
        if itemName then
            toolName = itemName.Value
        -- 斧头 Tool：用 ToolName.Value
        elseif toolObj:FindFirstChild("ToolName") then
            toolName = toolObj.ToolName.Value
        else
            toolName = toolObj.Name
        end
    end
    -- 去 LoadedAssets 动态匹配 AxeClass（斧头和剑都走这条路），decompile 读源码解析参数
    if toolName then
        local la = ReplicatedStorage:FindFirstChild("LoadedAssets")
        if la then
            -- normalizeName：小写、去空格/下划线/连字符、去 axeclass 后缀
            local function normalizeName(s)
                if type(s) ~= "string" then return "" end
                return s:lower():gsub("[%s_%-%c]", ""):gsub("axeclass$", "")
            end
            local target = normalizeName(toolName)
            local classModule = nil
            -- 精确匹配
            for _, obj in ipairs(la:GetDescendants()) do
                if obj:IsA("ModuleScript") and normalizeName(obj.Name) == target then
                    classModule = obj; break
                end
            end
            -- 包含匹配
            if not classModule then
                for _, obj in ipairs(la:GetDescendants()) do
                    if obj:IsA("ModuleScript") then
                        local n = normalizeName(obj.Name)
                        if n:find(target, 1, true) or target:find(n, 1, true) then
                            classModule = obj; break
                        end
                    end
                end
            end
            if classModule then
                local ok, src = pcall(function() return decompile(classModule) end)
                if ok and type(src) == "string" and #src > 0 then
                    -- parseSource：匹配 vN.Field = value 格式（反编译变量名随机）
                    local dmg = src:match("%w+%.Damage%s*=%s*([%d%.]+)")
                    local cd  = src:match("%w+%.SwingCooldown%s*=%s*([%d%.]+)")
                    local rng = src:match("%w+%.Range%s*=%s*([%d%.]+)")
                    -- SpecialTrees：vN.SpecialTrees.TreeName.Field = value
                    local specialTrees = {}
                    for treeName in src:gmatch("%w+%.SpecialTrees%.(%w+)%s*=%s*{}") do
                        if not specialTrees[treeName] then specialTrees[treeName] = {} end
                    end
                    for treeName, field, value in src:gmatch("%w+%.SpecialTrees%.(%w+)%.(%w+)%s*=%s*([%d%.]+)") do
                        if not specialTrees[treeName] then specialTrees[treeName] = {} end
                        specialTrees[treeName][field] = tonumber(value)
                    end
                    return {
                        Damage       = tonumber(dmg) or 1.5,
                        SwingCooldown = tonumber(cd) or 0.29,
                        Range        = tonumber(rng) or nil,
                        SpecialTrees = next(specialTrees) and specialTrees or nil
                    }
                end
            end
        end
    end
    return { Damage = 1.5, SwingCooldown = 0.29, SpecialTrees = nil }
end

local getTool = function()
    return speaker.Character:FindFirstChild("Tool") or speaker.Backpack:FindFirstChild("Tool")
end

getBestAxe = function(treeClass)
    local tools = getTools()
    if #tools == 0 then
        -- 背包没斧头，fallback 用剑
        local sword, swordName = getBestSword()
        if not sword then return notify("你需要斧头或剑", "warn") end
        return true, sword
    end
    local toolStats = {}
    local tool
    for _, v in next, tools do
        if treeClass == "LoneCave" and v.ToolName.Value == "EndTimesAxe" then tool = v; break end
        local axeStats = getToolStats(v)
        if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
            for i, v in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = v end
        end
        table.insert(toolStats, { tool = v, damage = axeStats.Damage })
    end
    if not tool and treeClass == "LoneCave" then return notify("你需要末日斧头", "warn") end
    table.sort(toolStats, function(a, b) return a.damage > b.damage end)
    return true, tool or toolStats[1].tool
end

cutPart = function(event, section, height, tool, treeClass, cachedStats)
    if not tool then
        notify("No axe equipped", "warn")
        return
    end
    -- 优先用外部传入的缓存，没有才现算
    local axeStats = cachedStats or getToolStats(tool)
    if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
        for i, v in next, axeStats.SpecialTrees[treeClass] do
            axeStats[i] = v
        end
    end
    ReplicatedStorage.Interaction.RemoteProxy:FireServer(event, {
        tool = tool,
        faceVector = Vector3.new(-1, 0, 0),
        height = height or 0.4,
        sectionId = section or 1,
        hitPoints = axeStats.Damage,
        cooldown = axeStats.SwingCooldown,
        cuttingClass = "Axe"
    })
end

local treeListener = function(treeClass, callback)
    local childAdded
    childAdded = workspace.LogModels.ChildAdded:Connect(function(child)
        local owner = child:WaitForChild("Owner")
        if owner.Value == lp and child.TreeClass.Value == treeClass then
            childAdded:Disconnect()
            callback(child)
        end
    end)
end

local getBiggestTree = function(treeClass)
    for _, v in next, workspace:GetChildren() do
        if tostring(v) == "TreeRegion" then
            for _, g in next, v:GetChildren() do
                if g:FindFirstChild("TreeClass") and tostring(g.TreeClass.Value) == treeClass and
                    g:FindFirstChild("Owner") then
                    if g.Owner.Value == nil or tostring(g.Owner.Value) == tostring(speaker) then
                        if g:FindFirstChild("WoodSection") then
                            local sectionCount = 0
                            for _, s in next, g:GetChildren() do
                                if s:FindFirstChild("ID") then sectionCount = sectionCount + 1 end
                            end
                            if sectionCount >= 3 then
                                for h, j in next, g:GetChildren() do
                                    if j:FindFirstChild("ID") and j.ID.Value == 1 and j.Size.Y > .5 then
                                        return j
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

bringTree = function(treeClass)
    local success, data = getBestAxe(treeClass)
    if not success or not data then return end

    notify("Bring Tree started: " .. treeClass, "info")

    local treeCut = false
    local chopped = nil
    local tree = getBiggestTree(treeClass)
    if not tree then
        notify("No tree found", "warn")
        return
    end

    local originCF = speaker.Character.HumanoidRootPart.CFrame

    -- 监听树倒
    local treeConn
    treeConn = workspace.LogModels.ChildAdded:Connect(function(child)
        local owner = child:WaitForChild("Owner", 10)
        if owner and owner.Value == speaker and child:FindFirstChild("TreeClass") and child.TreeClass.Value == treeClass then
            treeConn:Disconnect()
            chopped = child
            treeCut = true
        end
    end)

    -- 10秒超时
    local startTime = tick()
    task.spawn(function()
        while bai.bringtree and not treeCut do
            if tick() - startTime >= 10 then
                treeConn:Disconnect()
                notify("Timeout — returning to origin", "warn")
                bai.bringtree = false
                tp(originCF)
                return
            end
            task.wait(0.1)
        end
    end)

    -- 砍树主循环：每次 tp 到树旁再发包，最多 1000 次
    local iterations = 0
    while bai.bringtree and not treeCut do
        iterations = iterations + 1
        if iterations > 1000 then
            treeConn:Disconnect()
            notify("Too many attempts — returning to origin", "warn")
            bai.bringtree = false
            tp(originCF)
            return
        end
        tp(tree.CFrame + Vector3.new(4, 2, 2))
        cutPart(tree.Parent.CutEvent, 1, 0.4, data, treeClass)
        task.wait(0.05)
    end

    if not bai.bringtree then return end

    -- 树倒了，等 chopped 赋值
    local waitStart = tick()
    while not chopped do
        if tick() - waitStart > 5 then
            notify("Log not found", "warn")
            tp(originCF)
            bai.bringtree = false
            return
        end
        task.wait(0.1)
    end

    -- 等服务器确认 Owner 赋值完成
    chopped:WaitForChild("Owner", 10)
    task.wait(0.2)

    chopped.PrimaryPart = chopped:FindFirstChild("WoodSection")
    local woodPart = chopped:FindFirstChild("WoodSection")
    local dragRemote = ReplicatedStorage.Interaction.ClientIsDragging

    -- 传送到 log 旁边
    tp(woodPart.CFrame + Vector3.new(0, 4, 0))
    task.wait(0.05)

    -- Begin：告诉服务器开始拖
    pcall(function()
        dragRemote:FireServer("Begin", chopped, 5)
    end)
    task.wait(0.05)

    -- Refresh 循环：持续发 Refresh + 改坐标
    local tpConn = RunService.Heartbeat:Connect(function()
        if chopped and chopped.Parent then
            pcall(function()
                dragRemote:FireServer("Refresh", chopped, 5)
            end)
            chopped.PrimaryPart = chopped:FindFirstChild("WoodSection")
            chopped:PivotTo(bai.treecutset)
        end
    end)
    for i = 1, 60 do
        if not chopped.Parent then break end
        pcall(function()
            dragRemote:FireServer("Refresh", chopped, 5)
        end)
        chopped.PrimaryPart = chopped:FindFirstChild("WoodSection")
        chopped:PivotTo(bai.treecutset)
        RunService.Heartbeat:Wait()
    end
    tpConn:Disconnect()

    -- End：告诉服务器结束拖
    pcall(function()
        dragRemote:FireServer("End", chopped, 5)
    end)

    if chopped and chopped.Parent then
        chopped.PrimaryPart = chopped:FindFirstChild("WoodSection")
        chopped:PivotTo(bai.treecutset)
    end

    tp(originCF)
    notify("Tree brought back!", "success")
    bai.bringtree = false
end
autofarm = function(treeClass)
    local oldpos = speaker.Character.HumanoidRootPart.CFrame
    local success, data = getBestAxe(treeClass)
    if not success or not data then return end
    local axeStats = getToolStats(data)
    local tree = getBiggestTree(treeClass)
    if not tree then return notify("没有找到树", "warn") end
    local treeCut = false
    treeListener(treeClass, function(tree)
        tree.PrimaryPart = tree:FindFirstChild("WoodSection")
        treeCut = true
        for i = 1, 70 do
            pcall(function()
                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                _r:FireServer("Begin", tree.WoodSection, 5)
                _r:FireServer("Refresh", tree.WoodSection, 5)
                _r:FireServer("End", tree.WoodSection, 5)
            end)
            tree:MoveTo(oldpos)
            task.wait()
        end
    end)
    task.wait(0.15)
    task.spawn(function()
        repeat tp(tree.trunk.CFrame * CFrame.new(4, 3, 4)); task.wait() until treeCut
    end)
    task.wait()
    repeat
        cutPart(tree.Parent.CutEvent, 1, 0.3, data, treeClass)
        task.wait(0.001)
    until treeCut
    if bai.autofarm1 == false then notify("完成", "success") end
    tp(oldpos)
end

getPlanks = function()
    local plankList = {};
    for _, plank in next, Workspace.PlayerModels:GetChildren() do
        if plank:FindFirstChild('WoodSection') and plank:FindFirstChild('Owner') and plank.Owner.Value ==
            speaker and not table.find(plankList, plank) then
            table.insert(plankList, plank)
        end
    end
    return plankList;
end

sellwood = function()
    local oldpos = speaker.Character.HumanoidRootPart.CFrame
    for i, v in next, Workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == speaker then
            tp(v.WoodSection.CFrame)
            spawn(function()
                for i2, v2 in next, v:GetChildren() do
                    if v2.Name == "WoodSection" then
                        local FreezeWood = Instance.new("BodyVelocity", v2)
                        FreezeWood.Velocity = Vector3.new(0, 0, 0)
                        FreezeWood.P = 100000
                        spawn(function()
                            for i = 1, 50 do
                                pcall(function()
                                    local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                    _r:FireServer("Begin", v, 5)
                                    _r:FireServer("Refresh", v, 5)
                                    _r:FireServer("End", v, 5)
                                end)
                                v:PivotTo(CFrame.new(314.54, -0.5, 86.823))
                                v2.CFrame = CFrame.new(314.54, -0.5, 86.823)
                                pcall(function()
                                    local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                    _r:FireServer("Begin", v, 5)
                                    _r:FireServer("Refresh", v, 5)
                                    _r:FireServer("End", v, 5)
                                end)
                                RunService.Heartbeat:wait()
                            end
                        end)
                        task.wait(1)
                    end
                end
            end)
            task.wait(2)
        end
    end
    tp(oldpos)
end

PlankToBlueprint = function()
    local target;
    notify("选择一个木头和蓝图", "info")
    bai.PlankToBlueprint = Mouse.Button1Down:Connect(function()
        if Mouse.Target then target = Mouse.Target end
        if target.Parent:FindFirstChild('Type') and target.Parent.Type.Value == 'Blueprint' then
            bai.blueprintModel = Mouse.Parent
            notify("蓝图已选择", "success")
        end
        if tostring(target.Parent) == 'Plank' and target.Parent:FindFirstChild('Owner') and
            tostring(target.Parent.Owner.Value) == tostring(lp) then
            bai.plankModel = target.Parent
            notify("木头已选择", "success")
        end
    end)
    repeat wait() until bai.plankModel and bai.blueprintModel
    bai.PlankToBlueprint:Disconnect()
    bai.PlankToBlueprint = nil
    tp(CFrame.new(bai.plankModel:FindFirstChildOfClass 'Part'.CFrame.p + Vector3.new(0, 3, 4)))
    wait(.2)
    for i = 1, 30 do
        pcall(function()
            local _r = ReplicatedStorage.Interaction.ClientIsDragging
            _r:FireServer("Begin", bai.plankModel, 5)
            _r:FireServer("Refresh", bai.plankModel, 5)
            _r:FireServer("End", bai.plankModel, 5)
            bai.plankModel.WoodSection.CFrame = CFrame.new(bai.blueprintModel.Main.CFrame.p + Vector3.new(0, 1.5, 0))
            RunService.Stepped:wait()
        end)
    end
    notify("完成", "success")
    bai.blueprintModel = nil
    bai.plankModel = nil
end

lumbsmasher_legitpaint = function(wood_class, blueprint, tpback)
    local old = speaker.Character.HumanoidRootPart.CFrame
    local remote = ReplicatedStorage.PlaceStructure.ClientPlacedStructure
    local bp_type = blueprint.ItemName.Value
    local wood
    for i, v in pairs(ReplicatedStorage.ClientItemInfo:GetChildren()) do
        if v.Name == bp_type then
            for i, s in pairs(v:GetChildren()) do
                if s.Name == "WoodCost" then wood = s.Value end
            end
        end
    end
    if lp.SuperBlueprint.Value then wood = 1 end
    local required_wood = wood
    local tool = barkgetBestAxe2()
    local sawmill = getBestSawmill()
    if tool == nil then notify("请你装备斧头", "warn"); return end
    if wood_class == "LoneCave" then
        if tool.ToolName.Value ~= "EndTimesAxe" then notify("请你装备末日斧头", "warn"); return end
    end
    local WoodSection
    local Min = 9e99
    for i, v in pairs(Workspace:GetChildren()) do
        if v.Name == 'TreeRegion' then
            for j, Tree in pairs(v:GetChildren()) do
                if Tree:FindFirstChild('Leaves') and Tree:FindFirstChild('WoodSection') and Tree:FindFirstChild('TreeClass') then
                    if Tree:FindFirstChild('TreeClass').Value == wood_class then
                        for k, TreeSection in pairs(Tree:GetChildren()) do
                            if TreeSection.Name == 'WoodSection' then
                                local Size = TreeSection.Size.X * TreeSection.Size.Y * TreeSection.Size.Z
                                if (Size > required_wood) and (#TreeSection.ChildIDs:GetChildren() == 0) then
                                    if Min > TreeSection.Size.X then Min = TreeSection.Size.X; WoodSection = TreeSection end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if not WoodSection then notify("没有找到树", "warn"); return end
    local Chopped = false
    local treecon = Workspace.LogModels.ChildAdded:connect(function(add)
        local Owner = add:WaitForChild('Owner')
        if (add.Owner.Value == lp) and (add.TreeClass.Value == wood_class) and add:FindFirstChild("WoodSection") then
            Chopped = add; treecon:Disconnect()
        end
    end)
    local CutSize = required_wood / (WoodSection.Size.X * WoodSection.Size.X) + 0.01
    local swing_delay = get_axe_swingdelay(tool)
    local function axe(v, id, h)
        local hps = get_axe_damage(tool, Wood)
        local tbl = {
            ["tool"] = tool, ["faceVector"] = Vector3.new(0, 0, -1),
            ["height"] = h, ["sectionId"] = id, ["hitPoints"] = hps,
            ["cooldown"] = 0.112, ["cuttingClass"] = "Axe"
        }
        ReplicatedStorage.Interaction.RemoteProxy:FireServer(v.CutEvent, tbl)
        task.wait()
    end
    local iterations = 0
    local GetTreeNC = RunService.Stepped:connect(function()
        for i, v in next, speaker.Character:GetChildren() do
            if v:IsA("Part") or v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
    while Chopped == false do
        iterations = iterations + 1
        if iterations > 1000 then
            pcall(function()
                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                _r:FireServer("Begin", WoodSection.Parent, 5)
                _r:FireServer("Refresh", WoodSection.Parent, 5)
                _r:FireServer("End", WoodSection.Parent, 5)
            end)
            ReplicatedStorage.Interaction.DestroyStructure:FireServer(WoodSection.Parent)
            Chopped = true
        end
        tp(WoodSection.CFrame + Vector3.new(4, 2, 2))
        axe(WoodSection.Parent, WoodSection.ID.Value, WoodSection.Size.Y - CutSize)
    end
    GetTreeNC:Disconnect()
    speaker.Character.Humanoid:ChangeState(7)
    local target_cframe
    if blueprint:FindFirstChild("MainCFrame") then
        target_cframe = blueprint.MainCFrame.Value
    else
        target_cframe = blueprint.PrimaryPart.CFrame
    end
    local fill_target_cframe = sawmill.Particles.CFrame + Vector3.new(0, 1, 0)
    iterations = 0
    local Sawed = false
    local sawconn = Workspace.PlayerModels.ChildAdded:connect(function(add)
        local Owner = add:WaitForChild('Owner')
        if (add.Owner.Value == lp) and add:FindFirstChild("WoodSection") then
            if not add:FindFirstChild('TreeClass') then repeat wait() until add:FindFirstChild('TreeClass') end
            if add.TreeClass.Value == wood_class then Sawed = add; sawconn:Disconnect() end
        end
    end)
    while Chopped.Parent ~= nil do
        if Sawed then break end
        iterations = iterations + 1
        if iterations > 300 then notify("没有成功处理树", "warn") end
        tp(CFrame.new(Chopped.WoodSection.Position) + Vector3.new(0, 4, 0))
        pcall(function()
            local _r = ReplicatedStorage.Interaction.ClientIsDragging
            _r:FireServer("Begin", Chopped, 5)
            _r:FireServer("Refresh", Chopped, 5)
            _r:FireServer("End", Chopped, 5)
        end)
        Chopped.PrimaryPart = Chopped.WoodSection
        Chopped:SetPrimaryPartCFrame(sawmill.Particles.CFrame)
        pcall(function()
            local _r = ReplicatedStorage.Interaction.ClientIsDragging
            _r:FireServer("Begin", Chopped, 5)
            _r:FireServer("Refresh", Chopped, 5)
            _r:FireServer("End", Chopped, 5)
        end)
        wait(2)
    end
    repeat wait() until Sawed
    iterations = 0
    local placed = false
    local new_structure_connection
    new_structure_connection = Workspace.PlayerModels.ChildAdded:Connect(function(child)
        local owner = child:WaitForChild("Owner")
        if owner.Value == lp and child:FindFirstChild("Type") and child.Type.Value == "Structure" then
            if not child:FindFirstChild("BuildDependentWood") then
                notify("没有成功", "warn"); return
            end
            new_structure_connection:Disconnect()
            local wood_type
            if child:FindFirstChild("BlueprintWoodClass") then wood_type = child.BlueprintWoodClass.Value end
            remote:FireServer(child.ItemName.Value, target_cframe, lp, wood_type, child, true, nil)
            placed = true
        end
    end)
    while Sawed.Parent ~= nil do
        if iterations > 50 then
            ReplicatedStorage.Interaction.DestroyStructure:FireServer(Sawed)
            ReplicatedStorage.Interaction.DestroyStructure:FireServer(blueprint)
            notify("尝试太多次蓝图填充木头了", "warn")
        end
        iterations = iterations + 1
        if Sawed.Parent == nil then break end
        local connection, blueprint_made
        connection = Workspace.PlayerModels.ChildAdded:Connect(function(child)
            if child:WaitForChild("Owner") and child.Owner.Value == lp and
                child:FindFirstChild("Type") and child.Type.Value == "Blueprint" then
                connection:Disconnect(); blueprint = child; blueprint_made = true
            end
        end)
        ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint:FireServer(bp_type, Sawed.WoodSection.CFrame,
            lp, blueprint, blueprint.Parent ~= nil)
        local bp_wait_iter = 0
        repeat
            if bp_wait_iter > 500 then notify("没有找到蓝图", "warn") end
            wait(); bp_wait_iter = bp_wait_iter + 1
        until blueprint_made or placed
        if placed then pcall(connection.Disconnect, connection) end
    end
    repeat wait() until placed
    if tpback then tp(old); notify("完成", "success") end
end

shuaxinlb = function(zji)
    bai.dropdown = {}
    if zji == true then
        for p, I in next, game.Players:GetChildren() do table.insert(bai.dropdown, I.Name) end
    else
        for p, I in next, game.Players:GetChildren() do
            if I ~= lp then table.insert(bai.dropdown, I.Name) end
        end
    end
end
end

do
shuaxinlb(true)

-- 木头功能 UI 页面
local woodPage = pages[5]

-- 启动时扫描树种
local scannedTreeClasses = {}
local selectedTreeClass = "Generic"
local treeClassIndex = 1

local function scanTreeClasses()
    local found = {}
    local seen = {}
    for _, region in ipairs(workspace:GetChildren()) do
        if region.Name == "TreeRegion" or region.Name:lower():find("treeregion") then
            for _, tree in ipairs(region:GetChildren()) do
                local tc = tree:FindFirstChild("TreeClass")
                if tc and tc.Value ~= "" and not seen[tc.Value] then
                    seen[tc.Value] = true
                    table.insert(found, tc.Value)
                end
            end
        end
    end
    table.sort(found)
    if #found == 0 then found = {"Generic"} end
    scannedTreeClasses = found
    selectedTreeClass = found[1]
    treeClassIndex = 1
end
scanTreeClasses()

-- woodY 必须在所有 UI 元素之前定义
local woodY = px(1)

local function woodBtn(text, color, tc)
    local btn = Instance.new("TextButton")
    btn.Parent = woodPage
    btn.Size = UDim2.new(1, -px(8), 0, px(18))
    btn.Position = UDim2.new(0, px(4), 0, woodY)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = tc
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = px(9)
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, px(4))
    woodY = woodY + px(19)
    return btn
end

local function woodLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = woodPage
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, px(4), 0, woodY)
    lbl.Size = UDim2.new(1, -px(8), 0, px(12))
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(145, 103, 134)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = px(8)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    woodY = woodY + px(13)
    return lbl
end

-- 树种选择器（两个并排按钮：上一个 / 下一个，中间显示当前树种）
local treeRow = Instance.new("Frame")
treeRow.Parent = woodPage
treeRow.BackgroundTransparency = 1
treeRow.Position = UDim2.new(0, px(4), 0, woodY)
treeRow.Size = UDim2.new(1, -px(8), 0, px(18))
woodY = woodY + px(19)

local treePrevBtn = Instance.new("TextButton")
treePrevBtn.Parent = treeRow
treePrevBtn.Size = UDim2.new(0, px(18), 1, 0)
treePrevBtn.Position = UDim2.new(0, 0, 0, 0)
treePrevBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 110)
treePrevBtn.BorderSizePixel = 0
treePrevBtn.Text = "<"
treePrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
treePrevBtn.Font = Enum.Font.GothamBold
treePrevBtn.TextSize = px(9)
treePrevBtn.AutoButtonColor = false
Instance.new("UICorner", treePrevBtn).CornerRadius = UDim.new(0, px(4))

local treeNextBtn = Instance.new("TextButton")
treeNextBtn.Parent = treeRow
treeNextBtn.Size = UDim2.new(0, px(18), 1, 0)
treeNextBtn.Position = UDim2.new(1, -px(18), 0, 0)
treeNextBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 110)
treeNextBtn.BorderSizePixel = 0
treeNextBtn.Text = ">"
treeNextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
treeNextBtn.Font = Enum.Font.GothamBold
treeNextBtn.TextSize = px(9)
treeNextBtn.AutoButtonColor = false
Instance.new("UICorner", treeNextBtn).CornerRadius = UDim.new(0, px(4))

local treeNameLabel = Instance.new("TextLabel")
treeNameLabel.Parent = treeRow
treeNameLabel.Size = UDim2.new(1, -px(40), 1, 0)
treeNameLabel.Position = UDim2.new(0, px(20), 0, 0)
treeNameLabel.BackgroundColor3 = Color3.fromRGB(80, 45, 90)
treeNameLabel.BorderSizePixel = 0
treeNameLabel.Text = selectedTreeClass
treeNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
treeNameLabel.Font = Enum.Font.GothamBold
treeNameLabel.TextSize = px(8)
Instance.new("UICorner", treeNameLabel).CornerRadius = UDim.new(0, px(4))

treePrevBtn.MouseButton1Click:Connect(function()
    if #scannedTreeClasses == 0 then return end
    treeClassIndex = treeClassIndex - 1
    if treeClassIndex < 1 then treeClassIndex = #scannedTreeClasses end
    selectedTreeClass = scannedTreeClasses[treeClassIndex]
    treeNameLabel.Text = selectedTreeClass
    notify("Tree: " .. selectedTreeClass, "info")
end)

treeNextBtn.MouseButton1Click:Connect(function()
    if #scannedTreeClasses == 0 then return end
    treeClassIndex = treeClassIndex + 1
    if treeClassIndex > #scannedTreeClasses then treeClassIndex = 1 end
    selectedTreeClass = scannedTreeClasses[treeClassIndex]
    treeNameLabel.Text = selectedTreeClass
    notify("Tree: " .. selectedTreeClass, "info")
end)

-- 传送木头
woodBtn("传送木头", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    local OldPos = speaker.Character.HumanoidRootPart.CFrame
    for i, v in next, Workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == speaker then
            if not v.PrimaryPart then v.PrimaryPart = v:FindFirstChild("WoodSection") end
            speaker.Character.HumanoidRootPart.CFrame = CFrame.new(v:FindFirstChild("WoodSection").CFrame.p)
            spawn(function()
                for i = 1, 50 do
                    pcall(function()
                        local _r = ReplicatedStorage.Interaction.ClientIsDragging
                        _r:FireServer("Begin", v, 5)
                        _r:FireServer("Refresh", v, 5)
                        _r:FireServer("End", v, 5)
                    end)
                    task.wait()
                end
            end)
            for i = 1, 50 do task.wait(); v:PivotTo(OldPos) end
            task.wait()
        end
    end
    speaker.Character.HumanoidRootPart.CFrame = OldPos
end)

-- 传送木板
woodBtn("传送木板", Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140)).MouseButton1Click:Connect(function()
    local logFolder = getPlanks()
    local oldPos = speaker.Character.HumanoidRootPart.CFrame
    for _, log in next, logFolder do
        if log:FindFirstChild('WoodSection') then
            spawn(function()
                for i = 1, 20 do
                    pcall(function()
                        local _r = ReplicatedStorage.Interaction.ClientIsDragging
                        _r:FireServer("Begin", log, 5)
                        _r:FireServer("Refresh", log, 5)
                        _r:FireServer("End", log, 5)
                    end)
                    task.wait()
                end
            end)
            wait(0.18)
            if not log.PrimaryPart then log.PrimaryPart = log.WoodSection end
            log:SetPrimaryPartCFrame(oldPos)
        end
    end
end)

-- 卖木板
woodBtn("卖木板", Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101)).MouseButton1Click:Connect(function()
    for _, Plank in pairs(Workspace.PlayerModels:GetChildren()) do
        if Plank.Name == "Plank" and Plank:FindFirstChild("Owner") then
            if Plank.Owner.Value == speaker then
                for i, v in pairs(Plank:GetChildren()) do
                    if v.Name == "WoodSection" then
                        spawn(function()
                            for i = 1, 100 do
                                wait()
                                v.CFrame = CFrame.new(Vector3.new(315, -0.296, 85.791)) * CFrame.Angles(math.rad(90), 0, 0)
                            end
                        end)
                    end
                end
                spawn(function()
                    for i = 1, 100 do
                        wait()
                        pcall(function()
                            local _r = ReplicatedStorage.Interaction.ClientIsDragging
                            _r:FireServer("Begin", Plank, 5)
                            _r:FireServer("Refresh", Plank, 5)
                            _r:FireServer("End", Plank, 5)
                        end)
                    end
                end)
            end
        end
    end
end)

-- 自动卖木板
local autoSellPlankOn = false
local autoSellPlankBtn = woodBtn("自动卖木板: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
autoSellPlankBtn.MouseButton1Click:Connect(function()
    autoSellPlankOn = not autoSellPlankOn
    if autoSellPlankOn then
        autoSellPlankBtn.Text = "自动卖木板: 开"
        autoSellPlankBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        autoSellPlankBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        task.spawn(function()
            while autoSellPlankOn do
                for _, Plank in pairs(Workspace.PlayerModels:GetChildren()) do
                    if Plank.Name == "Plank" and Plank:FindFirstChild("Owner") then
                        if Plank.Owner.Value == speaker then
                            for i, v in pairs(Plank:GetChildren()) do
                                if v.Name == "WoodSection" then
                                    spawn(function()
                                        for i = 1, 10 do
                                            wait()
                                            v.CFrame = CFrame.new(Vector3.new(315, -0.296, 85.791)) * CFrame.Angles(math.rad(90), 0, 0)
                                        end
                                    end)
                                end
                            end
                            spawn(function()
                                for i = 1, 20 do
                                    wait()
                                    pcall(function()
                                        local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                        _r:FireServer("Begin", Plank, 5)
                                        _r:FireServer("Refresh", Plank, 5)
                                        _r:FireServer("End", Plank, 5)
                                    end)
                                end
                            end)
                        end
                    end
                end
                task.wait()
            end
        end)
    else
        autoSellPlankBtn.Text = "自动卖木板: 关"
        autoSellPlankBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        autoSellPlankBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
    end
end)

-- 卖木头
woodBtn("卖木头", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    sellwood()
end)

-- 自动卖木头
local autoSellWoodOn = false
local autoSellWoodBtn = woodBtn("自动卖木头: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
autoSellWoodBtn.MouseButton1Click:Connect(function()
    autoSellWoodOn = not autoSellWoodOn
    if autoSellWoodOn then
        autoSellWoodBtn.Text = "自动卖木头: 开"
        autoSellWoodBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        autoSellWoodBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        task.spawn(function()
            while autoSellWoodOn do
                sellwood()
                task.wait()
            end
        end)
    else
        autoSellWoodBtn.Text = "自动卖木头: 关"
        autoSellWoodBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        autoSellWoodBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
    end
end)

-- 拖拽器
local draggerOn = false
local draggerBtn = woodBtn("拖拽器: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
draggerBtn.MouseButton1Click:Connect(function()
    draggerOn = not draggerOn
    if draggerOn then
        draggerBtn.Text = "拖拽器: 开"
        draggerBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        draggerBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        workspace.ChildAdded:connect(function(Dragger)
            if tostring(Dragger) == 'Dragger' then
                local BodyGyro = Dragger:WaitForChild('BodyGyro')
                local BodyPosition = Dragger:WaitForChild('BodyPosition')
                repeat RunService.Stepped:wait() until workspace:FindFirstChild('Dragger')
                BodyPosition.P = 120000; BodyPosition.D = 1000
                BodyPosition.maxForce = Vector3.new(1, 1, 1) * 1000000
                BodyGyro.maxTorque = Vector3.new(1, 1, 1) * 200
                BodyGyro.P = 1200; BodyGyro.D = 140
            end
        end)
    else
        draggerBtn.Text = "拖拽器: 关"
        draggerBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        draggerBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
        workspace.ChildAdded:connect(function(Dragger)
            if tostring(Dragger) == 'Dragger' then
                local BodyGyro = Dragger:WaitForChild('BodyGyro')
                local BodyPosition = Dragger:WaitForChild('BodyPosition')
                repeat RunService.Stepped:wait() until workspace:FindFirstChild('Dragger')
                BodyPosition.P = 10000; BodyPosition.D = 800
                BodyPosition.maxForce = Vector3.new(17000, 17000, 17000)
                BodyGyro.maxTorque = Vector3.new(200, 200, 200)
                BodyGyro.P = 1200; BodyGyro.D = 140
            end
        end)
    end
end)

-- 处理树半自动(新)
woodBtn("处理树半自动(新)", Color3.fromRGB(255, 230, 180), Color3.fromRGB(140, 100, 40)).MouseButton1Click:Connect(function()
    local oldpos = speaker.Character.HumanoidRootPart.CFrame
    bai.modwood = true
    for _, Log in pairs(Workspace.LogModels:GetChildren()) do
        if Log.Name:sub(1, 6) == "Loose_" and Log:FindFirstChild("Owner") then
            if Log.Owner.Value == speaker then
                for i, v in pairs(Log:GetChildren()) do
                    if v.Name == "WoodSection" then
                        if bai.modwood == true then tp(v.CFrame) end
                        wait(0.2)
                        spawn(function()
                            for i = 1, 20 do
                                if bai.modwood == true then
                                    task.wait()
                                    v.CFrame = CFrame.new(330.98587, -0.574430406, 79.0872726, -6, 0.000781620154,
                                        -0.0201439466, 0.000569172669, 0.99994421, 0.0105500417, 0.0201510694,
                                        0.0105364323, -0.999741435)
                                    pcall(function()
                                        local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                        _r:FireServer("Begin", Log, 5)
                                        _r:FireServer("Refresh", Log, 5)
                                        _r:FireServer("End", Log, 5)
                                    end)
                                end
                            end
                            wait(1)
                            for i = 1, 10 do
                                task.wait()
                                v.CFrame = oldpos
                                pcall(function()
                                    local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                    _r:FireServer("Begin", Log, 5)
                                    _r:FireServer("Refresh", Log, 5)
                                    _r:FireServer("End", Log, 5)
                                end)
                            end
                            bai.modwood = false
                        end)
                    end
                end
            end
        end
    end
    tp(oldpos)
end)

-- 木板填充蓝图
woodBtn("木板填充蓝图", Color3.fromRGB(210, 201, 239), Color3.fromRGB(112, 91, 145)).MouseButton1Click:Connect(function()
    PlankToBlueprint()
end)

-- 查看幻影
local viewPhantomOn = false
local viewPhantomBtn = woodBtn("查看幻影: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
viewPhantomBtn.MouseButton1Click:Connect(function()
    viewPhantomOn = not viewPhantomOn
    if viewPhantomOn then
        viewPhantomBtn.Text = "查看幻影: 开"
        viewPhantomBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        viewPhantomBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        for i, v in pairs(Workspace:GetChildren()) do
            if v.Name == "TreeRegion" and v:FindFirstChildOfClass("Model") then
                if v.Model.TreeClass.Value == "LoneCave" then
                    workspace.Camera.CameraSubject = v.Model.WoodSection
                    task.wait()
                end
            end
        end
    else
        viewPhantomBtn.Text = "查看幻影: 关"
        viewPhantomBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        viewPhantomBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
        workspace.Camera.CameraSubject = speaker.Character
    end
end)

-- 锯木机最大木头体型
woodBtn("锯木机最大木头体型", Color3.fromRGB(255, 200, 150), Color3.fromRGB(140, 80, 40)).MouseButton1Click:Connect(function()
    local connection, sawmillModel
    notify("选择一个锯木机", "info")
    connection = Mouse.Button1Down:Connect(function(b)
        local target = Mouse.Target
        if target then
            local sawmill = target.Parent
            if sawmill.Name:find('Sawmill') then
                sawmillModel = sawmill
                notify("锯木机已选择", "success")
            elseif sawmill.Parent.Name:find('Sawmill') or sawmill.Parent:FindFirstChild('BlockageAlert') then
                sawmillModel = sawmill.Parent
                notify("锯木机已选择", "success")
            end
        end
    end)
    repeat wait() until sawmillModel ~= nil
    if connection then connection:Disconnect(); connection = nil end
    spawn(function()
        for i = 1, 50 do
            ReplicatedStorage.Interaction.RemoteProxy:FireServer(sawmillModel:FindFirstChild('ButtonRemote_XUp'))
            task.wait(0.5)
            ReplicatedStorage.Interaction.RemoteProxy:FireServer(sawmillModel:FindFirstChild('ButtonRemote_YUp'))
        end
    end)
end)

-- 自动把木头切成1个单位
local unitCutOn = false
local unitCutBtn = woodBtn("自动切1单位: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
unitCutBtn.MouseButton1Click:Connect(function()
    unitCutOn = not unitCutOn
    if unitCutOn then
        unitCutBtn.Text = "自动切1单位: 开"
        unitCutBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        unitCutBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        local oldpos = speaker.Character.HumanoidRootPart.CFrame
        local PlankReAdded = Workspace.PlayerModels.ChildAdded:Connect(function(v)
            if v:WaitForChild("TreeClass") and v:WaitForChild("WoodSection") then
                local SelTree = v
                task.wait()
                local UnitCutterClick = Mouse.Button1Up:Connect(function()
                    local Clicked = Mouse.Target
                    if Clicked.Name == "WoodSection" then
                        SelTree = Clicked.Parent
                        speaker.Character:MoveTo(Clicked.Position + Vector3.new(0, 3, -3))
                        local success, data = getBestAxe(SelTree.TreeClass.Value)
                        repeat
                            if unitCutOn == false then break end
                            cutPart(SelTree.CutEvent, 1, 1, data, SelTree.TreeClass.Value)
                            if SelTree:FindFirstChild("Cut") then
                                speaker.Character:MoveTo(SelTree:FindFirstChild("Cut").Position + Vector3.new(0, 3, -3))
                            end
                            task.wait()
                        until SelTree.WoodSection.Size.X <= 1.88 and SelTree.WoodSection.Size.Y <= 1.88 and
                            SelTree.WoodSection.Size.Z <= 1.88 or unitCutOn == false
                    end
                end)
            end
        end)
    else
        unitCutBtn.Text = "自动切1单位: 关"
        unitCutBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        unitCutBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
    end
end)

-- 分解树
woodBtn("分解树", Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101)).MouseButton1Click:Connect(function()
    local OldPos = speaker.Character.HumanoidRootPart.CFrame
    local LogChopped = false
    local branchadded = Workspace.LogModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("Owner") and v.Owner.Value == speaker then
            if v:WaitForChild("WoodSection") then LogChopped = true end
        end
    end)
    notify("请你点击一棵树", "info")
    local TreeToJointCut
    local DismemberTreeC = Mouse.Button1Up:Connect(function()
        local Clicked = Mouse.Target
        if Clicked.Parent:FindFirstAncestor("LogModels") then
            if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == speaker then
                TreeToJointCut = Clicked.Parent
            end
        end
    end)
    repeat task.wait() until tostring(TreeToJointCut) ~= "nil"
    for i, v in next, TreeToJointCut:GetChildren() do
        if v.Name == "WoodSection" then
            if v:FindFirstChild("ID") and v.ID.Value ~= 1 then
                speaker.Character.HumanoidRootPart.CFrame = CFrame.new(v.CFrame.p)
                local success, data = getBestAxe(v.Parent:FindFirstChild("TreeClass").Value)
                repeat
                    cutPart(v.Parent:FindFirstChild("CutEvent"), v.ID.Value, 0.2, data,
                        v.Parent:FindFirstChild("TreeClass").Value)
                    task.wait()
                until LogChopped == true
                LogChopped = false
                task.wait(1)
            end
        end
    end
    TreeToJointCut = nil
    branchadded:Disconnect()
    DismemberTreeC:Disconnect()
    speaker.Character.HumanoidRootPart.CFrame = OldPos
end)

-- 处理树自动
woodBtn("处理树自动", Color3.fromRGB(194, 231, 211), Color3.fromRGB(74, 125, 94)).MouseButton1Click:Connect(function()
    local wood, Saw
    local sell = CFrame.new(315, -4, 84)
    notify("请点击一颗树,再点击一个锯木机", "info")
    wait(0.5)
    local oldPosition = getPosition()
    local oldpos = speaker.Character.HumanoidRootPart.CFrame
    local ModTree = Mouse.Button1Up:Connect(function()
        local obj = Mouse.Target.Parent
        if not obj:FindFirstChild("RootCut") and obj.Parent.Name == "TreeRegion" then
            return notify("这棵树还没有砍!", "warn")
        end
        if obj:FindFirstChild("Owner") and obj.Owner.Value == lp and obj:FindFirstChild("WoodSection") then
            wood = obj; notify("已选择树!", "success")
        end
        if obj.Name:find('Sawmill') then
            Saw = obj; notify("锯木机已选择", "success")
        elseif obj.Parent.Name:find('Sawmill') or obj.Parent:FindFirstChild('BlockageAlert') then
            Saw = obj.Parent; notify("锯木机已选择", "success")
        end
    end)
    repeat task.wait(.01) until wood and Saw ~= nil
    ModTree:Disconnect(); ModTree = nil
    local SawC = Saw.Particles.CFrame + Vector3.new(0.7, 0)
    tp(wood.WoodSection.CFrame)
    spawn(function()
        for i = 1, 20 do
            wood:SetPrimaryPartCFrame(sell)
            pcall(function()
                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                _r:FireServer("Begin", wood, 5)
                _r:FireServer("Refresh", wood, 5)
                _r:FireServer("End", wood, 5)
            end)
            RunService.Stepped:wait()
        end
    end)
    task.wait(0.3)
    tp(wood.WoodSection.CFrame)
    task.wait(1)
    for i = 1, 20 do
        pcall(function()
            local _r = ReplicatedStorage.Interaction.ClientIsDragging
            _r:FireServer("Begin", wood, 5)
            _r:FireServer("Refresh", wood, 5)
            _r:FireServer("End", wood, 5)
        end)
        wood:MoveTo(oldPosition)
        RunService.Stepped:wait()
    end
    tp(oldpos)
    pcall(function()
        spawn(function()
            for i = 1, 200 do
                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                _r:FireServer("Begin", wood, 5)
                _r:FireServer("Refresh", wood, 5)
                _r:FireServer("End", wood, 5)
                wood:SetPrimaryPartCFrame(SawC)
                _r:FireServer("Begin", wood, 5)
                _r:FireServer("Refresh", wood, 5)
                _r:FireServer("End", wood, 5)
                task.wait()
            end
        end)
    end)
    tp(oldpos)
end)

-- 删除树/木板
woodBtn("删除树/木板", Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101)).MouseButton1Click:Connect(function()
    local f = Instance.new("Tool", speaker.Backpack)
    f.Name = "点击你要删除的树或木板"
    f.RequiresHandle = false
    f.Activated:Connect(function()
        local g = Mouse.Target.Parent
        local h = speaker.Character.HumanoidRootPart.CFrame
        if not g:FindFirstChild("WoodSection") then return end
        local i
        if g:FindFirstChild("Owner") and g.Owner.Value == speaker or g.Owner.Value == nil then
            if not g:FindFirstChild("RootCut") and g.Parent.Name == "TreeRegion" then
                for e, j in next, g:GetChildren() do
                    if j.Name == "WoodSection" and j:FindFirstChild("ID") and j:FindFirstChild("ID").Value == tonumber(1) then
                        i = j
                    end
                end
            else
                i = g.WoodSection
            end
            tp(i.CFrame)
            for e = 1, 3 do
                spawn(function()
                    for e = 1, 20 do
                        pcall(function()
                            local _r = ReplicatedStorage.Interaction.ClientIsDragging
                            _r:FireServer("Begin", g, 5)
                            _r:FireServer("Refresh", g, 5)
                            _r:FireServer("End", g, 5)
                        end)
                        ReplicatedStorage.Interaction.DestroyStructure:FireServer(g)
                        RunService.Stepped:wait()
                    end
                end)
                task.wait(.1)
            end
        end
        task.wait()
        tp(h)
    end)
    f.Parent = speaker.Backpack
end)

-- ===== 带来树 Section =====
woodLabel("── 带来树 ──")

-- 选择树类型下拉
local treeTypeBtn = Instance.new("TextButton")
treeTypeBtn.Parent = woodPage
treeTypeBtn.Size = UDim2.new(1, -px(8), 0, px(18))
treeTypeBtn.Position = UDim2.new(0, px(4), 0, woodY)
treeTypeBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
treeTypeBtn.BorderSizePixel = 0
treeTypeBtn.Text = "树类型: " .. selectedTreeClass
treeTypeBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
treeTypeBtn.Font = Enum.Font.GothamBold
treeTypeBtn.TextSize = px(9)
treeTypeBtn.AutoButtonColor = false
Instance.new("UICorner", treeTypeBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(19)

local treeTypeList = Instance.new("ScrollingFrame")
treeTypeList.Parent = woodPage
treeTypeList.Size = UDim2.new(1, -px(8), 0, px(50))
treeTypeList.Position = UDim2.new(0, px(4), 0, woodY)
treeTypeList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
treeTypeList.BorderSizePixel = 0
treeTypeList.ScrollBarThickness = 3
treeTypeList.Visible = false
treeTypeList.ZIndex = 30
Instance.new("UICorner", treeTypeList).CornerRadius = UDim.new(0, px(4))
local treeTypeLayout = Instance.new("UIListLayout")
treeTypeLayout.Parent = treeTypeList
treeTypeLayout.Padding = UDim.new(0, 1)
treeTypeLayout.SortOrder = Enum.SortOrder.LayoutOrder
woodY = woodY + px(0)

local function populateTreeTypeList()
    -- 清空旧按钮
    for _, child in ipairs(treeTypeList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    -- 用 scannedTreeClasses 动态填充
    for i, tc in ipairs(scannedTreeClasses) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Parent = treeTypeList
        itemBtn.Size = UDim2.new(1, 0, 0, 16)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = tc
        itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
        itemBtn.Font = Enum.Font.GothamMedium
        itemBtn.TextSize = px(8)
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.ZIndex = 31
        itemBtn.MouseButton1Click:Connect(function()
            bai.cuttreeselect = tc
            selectedTreeClass = tc
            treeNameLabel.Text = tc
            treeTypeBtn.Text = "树类型: " .. tc
            treeTypeList.Visible = false
        end)
    end
end
populateTreeTypeList()
treeTypeList.CanvasSize = UDim2.new(0, 0, 0, #scannedTreeClasses * 17)

treeTypeBtn.MouseButton1Click:Connect(function()
    treeTypeList.Visible = not treeTypeList.Visible
end)

-- 带来树数量输入框
local bringAmtBtn = Instance.new("TextBox")
bringAmtBtn.Parent = woodPage
bringAmtBtn.Size = UDim2.new(1, -px(8), 0, px(18))
bringAmtBtn.Position = UDim2.new(0, px(4), 0, woodY)
bringAmtBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
bringAmtBtn.BorderSizePixel = 0
bringAmtBtn.Text = "1"
bringAmtBtn.PlaceholderText = "带来数量"
bringAmtBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
bringAmtBtn.Font = Enum.Font.GothamBold
bringAmtBtn.TextSize = px(9)
bringAmtBtn.ClearTextOnFocus = true
Instance.new("UICorner", bringAmtBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(19)

bringAmtBtn.FocusLost:Connect(function()
    local n = tonumber(bringAmtBtn.Text)
    if n and n >= 1 then
        bai.bringamount = math.floor(n)
    end
    bringAmtBtn.Text = tostring(bai.bringamount)
end)

-- 带来树
woodBtn("带来树", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    bai.bringtree = true
    bai.treecutset = speaker.Character.HumanoidRootPart.CFrame
    task.wait(0.2)
    task.spawn(function()
        for i = 1, bai.bringamount do
            if not bai.bringtree then break end
            bringTree(selectedTreeClass)
            task.wait(0.1)
        end
        bai.bringtree = false
    end)
end)

-- 停止
woodBtn("停止带来", Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101)).MouseButton1Click:Connect(function()
    bai.bringtree = false
end)

-- 自动砍树
local autoFarmOn = false
local autoFarmBtn = woodBtn("自动砍树: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
autoFarmBtn.MouseButton1Click:Connect(function()
    autoFarmOn = not autoFarmOn
    if autoFarmOn then
        autoFarmBtn.Text = "自动砍树: 开"
        autoFarmBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        autoFarmBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        bai.autofarm = true
        task.spawn(function()
            while task.wait(0.3) do
                if bai.autofarm == true then bringTree(selectedTreeClass) end
            end
        end)
    else
        autoFarmBtn.Text = "自动砍树: 关"
        autoFarmBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        autoFarmBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
        bai.autofarm = false
    end
end)

-- 自动赚钱
local autoMoneyOn = false
local autoMoneyBtn = woodBtn("自动赚钱: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
autoMoneyBtn.MouseButton1Click:Connect(function()
    autoMoneyOn = not autoMoneyOn
    if autoMoneyOn then
        autoMoneyBtn.Text = "自动赚钱: 开"
        autoMoneyBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        autoMoneyBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
        bai.autofarm1 = true
        local oldpos = speaker.Character.HumanoidRootPart.CFrame
        task.spawn(function()
            while task.wait() do
                if bai.autofarm1 == true then
                    speaker.Character:MoveTo(Vector3.new(315, -0.296, 102.791))
                    autofarm(selectedTreeClass)
                    wait(1)
                    speaker.Character:MoveTo(Vector3.new(315, -0.296, 102.791))
                    wait(20)
                end
            end
        end)
    else
        autoMoneyBtn.Text = "自动赚钱: 关"
        autoMoneyBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        autoMoneyBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
        bai.autofarm1 = false
        for i, v in pairs(Workspace.Properties:GetChildren()) do
            if v.Owner.Value == speaker then
                speaker.Character.HumanoidRootPart.CFrame = v.OriginSquare.CFrame + Vector3.new(0, 10, 0)
            end
        end
    end
end)

-- ===== 填充蓝图（用木头） =====
woodLabel("── 填充蓝图 ──")

-- 选择木头类型（蓝图填充）
local fillTypeBtn = Instance.new("TextButton")
fillTypeBtn.Parent = woodPage
fillTypeBtn.Size = UDim2.new(1, -px(8), 0, px(18))
fillTypeBtn.Position = UDim2.new(0, px(4), 0, woodY)
fillTypeBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
fillTypeBtn.BorderSizePixel = 0
fillTypeBtn.Text = "蓝图木头: 普通树"
fillTypeBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
fillTypeBtn.Font = Enum.Font.GothamBold
fillTypeBtn.TextSize = px(9)
fillTypeBtn.AutoButtonColor = false
Instance.new("UICorner", fillTypeBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(19)

local fillTypeList = Instance.new("ScrollingFrame")
fillTypeList.Parent = woodPage
fillTypeList.Size = UDim2.new(1, -px(8), 0, px(50))
fillTypeList.Position = UDim2.new(0, px(4), 0, woodY)
fillTypeList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
fillTypeList.BorderSizePixel = 0
fillTypeList.ScrollBarThickness = 3
fillTypeList.Visible = false
fillTypeList.ZIndex = 30
Instance.new("UICorner", fillTypeList).CornerRadius = UDim.new(0, px(4))
local fillTypeLayout = Instance.new("UIListLayout")
fillTypeLayout.Parent = fillTypeList
fillTypeLayout.Padding = UDim.new(0, 1)
fillTypeLayout.SortOrder = Enum.SortOrder.LayoutOrder
woodY = woodY + px(0)

local FILL_TYPES = {
    {name = "普通树", val = "Generic"}, {name = "沼泽黄金", val = "GoldSwampy"},
    {name = "樱花", val = "Cherry"}, {name = "蓝木", val = "CaveCrawler"},
    {name = "冰木", val = "Frost"}, {name = "火山木", val = "Volcano"},
    {name = "橡木", val = "Oak"}, {name = "巧克力木", val = "Walnut"},
    {name = "青桦木", val = "Birch"}, {name = "黄金木", val = "SnowGlow"},
    {name = "雪地松", val = "Pine"}, {name = "僵尸木", val = "GreenSwampy"},
    {name = "大巧克力树", val = "Koa"}, {name = "椰子树", val = "Palm"},
    {name = "幻影", val = "LoneCave"},
}

for i, tt in ipairs(FILL_TYPES) do
    local itemBtn = Instance.new("TextButton")
    itemBtn.Parent = fillTypeList
    itemBtn.Size = UDim2.new(1, 0, 0, 16)
    itemBtn.BackgroundTransparency = 1
    itemBtn.Text = tt.name
    itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
    itemBtn.Font = Enum.Font.GothamMedium
    itemBtn.TextSize = px(8)
    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
    itemBtn.ZIndex = 31
    itemBtn.MouseButton1Click:Connect(function()
        bai.tchonmt = tt.val
        fillTypeBtn.Text = "蓝图木头: " .. tt.name
        fillTypeList.Visible = false
    end)
end
fillTypeList.CanvasSize = UDim2.new(0, 0, 0, #FILL_TYPES * 17)

fillTypeBtn.MouseButton1Click:Connect(function()
    fillTypeList.Visible = not fillTypeList.Visible
end)

-- 填充蓝图（木头）
woodBtn("填充蓝图(点击)", Color3.fromRGB(194, 231, 211), Color3.fromRGB(74, 125, 94)).MouseButton1Click:Connect(function()
    local tool = Instance.new("Tool", speaker.Backpack)
    tool.RequiresHandle = false
    tool.Name = "点击一块蓝图"
    tool.Activated:Connect(function()
        local str = getMouseTarget().Parent
        if str:FindFirstChild("Type") and str.Type.Value == "Blueprint" and str:FindFirstChild("Owner") then
            lumbsmasher_legitpaint(bai.tchonmt, str, true)
        end
    end)
end)

-- 填充蓝图（全部）
woodBtn("填充蓝图(全部)", Color3.fromRGB(194, 231, 211), Color3.fromRGB(74, 125, 94)).MouseButton1Click:Connect(function()
    for i, v in pairs(Workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Type") and v.Type.Value == "Blueprint" and v:FindFirstChild("Owner") then
            if v.Owner.Value == lp then
                lumbsmasher_legitpaint(bai.tchonmt, v, true)
                task.wait()
            end
        end
    end
end)

-- ===== 整理木板 =====
woodLabel("── 整理木板 ──")

-- 选择玩家
local sortPlayerBtn = Instance.new("TextButton")
sortPlayerBtn.Parent = woodPage
sortPlayerBtn.Size = UDim2.new(1, -px(8), 0, px(18))
sortPlayerBtn.Position = UDim2.new(0, px(4), 0, woodY)
sortPlayerBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
sortPlayerBtn.BorderSizePixel = 0
sortPlayerBtn.Text = "整理玩家: 自己"
sortPlayerBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
sortPlayerBtn.Font = Enum.Font.GothamBold
sortPlayerBtn.TextSize = px(9)
sortPlayerBtn.AutoButtonColor = false
Instance.new("UICorner", sortPlayerBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(19)

local sortPlayerList = Instance.new("ScrollingFrame")
sortPlayerList.Parent = woodPage
sortPlayerList.Size = UDim2.new(1, -px(8), 0, px(50))
sortPlayerList.Position = UDim2.new(0, px(4), 0, woodY)
sortPlayerList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
sortPlayerList.BorderSizePixel = 0
sortPlayerList.ScrollBarThickness = 3
sortPlayerList.Visible = false
sortPlayerList.ZIndex = 30
Instance.new("UICorner", sortPlayerList).CornerRadius = UDim.new(0, px(4))
local sortPlayerLayout = Instance.new("UIListLayout")
sortPlayerLayout.Parent = sortPlayerList
sortPlayerLayout.Padding = UDim.new(0, 1)
sortPlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
woodY = woodY + px(0)

local function rebuildSortPlayerList()
    for _, ch in ipairs(sortPlayerList:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    shuaxinlb(true)
    for i, pname in ipairs(bai.dropdown) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Parent = sortPlayerList
        itemBtn.Size = UDim2.new(1, 0, 0, 16)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = pname
        itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
        itemBtn.Font = Enum.Font.GothamMedium
        itemBtn.TextSize = px(8)
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.ZIndex = 31
        itemBtn.MouseButton1Click:Connect(function()
            bai.mtwjia = pname
            sortPlayerBtn.Text = "整理玩家: " .. pname
            sortPlayerList.Visible = false
        end)
    end
    sortPlayerList.CanvasSize = UDim2.new(0, 0, 0, #bai.dropdown * 17)
end

sortPlayerBtn.MouseButton1Click:Connect(function()
    sortPlayerList.Visible = not sortPlayerList.Visible
    if sortPlayerList.Visible then rebuildSortPlayerList() end
end)

-- 选择木头类型（整理）
local sortTypeBtn = Instance.new("TextButton")
sortTypeBtn.Parent = woodPage
sortTypeBtn.Size = UDim2.new(1, -px(8), 0, px(18))
sortTypeBtn.Position = UDim2.new(0, px(4), 0, woodY)
sortTypeBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
sortTypeBtn.BorderSizePixel = 0
sortTypeBtn.Text = "整理木头: 普通树"
sortTypeBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
sortTypeBtn.Font = Enum.Font.GothamBold
sortTypeBtn.TextSize = px(9)
sortTypeBtn.AutoButtonColor = false
Instance.new("UICorner", sortTypeBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(19)

local sortTypeList = Instance.new("ScrollingFrame")
sortTypeList.Parent = woodPage
sortTypeList.Size = UDim2.new(1, -px(8), 0, px(50))
sortTypeList.Position = UDim2.new(0, px(4), 0, woodY)
sortTypeList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
sortTypeList.BorderSizePixel = 0
sortTypeList.ScrollBarThickness = 3
sortTypeList.Visible = false
sortTypeList.ZIndex = 30
Instance.new("UICorner", sortTypeList).CornerRadius = UDim.new(0, px(4))
local sortTypeLayout = Instance.new("UIListLayout")
sortTypeLayout.Parent = sortTypeList
sortTypeLayout.Padding = UDim.new(0, 1)
sortTypeLayout.SortOrder = Enum.SortOrder.LayoutOrder
woodY = woodY + px(0)

local SORT_TYPES = {
    {name = "普通树", val = "Generic"}, {name = "沼泽黄金", val = "GoldSwampy"},
    {name = "樱花", val = "Cherry"}, {name = "蓝木", val = "CaveCrawler"},
    {name = "冰木", val = "Frost"}, {name = "火山木", val = "Volcano"},
    {name = "橡木", val = "Oak"}, {name = "巧克力木", val = "Walnut"},
    {name = "青桦木", val = "Birch"}, {name = "黄金木", val = "SnowGlow"},
    {name = "雪地松", val = "Pine"}, {name = "僵尸木", val = "GreenSwampy"},
    {name = "大巧克力树", val = "Koa"}, {name = "椰子树", val = "Palm"},
    {name = "幻影", val = "LoneCave"}, {name = "幽灵木", val = "Spooky"},
    {name = "南瓜木", val = "SpookyNeon"},
}

for i, tt in ipairs(SORT_TYPES) do
    local itemBtn = Instance.new("TextButton")
    itemBtn.Parent = sortTypeList
    itemBtn.Size = UDim2.new(1, 0, 0, 16)
    itemBtn.BackgroundTransparency = 1
    itemBtn.Text = tt.name
    itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
    itemBtn.Font = Enum.Font.GothamMedium
    itemBtn.TextSize = px(8)
    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
    itemBtn.ZIndex = 31
    itemBtn.MouseButton1Click:Connect(function()
        bai.zlmt = tt.val
        sortTypeBtn.Text = "整理木头: " .. tt.name
        sortTypeList.Visible = false
    end)
end
sortTypeList.CanvasSize = UDim2.new(0, 0, 0, #SORT_TYPES * 17)

sortTypeBtn.MouseButton1Click:Connect(function()
    sortTypeList.Visible = not sortTypeList.Visible
end)

-- 竖着整理
local verticalOn = false
local verticalBtn = woodBtn("竖着整理: 关", Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
verticalBtn.MouseButton1Click:Connect(function()
    verticalOn = not verticalOn
    if verticalOn then
        bai.shuzhe = true
        verticalBtn.Text = "竖着整理: 开"
        verticalBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
        verticalBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
    else
        bai.shuzhe = false
        verticalBtn.Text = "竖着整理: 关"
        verticalBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
        verticalBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
    end
end)

-- 开始整理
woodBtn("开始整理", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    if bai.zlmt == nil then return notify("你没有选择木头", "warn") end
    if bai.shuzhe == false then
        local oldpos = speaker.Character.HumanoidRootPart.Position
        for _, Plank in pairs(Workspace.PlayerModels:GetChildren()) do
            if Plank.Name == "Plank" and Plank:FindFirstChild("Owner") then
                if Plank:FindFirstChild("Owner") and tostring(Plank.Owner.Value) == bai.mtwjia then
                    if Plank.TreeClass.Value == bai.zlmt then
                        tp(Plank.WoodSection.CFrame)
                        for i = 1, 50 do
                            pcall(function()
                                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                _r:FireServer("Begin", Plank, 5)
                                _r:FireServer("Refresh", Plank, 5)
                                _r:FireServer("End", Plank, 5)
                            end)
                            Plank.WoodSection.Position = oldpos
                            pcall(function()
                                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                _r:FireServer("Begin", Plank, 5)
                                _r:FireServer("Refresh", Plank, 5)
                                _r:FireServer("End", Plank, 5)
                            end)
                            RunService.Stepped:wait()
                        end
                    end
                end
            end
        end
    else
        local oldpos = speaker.Character.HumanoidRootPart.CFrame
        for _, Plank in pairs(Workspace.PlayerModels:GetChildren()) do
            if Plank.Name == "Plank" and Plank:FindFirstChild("Owner") then
                if Plank:FindFirstChild("Owner") and tostring(Plank.Owner.Value) == bai.mtwjia then
                    if Plank.TreeClass.Value == bai.zlmt then
                        tp(Plank.WoodSection.CFrame)
                        for i = 1, 50 do
                            pcall(function()
                                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                _r:FireServer("Begin", Plank, 5)
                                _r:FireServer("Refresh", Plank, 5)
                                _r:FireServer("End", Plank, 5)
                            end)
                            Plank.WoodSection.CFrame = oldpos
                            pcall(function()
                                local _r = ReplicatedStorage.Interaction.ClientIsDragging
                                _r:FireServer("Begin", Plank, 5)
                                _r:FireServer("Refresh", Plank, 5)
                                _r:FireServer("End", Plank, 5)
                            end)
                            RunService.Stepped:wait()
                        end
                    end
                end
            end
        end
    end
end)

-- ===== [移植自青脚本] 木头功能 结束 =====
end

