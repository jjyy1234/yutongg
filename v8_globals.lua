-- v8_globals.lua — 共享变量和工具函数
-- YUTONG v8 模块化：全局共享变量、UI 框架、白名单、Kick 逻辑
-- 所有模块通过 _G.V8 表访问共享变量

local V8 = _G.V8 or {}
_G.V8 = V8

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

-- 授权用户检测（从 GitHub whitelist.txt 加载）
local AUTHORIZED_USERS = {}
do
    local ok, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/whitelist.txt", true)
    end)
    if ok and result then
        for name in result:gmatch("[^\r\n]+") do
            name = name:match("^%s*(.-)%s*$")
            if #name > 0 then
                AUTHORIZED_USERS[name] = true
            end
        end
    end
end
local _authPlayer = Players.LocalPlayer
if not AUTHORIZED_USERS[_authPlayer.Name] then
	_authPlayer:Kick("非授权用户")
	_G.V8.authorized = false
	return
end
_G.V8.authorized = true

-- ===== 剑伤害表 =====


local function getSwordFromWorld(name)
    local lp2 = Players.LocalPlayer
    local bp = lp2:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(name) then return bp:FindFirstChild(name) end
    local char = lp2.Character
    if char and char:FindFirstChild(name) then return char:FindFirstChild(name) end
    local pm = workspace:FindFirstChild("PlayerModels")
    if pm then
        for _, obj in ipairs(pm:GetChildren()) do
            if obj.Name == name then
                local owner = obj:FindFirstChild("Owner")
                if owner and owner.Value == lp2 then return obj end
            end
        end
    end
    return nil
end

local function getBestSword()
    local lp2 = Players.LocalPlayer
    local containers = {lp2:FindFirstChild("Backpack"), lp2.Character}
    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                local itemName = obj:FindFirstChild("ItemName")
                if itemName and itemName:IsA("StringValue") then
                    return obj, itemName.Value
                end
            end
        end
    end
    return nil, nil
end

local speaker = Players.LocalPlayer
print("[Yutong] Script loading")

-- ===== 金钱 =====
local currentMoney = nil
pcall(function()
	local tx = ReplicatedStorage:FindFirstChild("Transactions")
	local stc = tx and tx:FindFirstChild("ServerToClient")
	local fc = stc and stc:FindFirstChild("FundsChanged")
	if fc and fc:IsA("RemoteEvent") then
		fc.OnClientEvent:Connect(function(a, b)
			if type(a) == "number" then
				currentMoney = a
			elseif type(b) == "number" then
				currentMoney = b
			elseif type(a) == "table" and type(a.Money) == "number" then
				currentMoney = a.Money
			end
		end)
	end
end)

local function getMoney()
	if type(currentMoney) == "number" then
		return currentMoney
	end
	local function from(inst)
		if not inst then return nil end
		for _, n in ipairs({"Money", "Cash", "Funds", "Gold", "money", "cash"}) do
			local v = inst:FindFirstChild(n)
			if v and v:IsA("ValueBase") and type(v.Value) == "number" then
				return v.Value
			end
		end
		for _, v in ipairs(inst:GetDescendants()) do
			if v:IsA("ValueBase") and (v.Name == "Money" or v.Name == "Cash" or v.Name == "Funds") then
				if type(v.Value) == "number" then return v.Value end
			end
		end
		return nil
	end
	local m = from(speaker:FindFirstChild("leaderstats"))
		or from(speaker)
		or from(speaker:FindFirstChild("PlayerData"))
		or from(speaker:FindFirstChild("Stats"))
	if type(m) == "number" then
		currentMoney = m
		return m
	end
	return currentMoney
end

local PlayerGui = speaker:WaitForChild("PlayerGui")
local Mouse = speaker:GetMouse()

local old = PlayerGui:FindFirstChild("YutongFlyUI")
if old then old:Destroy() end

local function getUIScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local short = math.min(vp.X, vp.Y)
	return math.clamp(short / 500, 0.75, 1.35)
end
local S = getUIScale()
local function px(n) return math.floor(n * S + 0.5) end
local FRAME_W = px(215)
local FRAME_H = px(178)

local main = Instance.new("ScreenGui")
main.Name = "YutongFlyUI"
main.Parent = PlayerGui
main.ResetOnSpawn = false
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.IgnoreGuiInset = true


-- ===================== 右下角通知弹窗 =====================
local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifyContainer"
notifContainer.Parent = main
notifContainer.AnchorPoint = Vector2.new(1, 1)
notifContainer.Position = UDim2.new(1, -12, 1, -12)
notifContainer.Size = UDim2.new(0, px(160), 1, -24)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100

local notifLayout = Instance.new("UIListLayout")
notifLayout.Parent = notifContainer
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.Padding = UDim.new(0, 6)

local notifSeq = 0

local function notify(text, kind)
	kind = kind or "info"
	notifSeq = notifSeq + 1
	local order = notifSeq

	local bg, stroke, tc
	if kind == "success" then
		bg = Color3.fromRGB(191, 226, 205)
		stroke = Color3.fromRGB(120, 180, 150)
		tc = Color3.fromRGB(72, 108, 88)
	elseif kind == "error" or kind == "fail" then
		bg = Color3.fromRGB(247, 202, 211)
		stroke = Color3.fromRGB(220, 150, 160)
		tc = Color3.fromRGB(146, 83, 101)
	elseif kind == "warn" then
		bg = Color3.fromRGB(255, 230, 180)
		stroke = Color3.fromRGB(220, 180, 100)
		tc = Color3.fromRGB(140, 100, 40)
	else
		bg = Color3.fromRGB(250, 238, 245)
		stroke = Color3.fromRGB(225, 198, 215)
		tc = Color3.fromRGB(145, 103, 134)
	end

	local card = Instance.new("Frame")
	card.Name = "Toast_" .. order
	card.Parent = notifContainer
	card.LayoutOrder = order
	card.Size = UDim2.new(0, px(150), 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = bg
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.ZIndex = 101
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, px(10))

	local st = Instance.new("UIStroke")
	st.Parent = card
	st.Color = stroke
	st.Thickness = 1
	st.Transparency = 0.2

	local pad = Instance.new("UIPadding")
	pad.Parent = card
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local label = Instance.new("TextLabel")
	label.Parent = card
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Text = tostring(text)
	label.TextColor3 = tc
	label.TextWrapped = true
	label.Font = Enum.Font.GothamMedium
	label.TextSize = px(8)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 102

	-- 入场：从右滑入感（透明度）
	card.BackgroundTransparency = 1
	label.TextTransparency = 1
	st.Transparency = 1
	TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 0.05}):Play()
	TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
	TweenService:Create(st, TweenInfo.new(0.18), {Transparency = 0.2}):Play()

	task.delay(2, function()
		if not card.Parent then return end
		local t1 = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		local t2 = TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1})
		local t3 = TweenService:Create(st, TweenInfo.new(0.2), {Transparency = 1})
		t1:Play(); t2:Play(); t3:Play()
		t1.Completed:Wait()
		card:Destroy()
	end)
end

_G.YutongNotify = notify

-- ===== 全店 NPC ID 探测（启动时）=====
local npcIdCache = {} -- [storeName] = id
local npcIdConfirmed = {} -- [storeName] = true 仅首次购买试错后锁定
local npcCtxCache = {} -- [storeName] = {Character, Name, ID, Dialog}

-- 商店基础 NPC ID（版本可能整体 -5～+5）
local STORE_CN = {
	SeaSide = "海边商店",
	HLStand = "HL摊位",
	MountainSide = "山边商店",
	BlackMarket = "黑市",
	FurnitureStore = "家具店",
	CarStore = "车店",
	FineFinds = "精品发现",
	TravelingTrader = "旅行商人",
	SaplingCart = "树苗车",
	PlanterStore = "花盆店",
	WoodRUs = "木材商店",
	SallysSeasonal = "莎莉季节店",
	StoneRUs = "石头商店",
	Igloo = "冰屋",
	PlantomicsChoice = "植物商店",
	VIPSHOP = "VIP商店",
	LandStore = "土地店",
	LogicStore = "逻辑店",
	FineArt = "艺术品店",
	MusicStore = "音乐店",
	AutumnCatalog = "秋季目录",
}
local function storeDisplayName(name)
	local cn = STORE_CN[name]
	if cn then
		return string.format("%s（%s）", cn, name)
	end
	return tostring(name)
end

local STORE_BASE_ID = {
	SeaSide = 12,
	HLStand = 13,
	MountainSide = 14,
	BlackMarket = 15,
	FurnitureStore = 16,
	CarStore = 17,
	FineFinds = 18,
	TravelingTrader = 19,
	SaplingCart = 21,
	PlanterStore = 22,
	WoodRUs = 24,
	SallysSeasonal = 25,
	StoneRUs = 26,
	Igloo = 28,
	PlantomicsChoice = 29,
	VIPSHOP = 31,
	-- 补充（按常见顺序，offset 仍适用）
	LandStore = 10,
	LogicStore = 11,
	FineArt = 27,
	MusicStore = 30,
	AutumnCatalog = 32,
}
local STORE_BASE_ID_ALT = {
	FurnitureStore = 20,
	CarStore = 23,
}

local serverIdOffset = nil -- 命中后：actual - base，全服共用

local function getStoreBaseIds(storeName)
	local list = {}
	local b = STORE_BASE_ID[storeName]
	local a = STORE_BASE_ID_ALT[storeName]
	if b then table.insert(list, b) end
	if a and a ~= b then table.insert(list, a) end
	if #list == 0 then table.insert(list, 24) end
	return list
end

local function candidateIdsForStore(storeName)
	local ids = {}
	local seen = {}
	local function add(id)
		if type(id) == "number" and id >= 1 and id <= 40 and not seen[id] then
			seen[id] = true
			table.insert(ids, id)
		end
	end
	-- 已缓存
	add(npcIdCache[storeName])
	if serverIdOffset ~= nil then
		for _, base in ipairs(getStoreBaseIds(storeName)) do
			add(base + serverIdOffset)
		end
	end
	for _, base in ipairs(getStoreBaseIds(storeName)) do
		-- 范围 base-2 .. base+2
		for d = -2, 2 do
			add(base + d)
		end
	end
	add(24)
	add(25)
	return ids
end


local function deepFindId(val, depth)
	depth = depth or 0
	if depth > 4 then return nil end
	if type(val) == "number" and val > 0 and val < 100000 then
		return val
	end
	if type(val) == "table" then
		if type(val.ID) == "number" then return val.ID end
		if type(val.Id) == "number" then return val.Id end
		for k, v in pairs(val) do
			if (k == "ID" or k == "Id") and type(v) == "number" then return v end
			local f = deepFindId(v, depth + 1)
			if f then return f end
		end
	end
	return nil
end

local function listenDialogTraffic(onId)
	local conns = {}
	pcall(function()
		local npc = ReplicatedStorage:FindFirstChild("NPCDialog")
		if not npc then return end
		local prompt = npc:FindFirstChild("PromptChat")
		if prompt and prompt:IsA("RemoteEvent") then
			table.insert(conns, prompt.OnClientEvent:Connect(function(...)
				for _, a in ipairs({...}) do
					local id = deepFindId(a)
					if id then onId(id, a) end
				end
			end))
		end
	end)
	-- 短暂 namecall 钩住 PlayerChatted 发出/返回
	pcall(function()
		if not hookmetamethod then return end
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if method == "InvokeServer" then
				local n = ""
				pcall(function() n = self.Name end)
				if n == "PlayerChatted" then
					local args = {...}
					for _, a in ipairs(args) do
						local id = deepFindId(a)
						if id then onId(id, a) end
					end
					local results = { old(self, ...) }
					for _, r in ipairs(results) do
						local id = deepFindId(r)
						if id then onId(id, r) end
					end
					return table.unpack(results)
				end
			end
			return old(self, ...)
		end)
		table.insert(conns, { Disconnect = function() end, __old = old })
	end)
	return conns
end

local function probeAllStoreNpcIds()
	local stores = Workspace:FindFirstChild("Stores")
	if not stores then
		print("[Yutong] 探测: 无 Stores")
		return
	end
	local npcDlg = ReplicatedStorage:FindFirstChild("NPCDialog")
	local playerChatted = npcDlg and npcDlg:FindFirstChild("PlayerChatted")
	local setVal = npcDlg and npcDlg:FindFirstChild("SetChattingValue")
	if not playerChatted then
		print("[Yutong] 探测: 无 PlayerChatted")
		return
	end

	local lastId = nil
	local lastTable = nil
	local conns = listenDialogTraffic(function(id, src)
		lastId = id
		if type(src) == "table" and src.Character then
			lastTable = src
		end
	end)

	print("[Yutong] 开始探测全店 NPC ID...")
	for _, store in ipairs(stores:GetChildren()) do
		local thom = nil
		for _, n in ipairs({"Thom", "NPC", "Shopkeeper", "Seller", "Clerk", "Guy", "Todd", "Jenny", "Corey", "Lincoln", "Ruhven"}) do
			local t = store:FindFirstChild(n)
			if t and t:FindFirstChild("Dialog") then thom = t break end
		end
		if not thom then
			for _, c in ipairs(store:GetChildren()) do
				if c:FindFirstChild("Dialog") and c.Name ~= "ShopItems" then
					thom = c
					break
				end
			end
		end
		if not thom then
			-- skip
		else
			lastId = nil
			lastTable = nil
			local dialog = thom:FindFirstChild("Dialog")
			local tryId = npcIdCache[store.Name] or 24
			local ctx = {
				Character = thom,
				Name = thom.Name,
				ID = tryId,
				Dialog = dialog,
			}
			pcall(function()
				playerChatted:InvokeServer(ctx, "Initiate")
			end)
			task.wait(0.12)
			-- 若 traffic 里抓到新 ID，更新
			if lastId then
				ctx.ID = lastId
			end
			if lastTable and type(lastTable.ID) == "number" then
				ctx.ID = lastTable.ID
				if lastTable.Character then ctx.Character = lastTable.Character end
				if lastTable.Dialog then ctx.Dialog = lastTable.Dialog end
				if type(lastTable.Name) == "string" then ctx.Name = lastTable.Name end
			end
			pcall(function()
				local attr = thom:GetAttribute("ID") or (dialog and dialog:GetAttribute("ID"))
				if type(attr) == "number" then
					ctx.ID = attr
				end
			end)
			-- 无论有没有抓到，都写入缓存（至少是默认/探测用的 ID）
			npcIdCache[store.Name] = ctx.ID
			npcCtxCache[store.Name] = ctx
			print("[Yutong] 探测", store.Name, thom.Name, "ID=", ctx.ID)
			pcall(function()
				playerChatted:InvokeServer(ctx, "EndChat")
			end)
			pcall(function()
				if setVal then setVal:InvokeServer(0) end
			end)
			task.wait(0.06)
		end
	end

	for _, c in ipairs(conns) do
		pcall(function() if c.Disconnect then c:Disconnect() end end)
	end
	print("[Yutong] 全店 ID 探测完成, 缓存数=", (function()
		local n = 0
		for _ in pairs(npcIdCache) do n = n + 1 end
		return n
	end)())
	-- 通知购买页刷新商店下拉（若已创建）
	pcall(function()
		if _G.YutongRefreshShopList then _G.YutongRefreshShopList() end
	end)
end

-- 被动监听 PromptChat，靠近 NPC 时自动更新缓存，买过一次后锁定不再覆盖
pcall(function()
    local npcDlg = ReplicatedStorage:WaitForChild("NPCDialog", 10)
    if not npcDlg then return end
    local prompt = npcDlg:FindFirstChild("PromptChat")
    if not prompt or not prompt:IsA("RemoteEvent") then return end
    local stores = Workspace:FindFirstChild("Stores")
    local function handleEntry(data)
        if type(data) ~= "table" then return end
        if type(data.ID) ~= "number" then return end
        if not data.Character then return end
        pcall(function()
            if not stores then return end
            local store = data.Character.Parent
            if not store then return end
            if store.Parent ~= stores then return end
            local name = store.Name
            -- 已有缓存的不覆盖
            if npcIdConfirmed[name] then return end
            if npcIdCache[name] then return end
            npcIdCache[name] = data.ID
            npcCtxCache[name] = {
                ID = data.ID,
                Character = data.Character,
                Name = data.Name or data.Character.Name,
                Dialog = data.Dialog,
            }
            print("[Yutong] PromptChat缓存", name, "ID=", data.ID)
        end)
    end
    prompt.OnClientEvent:Connect(function(...)
        local args = {...}
        for _, v in ipairs(args) do
            if type(v) == "table" then
                -- 可能是单条 {ID=x, Character=...} 或数组 {{ID=x,...}, {ID=y,...}}
                if type(v.ID) == "number" then
                    handleEntry(v)
                else
                    for _, entry in ipairs(v) do
                        handleEntry(entry)
                    end
                end
            end
        end
    end)
end)


local uiScale = Instance.new("UIScale")
uiScale.Name = "UIScale"
uiScale.Parent = main
uiScale.Scale = 1

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Parent = main
Frame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
Frame.Position = UDim2.new(0.08, 0, 0.38, 0)
Frame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
Frame.BackgroundTransparency = 0.04
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, px(14))
frameCorner.Parent = Frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Parent = Frame
frameStroke.Color = Color3.fromRGB(225, 198, 215)
frameStroke.Thickness = math.max(1, S * 1.2)
frameStroke.Transparency = 0.15

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Parent = Frame
menuButton.Position = UDim2.new(0, px(2), 0, px(2))
menuButton.Size = UDim2.new(0, px(18), 0, px(18))
menuButton.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
menuButton.BackgroundTransparency = 0.2
menuButton.BorderSizePixel = 0
menuButton.Text = ""
menuButton.AutoButtonColor = false
menuButton.ZIndex = 20
Instance.new("UICorner", menuButton).CornerRadius = UDim.new(0, px(4))

for i = 0, 2 do
	local line = Instance.new("Frame")
	line.Name = "Line_" .. i
	line.Parent = menuButton
	line.Size = UDim2.new(0, px(10), 0, px(1.5))
	line.Position = UDim2.new(0.5, -px(5), 0.5, -px(2) + i * px(3.5))
	line.BackgroundColor3 = Color3.fromRGB(145, 103, 134)
	line.BorderSizePixel = 0
	line.ZIndex = 21
end

local isEnlarged = true
uiScale.Scale = 1.5
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
menuButton.MouseButton1Click:Connect(function()
	isEnlarged = not isEnlarged
	if isEnlarged then
		uiScale.Scale = 1.5
		Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	else
		uiScale.Scale = 1
		Frame.AnchorPoint = Vector2.new(0, 0)
		Frame.Position = UDim2.new(0.08, 0, 0.38, 0)
	end
end)

local TextLabel = Instance.new("TextLabel")
TextLabel.Name = "Title"
TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1
TextLabel.Position = UDim2.new(0, px(22), 0, px(2))
TextLabel.Size = UDim2.new(0, px(60), 0, px(22))
TextLabel.Text = "Yutong"
TextLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
TextLabel.Font = Enum.Font.Cartoon
TextLabel.TextSize = px(18)
TextLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel")
SubTitle.Name = "SubTitle"
SubTitle.Parent = Frame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, px(22), 0, px(20))
SubTitle.Size = UDim2.new(0, px(90), 0, px(12))
SubTitle.Text = "Lumber Tycoon 2 Modded"
SubTitle.TextColor3 = Color3.fromRGB(173, 144, 163)
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextSize = px(7)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left


local mini = Instance.new("TextButton")
mini.Name = "minimize"
mini.Parent = Frame
mini.Position = UDim2.new(1, -px(50), 0, px(4))
mini.Size = UDim2.new(0, px(20), 0, px(20))
mini.BackgroundColor3 = Color3.fromRGB(215, 202, 232)
mini.BorderSizePixel = 0
mini.Text = "−"
mini.TextColor3 = Color3.fromRGB(110, 91, 130)
mini.Font = Enum.Font.GothamBold
mini.TextSize = px(12)
mini.ZIndex = 10
mini.AutoButtonColor = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(1, 0)

local closebutton = Instance.new("TextButton")
closebutton.Name = "Close"
closebutton.Parent = Frame
closebutton.Position = UDim2.new(1, -px(26), 0, px(4))
closebutton.Size = UDim2.new(0, px(20), 0, px(20))
closebutton.BackgroundColor3 = Color3.fromRGB(245, 179, 188)
closebutton.BorderSizePixel = 0
closebutton.Text = "×"
closebutton.TextColor3 = Color3.fromRGB(125, 75, 85)
closebutton.Font = Enum.Font.GothamBold
closebutton.TextSize = px(12)
closebutton.ZIndex = 10
closebutton.AutoButtonColor = false
Instance.new("UICorner", closebutton).CornerRadius = UDim.new(1, 0)

local TAB_NAMES = {"首页", "飞行", "传送", "购买", "木头", "其他", "调试"}
local TAB_COUNT = #TAB_NAMES
local TAB_WIDTH = px(40)
local TAB_HEIGHT = px(16)
local TAB_GAP = px(2)

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Parent = Frame
TabBar.BackgroundTransparency = 1
TabBar.Position = UDim2.new(0, px(4), 0, px(42))
TabBar.Size = UDim2.new(0, TAB_WIDTH, 0, TAB_COUNT * TAB_HEIGHT + (TAB_COUNT-1) * TAB_GAP)
TabBar.ZIndex = 5

local tabButtons = {}
local selectedTabIndex = 1
local selectTab

for i = 1, TAB_COUNT do
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = "Tab_" .. i
	tabBtn.Parent = TabBar
	tabBtn.Size = UDim2.new(0, TAB_WIDTH, 0, TAB_HEIGHT)
	tabBtn.Position = UDim2.new(0, 0, 0, (i-1) * (TAB_HEIGHT + TAB_GAP))
	tabBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(191, 226, 205) or Color3.fromRGB(230, 220, 228)
	tabBtn.BorderSizePixel = 0
	tabBtn.Text = TAB_NAMES[i]
	tabBtn.TextColor3 = (i == 1) and Color3.fromRGB(72, 108, 88) or Color3.fromRGB(145, 103, 134)
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = px(9)
	tabBtn.AutoButtonColor = false
	tabBtn.ZIndex = 6
	Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, px(4))
	tabButtons[i] = tabBtn

	tabBtn.MouseButton1Click:Connect(function()
		selectTab(i)
	end)
end

local CONTENT_LEFT = px(48)
local CONTENT_TOP = px(42)
local CONTENT_WIDTH = FRAME_W - CONTENT_LEFT - px(8)
local CONTENT_HEIGHT = px(126.5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = Frame
ContentContainer.Position = UDim2.new(0, CONTENT_LEFT, 0, CONTENT_TOP)
ContentContainer.Size = UDim2.new(0, CONTENT_WIDTH, 0, CONTENT_HEIGHT)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.ZIndex = 8

local pages = {}
for i = 1, TAB_COUNT do
	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. i
	page.Parent = ContentContainer
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Position = UDim2.new(0, 0, 0, 0)
	page.BackgroundTransparency = 1
	page.ClipsDescendants = true
	page.Visible = (i == 1)
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
	page.CanvasSize = UDim2.new(0, 0, 0, 400)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.BorderSizePixel = 0
	pages[i] = page
end

local speeds = 1
local nowe = false
local tpwalking = false
local currentBodyGyro = nil
local currentBodyVelocity = nil
local upConnection = nil
local downConnection = nil
local swimSoundConnections = {}

local lavaDeleteEnabled = false
local lavaDescendantAddedConn = nil

_G.WalkSpeed = _G.WalkSpeed or 16
_G.JumpPower = _G.JumpPower or 50
_G.Noclip = _G.Noclip or false
_G.AntiAFK = _G.AntiAFK or false
_G.SelfGlow = false
_G.AlwaysDay = false
_G.AlwaysNight = false
_G.NoShadow = false
_G.NoFog = false
_G.CameraFOV = 70

local selectMode = false
local selectedItems = {}
local teleportPoint = nil
local markerBall = nil
local selectionBoxes = {}
local itemNotifyFrame = nil

local function getItemModel(part)
	if not part then return nil end
	local current = part
	while current and current ~= Workspace do
		if current:IsA("Model") then
			if current:FindFirstChild("Owner") then
				return current
			end
			local nameLower = string.lower(current.Name)
			if string.find(nameLower, "axe") or string.find(nameLower, "box") or string.find(nameLower, "tool") or string.find(nameLower, "duck") then
				return current
			end
		end
		current = current.Parent
	end
	return nil
end

local function isOwnedByMe(item)
	if not item then return false end
	local owner = item:FindFirstChild("Owner")
	if owner then
		if owner:IsA("ObjectValue") and owner.Value == speaker then
			return true
		end
		if owner:IsA("StringValue") and owner.Value == speaker.Name then
			return true
		end
	end
	return false
end

local function isUnowned(item)
	if not item then return false end
	local owner = item:FindFirstChild("Owner")
	if not owner then return true end
	if owner:IsA("ObjectValue") and (owner.Value == nil) then return true end
	if owner:IsA("StringValue") and (owner.Value == "" or owner.Value == nil) then return true end
	return false
end

local function IsSwimSound(obj)
	if not obj:IsA("Sound") then return false end
	local n = string.lower(obj.Name)
	return string.find(n, "swim") or string.find(n, "splash") or string.find(n, "water") or string.find(n, "underwater")
end

local function MuteSwimmingSounds()
	local character = speaker.Character
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if IsSwimSound(obj) then
			obj.Volume = 0
			obj:Stop()
		end
	end
end

local function StartSwimmingSoundMute()
	MuteSwimmingSounds()
	local character = speaker.Character
	if not character then return end
	if swimSoundConnections.DescendantAdded then swimSoundConnections.DescendantAdded:Disconnect() end
	swimSoundConnections.DescendantAdded = character.DescendantAdded:Connect(function(obj)
		if IsSwimSound(obj) then obj.Volume = 0 obj:Stop() end
	end)
end

local function StopSwimmingSoundMute()
	if swimSoundConnections.DescendantAdded then
		swimSoundConnections.DescendantAdded:Disconnect()
		swimSoundConnections.DescendantAdded = nil
	end
end

local function RestoreHumanoidState(humanoid)
	if not humanoid then return end
	humanoid.PlatformStand = false
	for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
		humanoid:SetStateEnabled(state, true)
	end
	humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
end

local function CleanupFly()
	nowe = false
	tpwalking = false
	if upConnection then upConnection:Disconnect() upConnection = nil end
	if downConnection then downConnection:Disconnect() downConnection = nil end
	if currentBodyGyro then currentBodyGyro:Destroy() currentBodyGyro = nil end
	if currentBodyVelocity then currentBodyVelocity:Destroy() currentBodyVelocity = nil end
	StopSwimmingSoundMute()
	local character = speaker.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		RestoreHumanoidState(humanoid)
		humanoid.PlatformStand = false
		local animate = character:FindFirstChild("Animate")
		if animate then animate.Disabled = false end
		local Hum = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
		if Hum then
			for _, v in next, Hum:GetPlayingAnimationTracks() do v:AdjustSpeed(1) end
		end
	end
	if pages[2] and pages[2]:FindFirstChild("FlyToggle") then
		local btn = pages[2]:FindFirstChild("FlyToggle")
		btn.Text = "FLY"
		btn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
	end
end

local function StartFly()
	local character = speaker.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then return end

	nowe = true
	StartSwimmingSoundMute()

	local flyBtn = pages[2] and pages[2]:FindFirstChild("FlyToggle")
	if flyBtn then
		flyBtn.Text = "ON"
		flyBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
	end

	for i = 1, speeds do
		task.spawn(function()
			local hb = RunService.Heartbeat
			tpwalking = true
			local chr = speaker.Character
			local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
			while tpwalking and hb:Wait() and chr and hum and hum.Parent do
				if hum.MoveDirection.Magnitude > 0 then
					chr:TranslateBy(hum.MoveDirection)
				end
			end
		end)
	end

	local animate = character:FindFirstChild("Animate")
	if animate then animate.Disabled = true end

	local Hum = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
	if Hum then
		for _, v in next, Hum:GetPlayingAnimationTracks() do v:AdjustSpeed(0) end
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
	humanoid:ChangeState(Enum.HumanoidStateType.Swimming)

	local function startSuspensionLoop()
		local rigType = humanoid.RigType
		local part = nil
		if rigType == Enum.HumanoidRigType.R6 then
			part = character:FindFirstChild("Torso")
		else
			part = character:FindFirstChild("UpperTorso")
		end
		if not part then return end

		local bg = Instance.new("BodyGyro", part)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = part.CFrame
		currentBodyGyro = bg

		local bv = Instance.new("BodyVelocity", part)
		bv.velocity = Vector3.new(0, 0.1, 0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		currentBodyVelocity = bv

		if nowe == true then
			humanoid.PlatformStand = true
		end

		task.spawn(function()
			while nowe == true or (speaker.Character and speaker.Character.Humanoid and speaker.Character.Humanoid.Health == 0) do
				RunService.RenderStepped:Wait()
				local chr = speaker.Character
				local hum = chr and chr:FindFirstChildOfClass("Humanoid")
				if not chr or not hum or hum.Health <= 0 or not part.Parent then break end
				bv.velocity = Vector3.new(0, 0, 0)
				bg.cframe = workspace.CurrentCamera.CoordinateFrame
			end
			if currentBodyGyro == bg then currentBodyGyro = nil end
			if currentBodyVelocity == bv then currentBodyVelocity = nil end
			bg:Destroy()
			bv:Destroy()
			humanoid.PlatformStand = false
			local animate2 = character:FindFirstChild("Animate")
			if animate2 then animate2.Disabled = false end
			tpwalking = false
		end)
	end
	startSuspensionLoop()
end

local function IsLavaPart(part)
	if part and part:IsA("BasePart") then
		if part.Material == Enum.Material.Lava then return true end
		local n = string.lower(part.Name)
		return string.find(n, "lava") ~= nil
	end
	return false
end

local function RemoveAllLava()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if IsLavaPart(obj) then
			pcall(function() obj:Destroy() end)
		end
	end
	local terrain = Workspace.Terrain
	if terrain then
		pcall(function() terrain:ReplaceMaterial(Enum.Material.Lava, Enum.Material.Grass) end)
	end
end

local function StartLavaDelete()
	if lavaDeleteEnabled then return end
	lavaDeleteEnabled = true
	RemoveAllLava()
	lavaDescendantAddedConn = Workspace.DescendantAdded:Connect(function(desc)
		if IsLavaPart(desc) then
			pcall(function() desc:Destroy() end)
		end
	end)
end

local function StopLavaDelete()
	lavaDeleteEnabled = false
	if lavaDescendantAddedConn then
		lavaDescendantAddedConn:Disconnect()
		lavaDescendantAddedConn = nil
	end
end

local function createToggle(parent, positionX, positionY, initialState, onToggle)
	local toggleWidth = px(20)
	local toggleHeight = px(12)
	local knobSize = px(8)
	local knobPadding = px(2)

	local toggleBackground = Instance.new("TextButton")
	toggleBackground.Name = "Toggle"
	toggleBackground.Parent = parent
	toggleBackground.Position = UDim2.new(0, positionX, 0, positionY)
	toggleBackground.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	toggleBackground.BackgroundColor3 = initialState and Color3.fromRGB(76, 217, 100) or Color3.fromRGB(200, 200, 200)
	toggleBackground.BorderSizePixel = 0
	toggleBackground.AutoButtonColor = false
	toggleBackground.Text = ""
	Instance.new("UICorner", toggleBackground).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Parent = toggleBackground
	knob.Size = UDim2.new(0, knobSize, 0, knobSize)
	knob.Position = initialState and UDim2.new(0, toggleWidth - knobSize - knobPadding, 0, (toggleHeight - knobSize) / 2) or UDim2.new(0, knobPadding, 0, (toggleHeight - knobSize) / 2)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local isOn = initialState

	local function updateUI()
		toggleBackground.BackgroundColor3 = isOn and Color3.fromRGB(76, 217, 100) or Color3.fromRGB(200, 200, 200)
		if isOn then
			knob.Position = UDim2.new(0, toggleWidth - knobSize - knobPadding, 0, (toggleHeight - knobSize) / 2)
		else
			knob.Position = UDim2.new(0, knobPadding, 0, (toggleHeight - knobSize) / 2)
		end
	end

	toggleBackground.MouseButton1Click:Connect(function()
		isOn = not isOn
		updateUI()
		if onToggle then onToggle(isOn) end
	end)

	return {
		SetState = function(newState)
			isOn = newState
			updateUI()
		end,
		GetState = function() return isOn end
	}
end

local homePage
local RestoreCollisions
local selfGlowLight
local copyJobIdBtn
local jobIdBox
local joinJobBtn

do
homePage = pages[1]

local function createSlider(parent, label, minVal, maxVal, defaultVal, positionY, trackWidth)
	trackWidth = trackWidth or px(145)
	local labelText = Instance.new("TextLabel")
	labelText.Parent = parent
	labelText.BackgroundTransparency = 1
	labelText.Position = UDim2.new(0, px(4), 0, positionY)
	labelText.Size = UDim2.new(0, px(55), 0, px(12))
	labelText.Text = label
	labelText.TextColor3 = Color3.fromRGB(145, 103, 134)
	labelText.Font = Enum.Font.GothamBold
	labelText.TextSize = px(8)
	labelText.TextXAlignment = Enum.TextXAlignment.Left

	local valueButton = Instance.new("TextButton")
	valueButton.Parent = parent
	valueButton.BackgroundTransparency = 1
	valueButton.Position = UDim2.new(0, px(125), 0, positionY)
	valueButton.Size = UDim2.new(0, px(30), 0, px(12))
	valueButton.Text = tostring(defaultVal)
	valueButton.TextColor3 = Color3.fromRGB(72, 108, 88)
	valueButton.Font = Enum.Font.GothamBold
	valueButton.TextSize = px(8)
	valueButton.TextXAlignment = Enum.TextXAlignment.Left
	valueButton.AutoButtonColor = false

	local track = Instance.new("TextButton")
	track.Parent = parent
	track.Position = UDim2.new(0, px(4), 0, positionY + px(12))
	track.Size = UDim2.new(0, trackWidth, 0, px(4))
	track.BackgroundColor3 = Color3.fromRGB(220, 210, 218)
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Parent = track
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local function updateFromPosition(inputX)
		local trackAbsPos = track.AbsolutePosition
		local trackSizeX = track.AbsoluteSize.X
		local relX = math.clamp(inputX - trackAbsPos.X, 0, trackSizeX)
		local percent = relX / trackSizeX
		local val = minVal + percent * (maxVal - minVal)
		val = math.floor(val + 0.5)
		fill.Size = UDim2.new(0, relX, 1, 0)
		valueButton.Text = tostring(val)
		return val
	end

	track.MouseButton1Down:Connect(function()
		local mouseLocation = UserInputService:GetMouseLocation()
		updateFromPosition(mouseLocation.X)
		local con
		con = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromPosition(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				con:Disconnect()
			end
		end)
	end)

	local function startInput()
		local inputFrame = Instance.new("Frame")
		inputFrame.Name = "InputFrame"
		inputFrame.Parent = valueButton
		inputFrame.AnchorPoint = Vector2.new(0, 0.5)
		inputFrame.Position = UDim2.new(1.1, 0, 0.5, 0)
		inputFrame.Size = UDim2.new(0, px(50), 0, px(16))
		inputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inputFrame.BorderSizePixel = 1
		inputFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
		inputFrame.ZIndex = 30
		Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, px(4))

		local textBox = Instance.new("TextBox")
		textBox.Name = "InputBox"
		textBox.Parent = inputFrame
		textBox.AnchorPoint = Vector2.new(0.5, 0.5)
		textBox.Position = UDim2.new(0.5, 0, 0.5, 0)
		textBox.Size = UDim2.new(1, -px(6), 1, -px(4))
		textBox.BackgroundTransparency = 1
		textBox.Text = valueButton.Text
		textBox.TextColor3 = Color3.fromRGB(40, 40, 40)
		textBox.Font = Enum.Font.GothamBold
		textBox.TextSize = px(8)
		textBox.TextXAlignment = Enum.TextXAlignment.Center
		textBox.ZIndex = 31
		textBox.ClearTextOnFocus = false

		textBox.FocusLost:Connect(function(enterPressed)
			local newValue = tonumber(textBox.Text)
			if newValue then
				newValue = math.clamp(newValue, minVal, maxVal)
				valueButton.Text = tostring(newValue)
				local percent = (newValue - minVal) / (maxVal - minVal)
				fill.Size = UDim2.new(0, percent * track.AbsoluteSize.X, 1, 0)
			end
			inputFrame:Destroy()
		end)

		task.spawn(function()
			textBox:CaptureFocus()
		end)
	end

	valueButton.MouseButton1Click:Connect(startInput)

	return {
		GetValue = function() return tonumber(valueButton.Text) end,
		SetValue = function(val)
			val = math.clamp(val, minVal, maxVal)
			local percent = (val - minVal) / (maxVal - minVal)
			local relX = percent * track.AbsoluteSize.X
			fill.Size = UDim2.new(0, relX, 1, 0)
			valueButton.Text = tostring(val)
		end
	}
end

local walkSpeedSlider = createSlider(homePage, "人物速度", 1, 500, _G.WalkSpeed, px(2), px(145))
walkSpeedSlider.SetValue(_G.WalkSpeed)

local jumpPowerSlider = createSlider(homePage, "跳跃力度", 1, 1000, _G.JumpPower, px(22), px(145))
jumpPowerSlider.SetValue(_G.JumpPower)

local fovSlider = createSlider(homePage, "相机焦距", 1, 1000, _G.CameraFOV, px(42), px(145))
fovSlider.SetValue(_G.CameraFOV)

RunService.Heartbeat:Connect(function()
	_G.WalkSpeed = walkSpeedSlider.GetValue()
	_G.JumpPower = jumpPowerSlider.GetValue()
	_G.CameraFOV = fovSlider.GetValue()
	if workspace.CurrentCamera then
		workspace.CurrentCamera.FieldOfView = _G.CameraFOV
	end
end)

local TOGGLE_X = px(115)

local noclipBar = Instance.new("Frame")
noclipBar.Name = "NoclipBar"
noclipBar.Parent = homePage
noclipBar.Size = UDim2.new(1, -px(10), 0, px(16))
noclipBar.Position = UDim2.new(0, px(5), 0, px(64))
noclipBar.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
noclipBar.BorderSizePixel = 0
Instance.new("UICorner", noclipBar).CornerRadius = UDim.new(0, px(4))

local noclipLabel = Instance.new("TextLabel")
noclipLabel.Parent = noclipBar
noclipLabel.BackgroundTransparency = 1
noclipLabel.Position = UDim2.new(0, px(6), 0, 0)
noclipLabel.Size = UDim2.new(0, px(50), 1, 0)
noclipLabel.Text = "穿墙"
noclipLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
noclipLabel.Font = Enum.Font.GothamBold
noclipLabel.TextSize = px(8)
noclipLabel.TextXAlignment = Enum.TextXAlignment.Left
noclipLabel.TextYAlignment = Enum.TextYAlignment.Center

RestoreCollisions = function()
	local character = speaker.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

local noclipToggle = createToggle(noclipBar, TOGGLE_X, px(2), _G.Noclip, function(on)
	_G.Noclip = on
	if not on then
		RestoreCollisions()
	end
end)
noclipToggle.SetState(_G.Noclip)

local antiafkBar = Instance.new("Frame")
antiafkBar.Name = "AntiAFKBar"
antiafkBar.Parent = homePage
antiafkBar.Size = UDim2.new(1, -px(10), 0, px(16))
antiafkBar.Position = UDim2.new(0, px(5), 0, px(84))
antiafkBar.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
antiafkBar.BorderSizePixel = 0
Instance.new("UICorner", antiafkBar).CornerRadius = UDim.new(0, px(4))

local antiafkLabel = Instance.new("TextLabel")
antiafkLabel.Parent = antiafkBar
antiafkLabel.BackgroundTransparency = 1
antiafkLabel.Position = UDim2.new(0, px(6), 0, 0)
antiafkLabel.Size = UDim2.new(0, px(50), 1, 0)
antiafkLabel.Text = "防挂机"
antiafkLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
antiafkLabel.Font = Enum.Font.GothamBold
antiafkLabel.TextSize = px(8)
antiafkLabel.TextXAlignment = Enum.TextXAlignment.Left
antiafkLabel.TextYAlignment = Enum.TextYAlignment.Center

local antiafkToggle = createToggle(antiafkBar, TOGGLE_X, px(2), _G.AntiAFK, function(on)
	_G.AntiAFK = on
end)
antiafkToggle.SetState(_G.AntiAFK)

local glowBar = Instance.new("Frame")
glowBar.Parent = homePage
glowBar.Size = UDim2.new(1, -px(10), 0, px(16))
glowBar.Position = UDim2.new(0, px(5), 0, px(104))
glowBar.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
glowBar.BorderSizePixel = 0
Instance.new("UICorner", glowBar).CornerRadius = UDim.new(0, px(4))

local glowLabel = Instance.new("TextLabel")
glowLabel.Parent = glowBar
glowLabel.BackgroundTransparency = 1
glowLabel.Position = UDim2.new(0, px(6), 0, 0)
glowLabel.Size = UDim2.new(0, px(60), 1, 0)
glowLabel.Text = "自身发光"
glowLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
glowLabel.Font = Enum.Font.GothamBold
glowLabel.TextSize = px(8)
glowLabel.TextXAlignment = Enum.TextXAlignment.Left
glowLabel.TextYAlignment = Enum.TextYAlignment.Center

selfGlowLight = nil
local glowToggle = createToggle(glowBar, TOGGLE_X, px(2), false, function(on)
	_G.SelfGlow = on
	local character = speaker.Character
	if on then
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and not selfGlowLight then
				selfGlowLight = Instance.new("PointLight")
				selfGlowLight.Brightness = 2
				selfGlowLight.Range = 500
				selfGlowLight.Color = Color3.fromRGB(255, 240, 200)
				selfGlowLight.Parent = hrp
			end
		end
	else
		if selfGlowLight then
			selfGlowLight:Destroy()
			selfGlowLight = nil
		end
	end
end)

local dayNightBar = Instance.new("Frame")
dayNightBar.Parent = homePage
dayNightBar.Size = UDim2.new(1, -px(10), 0, px(16))
dayNightBar.Position = UDim2.new(0, px(5), 0, px(124))
dayNightBar.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
dayNightBar.BorderSizePixel = 0
Instance.new("UICorner", dayNightBar).CornerRadius = UDim.new(0, px(4))

local dayLabel = Instance.new("TextLabel")
dayLabel.Parent = dayNightBar
dayLabel.BackgroundTransparency = 1
dayLabel.Position = UDim2.new(0, px(4), 0, 0)
dayLabel.Size = UDim2.new(0, px(40), 1, 0)
dayLabel.Text = "白天"
dayLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
dayLabel.Font = Enum.Font.GothamBold
dayLabel.TextSize = px(8)
dayLabel.TextXAlignment = Enum.TextXAlignment.Left
dayLabel.TextYAlignment = Enum.TextYAlignment.Center

local dayToggle = createToggle(dayNightBar, px(42), px(2), false, function(on)
	_G.AlwaysDay = on
	if on then
		_G.AlwaysNight = false
		nightToggle.SetState(false)
		Lighting.ClockTime = 12
		Lighting.Brightness = 2
	end
end)

local nightLabel = Instance.new("TextLabel")
nightLabel.Parent = dayNightBar
nightLabel.BackgroundTransparency = 1
nightLabel.Position = UDim2.new(0, px(75), 0, 0)
nightLabel.Size = UDim2.new(0, px(40), 1, 0)
nightLabel.Text = "黑夜"
nightLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
nightLabel.Font = Enum.Font.GothamBold
nightLabel.TextSize = px(8)
nightLabel.TextXAlignment = Enum.TextXAlignment.Left
nightLabel.TextYAlignment = Enum.TextYAlignment.Center

local nightToggle = createToggle(dayNightBar, px(113), px(2), false, function(on)
	_G.AlwaysNight = on
	if on then
		_G.AlwaysDay = false
		dayToggle.SetState(false)
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.3
	end
end)

local shadowFogBar = Instance.new("Frame")
shadowFogBar.Parent = homePage
shadowFogBar.Size = UDim2.new(1, -px(10), 0, px(16))
shadowFogBar.Position = UDim2.new(0, px(5), 0, px(144))
shadowFogBar.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
shadowFogBar.BorderSizePixel = 0
Instance.new("UICorner", shadowFogBar).CornerRadius = UDim.new(0, px(4))

local shadowLabel = Instance.new("TextLabel")
shadowLabel.Parent = shadowFogBar
shadowLabel.BackgroundTransparency = 1
shadowLabel.Position = UDim2.new(0, px(4), 0, 0)
shadowLabel.Size = UDim2.new(0, px(50), 1, 0)
shadowLabel.Text = "除阴影"
shadowLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
shadowLabel.Font = Enum.Font.GothamBold
shadowLabel.TextSize = px(8)
shadowLabel.TextXAlignment = Enum.TextXAlignment.Left
shadowLabel.TextYAlignment = Enum.TextYAlignment.Center

local shadowToggle = createToggle(shadowFogBar, px(52), px(2), false, function(on)
	_G.NoShadow = on
	Lighting.GlobalShadows = not on
end)

local fogLabel = Instance.new("TextLabel")
fogLabel.Parent = shadowFogBar
fogLabel.BackgroundTransparency = 1
fogLabel.Position = UDim2.new(0, px(85), 0, 0)
fogLabel.Size = UDim2.new(0, px(35), 1, 0)
fogLabel.Text = "除雾"
fogLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
fogLabel.Font = Enum.Font.GothamBold
fogLabel.TextSize = px(8)
fogLabel.TextXAlignment = Enum.TextXAlignment.Left
fogLabel.TextYAlignment = Enum.TextYAlignment.Center

local fogToggle = createToggle(shadowFogBar, px(118), px(2), false, function(on)
	_G.NoFog = on
	if on then
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
	else
		Lighting.FogEnd = 1000
	end
end)

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Parent = homePage
rejoinBtn.Size = UDim2.new(1, -px(10), 0, px(18))
rejoinBtn.Position = UDim2.new(0, px(5), 0, px(224))
rejoinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 220)
rejoinBtn.BorderSizePixel = 0
rejoinBtn.Text = "重新加入服务器"
rejoinBtn.TextColor3 = Color3.fromRGB(90, 60, 110)
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = px(9)
rejoinBtn.AutoButtonColor = false
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, px(4))

rejoinBtn.MouseButton1Click:Connect(function()
	local placeId = game.PlaceId
	local jobId = game.JobId
	pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, speaker)
	end)
end)

local copyServerLinkBtn = Instance.new("TextButton")
copyServerLinkBtn.Parent = homePage
copyServerLinkBtn.Size = UDim2.new(1, -px(10), 0, px(18))
copyServerLinkBtn.Position = UDim2.new(0, px(5), 0, px(244))
copyServerLinkBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
copyServerLinkBtn.BorderSizePixel = 0
copyServerLinkBtn.Text = "复制服务器链接"
copyServerLinkBtn.TextColor3 = Color3.fromRGB(76, 116, 140)
copyServerLinkBtn.Font = Enum.Font.GothamBold
copyServerLinkBtn.TextSize = px(9)
copyServerLinkBtn.AutoButtonColor = false
Instance.new("UICorner", copyServerLinkBtn).CornerRadius = UDim.new(0, px(4))


local hopServerBtn = Instance.new("TextButton")
hopServerBtn.Parent = homePage
hopServerBtn.Size = UDim2.new(1, -px(10), 0, px(18))
hopServerBtn.Position = UDim2.new(0, px(5), 0, px(264))
hopServerBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 150)
hopServerBtn.BorderSizePixel = 0
hopServerBtn.Text = "Hop服务器(最少人)"
hopServerBtn.TextColor3 = Color3.fromRGB(140, 80, 40)
hopServerBtn.Font = Enum.Font.GothamBold
hopServerBtn.TextSize = px(9)
hopServerBtn.AutoButtonColor = false
Instance.new("UICorner", hopServerBtn).CornerRadius = UDim.new(0, px(4))

copyJobIdBtn = Instance.new("TextButton")
copyJobIdBtn.Parent = homePage
copyJobIdBtn.Size = UDim2.new(1, -px(10), 0, px(18))
copyJobIdBtn.Position = UDim2.new(0, px(5), 0, px(284))
copyJobIdBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
copyJobIdBtn.BorderSizePixel = 0
copyJobIdBtn.Text = "复制服务器ID"
copyJobIdBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
copyJobIdBtn.Font = Enum.Font.GothamBold
copyJobIdBtn.TextSize = px(9)
copyJobIdBtn.AutoButtonColor = false
Instance.new("UICorner", copyJobIdBtn).CornerRadius = UDim.new(0, px(4))

jobIdBox = Instance.new("TextBox")
jobIdBox.Parent = homePage
jobIdBox.Size = UDim2.new(0.62, -px(6), 0, px(18))
jobIdBox.Position = UDim2.new(0, px(5), 0, px(304))
jobIdBox.BackgroundColor3 = Color3.fromRGB(245, 240, 248)
jobIdBox.BorderSizePixel = 0
jobIdBox.Text = ""
jobIdBox.PlaceholderText = "输入服务器JobId"
jobIdBox.TextColor3 = Color3.fromRGB(90, 70, 100)
jobIdBox.Font = Enum.Font.Gotham
jobIdBox.TextSize = px(8)
jobIdBox.ClearTextOnFocus = false
Instance.new("UICorner", jobIdBox).CornerRadius = UDim.new(0, px(4))

joinJobBtn = Instance.new("TextButton")
joinJobBtn.Parent = homePage
joinJobBtn.Size = UDim2.new(0.38, -px(8), 0, px(18))
joinJobBtn.Position = UDim2.new(0.62, 0, 0, px(304))
joinJobBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
joinJobBtn.BorderSizePixel = 0
joinJobBtn.Text = "进入该服"
joinJobBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
joinJobBtn.Font = Enum.Font.GothamBold
joinJobBtn.TextSize = px(9)
joinJobBtn.AutoButtonColor = false
Instance.new("UICorner", joinJobBtn).CornerRadius = UDim.new(0, px(4))

copyServerLinkBtn.MouseButton1Click:Connect(function()
	local placeId = game.PlaceId
	local jobId = game.JobId
	-- 可加入同实例的 deep link
	local link = string.format("https://www.roblox.com/games/%s?gameInstanceId=%s", tostring(placeId), tostring(jobId))
	local okc = false
	pcall(function() if setclipboard then setclipboard(link) okc = true end end)
	pcall(function() if toclipboard then toclipboard(link) okc = true end end)
	if okc then
		copyServerLinkBtn.Text = "已复制!"
		pcall(function() notify("服务器链接已复制", "success") end)
		task.delay(1.2, function()
			copyServerLinkBtn.Text = "复制服务器链接"
		end)
	else
		copyServerLinkBtn.Text = "复制失败"
		print("[Yutong] Server link:", link)
		pcall(function() notify("无剪贴板，看Console", "warn") end)
		task.delay(1.5, function()
			copyServerLinkBtn.Text = "复制服务器链接"
		end)
	end
end)

local function httpGet(url)
	local body = nil
	pcall(function()
		if request then
			local r = request({Url = url, Method = "GET"})
			if r and (r.Success or r.StatusCode == 200) then
				body = r.Body or r.body
			end
		end
	end)
	if not body then
		pcall(function()
			if http_request then
				local r = http_request({Url = url, Method = "GET"})
				if r then body = r.Body or r.body end
			end
		end)
	end
	if not body then
		pcall(function()
			if syn and syn.request then
				local r = syn.request({Url = url, Method = "GET"})
				if r then body = r.Body or r.body end
			end
		end)
	end
	return body
end

local function hopLowestServer()
	local placeId = game.PlaceId
	local curJob = game.JobId
	notify("正在查找人数最少的服...", "info")
	local url = string.format(
		"https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
		tostring(placeId)
	)
	local body = httpGet(url)
	local bestId, bestPlayers = nil, math.huge
	if body and #body > 0 then
		pcall(function()
			local data = nil
			if game.GetService then
				local Hs = game:GetService("HttpService")
				data = Hs:JSONDecode(body)
			end
			if type(data) == "table" and type(data.data) == "table" then
				for _, s in ipairs(data.data) do
					local id = s.id or s.jobId
					local n = tonumber(s.playing) or tonumber(s.playerCount) or 99
					local maxn = tonumber(s.maxPlayers) or 0
					if id and tostring(id) ~= tostring(curJob) and n < bestPlayers then
						bestPlayers = n
						bestId = tostring(id)
					end
				end
			end
		end)
	end
	if bestId then
		notify(string.format("Hop → %d人服", bestPlayers), "success")
		hopServerBtn.Text = "传送中..."
		pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId, bestId, speaker)
		end)
		task.delay(3, function()
			hopServerBtn.Text = "Hop服务器(最少人)"
		end)
	else
		notify("列表失败，普通Hop", "warn")
		pcall(function()
			TeleportService:Teleport(placeId, speaker)
		end)
	end
end

hopServerBtn.MouseButton1Click:Connect(function()
	task.spawn(hopLowestServer)
end)
end

copyJobIdBtn.MouseButton1Click:Connect(function()
	local id = tostring(game.JobId)
	local okc = false
	pcall(function() if setclipboard then setclipboard(id) okc = true end end)
	pcall(function() if toclipboard then toclipboard(id) okc = true end end)
	if okc then
		copyJobIdBtn.Text = "已复制ID"
		notify("JobId已复制", "success")
		task.delay(1.2, function() copyJobIdBtn.Text = "复制服务器ID" end)
	else
		print("[Yutong] JobId:", id)
		notify("复制失败，看Console", "warn")
	end
end)

joinJobBtn.MouseButton1Click:Connect(function()
	local id = (jobIdBox.Text or ""):gsub("%s+", "")
	if id == "" then
		notify("请输入服务器JobId", "warn")
		return
	end
	notify("正在进入指定服...", "info")
	joinJobBtn.Text = "进入中..."
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, id, speaker)
	end)
	if not ok then
		notify("进入失败，检查ID", "error")
		joinJobBtn.Text = "进入该服"
	end
end)

-- ===== 夜晚检测 =====
local _wasNight = false
local function isGameNight()
	local t = Lighting.ClockTime
	-- LT2 常见：约 18~6 为夜
	return t >= 18 or t < 6
end
-- [memfix] 存句柄以便关闭时断开
local _nightHeartbeatConn
_nightHeartbeatConn = RunService.Heartbeat:Connect(function()
	if _G.AlwaysDay then
		Lighting.ClockTime = 12
	elseif _G.AlwaysNight then
		Lighting.ClockTime = 0
	end
	local night = isGameNight()
	if night and not _wasNight then
		-- 进入夜晚提示，持续 3.5 秒
		pcall(function()
			notify("已进入夜晚", "warn")
		end)
		-- 加一条更长显示的提示
		task.spawn(function()
			local card = Instance.new("TextLabel")
			card.Name = "NightWarn"
			card.Parent = main
			card.AnchorPoint = Vector2.new(0.5, 0)
			card.Position = UDim2.new(0.5, 0, 0.08, 0)
			card.Size = UDim2.new(0, px(180), 0, px(28))
			card.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
			card.BackgroundTransparency = 0.15
			card.Text = "夜晚到了"
			card.TextColor3 = Color3.fromRGB(200, 210, 255)
			card.Font = Enum.Font.GothamBold
			card.TextSize = px(12)
			card.ZIndex = 200
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, px(8))
			task.wait(3.5)
			if card and card.Parent then card:Destroy() end
		end)
	end
	_wasNight = night
end)


-- ===== 其他页共享函数（teleportOneItem 等）=====




local otherPage
local identifyMaterials
local BTN_H
local BTN_GAP
local currentY
local createOtherBtn
local teleportOneItem
local findOwnedItem
local findUnownedItem
local findUnownedDuckAngel
do
otherPage = pages[6]

local materialCode = {
	["老虎眼睛"] = "... . .",
	["普通鸭子"] = "-.-. -.-",
	["热可可"] = ".- .-. --",
	["鸡蛋"] = "--. .-. . .- -",
	["可乐"] = "... - -.--",
	["电池"] = ". .-.",
	["三叉戟"] = ".-..",
	["游戏机"] = "--- -.. .",
	["灯泡"] = "--. .... -",
	["神灯"] = ".. ... ....",
	["牛奶"] = "-.- .. . ...",
	["快乐球"] = "-.--",
}

local codeToMaterial = {}
for mat, code in pairs(materialCode) do
	if not codeToMaterial[code] then codeToMaterial[code] = {} end
	table.insert(codeToMaterial[code], mat)
end

identifyMaterials = function()
	local result = {}
	local texts = {}
	local stoneParts = Workspace:FindFirstChild("Stores") and Workspace.Stores:FindFirstChild("StoneRUs") and Workspace.Stores.StoneRUs:FindFirstChild("Parts")
	if stoneParts then
		for _, d in ipairs(stoneParts:GetDescendants()) do
			if d:IsA("TextLabel") then table.insert(texts, d.Text) end
		end
	end

	for i, v in ipairs(texts) do
		local bestMatch = nil
		local bestLength = 0
		for code, materials in pairs(codeToMaterial) do
			local codeLen = #code
			if codeLen > bestLength and string.sub(v, -codeLen) == code then
				bestLength = codeLen
				bestMatch = materials[1]
			end
		end
		result[i] = bestMatch or "未知"
	end

	if #result >= 4 then
		result[1], result[4] = result[4], result[1]
		result[2], result[3] = result[3], result[2]
	end
	return result
end

BTN_H = px(18)
BTN_GAP = px(4)
currentY = px(2)

createOtherBtn = function(name, text, color, textColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Parent = otherPage
	btn.Size = UDim2.new(1, -px(8), 0, BTN_H)
	btn.Position = UDim2.new(0, px(4), 0, currentY)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = textColor
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = px(9)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, px(4))
	currentY = currentY + BTN_H + BTN_GAP
	return btn
end

local materialButton = createOtherBtn("MaterialButton", "识别中...", Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101))

local function updateMaterialDisplay()
	local materials = identifyMaterials()
	local displayText = "恶魔鸭材料："
	if #materials >= 3 then
		displayText = displayText .. materials[1] .. " " .. materials[2] .. " " .. materials[3]
	else
		displayText = displayText .. "无法识别"
	end
	materialButton.Text = displayText
end

materialButton.MouseButton1Click:Connect(updateMaterialDisplay)
task.spawn(updateMaterialDisplay)

-- 统一拖拽传送（自动购买 / 选择传送 / 合成 共用）
-- ClientIsDragging 旧格式拖拽（与天堂鸭一致）
teleportOneItem = function(item, targetPos)
	local character = speaker.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or not item or not item.Parent then return false end

	if item:IsA("BasePart") and item.Parent:IsA("Model") then
		item = item.Parent
	end

	local itemCF
	if item:IsA("Model") then
		itemCF = item:GetPivot()
	elseif item:IsA("BasePart") then
		itemCF = item.CFrame
	else
		return false
	end

	local dragRemote = ReplicatedStorage:FindFirstChild("Interaction")
		and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
	if not dragRemote then return false end

	local key = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVW"
	local targetCF = CFrame.new(targetPos)

	-- 传送到物品旁边
	local pivot = item:IsA("Model") and item:GetPivot() or item.CFrame
	hrp.CFrame = pivot + Vector3.new(3, 0, 0)
	task.wait(0.1)

	-- 拖拽循环 0.9 秒
	local t0 = tick()
	while tick() - t0 < 0.9 do
		if not item.Parent then break end
		pcall(function()
			dragRemote:FireServer("Begin", item, 5)
			dragRemote:FireServer("Refresh", item, 5)
			dragRemote:FireServer("End", item, 5)
		end)
		if item:IsA("Model") then
			pcall(function() item:PivotTo(targetCF) end)
		elseif item:IsA("BasePart") then
			item.CFrame = targetCF
		end
		task.wait()
	end

	return true
end

findOwnedItem = function(name)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == name and isOwnedByMe(obj) then
			return obj
		end
	end
	return nil
end

findUnownedItem = function(name)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == name and isUnowned(obj) then
			return obj
		end
	end
	return nil
end

findUnownedDuckAngel = function()
	return findUnownedItem("DuckAngel")
end


end

-- ===== 全局收尾：selectTab、连接、mini2、closebutton =====



selectTab = function(index)
	if index < 1 or index > TAB_COUNT then return end
	selectedTabIndex = index

	for i, btn in ipairs(tabButtons) do
		if i == index then
			btn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
			btn.TextColor3 = Color3.fromRGB(72, 108, 88)
		else
			btn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
			btn.TextColor3 = Color3.fromRGB(145, 103, 134)
		end
	end

	for i, page in ipairs(pages) do
		page.Visible = (i == index)
	end
end

-- [memfix] 存句柄以便关闭时断开
local _walkSpeedHeartbeatConn
_walkSpeedHeartbeatConn = RunService.Heartbeat:Connect(function()
	local character = speaker.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = _G.WalkSpeed
			humanoid.JumpPower = _G.JumpPower
		end
	end
end)

-- [memfix] 存句柄以便关闭时断开
local _noclipSteppedConn
_noclipSteppedConn = RunService.Stepped:Connect(function()
	if _G.Noclip then
		local character = speaker.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end
end)

speaker.Idled:Connect(function()
	if _G.AntiAFK then
		pcall(function()
			VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	end
end)

local mini2 = Instance.new("TextButton")
mini2.Name = "minimize2"
mini2.Parent = main
mini2.Size = UDim2.new(0, 40, 0, 30)
mini2.Position = UDim2.new(0, 15, 0, 60)
mini2.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
mini2.BorderSizePixel = 0
mini2.Text = "Y"
mini2.TextColor3 = Color3.fromRGB(145, 105, 135)
mini2.Font = Enum.Font.Cartoon
mini2.TextSize = 18
mini2.Visible = false
mini2.Active = true
mini2.Draggable = true
Instance.new("UICorner", mini2).CornerRadius = UDim.new(0, 10)

mini.MouseButton1Click:Connect(function()
	Frame.Visible = false
	mini2.Visible = true
end)
mini2.MouseButton1Click:Connect(function()
	mini2.Visible = false
	Frame.Visible = true
end)

closebutton.MouseButton1Click:Connect(function()
	CleanupFly()
	StopLavaDelete()
	RestoreCollisions()
	-- [memfix] 断开所有永久连接
	if _nightHeartbeatConn then pcall(function() _nightHeartbeatConn:Disconnect() end) end
	if _walkSpeedHeartbeatConn then pcall(function() _walkSpeedHeartbeatConn:Disconnect() end) end
	if _noclipSteppedConn then pcall(function() _noclipSteppedConn:Disconnect() end) end
	main:Destroy()
end)

speaker.CharacterAdded:Connect(function(char)
	task.wait(0.7)
	if nowe then CleanupFly() end
	if _G.SelfGlow then
		local hrp = char:WaitForChild("HumanoidRootPart", 3)
		if hrp then
			if selfGlowLight then selfGlowLight:Destroy() end
			selfGlowLight = Instance.new("PointLight")
			selfGlowLight.Brightness = 2
			selfGlowLight.Range = 500
			selfGlowLight.Color = Color3.fromRGB(255, 240, 200)
			selfGlowLight.Parent = hrp
		end
	end
end)

print("[Yutong] UI loaded OK")
pcall(function()
	Frame.Visible = true
	main.Enabled = true
end)
pcall(function() notify("Yutong 已加载", "success") end)


-- ===== 暴露共享变量到 _G.V8 =====
V8.Players = Players
V8.RunService = RunService
V8.StarterGui = StarterGui
V8.UserInputService = UserInputService
V8.TweenService = TweenService
V8.Workspace = Workspace
V8.VirtualUser = VirtualUser
V8.ReplicatedStorage = ReplicatedStorage
V8.Lighting = Lighting
V8.TeleportService = TeleportService
V8.speaker = speaker
V8.PlayerGui = PlayerGui
V8.Mouse = Mouse
V8.notify = notify
V8.px = px
V8.getMoney = getMoney
V8.getUIScale = getUIScale
V8.getSwordFromWorld = getSwordFromWorld
V8.getBestSword = getBestSword
V8.main = main
V8.Frame = Frame
V8.TabBar = TabBar
V8.pages = pages
V8.tabButtons = tabButtons
V8.TAB_NAMES = TAB_NAMES
V8.TAB_COUNT = TAB_COUNT
V8.selectTab = selectTab
V8.createToggle = createToggle
V8.createSlider = createSlider
V8.CleanupFly = CleanupFly
V8.StartFly = StartFly
V8.IsLavaPart = IsLavaPart
V8.RemoveAllLava = RemoveAllLava
V8.StartLavaDelete = StartLavaDelete
V8.StopLavaDelete = StopLavaDelete
V8.RestoreCollisions = RestoreCollisions
V8.getItemModel = getItemModel
V8.isOwnedByMe = isOwnedByMe
V8.isUnowned = isUnowned
V8.nowe = nowe
V8.speeds = speeds
V8.tpwalking = tpwalking
V8.teleportPoint = teleportPoint
V8.markerBall = markerBall
V8.selectMode = selectMode
V8.selectedItems = selectedItems
V8.selectionBoxes = selectionBoxes
V8.itemNotifyFrame = itemNotifyFrame
V8.swimSoundConnections = swimSoundConnections
V8.lavaDeleteEnabled = lavaDeleteEnabled
V8.npcIdCache = npcIdCache
V8.npcCtxCache = npcCtxCache
V8.npcIdConfirmed = npcIdConfirmed
V8.serverIdOffset = serverIdOffset
V8.STORE_CN = STORE_CN
V8.STORE_BASE_ID = STORE_BASE_ID
V8.STORE_BASE_ID_ALT = STORE_BASE_ID_ALT
V8.storeDisplayName = storeDisplayName
V8.getStoreBaseIds = getStoreBaseIds
V8.candidateIdsForStore = candidateIdsForStore
V8.deepFindId = deepFindId
V8.listenDialogTraffic = listenDialogTraffic
V8.probeAllStoreNpcIds = probeAllStoreNpcIds
V8.currentMoney = currentMoney
V8.uiScale = uiScale
V8.S = S
V8.FRAME_W = FRAME_W
V8.FRAME_H = FRAME_H
V8.notifContainer = notifContainer
V8.otherPage = otherPage
V8.identifyMaterials = identifyMaterials
V8.BTN_H = BTN_H
V8.BTN_GAP = BTN_GAP
V8.currentY = currentY
V8.createOtherBtn = createOtherBtn
V8.teleportOneItem = teleportOneItem
V8.findOwnedItem = findOwnedItem
V8.findUnownedItem = findUnownedItem
V8.findUnownedDuckAngel = findUnownedDuckAngel
V8.getStoreCounter = getStoreCounter
V8.shopCatalog = shopCatalog
V8.selectedShopIndex = selectedShopIndex
V8.selectedProductIndex = selectedProductIndex
V8.buyQuantity = buyQuantity
V8.scanAllShops = scanAllShops
V8._G = _G

-- ===== 启动 =====
selectTab(1)
print("[Yutong] tabs=", TAB_COUNT, "pages=", #pages)

