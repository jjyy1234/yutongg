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

-- 授权用户检测（最先执行）
local AUTHORIZED_USERS = {
	["gccgbxfnb0"] = true,
      ["hxa1010"] = true,
	["gccgbxfnb4"] = true,
	["xiguayyds"] = true,
     ["xiaojun1221"] = true,

}
local _authPlayer = Players.LocalPlayer
if not AUTHORIZED_USERS[_authPlayer.Name] then
	_authPlayer:Kick("非授权用户")
	return
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
local FRAME_W = px(220)
local FRAME_H = px(160)

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

task.spawn(function()
	task.wait(1.5)
	pcall(probeAllStoreNpcIds)
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
local CONTENT_HEIGHT = px(110)

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

local homePage = pages[1]

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

local function RestoreCollisions()
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

local selfGlowLight = nil
local glowToggle = createToggle(glowBar, TOGGLE_X, px(2), false, function(on)
	_G.SelfGlow = on
	local character = speaker.Character
	if on then
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and not selfGlowLight then
				selfGlowLight = Instance.new("PointLight")
				selfGlowLight.Brightness = 2
				selfGlowLight.Range = 12
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

local copyJobIdBtn = Instance.new("TextButton")
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

local jobIdBox = Instance.new("TextBox")
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

local joinJobBtn = Instance.new("TextButton")
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

do
-- ===== 玩家透视 =====
local playerEspOn = false
local playerEspFolder = Instance.new("Folder")
playerEspFolder.Name = "YutongPlayerESP"
playerEspFolder.Parent = Workspace
local playerEspMap = {} -- [player] = {bb, distLabel, img}

local function clearPlayerEsp()
	for plr, data in pairs(playerEspMap) do
		pcall(function()
			if data.bb then data.bb:Destroy() end
		end)
		playerEspMap[plr] = nil
	end
	for _, ch in ipairs(playerEspFolder:GetChildren()) do
		pcall(function() ch:Destroy() end)
	end
end

local function makePlayerEsp(plr)
	if plr == speaker then return end
	if playerEspMap[plr] then return end
	local char = plr.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP_" .. plr.Name
	bb.Adornee = head
	bb.Size = UDim2.new(0, 90, 0, 70)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 2000
	bb.Parent = playerEspFolder

	local frame = Instance.new("Frame")
	frame.Parent = bb
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	local img = Instance.new("ImageLabel")
	img.Parent = frame
	img.Size = UDim2.new(0, 28, 0, 28)
	img.Position = UDim2.new(0.5, -14, 0, 4)
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	pcall(function()
		local content, isReady = Players:GetUserThumbnailAsync(
			plr.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
		img.Image = content
	end)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Parent = frame
	nameLbl.BackgroundTransparency = 1
	nameLbl.Position = UDim2.new(0, 2, 0, 32)
	nameLbl.Size = UDim2.new(1, -4, 0, 14)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 10
	nameLbl.TextColor3 = Color3.fromRGB(255, 230, 245)
	nameLbl.Text = plr.Name
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local distLbl = Instance.new("TextLabel")
	distLbl.Parent = frame
	distLbl.BackgroundTransparency = 1
	distLbl.Position = UDim2.new(0, 2, 0, 46)
	distLbl.Size = UDim2.new(1, -4, 0, 14)
	distLbl.Font = Enum.Font.Gotham
	distLbl.TextSize = 10
	distLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
	distLbl.Text = "..."

	playerEspMap[plr] = { bb = bb, dist = distLbl, img = img }
end

local function refreshPlayerEsp()
	if not playerEspOn then return end
	local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	local myPos = hrp and hrp.Position
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= speaker then
			if not playerEspMap[plr] or not playerEspMap[plr].bb or not playerEspMap[plr].bb.Parent then
				playerEspMap[plr] = nil
				makePlayerEsp(plr)
			else
				-- update adornee if respawned
				local head = plr.Character and plr.Character:FindFirstChild("Head")
				if head and playerEspMap[plr].bb.Adornee ~= head then
					playerEspMap[plr].bb.Adornee = head
				end
			end
			local data = playerEspMap[plr]
			if data and data.dist and myPos then
				local ohrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if ohrp then
					local d = (ohrp.Position - myPos).Magnitude
					data.dist.Text = string.format("%.0fm", d)
				else
					data.dist.Text = "..."
				end
			end
		end
	end
	-- remove left players
	for plr, data in pairs(playerEspMap) do
		if not plr.Parent then
			pcall(function() if data.bb then data.bb:Destroy() end end)
			playerEspMap[plr] = nil
		end
	end
end

Players.PlayerRemoving:Connect(function(plr)
	local data = playerEspMap[plr]
	if data then
		pcall(function() if data.bb then data.bb:Destroy() end end)
		playerEspMap[plr] = nil
	end
end)

local espToggleBtn = Instance.new("TextButton")
espToggleBtn.Parent = homePage
espToggleBtn.Size = UDim2.new(1, -px(10), 0, px(18))
espToggleBtn.Position = UDim2.new(0, px(5), 0, px(164))
espToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
espToggleBtn.BorderSizePixel = 0
espToggleBtn.Text = "玩家透视: 关"
espToggleBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
espToggleBtn.Font = Enum.Font.GothamBold
espToggleBtn.TextSize = px(9)
espToggleBtn.AutoButtonColor = false
Instance.new("UICorner", espToggleBtn).CornerRadius = UDim.new(0, px(4))

espToggleBtn.MouseButton1Click:Connect(function()
	playerEspOn = not playerEspOn
	if playerEspOn then
		espToggleBtn.Text = "玩家透视: 开"
		espToggleBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
		espToggleBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
		pcall(function() notify("玩家透视已开", "success") end)
		for _, plr in ipairs(Players:GetPlayers()) do
			makePlayerEsp(plr)
		end
	else
		espToggleBtn.Text = "玩家透视: 关"
		espToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
		espToggleBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
		clearPlayerEsp()
		pcall(function() notify("玩家透视已关", "info") end)
	end
end)

task.spawn(function()
	while main and main.Parent do
		if playerEspOn then
			pcall(refreshPlayerEsp)
		end
		task.wait(0.2)
	end
end)

-- ===== 传送到玩家 / 观察玩家 =====
local selectedTargetPlr = nil
local observing = false
local observeConn = nil
local savedCameraType = nil
local savedCameraSub = nil

local function getOtherPlayers()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= speaker then
			table.insert(t, p)
		end
	end
	table.sort(t, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	return t
end

local function stopObserve()
	observing = false
	if observeConn then
		pcall(function() observeConn:Disconnect() end)
		observeConn = nil
	end
	local cam = workspace.CurrentCamera
	if cam then
		pcall(function()
			if savedCameraType ~= nil then
				cam.CameraType = savedCameraType
			else
				cam.CameraType = Enum.CameraType.Custom
			end
			if savedCameraSub ~= nil then
				cam.CameraSubject = savedCameraSub
			else
				local hum = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
				if hum then cam.CameraSubject = hum end
			end
		end)
	end
	savedCameraType = nil
	savedCameraSub = nil
end

local function startObserve(plr)
	if not plr or plr == speaker then return end
	stopObserve()
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not hum and not head then
		notify("目标无角色", "warn")
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	savedCameraType = cam.CameraType
	savedCameraSub = cam.CameraSubject
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum or head
	observing = true
	notify("观察中: " .. plr.Name .. "（再点观察可停）", "success")
	observeConn = RunService.RenderStepped:Connect(function()
		if not observing then return end
		if not plr.Parent then
			stopObserve()
			notify("目标已离开", "warn")
			return
		end
		local c = plr.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local hd = c and c:FindFirstChild("Head")
		if cam and (h or hd) then
			cam.CameraSubject = h or hd
		end
	end)
end

local playerTargetBtn = Instance.new("TextButton")
playerTargetBtn.Parent = homePage
playerTargetBtn.Size = UDim2.new(1, -px(10), 0, px(18))
playerTargetBtn.Position = UDim2.new(0, px(5), 0, px(184))
playerTargetBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
playerTargetBtn.BorderSizePixel = 0
playerTargetBtn.Text = "目标玩家: 点选"
playerTargetBtn.TextColor3 = Color3.fromRGB(76, 116, 140)
playerTargetBtn.Font = Enum.Font.GothamBold
playerTargetBtn.TextSize = px(9)
playerTargetBtn.AutoButtonColor = false
Instance.new("UICorner", playerTargetBtn).CornerRadius = UDim.new(0, px(4))

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Parent = homePage
playerListFrame.Size = UDim2.new(1, -px(10), 0, px(70))
playerListFrame.Position = UDim2.new(0, px(5), 0, px(204))
playerListFrame.BackgroundColor3 = Color3.fromRGB(235, 230, 240)
playerListFrame.BorderSizePixel = 0
playerListFrame.Visible = false
playerListFrame.ZIndex = 40
playerListFrame.ScrollBarThickness = 3
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, px(4))
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Parent = playerListFrame
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Padding = UDim.new(0, 2)

local function rebuildPlayerList()
	for _, ch in ipairs(playerListFrame:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	local list = getOtherPlayers()
	for i, plr in ipairs(list) do
		local b = Instance.new("TextButton")
		b.Parent = playerListFrame
		b.Size = UDim2.new(1, -4, 0, 16)
		b.BackgroundTransparency = 1
		b.Text = plr.Name
		b.TextColor3 = Color3.fromRGB(90, 70, 100)
		b.Font = Enum.Font.GothamMedium
		b.TextSize = px(9)
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.ZIndex = 26
		b.MouseButton1Click:Connect(function()
			selectedTargetPlr = plr
			playerTargetBtn.Text = "目标: " .. plr.Name
			playerListFrame.Visible = false
			notify("已选目标: " .. plr.Name, "success")
		end)
	end
	playerListFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(1, #list) * 18)
	if #list == 0 then
		playerTargetBtn.Text = "目标玩家: 无其他玩家"
		notify("当前没有其他玩家", "warn")
	end
end

playerTargetBtn.MouseButton1Click:Connect(function()
	playerListFrame.Visible = not playerListFrame.Visible
	if playerListFrame.Visible then
		rebuildPlayerList()
	end
end)

-- 玩家进出自动刷新列表；打开时定时刷新
Players.PlayerAdded:Connect(function()
	if playerListFrame.Visible then
		task.defer(rebuildPlayerList)
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	if playerListFrame.Visible then
		task.defer(rebuildPlayerList)
	end
end)
task.spawn(function()
	while main and main.Parent do
		if playerListFrame.Visible then
			pcall(rebuildPlayerList)
		end
		task.wait(2)
	end
end)

local tpToPlayerBtn = Instance.new("TextButton")
tpToPlayerBtn.Parent = homePage
tpToPlayerBtn.Size = UDim2.new(0.5, -px(8), 0, px(18))
tpToPlayerBtn.Position = UDim2.new(0, px(5), 0, px(204))
tpToPlayerBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
tpToPlayerBtn.BorderSizePixel = 0
tpToPlayerBtn.Text = "传送到玩家"
tpToPlayerBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
tpToPlayerBtn.Font = Enum.Font.GothamBold
tpToPlayerBtn.TextSize = px(9)
tpToPlayerBtn.AutoButtonColor = false
Instance.new("UICorner", tpToPlayerBtn).CornerRadius = UDim.new(0, px(4))

tpToPlayerBtn.MouseButton1Click:Connect(function()
	local plr = selectedTargetPlr
	if not plr or not plr.Parent then
		notify("请先选择目标玩家", "warn")
		return
	end
	local ohrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if not ohrp or not hrp then
		notify("无法传送：缺少角色", "error")
		return
	end
	hrp.CFrame = ohrp.CFrame * CFrame.new(0, 0, 3)
	notify("已传到: " .. plr.Name, "success")
end)

local observeBtn = Instance.new("TextButton")
observeBtn.Parent = homePage
observeBtn.Size = UDim2.new(0.5, -px(8), 0, px(18))
observeBtn.Position = UDim2.new(0.5, px(2), 0, px(204))
observeBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
observeBtn.BorderSizePixel = 0
observeBtn.Text = "观察玩家"
observeBtn.TextColor3 = Color3.fromRGB(140, 100, 40)
observeBtn.Font = Enum.Font.GothamBold
observeBtn.TextSize = px(9)
observeBtn.AutoButtonColor = false
Instance.new("UICorner", observeBtn).CornerRadius = UDim.new(0, px(4))

observeBtn.MouseButton1Click:Connect(function()
	if observing then
		stopObserve()
		observeBtn.Text = "观察玩家"
		observeBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
		notify("已停止观察", "info")
		return
	end
	local plr = selectedTargetPlr
	if not plr or not plr.Parent then
		notify("请先选择目标玩家", "warn")
		return
	end
	startObserve(plr)
	observeBtn.Text = "停止观察"
	observeBtn.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
end)

Players.PlayerRemoving:Connect(function(plr)
	if selectedTargetPlr == plr then
		selectedTargetPlr = nil
		playerTargetBtn.Text = "目标玩家: 点选"
		if observing then
			stopObserve()
			observeBtn.Text = "观察玩家"
			observeBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
		end
	end
end)


end
local _wasNight = false
local function isGameNight()
	local t = Lighting.ClockTime
	-- LT2 常见：约 18~6 为夜
	return t >= 18 or t < 6
end
RunService.Heartbeat:Connect(function()
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

local flyPage = pages[2]

local flyToggle = Instance.new("TextButton")
flyToggle.Name = "FlyToggle"
flyToggle.Parent = flyPage
flyToggle.Size = UDim2.new(0, px(40), 0, px(20))
flyToggle.Position = UDim2.new(0, px(4), 0, px(4))
flyToggle.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
flyToggle.BorderSizePixel = 0
flyToggle.Text = "FLY"
flyToggle.TextColor3 = Color3.fromRGB(72, 108, 88)
flyToggle.Font = Enum.Font.GothamBold
flyToggle.TextSize = px(10)
flyToggle.AutoButtonColor = false
Instance.new("UICorner", flyToggle).CornerRadius = UDim.new(1, 0)
flyToggle.MouseButton1Click:Connect(function()
	if nowe then CleanupFly() else StartFly() end
end)

local soonButton = Instance.new("TextButton")
soonButton.Name = "SoonButton"
soonButton.Parent = flyPage
soonButton.Size = UDim2.new(0, px(50), 0, px(20))
soonButton.Position = UDim2.new(0, px(48), 0, px(4))
soonButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
soonButton.BorderSizePixel = 0
soonButton.Text = "即将开放"
soonButton.TextColor3 = Color3.fromRGB(120, 120, 120)
soonButton.Font = Enum.Font.GothamBold
soonButton.TextSize = px(8)
soonButton.AutoButtonColor = false
Instance.new("UICorner", soonButton).CornerRadius = UDim.new(1, 0)

local upBtn = Instance.new("TextButton")
upBtn.Name = "Up"
upBtn.Parent = flyPage
upBtn.Size = UDim2.new(0, px(26), 0, px(22))
upBtn.Position = UDim2.new(0, px(4), 0, px(28))
upBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
upBtn.BorderSizePixel = 0
upBtn.Text = "↑"
upBtn.TextColor3 = Color3.fromRGB(76, 116, 140)
upBtn.Font = Enum.Font.GothamBold
upBtn.TextSize = px(12)
upBtn.AutoButtonColor = false
Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, px(4))
upBtn.MouseButton1Down:Connect(function()
	if not nowe then return end
	upConnection = RunService.Heartbeat:Connect(function()
		local character = speaker.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then root.CFrame = root.CFrame * CFrame.new(0, 1, 0) end
	end)
end)
upBtn.MouseButton1Up:Connect(function()
	if upConnection then upConnection:Disconnect() upConnection = nil end
end)
upBtn.MouseLeave:Connect(function()
	if upConnection then upConnection:Disconnect() upConnection = nil end
end)

local downBtn = Instance.new("TextButton")
downBtn.Name = "Down"
downBtn.Parent = flyPage
downBtn.Size = UDim2.new(0, px(26), 0, px(22))
downBtn.Position = UDim2.new(0, px(32), 0, px(28))
downBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
downBtn.BorderSizePixel = 0
downBtn.Text = "↓"
downBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
downBtn.Font = Enum.Font.GothamBold
downBtn.TextSize = px(12)
downBtn.AutoButtonColor = false
Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, px(4))
downBtn.MouseButton1Down:Connect(function()
	if not nowe then return end
	downConnection = RunService.Heartbeat:Connect(function()
		local character = speaker.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then root.CFrame = root.CFrame * CFrame.new(0, -1, 0) end
	end)
end)
downBtn.MouseButton1Up:Connect(function()
	if downConnection then downConnection:Disconnect() downConnection = nil end
end)
downBtn.MouseLeave:Connect(function()
	if downConnection then downConnection:Disconnect() downConnection = nil end
end)

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Parent = flyPage
speedLabel.Size = UDim2.new(0, px(22), 0, px(22))
speedLabel.Position = UDim2.new(0, px(60), 0, px(28))
speedLabel.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
speedLabel.BorderSizePixel = 0
speedLabel.Text = tostring(speeds)
speedLabel.TextColor3 = Color3.fromRGB(147, 105, 75)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = px(10)
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
speedLabel.TextYAlignment = Enum.TextYAlignment.Center
Instance.new("UICorner", speedLabel).CornerRadius = UDim.new(0, px(4))

local minusBtn = Instance.new("TextButton")
minusBtn.Name = "Minus"
minusBtn.Parent = flyPage
minusBtn.Size = UDim2.new(0, px(18), 0, px(22))
minusBtn.Position = UDim2.new(0, px(84), 0, px(28))
minusBtn.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
minusBtn.BorderSizePixel = 0
minusBtn.Text = "−"
minusBtn.TextColor3 = Color3.fromRGB(146, 83, 101)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = px(12)
minusBtn.AutoButtonColor = false
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, px(4))
minusBtn.MouseButton1Click:Connect(function()
	if speeds <= 1 then
		speedLabel.Text = "MIN"
		task.wait(0.7)
		speedLabel.Text = tostring(speeds)
		return
	end
	speeds = speeds - 1
	speedLabel.Text = tostring(speeds)
	if nowe == true then
		tpwalking = false
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
	end
end)

local plusBtn = Instance.new("TextButton")
plusBtn.Name = "Plus"
plusBtn.Parent = flyPage
plusBtn.Size = UDim2.new(0, px(18), 0, px(22))
plusBtn.Position = UDim2.new(0, px(104), 0, px(28))
plusBtn.BackgroundColor3 = Color3.fromRGB(194, 231, 211)
plusBtn.BorderSizePixel = 0
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(74, 125, 94)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = px(12)
plusBtn.AutoButtonColor = false
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, px(4))
plusBtn.MouseButton1Click:Connect(function()
	speeds = speeds + 1
	speedLabel.Text = tostring(speeds)
	if nowe == true then
		tpwalking = false
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
	end
end)

local lavaButton = Instance.new("TextButton")
lavaButton.Name = "LavaToggle"
lavaButton.Parent = flyPage
lavaButton.Size = UDim2.new(1, -px(8), 0, px(20))
lavaButton.Position = UDim2.new(0, px(4), 0, px(54))
lavaButton.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
lavaButton.BorderSizePixel = 0
lavaButton.Text = "删除岩浆伤害"
lavaButton.TextColor3 = Color3.fromRGB(147, 105, 75)
lavaButton.Font = Enum.Font.GothamBold
lavaButton.TextSize = px(9)
lavaButton.AutoButtonColor = false
Instance.new("UICorner", lavaButton).CornerRadius = UDim.new(0, px(4))
lavaButton.MouseButton1Click:Connect(function()
	if lavaDeleteEnabled then
		StopLavaDelete()
		lavaButton.Text = "删除岩浆伤害"
		lavaButton.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
	else
		StartLavaDelete()
		lavaButton.Text = "恢复岩浆伤害"
		lavaButton.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
	end
end)

local teleportPage = pages[3]

local function findMyPropertyPosition()
	-- 查找属于自己的 Property 地皮中心
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("Folder") then
			local nameLower = string.lower(obj.Name)
			if string.find(nameLower, "property") or string.find(nameLower, "base") or string.find(nameLower, "plot") then
				local owner = obj:FindFirstChild("Owner")
				if owner then
					local isMine = false
					if owner:IsA("ObjectValue") and owner.Value == speaker then
						isMine = true
					elseif owner:IsA("StringValue") and owner.Value == speaker.Name then
						isMine = true
					end
					if isMine then
						local part = obj:FindFirstChildWhichIsA("BasePart", true)
						if part then
							return part.Position + Vector3.new(0, 5, 0)
						end
						local ok, pivot = pcall(function() return obj:GetPivot().Position end)
						if ok and pivot then
							return pivot + Vector3.new(0, 5, 0)
						end
					end
				end
			end
		end
	end
	-- 备用：常见 LT2 地皮结构
	local properties = Workspace:FindFirstChild("Properties")
	if properties then
		for _, prop in ipairs(properties:GetChildren()) do
			local owner = prop:FindFirstChild("Owner")
			if owner then
				local isMine = (owner:IsA("ObjectValue") and owner.Value == speaker)
					or (owner:IsA("StringValue") and owner.Value == speaker.Name)
				if isMine then
					local part = prop:FindFirstChildWhichIsA("BasePart", true)
					if part then return part.Position + Vector3.new(0, 5, 0) end
				end
			end
		end
	end
	return Vector3.new(188.8, 2.3, 56.6) -- 找不到就回出生点
end

local teleportLocations = {
	{ name = "1. 回家", pos = nil, isHome = true },
	{ name = "2. 出生点", pos = Vector3.new(188.8, 2.3, 56.6) },
	{ name = "3. 木材反斗城", pos = Vector3.new(266.7, 2.5, 57.8) },
	{ name = "4. 土地商店", pos = Vector3.new(263.0, 2.5, -98.2) },
	{ name = "5. VIP商店", pos = Vector3.new(907.7, 2.4, -92.3) },
	{ name = "6. 辐射商店", pos = Vector3.new(176.3, 11.5, -2639.3) },
	{ name = "7. 桥头商店", pos = Vector3.new(64.2, 2.4, -455.5) },
	{ name = "8. 核污染区", pos = Vector3.new(209.1, 13.5, -2758.7) },
	{ name = "9. 树苗摊位", pos = Vector3.new(-31.4, 16.7, -2717.7) },
	{ name = "10. 车店", pos = Vector3.new(483.0, 5.9, -1473.8) },
	{ name = "11. 沼泽商店", pos = Vector3.new(-1274.0, 130.9, -1443.0) },
	{ name = "12. 家具店", pos = Vector3.new(478.1, 4.9, -1725.4) },
	{ name = "13. 草坪商店", pos = Vector3.new(-566.5, 23.3, -120.8) },
	{ name = "14. 快递站", pos = Vector3.new(1894.6, -4.7, 1579.4) },
	{ name = "15. 雪山", pos = Vector3.new(1520.1, 412.6, 3284.3) },
	{ name = "16. 复仇剑合成点", pos = Vector3.new(6466.8, -95.6, -4540.0) },
	{ name = "17. 星空鸭合成点", pos = Vector3.new(-7063.9, 389.7, 4886.1) },
	{ name = "18. 三叉戟 永恒剑合成点", pos = Vector3.new(-373.8, 12.0, -1340.5) },
	{ name = "19. 恶魔鸭合成点", pos = Vector3.new(-224.2, 59.1, 924.8) },
	{ name = "20. 唱片商店", pos = Vector3.new(-436.2, 194.1, 1027.2) },
	{ name = "21. 地狱火合成点", pos = Vector3.new(-1778.2, 341.7, 1474.3) },
	{ name = "22. 天堂剑合成入口", pos = Vector3.new(-411.5, 21.3, -491.5) },
	{ name = "23. Doom勋章合成点", pos = Vector3.new(-1290.3, 21.7, -100.0) },
	{ name = "24. HL摊位", pos = Vector3.new(-925.2, -247.7, 65.7) },
	{ name = "25. Doom剑合成点", pos = Vector3.new(-1486.4, -248.3, 286.4) },
	{ name = "26. 石头商店", pos = Vector3.new(-2359.0, 302.3, -1853.1) },
	{ name = "27. 海边商店", pos = Vector3.new(6698.3, 2.5, -3563.8) },
	{ name = "28. 黑市", pos = Vector3.new(-83.1, 62.2, 1408.3) },
}

local selectedTeleportIndex = 1

local dropdownButton = Instance.new("TextButton")
dropdownButton.Name = "TeleportDropdown"
dropdownButton.Parent = teleportPage
dropdownButton.Size = UDim2.new(1, -px(8), 0, px(18))
dropdownButton.Position = UDim2.new(0, px(4), 0, px(4))
dropdownButton.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
dropdownButton.BorderSizePixel = 0
dropdownButton.Text = teleportLocations[selectedTeleportIndex].name
dropdownButton.TextColor3 = Color3.fromRGB(112, 91, 145)
dropdownButton.Font = Enum.Font.GothamBold
dropdownButton.TextSize = px(9)
dropdownButton.AutoButtonColor = false
Instance.new("UICorner", dropdownButton).CornerRadius = UDim.new(0, px(4))

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "DropdownList"
dropdownList.Parent = teleportPage
dropdownList.Size = UDim2.new(1, -px(8), 0, px(60))
dropdownList.Position = UDim2.new(0, px(4), 0, px(24))
dropdownList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
dropdownList.BorderSizePixel = 0
dropdownList.ScrollBarThickness = 3
dropdownList.ScrollBarImageColor3 = Color3.fromRGB(180, 160, 170)
dropdownList.CanvasSize = UDim2.new(0, 0, 0, #teleportLocations * 20)
dropdownList.Visible = false
dropdownList.ZIndex = 20
Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, px(4))

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = dropdownList
listLayout.Padding = UDim.new(0, 1)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

for i, loc in ipairs(teleportLocations) do
	local itemBtn = Instance.new("TextButton")
	itemBtn.Name = "Item_" .. i
	itemBtn.Parent = dropdownList
	itemBtn.Size = UDim2.new(1, 0, 0, 16)
	itemBtn.BackgroundTransparency = 1
	itemBtn.Text = loc.name
	itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
	itemBtn.Font = Enum.Font.GothamMedium
	itemBtn.TextSize = px(8)
	itemBtn.TextXAlignment = Enum.TextXAlignment.Left
	itemBtn.AutoButtonColor = false
	itemBtn.ZIndex = 21

	itemBtn.MouseButton1Click:Connect(function()
		selectedTeleportIndex = i
		dropdownButton.Text = loc.name
		dropdownList.Visible = false
	end)
end

dropdownButton.MouseButton1Click:Connect(function()
	dropdownList.Visible = not dropdownList.Visible
	if dropdownList.Visible then
		dropdownList.CanvasSize = UDim2.new(0, 0, 0, #teleportLocations * 20)
	end
end)

local teleportBtn = Instance.new("TextButton")
teleportBtn.Name = "TeleportButton"
teleportBtn.Parent = teleportPage
teleportBtn.Size = UDim2.new(1, -px(8), 0, px(18))
teleportBtn.Position = UDim2.new(0, px(4), 0, px(28))
teleportBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "传送选中地点"
teleportBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = px(9)
teleportBtn.AutoButtonColor = false
Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, px(4))

teleportBtn.MouseButton1Click:Connect(function()
	if nowe then CleanupFly() end
	local character = speaker.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local loc = teleportLocations[selectedTeleportIndex]
		local targetPos = loc.pos
		if loc.isHome then
			targetPos = findMyPropertyPosition()
		end
		if targetPos then
			rootPart.CFrame = CFrame.new(targetPos)
		end
		dropdownList.Visible = false
	end
end)

local itemTeleportLabel = Instance.new("TextLabel")
itemTeleportLabel.Name = "ItemTeleportLabel"
itemTeleportLabel.Parent = teleportPage
itemTeleportLabel.BackgroundTransparency = 1
itemTeleportLabel.Position = UDim2.new(0, px(4), 0, px(50))
itemTeleportLabel.Size = UDim2.new(1, -px(8), 0, px(12))
itemTeleportLabel.Text = "物品传送 (Owner: 自己)"
itemTeleportLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
itemTeleportLabel.Font = Enum.Font.GothamBold
itemTeleportLabel.TextSize = px(9)
itemTeleportLabel.TextXAlignment = Enum.TextXAlignment.Left

local setPointBtn = Instance.new("TextButton")
setPointBtn.Name = "SetPoint"
setPointBtn.Parent = teleportPage
setPointBtn.Size = UDim2.new(1, -px(8), 0, px(18))
setPointBtn.Position = UDim2.new(0, px(4), 0, px(64))
setPointBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
setPointBtn.BorderSizePixel = 0
setPointBtn.Text = "设置传送点"
setPointBtn.TextColor3 = Color3.fromRGB(76, 116, 140)
setPointBtn.Font = Enum.Font.GothamBold
setPointBtn.TextSize = px(9)
setPointBtn.AutoButtonColor = false
Instance.new("UICorner", setPointBtn).CornerRadius = UDim.new(0, px(4))

setPointBtn.MouseButton1Click:Connect(function()
	local character = speaker.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		pcall(function() notify("设置失败：无角色", "error") end)
		return
	end
	teleportPoint = rootPart.Position
	if markerBall then markerBall:Destroy() end
	markerBall = Instance.new("Part")
	markerBall.Name = "TeleportMarker"
	markerBall.Shape = Enum.PartType.Ball
	markerBall.Size = Vector3.new(1, 1, 1)
	markerBall.BrickColor = BrickColor.new("Bright blue")
	markerBall.Material = Enum.Material.Neon
	markerBall.Anchored = true
	markerBall.CanCollide = false
	markerBall.Position = teleportPoint
	markerBall.Parent = Workspace
	local p = teleportPoint
	pcall(function()
		notify(string.format("已设置传送点 (%.1f, %.1f, %.1f)", p.X, p.Y, p.Z), "success")
	end)
end)

local deletePointBtn = Instance.new("TextButton")
deletePointBtn.Name = "DeletePoint"
deletePointBtn.Parent = teleportPage
deletePointBtn.Size = UDim2.new(1, -px(8), 0, px(18))
deletePointBtn.Position = UDim2.new(0, px(4), 0, px(84))
deletePointBtn.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
deletePointBtn.BorderSizePixel = 0
deletePointBtn.Text = "删除传送点"
deletePointBtn.TextColor3 = Color3.fromRGB(146, 83, 101)
deletePointBtn.Font = Enum.Font.GothamBold
deletePointBtn.TextSize = px(9)
deletePointBtn.AutoButtonColor = false
Instance.new("UICorner", deletePointBtn).CornerRadius = UDim.new(0, px(4))

deletePointBtn.MouseButton1Click:Connect(function()
	teleportPoint = nil
	if markerBall then
		markerBall:Destroy()
		markerBall = nil
	end
	pcall(function() notify("已清除传送点", "info") end)
end)

local selectModeToggle = createToggle(teleportPage, px(4), px(104), false, function(on)
	selectMode = on
	pcall(function()
		notify(on and "选择模式：开 · 点击物品选中" or "选择模式：关", on and "success" or "info")
	end)
end)

local selectModeLabel = Instance.new("TextLabel")
selectModeLabel.Name = "SelectModeLabel"
selectModeLabel.Parent = teleportPage
selectModeLabel.BackgroundTransparency = 1
selectModeLabel.Position = UDim2.new(0, px(30), 0, px(104))
selectModeLabel.Size = UDim2.new(0, px(80), 0, px(12))
selectModeLabel.Text = "选择物品 (点击)"
selectModeLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
selectModeLabel.Font = Enum.Font.GothamBold
selectModeLabel.TextSize = px(8)
selectModeLabel.TextXAlignment = Enum.TextXAlignment.Left

local selectSameBtn = Instance.new("TextButton")
selectSameBtn.Name = "SelectSame"
selectSameBtn.Parent = teleportPage
selectSameBtn.Size = UDim2.new(1, -px(8), 0, px(18))
selectSameBtn.Position = UDim2.new(0, px(4), 0, px(124))
selectSameBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
selectSameBtn.BorderSizePixel = 0
selectSameBtn.Text = "选择同名物品"
selectSameBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
selectSameBtn.Font = Enum.Font.GothamBold
selectSameBtn.TextSize = px(9)
selectSameBtn.AutoButtonColor = false
Instance.new("UICorner", selectSameBtn).CornerRadius = UDim.new(0, px(4))

selectSameBtn.MouseButton1Click:Connect(function()
	if #selectedItems == 0 then
		pcall(function() notify("请先选中一件物品", "warn") end)
		return
	end
	local targetModel = selectedItems[1]
	if not targetModel or not targetModel:IsA("Model") then
		pcall(function() notify("选中无效", "warn") end)
		return
	end
	local targetName = targetModel.Name
	local added = 0
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == targetName and isOwnedByMe(obj) and not table.find(selectedItems, obj) then
			table.insert(selectedItems, obj)
			local sb = Instance.new("SelectionBox")
			sb.Adornee = obj
			sb.Color3 = Color3.fromRGB(0, 100, 255)
			sb.LineThickness = 0.05
			sb.Parent = obj
			table.insert(selectionBoxes, sb)
			added = added + 1
		end
	end
	local total = 0
	for _, it in ipairs(selectedItems) do
		if it and it.Name == targetName then total = total + 1 end
	end
	pcall(function()
		notify(string.format("同名「%s」新增 %d，合计 %d 个", targetName, added, total), "success")
	end)
end)

local clearSelectedBtn = Instance.new("TextButton")
clearSelectedBtn.Name = "ClearSelected"
clearSelectedBtn.Parent = teleportPage
clearSelectedBtn.Size = UDim2.new(1, -px(8), 0, px(18))
clearSelectedBtn.Position = UDim2.new(0, px(4), 0, px(144))
clearSelectedBtn.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
clearSelectedBtn.BorderSizePixel = 0
clearSelectedBtn.Text = "删除所有选中"
clearSelectedBtn.TextColor3 = Color3.fromRGB(146, 83, 101)
clearSelectedBtn.Font = Enum.Font.GothamBold
clearSelectedBtn.TextSize = px(9)
clearSelectedBtn.AutoButtonColor = false
Instance.new("UICorner", clearSelectedBtn).CornerRadius = UDim.new(0, px(4))

clearSelectedBtn.MouseButton1Click:Connect(function()
	local n = #selectedItems
	selectedItems = {}
	for _, sb in pairs(selectionBoxes) do sb:Destroy() end
	selectionBoxes = {}
	pcall(function() notify(n > 0 and ("已清空选中 " .. n .. " 件") or "没有选中物品", "info") end)
end)

local startTeleportItemsBtn = Instance.new("TextButton")
startTeleportItemsBtn.Name = "StartTeleportItems"
startTeleportItemsBtn.Parent = teleportPage
startTeleportItemsBtn.Size = UDim2.new(1, -px(8), 0, px(20))
startTeleportItemsBtn.Position = UDim2.new(0, px(4), 0, px(164))
startTeleportItemsBtn.BackgroundColor3 = Color3.fromRGB(194, 231, 211)
startTeleportItemsBtn.BorderSizePixel = 0
startTeleportItemsBtn.Text = "开始传送物品"
startTeleportItemsBtn.TextColor3 = Color3.fromRGB(74, 125, 94)
startTeleportItemsBtn.Font = Enum.Font.GothamBold
startTeleportItemsBtn.TextSize = px(10)
startTeleportItemsBtn.AutoButtonColor = false
Instance.new("UICorner", startTeleportItemsBtn).CornerRadius = UDim.new(0, px(4))

startTeleportItemsBtn.MouseButton1Click:Connect(function()
	print("[Yutong] 开始传送物品", "point=", teleportPoint ~= nil, "count=", #selectedItems)
	if not teleportPoint then
		pcall(function() notify("请先点「设置传送点」", "warn") end)
		return
	end
	if #selectedItems == 0 then
		pcall(function() notify("请先开选择模式并点击物品", "warn") end)
		return
	end

	selectMode = false -- 避免和点击冲突
	local character = speaker.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		pcall(function() notify("无角色", "error") end)
		return
	end
	local originalCF = hrp.CFrame
	local key = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVW"
	local dragRemote = ReplicatedStorage:FindFirstChild("Interaction")
		and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
	if not dragRemote then
		pcall(function() notify("无 ClientIsDragging", "error") end)
		return
	end

	pcall(function() notify("传送中 x" .. #selectedItems, "info") end)
	local moved = 0
	for idx = #selectedItems, 1, -1 do
		local item = selectedItems[idx]
		if item and item.Parent then
			if item:IsA("BasePart") and item.Parent:IsA("Model") then
				item = item.Parent
			end
			-- 与自动购买相同原理
			local okItem = false
			pcall(function()
				local itemCF = item:IsA("Model") and item:GetPivot() or item.CFrame
				hrp.CFrame = itemCF + Vector3.new(3, 0, 0)
				task.wait(0.12)
				local t0 = tick()
				while tick() - t0 < 0.7 do
					dragRemote:FireServer(item, key)
					local targetCF = CFrame.new(teleportPoint + Vector3.new(math.random(-0.2, 0.2), 0, math.random(-0.2, 0.2)))
					if item:IsA("Model") then
						item:PivotTo(targetCF)
					elseif item:IsA("BasePart") then
						item.CFrame = targetCF
					end
					task.wait()
				end
				okItem = true
			end)
			if okItem then
				moved = moved + 1
			else
				pcall(function() notify("失败: " .. tostring(item.Name), "warn") end)
			end
			for sbi, sb in ipairs(selectionBoxes) do
				if sb.Adornee == item or (item and sb.Adornee == item) then
					pcall(function() sb:Destroy() end)
					table.remove(selectionBoxes, sbi)
					break
				end
			end
			table.remove(selectedItems, idx)
			task.wait(0.08)
		else
			table.remove(selectedItems, idx)
		end
	end

	hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = originalCF end
	pcall(function() notify("传送完成 " .. moved .. " 件", moved > 0 and "success" or "warn") end)
	print("[Yutong] 传送完成", moved)
end)

Mouse.Button1Down:Connect(function()
	if not selectMode or not Mouse.Target then return end

	local targetPart = Mouse.Target
	local itemModel = getItemModel(targetPart)
	if not itemModel then
		pcall(function() notify("选不中：不是物品模型", "warn") end)
		return
	end
	if not isOwnedByMe(itemModel) then
		pcall(function() notify("选不中：不是你的「" .. itemModel.Name .. "」", "warn") end)
		return
	end
	if table.find(selectedItems, itemModel) then
		pcall(function() notify("已在列表中：" .. itemModel.Name, "info") end)
		return
	end

	table.insert(selectedItems, itemModel)

	local sb = Instance.new("SelectionBox")
	sb.Adornee = itemModel
	sb.Color3 = Color3.fromRGB(0, 100, 255)
	sb.LineThickness = 0.05
	sb.Parent = itemModel
	table.insert(selectionBoxes, sb)

	local same = 0
	for _, it in ipairs(selectedItems) do
		if it and it.Name == itemModel.Name then same = same + 1 end
	end
	pcall(function()
		if same > 1 then
			notify(string.format("选中「%s」· 同名共 %d 个 · 总选中 %d", itemModel.Name, same, #selectedItems), "success")
		else
			notify(string.format("选中「%s」· 总选中 %d", itemModel.Name, #selectedItems), "success")
		end
	end)

	if itemNotifyFrame then itemNotifyFrame:Destroy() end
	itemNotifyFrame = Instance.new("Frame")
	itemNotifyFrame.Parent = PlayerGui
	itemNotifyFrame.AnchorPoint = Vector2.new(1, 1)
	itemNotifyFrame.Position = UDim2.new(1, -10, 1, -10)
	itemNotifyFrame.Size = UDim2.new(0, 160, 0, 50)
	itemNotifyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	itemNotifyFrame.BackgroundTransparency = 0.1
	itemNotifyFrame.BorderSizePixel = 0
	Instance.new("UICorner", itemNotifyFrame).CornerRadius = UDim.new(0, 8)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Parent = itemNotifyFrame
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.Size = UDim2.new(1, -20, 0, 16)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "已选中物品"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Parent = itemNotifyFrame
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 10, 0, 24)
	nameLabel.Size = UDim2.new(1, -20, 0, 16)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = itemModel.Name
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	task.delay(2, function()
		if itemNotifyFrame then
			itemNotifyFrame:Destroy()
			itemNotifyFrame = nil
		end
	end)
end)




local otherPage = pages[5]

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

local function identifyMaterials()
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

local BTN_H = px(18)
local BTN_GAP = px(4)
local currentY = px(2)

local function createOtherBtn(name, text, color, textColor)
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
-- ClientIsDragging 声明拖拽 + PivotTo 改坐标
local function teleportOneItem(item, targetPos)
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

	hrp.CFrame = itemCF + Vector3.new(3, 0, 0)
	task.wait(0.12)

	local dragRemote = ReplicatedStorage:FindFirstChild("Interaction")
		and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
	local key = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVW"
	local startTime = tick()
	while tick() - startTime < 0.55 do
		if dragRemote then
			pcall(function() dragRemote:FireServer(item, key) end)
		end
		local targetCF = CFrame.new(targetPos + Vector3.new(math.random(-0.3, 0.3), 0, math.random(-0.3, 0.3)))
		if item:IsA("Model") then
			pcall(function() item:PivotTo(targetCF) end)
		elseif item:IsA("BasePart") then
			item.CFrame = targetCF
		end
		task.wait()
	end
	return true
end

local function findOwnedItem(name)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == name and isOwnedByMe(obj) then
			return obj
		end
	end
	return nil
end

local function findUnownedItem(name)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == name and isUnowned(obj) then
			return obj
		end
	end
	return nil
end

local function findUnownedDuckAngel()
	return findUnownedItem("DuckAngel")
end


-- ===================== 购买页：下拉选项 + 自动购买 =====================
local WOODRUS_COUNTER = Vector3.new(268.7, 5.2, 67.6)

local shopCatalog = {}
local selectedShopIndex = 1
local selectedProductIndex = 1
local buyQuantity = 1

local function getModelPos(model)
	if not model then return nil end
	local ok, piv = pcall(function() return model:GetPivot().Position end)
	if ok and piv then return piv end
	local p = model:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position
end

local function findCounterInStore(storeModel)
	if not storeModel then return WOODRUS_COUNTER end
	-- 固定柜台
	if storeModel.Name == "PlantomicsChoice" then
		return Vector3.new(189.2, 12.8, -2662.5)
	end
	local best, bestDist = nil, 9999
	local center = getModelPos(storeModel) or WOODRUS_COUNTER
	for _, obj in ipairs(storeModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = string.lower(obj.Name)
			if string.find(n, "counter") or string.find(n, "desk") or string.find(n, "checkout") or string.find(n, "table") then
				local d = (obj.Position - center).Magnitude
				if d < bestDist then
					bestDist = d
					best = obj
				end
			end
		end
	end
	if best then return best.Position end
	-- WoodRUs 已知柜台
	return center
end

local PRODUCT_CN = {
	["Battery"] = "电池", ["HappyBall"] = "快乐球", ["Egg"] = "鸡蛋",
	["NESController"] = "游戏机", ["MagicLamp"] = "神灯", ["LightBulb"] = "灯泡",
	["Duck"] = "普通鸭子", ["WhiteDuck"] = "普通鸭子",
	["Trident"] = "三叉戟", ["DemonTrident"] = "三叉戟",
	["Milk"] = "牛奶", ["Cola"] = "可乐", ["Soda"] = "可乐",
	["HotCocoa"] = "热可可", ["Cocoa"] = "热可可", ["TigerEye"] = "老虎眼睛",
	["BasicHatchet"] = "基础斧", ["BlurpleAxe"] = "蓝紫斧", ["AxeBlurple"] = "蓝紫斧",
	["HardenedAxe"] = "硬化斧", ["Sawmill"] = "锯木机",
	["4SeatTruck"] = "四座卡车", ["Truck"] = "卡车", ["Car"] = "车",
	["Box"] = "箱子", ["Crate"] = "板条箱", ["Wood"] = "木头", ["Plank"] = "木板",
	["Painting"] = "画", ["Chair"] = "椅子", ["Table"] = "桌子",
	["Wall"] = "墙", ["Floor"] = "地板", ["Door"] = "门",
	["Wire"] = "电线", ["Lever"] = "拉杆", ["Button"] = "按钮",
	["Sign"] = "牌子", ["Bag"] = "袋子", ["Seed"] = "种子", ["Sapling"] = "树苗",
	["Conveyor"] = "传送带", ["Vehicle"] = "载具",
}
local function productDisplayName(name)
	if PRODUCT_CN[name] then return PRODUCT_CN[name] end
	for en, cn in pairs(PRODUCT_CN) do
		if string.find(name, en, 1, true) then
			return cn .. "(" .. name .. ")"
		end
	end
	return name
end

local function scanAllShops()
	shopCatalog = {}
	local storesFolder = Workspace:FindFirstChild("Stores")
	if not storesFolder then
		storesFolder = Workspace:WaitForChild("Stores", 5)
	end
	if not storesFolder then
		warn("[Yutong] Workspace.Stores 不存在")
		pcall(function() notify("未找到 Stores", "error") end)
		return shopCatalog
	end

	print("[Yutong] 扫描商店 子项数=", #storesFolder:GetChildren())

	for _, store in ipairs(storesFolder:GetChildren()) do
		if store:IsA("Folder") or store:IsA("Model") then
			local products = {}
			local seenName = {}
			local shopItems = store:FindFirstChild("ShopItems")
				or store:FindFirstChild("Items")
				or store:FindFirstChild("Products")

			local function addModel(model)
				if not model or not model:IsA("Model") then return end
				local name = model.Name
				if name == "ShopItems" or name == "Items" or name == store.Name then return end
				if seenName[name] then return end
				-- 跳过 NPC（有 Dialog / Humanoid）
				if model:FindFirstChild("Dialog") or model:FindFirstChildOfClass("Humanoid") then
					return
				end
				seenName[name] = true
				local pos = getModelPos(model)
				if not pos then
					local part = model:FindFirstChildWhichIsA("BasePart", true)
					pos = part and part.Position or Vector3.new(0, 0, 0)
				end
				local disp = name
				pcall(function() disp = productDisplayName(name) end)
				table.insert(products, {
					name = name,
					display = disp,
					model = model,
					pos = pos,
				})
			end

			if shopItems then
				-- 直接子级 + 再下一层
				for _, child in ipairs(shopItems:GetChildren()) do
					if child:IsA("Model") then
						addModel(child)
					elseif child:IsA("Folder") then
						for _, sub in ipairs(child:GetChildren()) do
							if sub:IsA("Model") then addModel(sub) end
						end
					end
				end
				-- 兜底：ShopItems 下所有 Model
				if #products == 0 then
					for _, d in ipairs(shopItems:GetDescendants()) do
						if d:IsA("Model") and d.Parent == shopItems then
							addModel(d)
						elseif d:IsA("Model") and d.Parent and d.Parent.Parent == shopItems then
							addModel(d)
						end
					end
				end
				-- 再兜底：任意有 PrimaryPart/BasePart 的 Model
				if #products == 0 then
					for _, d in ipairs(shopItems:GetDescendants()) do
						if d:IsA("Model") then
							addModel(d)
						end
					end
				end
			else
				for _, child in ipairs(store:GetChildren()) do
					if child:IsA("Model") then addModel(child) end
				end
			end

			table.sort(products, function(a, b)
				return tostring(a.display or a.name) < tostring(b.display or b.name)
			end)

			local counterPos = WOODRUS_COUNTER
			pcall(function()
				if store.Name == "PlantomicsChoice" then
					counterPos = Vector3.new(189.2, 12.8, -2662.5)
				else
					counterPos = findCounterInStore(store) or WOODRUS_COUNTER
				end
			end)

			table.insert(shopCatalog, {
				name = store.Name,
				center = getModelPos(store) or counterPos,
				counterPos = counterPos,
				storeModel = store,
				products = products,
			})
			print("[Yutong] 店", store.Name, "商品", #products)
		end
	end

	table.sort(shopCatalog, function(a, b) return a.name < b.name end)
	print("[Yutong] 扫描完成 店=", #shopCatalog)
	return shopCatalog
end

task.spawn(function()
	local ok, err = pcall(function()
		local buyPage = pages[4]
		if not buyPage then error("pages[4] missing") end

		-- 清空旧内容
		for _, ch in ipairs(buyPage:GetChildren()) do
			ch:Destroy()
		end

		local status = Instance.new("TextLabel")
		status.Parent = buyPage
		status.BackgroundTransparency = 1
		status.Position = UDim2.new(0, px(4), 0, px(2))
		status.Size = UDim2.new(1, -px(8), 0, px(16))
		status.Text = "扫描中..."
		status.TextColor3 = Color3.fromRGB(145, 103, 134)
		status.Font = Enum.Font.GothamBold
		status.TextSize = px(8)
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.ZIndex = 5

		-- ===== 商店下拉（同传送页风格）=====
		local shopDropBtn = Instance.new("TextButton")
		shopDropBtn.Parent = buyPage
		shopDropBtn.Size = UDim2.new(1, -px(8), 0, px(18))
		shopDropBtn.Position = UDim2.new(0, px(4), 0, px(14))
		shopDropBtn.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
		shopDropBtn.BorderSizePixel = 0
		shopDropBtn.Text = "商店: 扫描中"
		shopDropBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
		shopDropBtn.Font = Enum.Font.GothamBold
		shopDropBtn.TextSize = px(9)
		shopDropBtn.AutoButtonColor = false
		shopDropBtn.ZIndex = 10
		Instance.new("UICorner", shopDropBtn).CornerRadius = UDim.new(0, px(4))

		local shopList = Instance.new("ScrollingFrame")
		shopList.Parent = buyPage
		shopList.Size = UDim2.new(1, -px(8), 0, px(50))
		shopList.Position = UDim2.new(0, px(4), 0, px(40))
		shopList.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
		shopList.BorderSizePixel = 0
		shopList.ScrollBarThickness = 3
		shopList.Visible = false
		shopList.ZIndex = 30
		Instance.new("UICorner", shopList).CornerRadius = UDim.new(0, px(4))
		local shopLayout = Instance.new("UIListLayout")
		shopLayout.Parent = shopList
		shopLayout.Padding = UDim.new(0, 1)
		shopLayout.SortOrder = Enum.SortOrder.LayoutOrder

		-- ===== 商品下拉 =====
		local prodDropBtn = Instance.new("TextButton")
		prodDropBtn.Parent = buyPage
		prodDropBtn.Size = UDim2.new(1, -px(8), 0, px(18))
		prodDropBtn.Position = UDim2.new(0, px(4), 0, px(40))
		prodDropBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
		prodDropBtn.BorderSizePixel = 0
		prodDropBtn.Text = "商品: 扫描中"
		prodDropBtn.TextColor3 = Color3.fromRGB(76, 116, 140)
		prodDropBtn.Font = Enum.Font.GothamBold
		prodDropBtn.TextSize = px(9)
		prodDropBtn.AutoButtonColor = false
		prodDropBtn.ZIndex = 10
		Instance.new("UICorner", prodDropBtn).CornerRadius = UDim.new(0, px(4))

		local prodList = Instance.new("ScrollingFrame")
		prodList.Parent = buyPage
		prodList.Size = UDim2.new(1, -px(8), 0, px(55))
		prodList.Position = UDim2.new(0, px(4), 0, px(62))
		prodList.BackgroundColor3 = Color3.fromRGB(230, 240, 248)
		prodList.BorderSizePixel = 0
		prodList.ScrollBarThickness = 3
		prodList.Visible = false
		prodList.ZIndex = 30
		Instance.new("UICorner", prodList).CornerRadius = UDim.new(0, px(4))
		local prodLayout = Instance.new("UIListLayout")
		prodLayout.Parent = prodList
		prodLayout.Padding = UDim.new(0, 1)
		prodLayout.SortOrder = Enum.SortOrder.LayoutOrder

		-- 数量 + 按钮
		local qtyBtn = Instance.new("TextButton")
		qtyBtn.Parent = buyPage
		qtyBtn.Size = UDim2.new(1/3, -px(6), 0, px(18))
		qtyBtn.Position = UDim2.new(0, px(4), 0, px(68))
		qtyBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
		qtyBtn.BorderSizePixel = 0
		qtyBtn.Text = "数量: 1"
		qtyBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
		qtyBtn.Font = Enum.Font.GothamBold
		qtyBtn.TextSize = px(9)
		qtyBtn.ZIndex = 10
		Instance.new("UICorner", qtyBtn).CornerRadius = UDim.new(0, px(4))

		local startBtn = Instance.new("TextButton")
		startBtn.Parent = buyPage
		startBtn.Size = UDim2.new(1/3, -px(6), 0, px(18))
		startBtn.Position = UDim2.new(1/3, px(2), 0, px(68))
		startBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
		startBtn.BorderSizePixel = 0
		startBtn.Text = "开始购买"
		startBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
		startBtn.Font = Enum.Font.GothamBold
		startBtn.TextSize = px(9)
		startBtn.ZIndex = 10
		Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, px(4))

		local rescanBtn = Instance.new("TextButton")
		rescanBtn.Parent = buyPage
		rescanBtn.Size = UDim2.new(1/3, -px(6), 0, px(18))
		rescanBtn.Position = UDim2.new(2/3, -px(6), 0, px(68))
		rescanBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
		rescanBtn.BorderSizePixel = 0
		rescanBtn.Text = "重扫"
		rescanBtn.TextColor3 = Color3.fromRGB(140, 100, 40)
		rescanBtn.Font = Enum.Font.GothamBold
		rescanBtn.TextSize = px(9)
		rescanBtn.ZIndex = 10
		Instance.new("UICorner", rescanBtn).CornerRadius = UDim.new(0, px(4))

		local buyHint = Instance.new("TextLabel")
		buyHint.Parent = buyPage
		buyHint.BackgroundTransparency = 1
		buyHint.Position = UDim2.new(0, px(4), 0, px(94))
		buyHint.Size = UDim2.new(1, -px(8), 0, px(28))
		buyHint.Text = "提示：首次购买调用函数时间稍长"
		buyHint.TextColor3 = Color3.fromRGB(160, 120, 100)
		buyHint.Font = Enum.Font.Gotham
		buyHint.TextSize = px(9)
		buyHint.TextWrapped = true
		buyHint.TextXAlignment = Enum.TextXAlignment.Left
		buyHint.ZIndex = 10

		-- 布局：下拉展开时把下面按钮下移会复杂，保持传送页同款重叠风格
		-- 默认商品下拉位置在商店下拉下方；打开商店列表时盖住
		prodDropBtn.Position = UDim2.new(0, px(4), 0, px(42))
		qtyBtn.Position = UDim2.new(0, px(4), 0, px(64))
		startBtn.Position = UDim2.new(0.32, px(2), 0, px(64))
		rescanBtn.Position = UDim2.new(0.70, 0, 0, px(64))
		prodList.Position = UDim2.new(0, px(4), 0, px(62))

		local function currentShop()
			return shopCatalog[selectedShopIndex]
		end
		local function currentProduct()
			local s = currentShop()
			return s and s.products[selectedProductIndex]
		end

		local function rebuildProductList()
			for _, ch in ipairs(prodList:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			local s = currentShop()
			if not s or #s.products == 0 then
				prodDropBtn.Text = "商品: (无)"
				selectedProductIndex = 1
				return
			end
			if selectedProductIndex > #s.products then selectedProductIndex = 1 end
			prodDropBtn.Text = "商品: " .. s.products[selectedProductIndex].name
			for i, pr in ipairs(s.products) do
				local itemBtn = Instance.new("TextButton")
				itemBtn.Parent = prodList
				itemBtn.Size = UDim2.new(1, 0, 0, 16)
				itemBtn.BackgroundTransparency = 1
				itemBtn.Text = pr.name
				itemBtn.TextColor3 = Color3.fromRGB(70, 90, 110)
				itemBtn.Font = Enum.Font.GothamMedium
				itemBtn.TextSize = px(8)
				itemBtn.TextXAlignment = Enum.TextXAlignment.Left
				itemBtn.ZIndex = 31
				itemBtn.MouseButton1Click:Connect(function()
					selectedProductIndex = i
					prodDropBtn.Text = "商品: " .. pr.name
					prodList.Visible = false
				end)
			end
			prodList.CanvasSize = UDim2.new(0, 0, 0, #s.products * 18)
		end

		local function shopLabel(s)
			local ok, text = pcall(function()
				local id = npcIdCache[s.name]
				if not id and npcCtxCache[s.name] then
					id = npcCtxCache[s.name].ID
				end
				if not id then
					local bases = {24}
					pcall(function() bases = getStoreBaseIds(s.name) end)
					id = (bases[1] or 24)
				end
				local nprod = s.products and #s.products or 0
				local disp = storeDisplayName(s.name)
				return string.format("%s ID:%s (%d)", disp, tostring(id), nprod)
			end)
			if ok then return text end
			return storeDisplayName(tostring(s and s.name or "?")) .. " (?)"
		end


		local function rebuildShopList()
			for _, ch in ipairs(shopList:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			for i, s in ipairs(shopCatalog) do
				local itemBtn = Instance.new("TextButton")
				itemBtn.Parent = shopList
				itemBtn.Size = UDim2.new(1, 0, 0, 16)
				itemBtn.BackgroundTransparency = 1
				itemBtn.Text = shopLabel(s)
				itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
				itemBtn.Font = Enum.Font.GothamMedium
				itemBtn.TextSize = px(10)
				itemBtn.TextXAlignment = Enum.TextXAlignment.Left
				itemBtn.ZIndex = 31
				itemBtn.MouseButton1Click:Connect(function()
					selectedShopIndex = i
					selectedProductIndex = 1
					shopDropBtn.Text = "商店: " .. shopLabel(s)
					shopList.Visible = false
					rebuildProductList()
				end)
			end
			shopList.CanvasSize = UDim2.new(0, 0, 0, math.max(1, #shopCatalog) * 18)
			if shopCatalog[selectedShopIndex] then
				shopDropBtn.Text = "商店: " .. shopLabel(shopCatalog[selectedShopIndex])
			end
			rebuildProductList()
		end

		shopDropBtn.MouseButton1Click:Connect(function()
			prodList.Visible = false
			shopList.Visible = not shopList.Visible
		end)
		prodDropBtn.MouseButton1Click:Connect(function()
			shopList.Visible = false
			prodList.Visible = not prodList.Visible
		end)
		qtyBtn.MouseButton1Click:Connect(function()
			buyQuantity = buyQuantity >= 10 and 1 or (buyQuantity + 1)
			qtyBtn.Text = "数量: " .. tostring(buyQuantity)
		end)

		local function doScan()
			status.Text = "扫描中..."
			pcall(function() notify("正在扫描商店...", "info") end)
			local okScan, errScan = pcall(scanAllShops)
			if not okScan then
				warn("[Yutong] scanAllShops", errScan)
				status.Text = "扫描出错: " .. tostring(errScan)
				pcall(function() notify("扫描失败", "error") end)
				return
			end
			selectedShopIndex = 1
			selectedProductIndex = 1
			local total = 0
			for _, s in ipairs(shopCatalog) do total = total + #s.products end
			local okR, errR = pcall(rebuildShopList)
			if not okR then
				warn("[Yutong] rebuildShopList", errR)
				status.Text = "列表错误: " .. tostring(errR)
				return
			end
			status.Text = string.format("店%d 商品%d · 选下拉后点开始购买", #shopCatalog, total)
			pcall(function() notify(string.format("扫描完成 店%d 商品%d", #shopCatalog, total), "success") end)
			print("[Yutong] doScan 店", #shopCatalog, "商品", total)
		end

		rescanBtn.MouseButton1Click:Connect(function()
			task.spawn(doScan)
		end)


		-- 使用启动时全局 npcIdCache / npcCtxCache

		local function findStoreNpc(store)
			if not store then return nil end
			for _, n in ipairs({"Thom", "NPC", "Shopkeeper", "Seller", "Clerk"}) do
				local t = store:FindFirstChild(n)
				if t then return t end
			end
			for _, c in ipairs(store:GetChildren()) do
				if c:FindFirstChild("Dialog") then return c end
			end
			return nil
		end

		local function scanNpcId(thom)
			if not thom then return nil end
			local dialog = thom:FindFirstChild("Dialog")
			for _, root in ipairs({ thom, dialog }) do
				if root then
					local idv = root:FindFirstChild("ID")
					if idv and idv:IsA("ValueBase") then
						return idv.Value
					end
					for _, d in ipairs(root:GetDescendants()) do
						if d.Name == "ID" and d:IsA("ValueBase") then
							return d.Value
						end
					end
				end
			end
			return nil
		end

		local function getThomContext(storeName)
			storeName = storeName or "WoodRUs"
			if npcCtxCache[storeName] and npcCtxCache[storeName].Character then
				local c = npcCtxCache[storeName]
				print("[Yutong] NPC上下文(缓存)", storeName, c.Name, "ID=", c.ID)
				return c, c.Character
			end
			local stores = Workspace:FindFirstChild("Stores")
			local store = stores and stores:FindFirstChild(storeName)
			local thom = findStoreNpc(store)
			if not thom then
				print("[Yutong] 商店无NPC:", storeName)
				return nil
			end
			local dialog = thom:FindFirstChild("Dialog")
			local id = scanNpcId(thom) or npcIdCache[storeName] or npcIdCache[thom.Name] or 24
			npcIdCache[storeName] = id
			local ctx = {
				Character = thom,
				Name = thom.Name,
				ID = id,
				Dialog = dialog,
			}
			npcCtxCache[storeName] = ctx
			print("[Yutong] NPC上下文", storeName, thom.Name, "ID=", id)
			return ctx, thom
		end

		local function resetChatState(storeName)
			pcall(function()
				local ctx = getThomContext(storeName or "WoodRUs")
				local npcDlg = ReplicatedStorage:FindFirstChild("NPCDialog")
				local playerChatted = npcDlg and npcDlg:FindFirstChild("PlayerChatted")
				local setVal = npcDlg and npcDlg:FindFirstChild("SetChattingValue")
				if ctx and playerChatted then
					pcall(function() playerChatted:InvokeServer(ctx, "EndChat") end)
				end
				task.wait(0.05)
				if setVal then
					pcall(function() setVal:InvokeServer(0) end)
				end
			end)
			pcall(function()
				local cg = PlayerGui:FindFirstChild("ChatGUI")
				if not cg then return end
				local chat = cg:FindFirstChild("Chat")
				if chat then
					local choices = chat:FindFirstChild("Choices")
					if choices then
						for _, c in ipairs(choices:GetChildren()) do
							pcall(function() c.Visible = false end)
						end
					end
					pcall(function() chat.Visible = false end)
				end
			end)
			pcall(function()
				local ig = PlayerGui:FindFirstChild("InteractionGUI")
				if ig then ig.Enabled = true end
			end)
		end

		local function moneyDropped(before)
			if type(before) ~= "number" then return false end
			local m = getMoney()
			return type(m) == "number" and m < before - 0.5
		end

		local function silentConfirmPurchase(storeName, moneyBefore)
			local ctx = getThomContext(storeName)
			if not ctx then
				print("[Yutong] 无 NPC 上下文")
				return false, nil
			end
			local npcDlg = ReplicatedStorage:FindFirstChild("NPCDialog")
			if not npcDlg then return false, nil end
			local playerChatted = npcDlg:FindFirstChild("PlayerChatted")
			local setVal = npcDlg:FindFirstChild("SetChattingValue")
			if not playerChatted then return false, nil end

			-- 刷新一次余额
			if type(moneyBefore) ~= "number" then
				moneyBefore = getMoney()
			end
			print("[Yutong] silentConfirm moneyBefore=", moneyBefore, "store=", storeName)

			local lastFunds = moneyBefore
			local fundsConn
			pcall(function()
				local tx = ReplicatedStorage:FindFirstChild("Transactions")
				local stc = tx and tx:FindFirstChild("ServerToClient")
				local fc = stc and stc:FindFirstChild("FundsChanged")
				if fc then
					fundsConn = fc.OnClientEvent:Connect(function(a, b)
						if type(a) == "number" then lastFunds = a currentMoney = a
						elseif type(b) == "number" then lastFunds = b currentMoney = b end
					end)
				end
			end)

			local function tryId(id)
				ctx.ID = id
				local function oneShot()
					print("[Yutong] 试 ID=", id, storeName, ctx.Name)
					local before = getMoney() or lastFunds or moneyBefore
					pcall(function()
						playerChatted:InvokeServer(ctx, "Initiate")
					end)
					task.wait(0.04)
					pcall(function()
						playerChatted:InvokeServer(ctx, "ConfirmPurchase")
					end)
					local hit = false
					local t0 = tick()
					while tick() - t0 < 0.25 do
						local m = getMoney() or lastFunds
						if type(before) == "number" and type(m) == "number" and m < before - 0.5 then
							hit = true
							break
						end
						task.wait(0.04)
					end
					pcall(function()
						if setVal then setVal:InvokeServer(2) end
					end)
					return hit, before
				end

				local hit, before = oneShot()
				if not hit then
					-- 失败：EndChat 清状态，同一 ID 再试一次
					print("[Yutong] ID", id, "未扣费，EndChat 后重试")
					pcall(function()
						playerChatted:InvokeServer(ctx, "EndChat")
					end)
					pcall(function()
						if setVal then setVal:InvokeServer(0) end
					end)
					task.wait(0.12)
					hit, before = oneShot()
				end

				if hit then
					npcIdCache[storeName] = id
					npcCtxCache[storeName] = {
						Character = ctx.Character,
						Name = ctx.Name,
						ID = id,
						Dialog = ctx.Dialog,
					}
					print("[Yutong] 命中 ID=", id, "余额", before, "->", getMoney() or lastFunds)
					return true
				end
				-- 两次都失败再关对话
				pcall(function()
					playerChatted:InvokeServer(ctx, "EndChat")
				end)
				pcall(function()
					if setVal then setVal:InvokeServer(0) end
				end)
				return false
			end

			-- 首次购买该店：试基础ID -2～+2；命中后锁定，之后只走缓存 ID
			local order2 = {}
			local seen2 = {}
			local function add2(id)
				if type(id) == "number" and id >= 1 and not seen2[id] then
					seen2[id] = true
					table.insert(order2, id)
				end
			end
			if npcIdConfirmed[storeName] and type(npcIdCache[storeName]) == "number" then
				add2(npcIdCache[storeName])
				print("[Yutong] 使用已锁定 ID=", npcIdCache[storeName], storeName)
			else
				for _, base in ipairs(getStoreBaseIds(storeName)) do
					for d = -2, 2 do
						add2(base + d)
					end
				end
				table.sort(order2, function(a, b)
					local bases = getStoreBaseIds(storeName)
					local base = bases[1] or 24
					return math.abs(a - base) < math.abs(b - base)
				end)
				print("[Yutong] 首次试ID -2～+2 共", #order2, "个", storeName, table.concat(order2, ","))
			end

			for _, id in ipairs(order2) do
				if tryId(id) then
					npcIdCache[storeName] = id
					npcIdConfirmed[storeName] = true
					pcall(function()
						if fundsConn then fundsConn:Disconnect() end
					end)
					print("[Yutong] 命中并锁定 ID=", id, storeName)
					pcall(function() notify(storeName .. " ID锁定:" .. tostring(id), "success") end)
					return true, id
				end
				pcall(function()
					playerChatted:InvokeServer(ctx, "EndChat")
				end)
				pcall(function()
					if setVal then setVal:InvokeServer(0) end
				end)
				task.wait(0.02)
			end
			pcall(function()
				if fundsConn then fundsConn:Disconnect() end
			end)
			print("[Yutong] 未扣费 store=", storeName, "money=", tostring(getMoney()))
			return false, nil
		end
		_G.YutongSilentConfirm = silentConfirmPurchase

		local buying = false
		startBtn.MouseButton1Click:Connect(function()
			print("[Yutong] 开始购买 clicked", "buying=", buying)
			pcall(function() notify("开始购买...", "info") end)
			if buying then
				-- 防止卡死：强制解锁
				print("[Yutong] 上次购买标记仍为 true，强制解锁")
				buying = false
				startBtn.Text = "开始购买"
			end
			local s = currentShop()
			local p = currentProduct()
			if not s then
				status.Text = "请选择商店"
				pcall(function() notify("请选择商店", "warn") end)
				return
			end
			if not p then
				status.Text = "请选择商品"
				pcall(function() notify("请选择商品", "warn") end)
				return
			end
			if type(teleportOneItem) ~= "function" then
				status.Text = "teleportOneItem 不可用"
				return
			end

			buying = true
			startBtn.Text = "购买中..."
			task.spawn(function()
				local okBuy, errBuy = pcall(function()
					local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
					local originCF = hrp and hrp.CFrame
					local counter = s.counterPos or s.center or WOODRUS_COUNTER
					if s.name == "PlantomicsChoice" then
						counter = Vector3.new(189.2, 12.8, -2662.5)
					end
					local successCount = 0

					local function resolveUnownedProduct()
						-- 始终找「当前无主」的同名商品，避免买完一次后还指着已有主模型
						if p.model and p.model.Parent and isUnowned(p.model) then
							return p.model
						end
						local name = p.name
						local store = s.storeModel
						local items = store and store:FindFirstChild("ShopItems")
						if items then
							for _, obj in ipairs(items:GetDescendants()) do
								if obj:IsA("Model") and obj.Name == name and isUnowned(obj) then
									return obj
								end
							end
						end
						for _, obj in ipairs(Workspace:GetDescendants()) do
							if obj:IsA("Model") and obj.Name == name and isUnowned(obj) then
								return obj
							end
						end
						return nil
					end

					for q = 1, buyQuantity do
						local model = resolveUnownedProduct()
						p.model = model
						if not model then
							status.Text = "无无主商品 " .. tostring(p.name)
							pcall(function() notify("没有可买的无主: " .. tostring(p.name), "warn") end)
							break
						end

						status.Text = string.format("%d/%d 传柜台", q, buyQuantity)
						teleportOneItem(model, counter)
						task.wait(0.15)

						hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							hrp.CFrame = CFrame.new(counter + Vector3.new(0, 3, 5), counter)
						end
						task.wait(0.12)

						status.Text = string.format("%d/%d 试ID购买", q, buyQuantity)
						local storeName = s.name or "WoodRUs"
						local moneyBefore = nil
						pcall(function() moneyBefore = getMoney() end)
						print("[Yutong] moneyBefore=", moneyBefore, "model=", model:GetFullName())
						local bought, hitId = false, nil
						local okSC, r1, r2 = pcall(function()
							return silentConfirmPurchase(storeName, moneyBefore)
						end)
						if okSC then
							bought, hitId = r1, r2
						else
							warn("[Yutong] silentConfirm", r1)
							status.Text = "购买函数错误"
						end
						local moneyAfter = getMoney()
						if type(moneyBefore) == "number" and type(moneyAfter) == "number" and moneyAfter < moneyBefore then
							bought = true
						end
						if not bought and model.Parent and not isUnowned(model) then
							bought = true
							print("[Yutong] 以归属变化判定成功")
						end
						print("[Yutong] bought=", bought, "hitId=", hitId)

						-- 无论成败，清对话，避免卡死下一单
						pcall(function()
							local npcDlg = ReplicatedStorage:FindFirstChild("NPCDialog")
							local playerChatted = npcDlg and npcDlg:FindFirstChild("PlayerChatted")
							local setVal = npcDlg and npcDlg:FindFirstChild("SetChattingValue")
							local ctx = getThomContext and getThomContext(storeName)
							if playerChatted and ctx then
								playerChatted:InvokeServer(ctx, "EndChat")
							end
							if setVal then setVal:InvokeServer(0) end
						end)

						if bought then
							successCount = successCount + 1
							pcall(function() notify("购买成功 " .. p.name, "success") end)
							if originCF then teleportOneItem(model, originCF.Position) end
							status.Text = string.format("成功 %d", successCount)
							-- 清空引用，下一件重新找无主
							p.model = nil
						else
							pcall(function() notify("购买失败 " .. p.name, "warn") end)
							status.Text = "本单未扣费"
							-- 失败也清引用，方便重试时重新解析
							p.model = nil
							break
						end
						task.wait(0.1)
					end

					hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
					if originCF and hrp then hrp.CFrame = originCF end
					status.Text = string.format("完成 %d/%d", successCount, buyQuantity)
				end)
				if not okBuy then
					status.Text = "错误: " .. tostring(errBuy)
					warn("[Yutong] buy error", errBuy)
					pcall(function() notify("购买出错", "error") end)
				end
				startBtn.Text = "开始购买"
				buying = false
				print("[Yutong] 购买流程结束 buying=false")
			end)
		end)


		doScan()
	end)
	if not ok then
		warn("[Yutong] 购买页失败: ", err)
	else
		print("[Yutong] 购买页 OK")
	end
end)


local function inputAngelDuckCode()
	local controller = Workspace:FindFirstChild("Stores")
		and Workspace.Stores:FindFirstChild("PlantomicsChoice")
		and Workspace.Stores.PlantomicsChoice:FindFirstChild("Parts")
		and Workspace.Stores.PlantomicsChoice.Parts:FindFirstChild("Controller")
		and Workspace.Stores.PlantomicsChoice.Parts.Controller:FindFirstChild("yes")

	if not controller then return false end

	local sequence = {"Up", "Up", "Down", "Down", "Left", "Right", "Left", "Right", "B", "A", "Start"}

	for _, name in ipairs(sequence) do
		local btn = controller:FindFirstChild(name)
		if btn then
			local detector = btn:FindFirstChildOfClass("ClickDetector")
			if detector then
				if fireclickdetector then
					fireclickdetector(detector)
				else
					pcall(function() detector:FireClick() end)
				end
			end
		end
		task.wait(0.10)
	end
	return true
end

do
local autoAngelDuckBtn = createOtherBtn("AutoAngelDuck", "自动获取天堂鸭", Color3.fromRGB(255, 200, 150), Color3.fromRGB(140, 80, 40))

autoAngelDuckBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoAngelDuckBtn.Text = "极速获取..."
		autoAngelDuckBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			autoAngelDuckBtn.Text = "自动获取天堂鸭"
			autoAngelDuckBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 150)
			return
		end

		local originalCF = hrp.CFrame
		local originalPos = hrp.Position

		hrp.CFrame = CFrame.new(188.7, 11.5, -2666.4)
		task.wait(0.28)

		local duck = findUnownedDuckAngel()
		if not duck then
			inputAngelDuckCode()
			-- 短轮询
			for _ = 1, 15 do
				duck = findUnownedDuckAngel()
				if duck then break end
				task.wait(0.12)
			end
		end

		if duck then
			autoAngelDuckBtn.Text = "拖回中..."
			-- 鸭子刚生成可能还在无主/模型会变，多试几次
			local brought = false
			for try = 1, 5 do
				local target = duck
				if not target or not target.Parent then
					target = findUnownedDuckAngel() or findOwnedItem("DuckAngel")
				end
				if target then
					local ok = false
					pcall(function()
						ok = teleportOneItem(target, originalPos)
					end)
					-- 兜底再拖一次更久
					if not ok or try <= 2 then
						pcall(function()
							local dragRemote = ReplicatedStorage:FindFirstChild("Interaction")
								and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
							local key = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVW"
							local h = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
							if h and target.Parent then
								local pivot = target:IsA("Model") and target:GetPivot() or target.CFrame
								h.CFrame = pivot + Vector3.new(3, 0, 0)
								task.wait(0.1)
								local t0 = tick()
								while tick() - t0 < 0.9 do
									if dragRemote then
										dragRemote:FireServer(target, key)
									end
									local cf = CFrame.new(originalPos + Vector3.new(math.random(-0.3,0.3), 0, math.random(-0.3,0.3)))
									if target:IsA("Model") then
										target:PivotTo(cf)
									end
									task.wait()
								end
							end
						end)
					end
					brought = true
					duck = target
					break
				end
				task.wait(0.15)
			end
			hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = originalCF end
			if brought then
				autoAngelDuckBtn.Text = "已获取！"
				autoAngelDuckBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
				notify("天堂鸭获取并拖回", "success")
			else
				notify("获取到了但拖回失败，请手动拖", "warn")
				autoAngelDuckBtn.Text = "拖回失败"
			end
			task.wait(0.6)
		else
			if hrp then hrp.CFrame = originalCF end
			notify("天堂鸭未出现", "warn")
		end

		autoAngelDuckBtn.Text = "自动获取天堂鸭"
		autoAngelDuckBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 150)
	end)
end)

-- 无作用测试按钮
local autoDemonDuckTestBtn = createOtherBtn("AutoDemonDuckTest", "自动合成恶魔鸭", Color3.fromRGB(180, 100, 100), Color3.fromRGB(90, 30, 30))
autoDemonDuckTestBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		local btn = autoDemonDuckTestBtn
		btn.Text = "识别材料..."
		btn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			btn.Text = "无角色"
			task.wait(0.45)
			btn.Text = "自动合成恶魔鸭"
			btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
			return
		end
		local originalCF = hrp.CFrame

		-- 材料名 → 可能的物品名（中英）
		local alias = {
			["电池"] = {"Battery", "电池"},
			["快乐球"] = {"HappyBall", "快乐球"},
			["鸡蛋"] = {"Egg", "鸡蛋"},
			["神灯"] = {"MagicLamp", "神灯"},
			["普通鸭子"] = {"Duck"},
			["鸭子"] = {"Duck"},
			["老虎眼睛"] = {"Eye3"},
			["老虎眼"] = {"Eye3"},
			["热可可"] = {"HotCocoa", "热可可", "Cocoa"},
			["可乐"] = {"Cola", "可乐", "Soda"},
			["三叉戟"] = {"Trident", "三叉戟", "DemonTrident"},
			["游戏机"] = {"NESController", "游戏机", "GameConsole", "NES"},
			["灯泡"] = {"LightBulb"},
			["牛奶"] = {"Milk", "牛奶"},
		}

local placePos = {
	Vector3.new(-224.01, 58.40, 940.58),
	Vector3.new(-232.82, 58.40, 933.19),
	Vector3.new(-241.93, 58.40, 925.54),
}

		local mats = identifyMaterials()
		local need = {}
		for i = 1, 3 do
			if mats[i] and mats[i] ~= "未知" then
				table.insert(need, mats[i])
			end
		end
		if #need < 3 then
			btn.Text = "材料识别失败"
			notify("恶魔鸭材料识别失败", "warn")
			task.wait(0.68)
			btn.Text = "自动合成恶魔鸭"
			btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
			return
		end
		print("[Yutong] 恶魔鸭材料", need[1], need[2], need[3])
		notify(string.format("材料: %s / %s / %s", need[1], need[2], need[3]), "info")

		-- 禁止材料：有则整单拒绝
		local forbidden = {
			["三叉戟"] = true,
			["可乐"] = true,
		}
		local bad = {}
		for _, m in ipairs(need) do
			if forbidden[m] then
				table.insert(bad, m)
			elseif type(m) == "string" then
				if m:find("三叉戟") or m:find("可乐") then
					table.insert(bad, m)
				end
			end
		end
		if #bad > 0 then
			local msg = "拒绝合成，所需材料有: " .. table.concat(bad, "、")
			print("[Yutong]", msg)
			btn.Text = "已拒绝"
			notify(msg, "error")
			task.wait(0.90)
			btn.Text = "自动合成恶魔鸭"
			btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
			return
		end

		local function matchName(itemName, matName)
			local list = alias[matName] or { matName }
			local low = string.lower(itemName)
			for _, a in ipairs(list) do
				if itemName == a or low == string.lower(a) then return true end
				if string.find(low, string.lower(a), 1, true) then return true end
			end
			return false
		end

		local function findOwnedMat(matName)
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and isOwnedByMe(obj) and matchName(obj.Name, matName) then
					return obj
				end
			end
			-- 别名精确找
			local list = alias[matName] or { matName }
			for _, n in ipairs(list) do
				local it = findOwnedItem(n)
				if it then return it end
			end
			return nil
		end

		local function findShopProduct(matName)
			local stores = Workspace:FindFirstChild("Stores")
			if not stores then return nil, nil end
			for _, store in ipairs(stores:GetChildren()) do
				local items = store:FindFirstChild("ShopItems")
				if items then
					for _, it in ipairs(items:GetChildren()) do
						if matchName(it.Name, matName) and isUnowned(it) then
							return it, store.Name
						end
					end
					-- 深层
					for _, it in ipairs(items:GetDescendants()) do
						if it:IsA("Model") and matchName(it.Name, matName) and isUnowned(it) then
							return it, store.Name
						end
					end
				end
			end
			return nil, nil
		end

		local function buyOne(matName)
			local prod, storeName = findShopProduct(matName)
			if not prod then
				print("[Yutong] 商店无此商品", matName)
				pcall(function() notify("商店无: " .. matName, "warn") end)
				return nil
			end
			storeName = storeName or "WoodRUs"
			btn.Text = "购买 " .. matName
			pcall(function() notify("购买 " .. matName .. " @" .. storeName, "info") end)

			-- 柜台：与购买页同一套
			local counter = Vector3.new(268.7, 5.2, 67.6)
			if storeName == "PlantomicsChoice" then
				counter = Vector3.new(189.2, 12.8, -2662.5)
			elseif _G.YutongGetCounter then
				local okc, cpos = pcall(_G.YutongGetCounter, storeName)
				if okc and cpos then counter = cpos end
			else
				pcall(function()
					local store = Workspace.Stores and Workspace.Stores:FindFirstChild(storeName)
					if store and findCounterInStore then
						counter = findCounterInStore(store) or counter
					end
				end)
			end

			print("[Yutong] 恶魔鸭购买", matName, storeName, counter)
			teleportOneItem(prod, counter)
			task.wait(0.08)
			hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(counter + Vector3.new(0, 3, 5), counter)
			end
			task.wait(0.05)

			local moneyBefore = getMoney()
			local bought, hitId = false, nil

			-- 优先调用购买页同一套 silentConfirm（含 ID -2～+2）
			if type(_G.YutongSilentConfirm) == "function" then
				local ok, a, b = pcall(_G.YutongSilentConfirm, storeName, moneyBefore)
				if ok then
					bought, hitId = a, b
				else
					warn("[Yutong] SilentConfirm err", a)
				end
			end

			-- 兜底：本地复制同一试 ID 逻辑
			if not bought then
				local npcDlg = ReplicatedStorage:FindFirstChild("NPCDialog")
				local playerChatted = npcDlg and npcDlg:FindFirstChild("PlayerChatted")
				local setVal = npcDlg and npcDlg:FindFirstChild("SetChattingValue")
				local store = Workspace.Stores and Workspace.Stores:FindFirstChild(storeName)
				local thom = nil
				if store then
					for _, c in ipairs(store:GetChildren()) do
						if c:FindFirstChild("Dialog") and c.Name ~= "ShopItems" then
							thom = c
							break
						end
					end
				end
				if playerChatted and thom then
					local bases = {24}
					pcall(function() bases = getStoreBaseIds(storeName) end)
					local ids, seen = {}, {}
					local function add(id)
						if type(id) == "number" and not seen[id] then
							seen[id] = true
							table.insert(ids, id)
						end
					end
					if npcIdConfirmed[storeName] and type(npcIdCache[storeName]) == "number" then
						add(npcIdCache[storeName])
					else
						for _, base in ipairs(bases) do
							for d = -2, 2 do add(base + d) end
						end
						table.sort(ids, function(a, b)
							local base = bases[1] or 24
							return math.abs(a - base) < math.abs(b - base)
						end)
					end
					local ctx = {
						Character = thom,
						Name = thom.Name,
						ID = bases[1] or 24,
						Dialog = thom:FindFirstChild("Dialog"),
					}
					for _, id in ipairs(ids) do
						ctx.ID = id
						local before = getMoney() or moneyBefore
						pcall(function() playerChatted:InvokeServer(ctx, "Initiate") end)
						task.wait(0.05)
						pcall(function() playerChatted:InvokeServer(ctx, "ConfirmPurchase") end)
						local t0 = tick()
						while tick() - t0 < 0.22 do
							local m = getMoney()
							if type(before) == "number" and type(m) == "number" and m < before - 0.5 then
								bought, hitId = true, id
								npcIdCache[storeName] = id
								npcIdConfirmed[storeName] = true
								break
							end
							task.wait(0.05)
						end
						pcall(function()
							playerChatted:InvokeServer(ctx, "EndChat")
							if setVal then setVal:InvokeServer(0) end
						end)
						if bought then break end
						task.wait(0.05)
					end
				end
			end

			if bought then
				pcall(function() notify("已购 " .. matName .. (hitId and (" ID:" .. hitId) or ""), "success") end)
			else
				pcall(function() notify("购买失败 " .. matName, "warn") end)
			end
			task.wait(0.11)
			return findOwnedMat(matName)
		end

		local owned = {}
		local function isDuckMat(matName)
			if not matName then return false end
			return matName == "普通鸭子" or matName == "鸭子" or matName == "Duck"
				or (type(matName) == "string" and matName:find("鸭子"))
		end
		for i, matName in ipairs(need) do
			btn.Text = "查找 " .. matName
			local item = nil
			if isDuckMat(matName) then
				item = findOwnedItem("Duck")
				if not item then
					btn.Text = "缺自己的Duck"
					notify("需要自己的 Duck，不购买鸭子", "error")
					task.wait(0.9)
					btn.Text = "自动合成恶魔鸭"
					btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
					hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
					if hrp then hrp.CFrame = originalCF end
					return
				end
			else
				item = findOwnedMat(matName)
				if not item then
					btn.Text = "购买 " .. matName
					notify("缺少 " .. matName .. "，尝试购买", "warn")
					item = buyOne(matName)
				end
			end
			if not item then
				btn.Text = "缺材料:" .. matName
				notify("无法获得 " .. matName, "error")
				task.wait(0.68)
				btn.Text = "自动合成恶魔鸭"
				btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
				hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = originalCF end
				return
			end
			owned[i] = item
			print("[Yutong] 材料就绪", matName, item:GetFullName())
		end

		-- 记录当前无主 DuckEvil（只带回新出现的）
		local function snapshotUnownedDuckEvil()
			local set = {}
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and (obj.Name == "DuckEvil" or obj.Name == "DuckEvil ") then
					if isUnowned(obj) then
						set[obj] = true
					end
				end
			end
			return set
		end
		local beforeDucks = snapshotUnownedDuckEvil()
		local beforeCount = 0
		for _ in pairs(beforeDucks) do beforeCount = beforeCount + 1 end
		print("[Yutong] 初始无主DuckEvil数", beforeCount)

		-- 放置到合成点（稍慢，保证落稳）
		pcall(function() notify("传送材料到祭坛", "info") end)
		for i = 1, 3 do
			btn.Text = string.format("放置%d", i)
			teleportOneItem(owned[i], placePos[i])
			task.wait(0.2)
		end

		local altarPos = Vector3.new(-224.2, 59.1, 924.8)
		task.wait(0.35)

		-- 玩家到各材料旁再开盒（放慢，否则 Open box 无效）
		local function selectThenOpen(m, label)
			if not m then return false end
			local inter = ReplicatedStorage:FindFirstChild("Interaction")
			local clientInteracted = inter and inter:FindFirstChild("ClientInteracted")
			local clientDragging = inter and inter:FindFirstChild("ClientIsDragging")
			local DRAG_KEY = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVW"
			if not clientInteracted then return false end
			local target = m
			pcall(function()
				if not target.Parent then
					local pm = Workspace:FindFirstChild("PlayerModels")
					if pm then
						for _, c in ipairs(pm:GetChildren()) do
							if c:IsA("Model") and isOwnedByMe(c) and c.Name == m.Name then
								target = c
								break
							end
						end
					end
				end
			end)
			print("[Yutong] 选中+开盒", label or "", target:GetFullName())
			pcall(function()
				if clientDragging then clientDragging:FireServer(target, DRAG_KEY) end
			end)
			task.wait(0.2)
			pcall(function()
				if clientDragging then clientDragging:FireServer(target, DRAG_KEY) end
			end)
			task.wait(0.25)
			pcall(function()
				clientInteracted:FireServer(target, "Open box")
			end)
			task.wait(0.2)
			pcall(function()
				clientInteracted:FireServer(target, "Open box")
			end)
			task.wait(0.25)
			return true
		end

		btn.Text = "开盒..."
		for i = 1, 3 do
			local pos = placePos[i]
			hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			if hrp and pos then
				hrp.CFrame = CFrame.new(pos + Vector3.new(2, 2.5, 2), pos)
			end
			task.wait(0.2)
			selectThenOpen(owned[i], need[i] or ("材料"..i))
			task.wait(0.35)
		end

		-- 监测新出现的无主 DuckEvil
		local function findNewDuckEvil()
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and obj.Name == "DuckEvil" and isUnowned(obj) then
					if not beforeDucks[obj] then
						return obj
					end
				end
			end
			return nil
		end

		local function waitNewDuck(seconds)
			local newDuck = nil
			local t0 = tick()
			while tick() - t0 < seconds do
				newDuck = findNewDuckEvil()
				if newDuck then return newDuck end
				task.wait(0.1)
			end
			return findNewDuckEvil()
		end

		-- 开盒后先监测 1.2 秒
		btn.Text = "监测1.2s..."
		pcall(function() notify("监测无主DuckEvil 1.2秒", "info") end)
		local newDuck = waitNewDuck(1.2)

		-- 没有则重新放置材料（不开盒），再监测 1 秒
		if not newDuck then
			btn.Text = "重放材料..."
			pcall(function() notify("未出鸭，重新执行放置(步骤5，不开盒)", "warn") end)
			for i = 1, 3 do
				if owned[i] and owned[i].Parent then
					teleportOneItem(owned[i], placePos[i])
					task.wait(0.12)
				end
			end
			btn.Text = "再监测1.2s..."
			pcall(function() notify("重放后监测 1.2 秒", "info") end)
			newDuck = waitNewDuck(1.2)
		end

		if newDuck then
			btn.Text = "带回新恶魔鸭"
			teleportOneItem(newDuck, originalCF.Position)
			notify("新恶魔鸭已带回", "success")
			btn.Text = "合成成功"
			btn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
		else
			notify("仍无新DuckEvil，返回原地", "warn")
			btn.Text = "无新鸭子"
			btn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
		end
		task.wait(0.35)
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = originalCF end
		btn.Text = "自动合成恶魔鸭"
		btn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
	end)
end)

-- 自动合成Doom核心
local autoLunarDuckBtn = createOtherBtn("AutoLunarDuck", "自动合成星空鸭", Color3.fromRGB(180, 200, 255), Color3.fromRGB(50, 70, 140))

autoLunarDuckBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoLunarDuckBtn.Text = "进行中..."
		autoLunarDuckBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local duckAngel = findOwnedItem("DuckAngel")
		local duck = findOwnedItem("Duck")
		local duckEvil = findOwnedItem("DuckEvil")

		if not duckAngel or not duck or not duckEvil then
			autoLunarDuckBtn.Text = "材料不足"
			notify("星空鸭材料不足", "warn")
			task.wait(1.2)
			autoLunarDuckBtn.Text = "自动合成星空鸭"
			autoLunarDuckBtn.BackgroundColor3 = Color3.fromRGB(180, 200, 255)
			return
		end

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local originalPos = hrp and hrp.Position

		teleportOneItem(duckAngel, Vector3.new(-7041.8, 391.3, 4906.3))
		task.wait(0.25)
		teleportOneItem(duck, Vector3.new(-7066.7, 391.4, 4898.7))
		task.wait(0.25)
		teleportOneItem(duckEvil, Vector3.new(-7091.9, 391.4, 4890.9))
		task.wait(0.8)

		local lunar = findUnownedItem("LunarDuck")
		if lunar and originalPos then
			teleportOneItem(lunar, originalPos)
		end

		autoLunarDuckBtn.Text = "自动合成星空鸭"
		autoLunarDuckBtn.BackgroundColor3 = Color3.fromRGB(180, 200, 255)
	end)
end)

local autoVengeanceBtn = createOtherBtn("AutoVengeance", "自动合成复仇剑", Color3.fromRGB(194, 231, 211), Color3.fromRGB(74, 125, 94))

autoVengeanceBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoVengeanceBtn.Text = "进行中..."
		autoVengeanceBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local duckEvil = findOwnedItem("DuckEvil")
		local duckAngel = findOwnedItem("DuckAngel")

		if not duckEvil or not duckAngel then
			autoVengeanceBtn.Text = "材料不足"
			notify("复仇剑材料不足", "warn")
			task.wait(1.2)
			autoVengeanceBtn.Text = "自动合成复仇剑"
			autoVengeanceBtn.BackgroundColor3 = Color3.fromRGB(194, 231, 211)
			return
		end

		teleportOneItem(duckEvil, Vector3.new(6486.7, -97.4, -4550.9))
		task.wait(0.25)
		teleportOneItem(duckAngel, Vector3.new(6447.6, -99.4, -4523.6))
		task.wait(0.25)

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(6464.1, -95.6, -4539.5)
		end

		autoVengeanceBtn.Text = "自动合成复仇剑"
		autoVengeanceBtn.BackgroundColor3 = Color3.fromRGB(194, 231, 211)
	end)
end)

local autoTridentBtn = createOtherBtn("AutoTrident", "自动合成三叉戟", Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140))

autoTridentBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoTridentBtn.Text = "进行中..."
		autoTridentBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local duckAngel = findOwnedItem("DuckAngel")
		local lunarDuck = findOwnedItem("LunarDuck")
		local duckEvil = findOwnedItem("DuckEvil")

		if not duckAngel or not lunarDuck or not duckEvil then
			autoTridentBtn.Text = "材料不足"
			notify("三叉戟材料不足", "warn")
			task.wait(1.2)
			autoTridentBtn.Text = "自动合成三叉戟"
			autoTridentBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
			return
		end

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local originalPos = hrp and hrp.Position
		local originalCF = hrp and hrp.CFrame

		-- 记录已有 DemonTrident，只带回新的
		local before = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name == "DemonTrident" then
				before[obj] = true
			end
		end

		teleportOneItem(duckAngel, Vector3.new(-360.1, 12.3, -1333.8))
		task.wait(0.1)
		teleportOneItem(lunarDuck, Vector3.new(-371.8, 12.8, -1330.3))
		task.wait(0.1)
		teleportOneItem(duckEvil, Vector3.new(-383.2, 13.2, -1327.8))
		task.wait(0.15)

		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(-373.8, 12.0, -1340.5)
		end

		autoTridentBtn.Text = "监测三叉戟..."
		local trident = nil
		for _ = 1, 40 do
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and obj.Name == "DemonTrident" and not before[obj] then
					trident = obj
					break
				end
			end
			if not trident then
				trident = findUnownedItem("DemonTrident")
			end
			if trident then break end
			task.wait(0.12)
		end

		if trident and originalPos then
			autoTridentBtn.Text = "带回三叉戟..."
			teleportOneItem(trident, originalPos)
			notify("DemonTrident 已带回", "success")
			autoTridentBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
		else
			notify("未检测到新三叉戟", "warn")
			autoTridentBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
		end

		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if originalCF and hrp then hrp.CFrame = originalCF end
		task.wait(0.6)
		autoTridentBtn.Text = "自动合成三叉戟"
		autoTridentBtn.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
	end)
end)

local autoEternalBtn = createOtherBtn(
	"AutoEternal",
	"自动合成永恒剑",
	Color3.fromRGB(220, 200, 255),
	Color3.fromRGB(100, 70, 140)
)

local function findOwnedItemAny(names)
	for _, name in ipairs(names) do
		local item = findOwnedItem(name)
		if item then
			return item
		end
	end
	return nil
end

autoEternalBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoEternalBtn.Text = "检查材料..."
		autoEternalBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not hrp then
			autoEternalBtn.Text = "角色不存在"
			task.wait(1)
			autoEternalBtn.Text = "自动合成永恒剑"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
			return
		end

		local originalCF = hrp.CFrame
		local originalPos = hrp.Position

		local trident = findOwnedItemAny({
			"DemonTrident"
		})

		local vengeance = findOwnedItemAny({
			"Vengeance",
			"VengeanceSword"
		})

		local duckEvil = findOwnedItemAny({
			"DuckEvil"
		})

		if not trident or not vengeance or not duckEvil then
			local missing = {}

			if not trident then
				table.insert(missing, "三叉戟")
			end

			if not vengeance then
				table.insert(missing, "复仇剑")
			end

			if not duckEvil then
				table.insert(missing, "恶魔鸭")
			end

			autoEternalBtn.Text = "缺少：" .. table.concat(missing, "、")
			task.wait(1.5)
			autoEternalBtn.Text = "自动合成永恒剑"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
			return
		end

		local eternalStation = Vector3.new(-373.8, 12.0, -1340.5)
		local tridentPos = Vector3.new(-360.1, 12.3, -1333.8)
		local vengeancePos = Vector3.new(-371.8, 12.8, -1330.3)
		local duckEvilPos = Vector3.new(-383.2, 13.2, -1327.8)

		hrp.CFrame = CFrame.new(eternalStation)
		task.wait(0.5)

		autoEternalBtn.Text = "放置三叉戟..."
		if not teleportOneItem(trident, tridentPos) then
			hrp.CFrame = originalCF
			autoEternalBtn.Text = "三叉戟传送失败"
			task.wait(1.2)
			autoEternalBtn.Text = "自动合成永恒剑"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
			return
		end

		task.wait(0.5)

		autoEternalBtn.Text = "放置复仇剑..."
		if not teleportOneItem(vengeance, vengeancePos) then
			hrp.CFrame = originalCF
			autoEternalBtn.Text = "复仇剑传送失败"
			task.wait(1.2)
			autoEternalBtn.Text = "自动合成永恒剑"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
			return
		end

		task.wait(0.5)

		autoEternalBtn.Text = "放置恶魔鸭..."
		if not teleportOneItem(duckEvil, duckEvilPos) then
			hrp.CFrame = originalCF
			autoEternalBtn.Text = "恶魔鸭传送失败"
			task.wait(1.2)
			autoEternalBtn.Text = "自动合成永恒剑"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
			return
		end

		task.wait(0.8)

		hrp.CFrame = CFrame.new(eternalStation)
		task.wait(1)

		autoEternalBtn.Text = "等待合成..."

		local eternalSword = nil
		for attempt = 1, 20 do
			eternalSword = findUnownedItem("EternalSword")
			if not eternalSword then
				eternalSword = findUnownedItem("Eternal")
			end
			if eternalSword then break end
			task.wait(0.25)
		end

		if eternalSword then
			autoEternalBtn.Text = "获取永恒剑..."
			task.wait(0.3)
			teleportOneItem(eternalSword, originalPos)
			task.wait(0.3)
			hrp.CFrame = originalCF
			autoEternalBtn.Text = "合成成功！"
			notify("永恒剑合成成功", "success")
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
			task.wait(1.5)
		else
			hrp.CFrame = originalCF
			autoEternalBtn.Text = "已放置材料"
			autoEternalBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
			task.wait(1.5)
		end

		autoEternalBtn.Text = "自动合成永恒剑"
		autoEternalBtn.BackgroundColor3 = Color3.fromRGB(220, 200, 255)
	end)
end)

local autoHellfireBtn = createOtherBtn("AutoHellfire", "自动合成地狱火", Color3.fromRGB(255, 160, 120), Color3.fromRGB(140, 50, 30))

autoHellfireBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoHellfireBtn.Text = "进行中..."
		autoHellfireBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local trident = findOwnedItemAny({
			"DemonTrident"
		})
		local duckEvil = findOwnedItem("DuckEvil")

		if not trident or not duckEvil then
			autoHellfireBtn.Text = "材料不足"
			notify("地狱火材料不足", "warn")
			task.wait(1.2)
			autoHellfireBtn.Text = "自动合成地狱火"
			autoHellfireBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 120)
			return
		end

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local originalPos = hrp and hrp.Position
		local originalCF = hrp and hrp.CFrame
		local before = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and (obj.Name == "Hellfire" or obj.Name == "HellfireAxe" or obj.Name == "HellFire") then
				before[obj] = true
			end
		end
		teleportOneItem(trident, Vector3.new(-1755.5, 343.9, 1478.5))
		task.wait(0.25)
		teleportOneItem(duckEvil, Vector3.new(-1785.6, 343.9, 1495.5))
		task.wait(0.25)

		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(-1684.1, 348.9, 1477.7)
		end
		notify("监测 Hellfire...", "info")
		local product = nil
		for _ = 1, 35 do
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and (obj.Name == "Hellfire" or obj.Name == "HellfireAxe" or obj.Name == "HellFire") and not before[obj] then
					product = obj
					break
				end
			end
			if product then break end
			task.wait(0.12)
		end
		if product and originalPos then
			teleportOneItem(product, originalPos)
			notify("Hellfire 已带回", "success")
		else
			notify("未出 Hellfire，材料留在合成点", "warn")
		end
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp and originalCF then hrp.CFrame = originalCF end
		autoHellfireBtn.Text = "自动合成地狱火"
		autoHellfireBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 120)
	end)
end)

local autoHeavenSwordBtn = createOtherBtn("AutoHeavenSword", "自动合成天堂剑", Color3.fromRGB(255, 230, 150), Color3.fromRGB(140, 100, 40))

autoHeavenSwordBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoHeavenSwordBtn.Text = "进行中..."
		autoHeavenSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local halo = findOwnedItem("AngelHalo")

		if not halo then
			autoHeavenSwordBtn.Text = "材料不足"
			notify("需要自己的 AngelHalo", "warn")
			task.wait(1.2)
			autoHeavenSwordBtn.Text = "自动合成天堂剑"
			autoHeavenSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 150)
			return
		end

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local originalPos = hrp and hrp.Position
		local originalCF = hrp and hrp.CFrame
		local place = Vector3.new(1662.8, 401.7, 3280.5)
		local before = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and (obj.Name == "GodlySword" or obj.Name == "Godly") then
				before[obj] = true
			end
		end
		teleportOneItem(halo, place)
		task.wait(0.3)
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(place + Vector3.new(0, 3, 0))
		end
		notify("监测 GodlySword...", "info")
		local product = nil
		for _ = 1, 35 do
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and (obj.Name == "GodlySword" or obj.Name == "Godly") and not before[obj] then
					product = obj
					break
				end
			end
			if product then break end
			task.wait(0.12)
		end
		if product and originalPos then
			teleportOneItem(product, originalPos)
			notify("天堂剑已带回", "success")
		else
			notify("未出产物，材料留在合成点", "warn")
		end
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp and originalCF then hrp.CFrame = originalCF end
		autoHeavenSwordBtn.Text = "自动合成天堂剑"
		autoHeavenSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 230, 150)
	end)
end)

-- 自动合成月神剑
local autoLunarisSwordBtn = createOtherBtn("AutoLunarisSword", "自动合成月神剑", Color3.fromRGB(200, 180, 255), Color3.fromRGB(80, 50, 140))
autoLunarisSwordBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoLunarisSwordBtn.Text = "进行中..."
		autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			autoLunarisSwordBtn.Text = "自动合成月神剑"
			autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
			return
		end
		local originalCF = hrp.CFrame
		local originalPos = hrp.Position
		local place = Vector3.new(-7648.2, 322.1, 4233.9)

		local core = findOwnedItem("LunarCore")
		if not core then
			autoLunarisSwordBtn.Text = "材料不足"
			notify("需要自己的 LunarCore", "warn")
			task.wait(1.2)
			autoLunarisSwordBtn.Text = "自动合成月神剑"
			autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
			return
		end

		-- 记录已有无主 Lunaris
		local before = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name == "Lunaris" and isUnowned(obj) then
				before[obj] = true
			end
		end

		teleportOneItem(core, place)
		task.wait(0.25)
		hrp.CFrame = CFrame.new(place + Vector3.new(0, 3, 0))
		task.wait(0.3)

		autoLunarisSwordBtn.Text = "监测 Lunaris..."
		pcall(function() notify("监测无主 Lunaris", "info") end)
		local lunaris = nil
		for _ = 1, 40 do
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and obj.Name == "Lunaris" and isUnowned(obj) and not before[obj] then
					lunaris = obj
					break
				end
			end
			if not lunaris then
				lunaris = findUnownedItem("Lunaris")
				if lunaris and before[lunaris] then lunaris = nil end
			end
			if lunaris then break end
			task.wait(0.12)
		end

		if lunaris then
			autoLunarisSwordBtn.Text = "带回月神剑..."
			teleportOneItem(lunaris, originalPos)
			notify("Lunaris 已带回", "success")
			autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
		else
			notify("未检测到新 Lunaris", "warn")
			autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
		end
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = originalCF end
		task.wait(0.5)
		autoLunarisSwordBtn.Text = "自动合成月神剑"
		autoLunarisSwordBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	end)
end)


local autoEvilCoreBtn = createOtherBtn("AutoEvilCore", "自动合成Doom核心", Color3.fromRGB(120, 40, 40), Color3.fromRGB(255, 200, 200))
autoEvilCoreBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoEvilCoreBtn.Text = "进行中..."
		autoEvilCoreBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)

		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			autoEvilCoreBtn.Text = "自动合成Doom核心"
			autoEvilCoreBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
			return
		end

		local originalCF = hrp.CFrame

		-- 需要的四件材料及放置坐标
		local materials = {
			{ names = {"GodlySword", "Godly"}, pos = Vector3.new(-1274.4, 24.5, -93.1), label = "神剑" },
			{ names = {"Eternal", "EternalSword"}, pos = Vector3.new(-1285.8, 24.5, -89.6), label = "永恒剑" },
			{ names = {"Hellfire", "HellfireAxe", "HellFire"}, pos = Vector3.new(-1296.9, 24.5, -86.7), label = "地狱火" },
			{ names = {"Lunaris", "LunarDuck", "LunarisSword"}, pos = Vector3.new(-1306.6, 24.6, -84.3), label = "星空" },
		}

		local foundItems = {}
		local missing = {}
		for _, mat in ipairs(materials) do
			local item = nil
			for _, n in ipairs(mat.names) do
				item = findOwnedItem(n)
				if item then break end
			end
			if item then
				table.insert(foundItems, { item = item, pos = mat.pos, label = mat.label })
			else
				table.insert(missing, mat.label)
			end
		end

		if #missing > 0 then
			autoEvilCoreBtn.Text = "缺少：" .. table.concat(missing, "、")
			notify("末日核心缺少：" .. table.concat(missing, "、"), "warn")
			task.wait(1.8)
			autoEvilCoreBtn.Text = "自动合成Doom核心"
			autoEvilCoreBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
			return
		end

		-- 依次放置材料
		for i, entry in ipairs(foundItems) do
			autoEvilCoreBtn.Text = "放置" .. entry.label .. " (" .. i .. "/4)"
			teleportOneItem(entry.item, entry.pos)
			task.wait(0.35)
		end

		-- 合成完成后传送到 Doom 勋章合成点
		autoEvilCoreBtn.Text = "前往Doom勋章点..."
		task.wait(0.5)
		hrp.CFrame = CFrame.new(-1290.3, 21.7, -100.0)

		autoEvilCoreBtn.Text = "已完成"
		autoEvilCoreBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
		task.wait(1.5)

		autoEvilCoreBtn.Text = "自动合成Doom核心"
		autoEvilCoreBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	end)
end)


-- 自动合成 Doom 剑（传送自己的 EvilCore）
local autoDoomSwordBtn = createOtherBtn("AutoDoomSword", "自动合成Doom剑", Color3.fromRGB(60, 60, 60), Color3.fromRGB(220, 220, 220))
autoDoomSwordBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		autoDoomSwordBtn.Text = "进行中..."
		autoDoomSwordBtn.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
		local core = findOwnedItem("EvilCore")
		if not core then
			core = findOwnedItemAny and findOwnedItemAny({"EvilCore", "Doom"}) or findOwnedItem("Doom")
		end
		if not core then
			autoDoomSwordBtn.Text = "材料不足"
			notify("需要自己的 EvilCore", "warn")
			task.wait(1.2)
			autoDoomSwordBtn.Text = "自动合成Doom剑"
			autoDoomSwordBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			return
		end
		local pos = Vector3.new(-1497.2, -245.3, 291.0)
		local character = speaker.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local originalPos = hrp and hrp.Position
		local originalCF = hrp and hrp.CFrame
		local before = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name == "Doom" then
				before[obj] = true
			end
		end
		notify("传送 EvilCore 到合成点", "info")
		teleportOneItem(core, pos)
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
		end
		notify("监测 Doom...", "info")
		local product = nil
		for _ = 1, 35 do
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Model") and obj.Name == "Doom" and not before[obj] then
					product = obj
					break
				end
			end
			if product then break end
			task.wait(0.12)
		end
		if product and originalPos then
			teleportOneItem(product, originalPos)
			notify("Doom 已带回", "success")
		else
			notify("未出 Doom，材料留在合成点", "warn")
		end
		hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
		if hrp and originalCF then hrp.CFrame = originalCF end
		autoDoomSwordBtn.Text = "自动合成Doom剑"
		autoDoomSwordBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end)
end)

-- 细分割线
local doomDiv = Instance.new("Frame")
doomDiv.Name = "DoomDivider"
doomDiv.Parent = otherPage
doomDiv.Size = UDim2.new(1, -px(12), 0, 1)
doomDiv.Position = UDim2.new(0, px(6), 0, currentY + 2)
doomDiv.BackgroundColor3 = Color3.fromRGB(200, 180, 195)
doomDiv.BackgroundTransparency = 0.35
doomDiv.BorderSizePixel = 0
currentY = currentY + 8

-- 持续合成恶魔鸭（测试）toggle
local contDemonDuck = false
local contDemonBtn = Instance.new("TextButton")
contDemonBtn.Name = "ContDemonDuck"
contDemonBtn.Parent = otherPage
contDemonBtn.Size = UDim2.new(1, -px(8), 0, px(18))
contDemonBtn.Position = UDim2.new(0, px(4), 0, currentY)
contDemonBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
contDemonBtn.BorderSizePixel = 0
contDemonBtn.Text = "持续合成恶魔鸭（测试）: 关"
contDemonBtn.TextColor3 = Color3.fromRGB(90, 30, 30)
contDemonBtn.Font = Enum.Font.GothamBold
contDemonBtn.TextSize = px(9)
contDemonBtn.AutoButtonColor = false
Instance.new("UICorner", contDemonBtn).CornerRadius = UDim.new(0, px(4))
currentY = currentY + BTN_H + BTN_GAP

contDemonBtn.MouseButton1Click:Connect(function()
	contDemonDuck = not contDemonDuck
	if not contDemonDuck then
		contDemonBtn.Text = "持续合成恶魔鸭（测试）: 关"
		contDemonBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
		contDemonBtn.TextColor3 = Color3.fromRGB(90, 30, 30)
		pcall(function() notify("已停止持续合成恶魔鸭", "info") end)
		return
	end
	contDemonBtn.Text = "持续合成恶魔鸭（测试）: 开"
	contDemonBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
	contDemonBtn.TextColor3 = Color3.fromRGB(72, 108, 88)
	pcall(function() notify("开始持续合成恶魔鸭", "success") end)
	task.spawn(function()
		while contDemonDuck do
			-- 触发一次「自动合成恶魔鸭」
			local fired = false
			pcall(function()
				if getconnections then
					for _, conn in ipairs(getconnections(autoDemonDuckTestBtn.MouseButton1Click)) do
						pcall(function()
							if conn.Fire then conn:Fire() fired = true
							elseif conn.Function then conn.Function() fired = true end
						end)
					end
				end
			end)
			if not fired then
				pcall(function()
					-- 部分执行器
					firesignal(autoDemonDuckTestBtn.MouseButton1Click)
					fired = true
				end)
			end
			if not fired then
				pcall(function() notify("无法触发合成，请检查执行器", "error") end)
				break
			end
			-- 等待本轮结束（按钮文字恢复）
			task.wait(1.2)
			local t0 = tick()
			while contDemonDuck and tick() - t0 < 150 do
				local t = tostring(autoDemonDuckTestBtn.Text or "")
				if t == "自动合成恶魔鸭" or t == "合成成功" or t == "无新鸭子" or t == "已拒绝" or t:find("缺") then
					-- 再等一小会让收尾跑完
					task.wait(0.5)
					break
				end
				contDemonBtn.Text = "持续中: " .. t
				task.wait(0.35)
			end
			if not contDemonDuck then break end
			-- 成功或结束一轮后等 20 秒
			for i = 20, 1, -1 do
				if not contDemonDuck then break end
				contDemonBtn.Text = string.format("持续合成 等待 %ds", i)
				task.wait(1)
			end
		end
		if contDemonBtn and contDemonBtn.Parent then
			contDemonBtn.Text = "持续合成恶魔鸭（测试）: 关"
			contDemonBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
			contDemonBtn.TextColor3 = Color3.fromRGB(90, 30, 30)
		end
		contDemonDuck = false
	end)
end)


end
-- ===================== 调试页 =====================
task.spawn(function()
	local ok, err = pcall(function()
		local debugPage = pages[6]
		if not debugPage then
			-- 若只有5页则挂到其他
			debugPage = pages[5]
		end
		if not debugPage then error("no debug page") end

		local dbgLog = ""
		local remoteOn = false
		local clickOn = false
		local guiOn = false
		local remoteHooked = false
		local maxLog = 60000

		local function dbgAppend(line)
			dbgLog = dbgLog .. line .. "\n"
			if #dbgLog > maxLog then dbgLog = dbgLog:sub(-math.floor(maxLog * 0.7)) end
		end

		local title = Instance.new("TextLabel")
		title.Parent = debugPage
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -px(8), 0, px(14))
		title.Position = UDim2.new(0, px(4), 0, px(2))
		title.Text = "调试监控"
		title.TextColor3 = Color3.fromRGB(145, 103, 134)
		title.Font = Enum.Font.GothamBold
		title.TextSize = px(9)
		title.TextXAlignment = Enum.TextXAlignment.Left

		local function mkBtn(text, y, bg, tc)
			local b = Instance.new("TextButton")
			b.Parent = debugPage
			b.Size = UDim2.new(1, -px(8), 0, px(16))
			b.Position = UDim2.new(0, px(4), 0, y)
			b.BackgroundColor3 = bg
			b.BorderSizePixel = 0
			b.Text = text
			b.TextColor3 = tc
			b.Font = Enum.Font.GothamBold
			b.TextSize = px(8)
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, px(3))
			return b
		end

		local y0 = px(18)
		local remoteBtn = mkBtn("Remote监控: 关", y0, Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
		local clickBtn = mkBtn("ClickDetector扫描", y0 + px(18), Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140))
		local guiBtn = mkBtn("扫描ChatGUI/Yes", y0 + px(36), Color3.fromRGB(210, 201, 239), Color3.fromRGB(112, 91, 145))
		local storesBtn = mkBtn("扫描Stores目录", y0 + px(54), Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88))
		local copyBtn = mkBtn("复制调试日志", y0 + px(72), Color3.fromRGB(255, 230, 180), Color3.fromRGB(140, 100, 40))
		local clearBtn = mkBtn("清空日志", y0 + px(90), Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101))

		local status = Instance.new("TextLabel")
		status.Parent = debugPage
		status.BackgroundTransparency = 1
		status.Position = UDim2.new(0, px(4), 0, y0 + px(108))
		status.Size = UDim2.new(1, -px(8), 0, px(40))
		status.Text = "打开Remote后，手动买一次可抓参数"
		status.TextColor3 = Color3.fromRGB(120, 100, 120)
		status.Font = Enum.Font.Gotham
		status.TextSize = px(7)
		status.TextWrapped = true
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.TextYAlignment = Enum.TextYAlignment.Top

		local function tryCopy(text)
			local okc = false
			pcall(function() if setclipboard then setclipboard(text) okc = true end end)
			pcall(function() if toclipboard then toclipboard(text) okc = true end end)
			if okc then
				status.Text = "已复制 " .. #text .. " 字符"
				pcall(function() notify("调试日志已复制", "success") end)
			else
				status.Text = "无剪贴板API，看Console print"
				print(text)
			end
		end

		local function pathOf(inst)
			local t = {}
			local c = inst
			local n = 0
			while c and c ~= game and n < 30 do
				table.insert(t, 1, c.Name)
				c = c.Parent
				n = n + 1
			end
			return table.concat(t, ".")
		end

		local function shortArgs(...)
			local a = {...}
			local parts = {}
			for i = 1, math.min(#a, 8) do
				local v = a[i]
				local s
				if typeof(v) == "Instance" then
					s = "I:" .. v:GetFullName()
				elseif type(v) == "string" then
					s = string.format("%q", v:sub(1, 80))
				elseif type(v) == "table" then
					s = "{table}"
				else
					s = tostring(v)
				end
				table.insert(parts, s)
			end
			if #a > 8 then table.insert(parts, "...") end
			return table.concat(parts, ", ")
		end

		local function hookRemotes()
			if remoteHooked then return true end
			local okHook = false
			pcall(function()
				local mt = getrawmetatable(game)
				if not mt then return end
				local old = mt.__namecall
				if setreadonly then setreadonly(mt, false) end
				local wrapper = function(self, ...)
					local method = getnamecallmethod()
					if remoteOn and (method == "FireServer" or method == "InvokeServer") then
						local name = ""
						pcall(function() name = self:GetFullName() end)
						local nlow = string.lower(name)
						-- 过滤噪音可选：只记对话/交互相关时取消注释
						local line = string.format("[%s] %s\n  args: %s", method, name, shortArgs(...))
						dbgAppend(line)
						print("[DBG]", method, name, shortArgs(...))
					end
					return old(self, ...)
				end
				if newcclosure then
					mt.__namecall = newcclosure(wrapper)
				else
					mt.__namecall = wrapper
				end
				if setreadonly then setreadonly(mt, true) end
				okHook = true
				remoteHooked = true
			end)
			-- 备用：逐个 hook 已知对话
			pcall(function()
				local function hookInst(inst)
					if not inst then return end
					if inst:IsA("RemoteEvent") then
						local oldFire = inst.FireServer
						-- 无法简单替换 FireServer 在部分执行器
					end
				end
				local npc = ReplicatedStorage:FindFirstChild("NPCDialog")
				if npc then
					dbgAppend("[info] 发现 NPCDialog")
					for _, c in ipairs(npc:GetChildren()) do
						dbgAppend("  " .. c.ClassName .. " " .. c.Name)
					end
				end
				local inter = ReplicatedStorage:FindFirstChild("Interaction")
				if inter then
					dbgAppend("[info] 发现 Interaction 子项数 " .. #inter:GetChildren())
				end
			end)
			return okHook
		end

		remoteBtn.MouseButton1Click:Connect(function()
			remoteOn = not remoteOn
			if remoteOn then
				local okh = hookRemotes()
				remoteBtn.Text = "Remote监控: 开"
				remoteBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
				status.Text = okh and "Remote监控已开，请手动买一次" or "Hook失败，仍记录已知目录"
				dbgAppend("===== Remote ON =====")
				pcall(function() notify("Remote监控开", "success") end)
			else
				remoteBtn.Text = "Remote监控: 关"
				remoteBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
				status.Text = "Remote监控已关"
				dbgAppend("===== Remote OFF =====")
			end
		end)

		clickBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== ClickDetector 扫描 =====")
			local n = 0
			local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			local origin = hrp and hrp.Position
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("ClickDetector") then
					local parent = d.Parent
					local pos = parent and parent:IsA("BasePart") and parent.Position
					local dist = (origin and pos) and (pos - origin).Magnitude or -1
					if dist < 0 or dist < 120 then
						dbgAppend(string.format("CD %.0f %s", dist, pathOf(d)))
						n = n + 1
						if n > 80 then break end
					end
				end
			end
			status.Text = "ClickDetector 约 " .. n .. " 条"
			dbgAppend("合计 " .. n)
			pcall(function() notify("CD扫描完成", "info") end)
		end)

		guiBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== ChatGUI =====")
			local cg = PlayerGui:FindFirstChild("ChatGUI")
			if not cg then
				dbgAppend("无 ChatGUI")
				status.Text = "无 ChatGUI"
				return
			end
			dbgAppend("ChatGUI Enabled=" .. tostring(cg.Enabled))
			for _, d in ipairs(cg:GetDescendants()) do
				if d:IsA("TextButton") or d:IsA("TextLabel") then
					local t = tostring(d.Text or "")
					if t ~= "" or d.Name:find("Prompt") or d.Name:find("Choice") or d.Name:find("Chat") then
						dbgAppend(string.format("%s %s Text=%q", d.ClassName, pathOf(d), t:sub(1, 60)))
					end
				end
			end
			status.Text = "ChatGUI 已写入日志"
			pcall(function() notify("ChatGUI已扫描", "info") end)
		end)

		storesBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== Stores =====")
			local stores = Workspace:FindFirstChild("Stores")
			if not stores then
				dbgAppend("无 Workspace.Stores")
				status.Text = "无 Stores"
				return
			end
			for _, store in ipairs(stores:GetChildren()) do
				local items = store:FindFirstChild("ShopItems")
				local count = items and #items:GetChildren() or 0
				dbgAppend(string.format("店 %s ShopItems=%d", store.Name, count))
				if items then
					local i = 0
					for _, it in ipairs(items:GetChildren()) do
						i = i + 1
						if i <= 15 then
							dbgAppend("  - " .. it.Name .. " (" .. it.ClassName .. ")")
						end
					end
					if count > 15 then dbgAppend("  ...") end
				end
			end
			status.Text = "Stores 已扫描"
			pcall(function() notify("Stores已扫描", "info") end)
		end)

		copyBtn.MouseButton1Click:Connect(function()
			tryCopy(dbgLog)
		end)
		clearBtn.MouseButton1Click:Connect(function()
			dbgLog = ""
			status.Text = "日志已清空"
		end)

		print("[Yutong] 调试页 OK")
	end)
	if not ok then warn("[Yutong] 调试页失败", err) end
end)



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

RunService.Heartbeat:Connect(function()
	local character = speaker.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = _G.WalkSpeed
			humanoid.JumpPower = _G.JumpPower
		end
	end
end)

RunService.Stepped:Connect(function()
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
			selfGlowLight.Range = 12
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
-- ===== [移植自青脚本] 木头功能 开始 =====

-- 木头功能状态表
local bai = {
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

local lp = speaker
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
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
    end)
    d[1]:PivotTo(d[2])
    return d
end

DragModelmain = function(...)
    local d = {...}
    pcall(function()
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
    end)
    d[1].Main.CFrame = d[2]
    return d
end

DragModel2 = function(...)
    local d = {...}
    pcall(function()
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
    end)
    d[1]:SetPrimaryPartCFrame(d[2])
    return d
end

DragModel1 = function(...)
    local d = {...}
    pcall(function()
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(d[1])
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

local function tp(pos)
    local pos = pos or Mouse.Hit + Vector3.new(0, speaker.Character.HumanoidRootPart.Size.Y, 0)
    if typeof(pos) == "CFrame" then
        speaker.Character:SetPrimaryPartCFrame(pos)
    elseif typeof(pos) == "Vector3" then
        speaker.Character:MoveTo(pos)
    end
end

local function getPosition(part)
    return getCFrame(part).Position
end

local function getMouseTarget()
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
    local axe_class = require(ReplicatedStorage.AxeClasses['AxeClass_' .. tool.ToolName.Value])
    local axe_table = axe_class.new()
    if axe_table["SpecialTrees"] then
        if axe_table["SpecialTrees"][tree] then
            return axe_table["SpecialTrees"][tree].Damage
        else
            return axe_table.Damage
        end
    else
        return axe_table.Damage
    end
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
    speaker.Character.Humanoid:UnequipTools()
    local tools = {}
    table_foreach(speaker.Backpack:GetChildren(), function(_, v)
        if v.Name ~= "BlueprintTool" then tools[#tools + 1] = v end
    end)
    return tools
end

local function getToolStats(toolName)
    if typeof(toolName) ~= "string" then toolName = toolName.ToolName.Value end
    return require(ReplicatedStorage.AxeClasses['AxeClass_' .. toolName]).new()
end

local getTool = function()
    return speaker.Character:FindFirstChild("Tool") or speaker.Backpack:FindFirstChild("Tool")
end

local function getBestAxe(treeClass)
    local tools = getTools()
    if #tools == 0 then return notify("你需要斧头", "warn") end
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

local function cutPart(event, section, height, tool, treeClass)
    local axeStats = getToolStats(tool)
    if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
        for i, v in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = v end
    end
    ReplicatedStorage.Interaction.RemoteProxy:FireServer(event, {
        tool = tool,
        faceVector = Vector3.new(-1, 0, 0),
        height = height or 0.3,
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
                        if #g:GetChildren() > 5 and g:FindFirstChild("WoodSection") then
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
    return false
end

local function bringTree(treeClass)
    local success, data = getBestAxe(treeClass)
    local axeStats = getToolStats(data)
    local treeCut = false
    treeListener(treeClass, function(tree)
        tree:WaitForChild('Owner', 60)
        tree.PrimaryPart = tree:FindFirstChild("WoodSection")
        treeCut = true
        task.spawn(function()
            for i = 1, 60 do
                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(tree)
                RunService.Heartbeat:wait()
            end
        end)
        task.wait(0.1)
        tree.PrimaryPart = tree.WoodSection
        spawn(function()
            for i = 1, 60 do
                tree.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
                tree:PivotTo(bai.treecutset)
                RunService.Heartbeat:wait()
            end
        end)
        wait(0.5)
        if treeClass == "LoneCave" then
            speaker.Character.Head:Destroy()
            speaker.CharacterAdded:Wait()
            wait(2)
        end
        tp(bai.treecutset)
    end)
    if treeClass == "LoneCave" then
        local GM = speaker.Character.HumanoidRootPart.RootJoint
        GM:Clone().Parent = speaker.Character.HumanoidRootPart
        GM:Destroy()
    end
    local tree = getBiggestTree(treeClass)
    if not tree then return notify("没有找到树", "warn") end
    spawn(function()
        repeat
            tp(tree.CFrame + Vector3.new(3, 3, 0))
            cutPart(tree.Parent.CutEvent, 1, 0.3, data, treeClass)
            RunService.Heartbeat:wait()
        until treeCut
    end)
end

local function autofarm(treeClass)
    local oldpos = speaker.Character.HumanoidRootPart.CFrame
    local success, data = getBestAxe(treeClass)
    local axeStats = getToolStats(data)
    local tree = getBiggestTree(treeClass)
    if not tree then return notify("没有找到树", "warn") end
    local treeCut = false
    treeListener(treeClass, function(tree)
        tree.PrimaryPart = tree:FindFirstChild("WoodSection")
        treeCut = true
        for i = 1, 70 do
            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(tree.WoodSection)
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
        cutPart(tree.tree.CutEvent, 1, 0.3, data, treeClass)
        task.wait(axeStats.SwingCooldown - 14)
    until treeCut
    if bai.autofarm1 == false then notify("完成", "success") end
    tp(oldpos)
end

local function getPlanks()
    local plankList = {};
    for _, plank in next, Workspace.PlayerModels:GetChildren() do
        if plank:FindFirstChild('WoodSection') and plank:FindFirstChild('Owner') and plank.Owner.Value ==
            speaker and not table.find(plankList, plank) then
            table.insert(plankList, plank)
        end
    end
    return plankList;
end

local function sellwood()
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
                                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(v)
                                v:PivotTo(CFrame.new(314.54, -0.5, 86.823))
                                v2.CFrame = CFrame.new(314.54, -0.5, 86.823)
                                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(v)
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

local function PlankToBlueprint()
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
            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(bai.plankModel)
            bai.plankModel.WoodSection.CFrame = CFrame.new(bai.blueprintModel.Main.CFrame.p + Vector3.new(0, 1.5, 0))
            RunService.Stepped:wait()
        end)
    end
    notify("完成", "success")
    bai.blueprintModel = nil
    bai.plankModel = nil
end

local function lumbsmasher_legitpaint(wood_class, blueprint, tpback)
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
            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(WoodSection.Parent)
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
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Chopped)
        Chopped.PrimaryPart = Chopped.WoodSection
        Chopped:SetPrimaryPartCFrame(sawmill.Particles.CFrame)
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Chopped)
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

local function shuaxinlb(zji)
    bai.dropdown = {}
    if zji == true then
        for p, I in next, game.Players:GetChildren() do table.insert(bai.dropdown, I.Name) end
    else
        for p, I in next, game.Players:GetChildren() do
            if I ~= lp then table.insert(bai.dropdown, I.Name) end
        end
    end
end
shuaxinlb(true)

-- 木头功能 UI 页面（使用 Yutong 的 Instance.new 风格）
local woodPage = pages[7]

local woodY = px(2)
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
    woodY = woodY + px(20)
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
    woodY = woodY + px(14)
    return lbl
end

-- 传送木头
woodBtn("传送木头", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    local OldPos = speaker.Character.HumanoidRootPart.CFrame
    for i, v in next, Workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == speaker then
            if not v.PrimaryPart then v.PrimaryPart = v:FindFirstChild("WoodSection") end
            speaker.Character.HumanoidRootPart.CFrame = CFrame.new(v:FindFirstChild("WoodSection").CFrame.p)
            spawn(function()
                for i = 1, 50 do
                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(v)
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
                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(log)
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
                        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
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
                                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
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
                                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Log)
                                end
                            end
                            wait(1)
                            for i = 1, 10 do
                                task.wait()
                                v.CFrame = oldpos
                                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Log)
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
            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(wood)
            RunService.Stepped:wait()
        end
    end)
    task.wait(0.3)
    tp(wood.WoodSection.CFrame)
    task.wait(1)
    for i = 1, 20 do
        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(wood)
        wood:MoveTo(oldPosition)
        RunService.Stepped:wait()
    end
    tp(oldpos)
    pcall(function()
        spawn(function()
            for i = 1, 200 do
                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(wood)
                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(wood)
                wood:SetPrimaryPartCFrame(SawC)
                ReplicatedStorage.Interaction.ClientIsDragging:FireServer(wood)
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
                        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(g)
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
treeTypeBtn.Text = "树类型: 普通树"
treeTypeBtn.TextColor3 = Color3.fromRGB(112, 91, 145)
treeTypeBtn.Font = Enum.Font.GothamBold
treeTypeBtn.TextSize = px(9)
treeTypeBtn.AutoButtonColor = false
Instance.new("UICorner", treeTypeBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(20)

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
woodY = woodY + px(52)

local TREE_TYPES = {
    {name = "普通树", val = "Generic"}, {name = "幻影木", val = "LoneCave"},
    {name = "沼泽黄金", val = "GoldSwampy"}, {name = "樱花", val = "Cherry"},
    {name = "蓝木", val = "CaveCrawler"}, {name = "冰木", val = "Frost"},
    {name = "火山木", val = "Volcano"}, {name = "橡木", val = "Oak"},
    {name = "巧克力木", val = "Walnut"}, {name = "青桦木", val = "Birch"},
    {name = "黄金木", val = "SnowGlow"}, {name = "雪地松", val = "Pine"},
    {name = "僵尸木", val = "GreenSwampy"}, {name = "大巧克力树", val = "Koa"},
    {name = "椰子树", val = "Palm"}, {name = "南瓜木", val = "SpookyNeon"},
    {name = "幽灵木", val = "Spooky"},
}

for i, tt in ipairs(TREE_TYPES) do
    local itemBtn = Instance.new("TextButton")
    itemBtn.Parent = treeTypeList
    itemBtn.Size = UDim2.new(1, 0, 0, 16)
    itemBtn.BackgroundTransparency = 1
    itemBtn.Text = tt.name
    itemBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
    itemBtn.Font = Enum.Font.GothamMedium
    itemBtn.TextSize = px(8)
    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
    itemBtn.ZIndex = 31
    itemBtn.MouseButton1Click:Connect(function()
        bai.cuttreeselect = tt.val
        treeTypeBtn.Text = "树类型: " .. tt.name
        treeTypeList.Visible = false
    end)
end

treeTypeBtn.MouseButton1Click:Connect(function()
    treeTypeList.Visible = not treeTypeList.Visible
end)

-- 带来树数量
local bringAmtBtn = Instance.new("TextButton")
bringAmtBtn.Parent = woodPage
bringAmtBtn.Size = UDim2.new(1, -px(8), 0, px(18))
bringAmtBtn.Position = UDim2.new(0, px(4), 0, woodY)
bringAmtBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
bringAmtBtn.BorderSizePixel = 0
bringAmtBtn.Text = "带来数量: 1"
bringAmtBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
bringAmtBtn.Font = Enum.Font.GothamBold
bringAmtBtn.TextSize = px(9)
bringAmtBtn.AutoButtonColor = false
Instance.new("UICorner", bringAmtBtn).CornerRadius = UDim.new(0, px(4))
woodY = woodY + px(20)

bringAmtBtn.MouseButton1Click:Connect(function()
    bai.bringamount = bai.bringamount >= 10 and 1 or (bai.bringamount + 1)
    bringAmtBtn.Text = "带来数量: " .. tostring(bai.bringamount)
end)

-- 带来树
woodBtn("带来树", Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88)).MouseButton1Click:Connect(function()
    bai.bringtree = true
    bai.treecutset = speaker.Character.HumanoidRootPart.CFrame
    task.wait(0.2)
    for i = 1, bai.bringamount do
        if bai.bringtree == true then task.wait(); bringTree(bai.cuttreeselect) end
    end
    task.wait()
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
                if bai.autofarm == true then bringTree(bai.cuttreeselect) end
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
                    autofarm(bai.cuttreeselect)
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
woodY = woodY + px(20)

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
woodY = woodY + px(52)

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
woodY = woodY + px(20)

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
woodY = woodY + px(52)

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
woodY = woodY + px(20)

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
woodY = woodY + px(52)

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
                            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
                            Plank.WoodSection.Position = oldpos
                            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
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
                            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
                            Plank.WoodSection.CFrame = oldpos
                            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(Plank)
                            RunService.Stepped:wait()
                        end
                    end
                end
            end
        end
    end
end)

-- ===== [移植自青脚本] 木头功能 结束 =====

selectTab(1)
print("[Yutong] tabs=", TAB_COUNT, "pages=", #pages)
