-- v8_buy.lua — 购买页（自动购买、柜台传送等）
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Workspace = V8.Workspace
local ReplicatedStorage = V8.ReplicatedStorage
local PlayerGui = V8.PlayerGui
local getMoney = V8.getMoney
local isUnowned = V8.isUnowned
local isOwnedByMe = V8.isOwnedByMe
local teleportOneItem = V8.teleportOneItem
local getStoreCounter = V8.getStoreCounter
local storeDisplayName = V8.storeDisplayName
local getStoreBaseIds = V8.getStoreBaseIds
local npcIdCache = V8.npcIdCache
local npcCtxCache = V8.npcCtxCache
local npcIdConfirmed = V8.npcIdConfirmed
local Mouse = V8.Mouse
local Lighting = V8.Lighting
local TeleportService = V8.TeleportService

local getStoreCounter
local shopCatalog
local selectedShopIndex
local selectedProductIndex
local buyQuantity
local scanAllShops
do
-- ===================== 购买页：下拉选项 + 自动购买 =====================
local WOODRUS_COUNTER = Vector3.new(268.0, 8.2, 67.4)

-- 真实柜台坐标表（Counter Scanner 扫描结果，人物落地坐标）
local STORE_COUNTER = {
    ["SallysSeasonal"]  = Vector3.new(-1275.4, 136.9, -1477.2),
    ["StoneRUs"]        = Vector3.new(-2359.0, 306.0, -1853.1),
    ["FineArt"]         = Vector3.new(5238.0, -161.0, 740.0),
    ["FineFinds"]       = Vector3.new(51.3, 8.1, -454.5),
    ["SeaSide"]         = Vector3.new(6698.3, 6.2, -3563.8),
    ["VIPSHOP"]         = Vector3.new(947.0, 9.8, -63.8),
    ["HLStand"]         = Vector3.new(-921.4, -240.9, 80.1),
    ["MountainSide"]    = Vector3.new(-649.3, 164.4, 403.6),
    ["BlackMarket"]     = Vector3.new(-83.1, 65.8, 1408.3),
    ["LandStore"]       = Vector3.new(283.2, 27.0, -99.1),
    ["LogicStore"]      = Vector3.new(4595.3, 12.4, -785.3),
    ["TravelingTrader"] = Vector3.new(-304.4, 27.9, -521.5),
    ["FurnitureStore"]  = Vector3.new(477.3, 8.6, -1722.4),
    ["SaplingCart"]     = Vector3.new(-37.0, 23.9, -2734.3),
    ["PlanterStore"]    = Vector3.new(-597.4, 29.3, -111.4),
    ["CarStore"]        = Vector3.new(482.6, 9.6, -1474.9),
    ["AutumnCatalog"]   = Vector3.new(5970.4, 9.9, 26.4),
    ["Igloo"]           = Vector3.new(2311.5, 261.2, 2982.3),
    ["PlantomicsChoice"]= Vector3.new(187.1, 18.3, -2664.6),
    ["MusicStore"]      = Vector3.new(-412.3, 200.6, 1052.1),
    ["WoodRUs"]         = Vector3.new(268.0, 8.2, 67.4),
}

getStoreCounter = function(storeName)
    return STORE_COUNTER[storeName] or WOODRUS_COUNTER
end

shopCatalog = {}
selectedShopIndex = 1
selectedProductIndex = 1
buyQuantity = 1

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

scanAllShops = function()
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

			local counterPos = getStoreCounter(store.Name)

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

		-- 数量输入框
		local qtyBtn = Instance.new("TextBox")
		qtyBtn.Parent = buyPage
		qtyBtn.Size = UDim2.new(1/3, -px(6), 0, px(18))
		qtyBtn.Position = UDim2.new(0, px(4), 0, px(68))
		qtyBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
		qtyBtn.BorderSizePixel = 0
		qtyBtn.Text = "1"
		qtyBtn.PlaceholderText = "数量"
		qtyBtn.TextColor3 = Color3.fromRGB(145, 103, 134)
		qtyBtn.Font = Enum.Font.GothamBold
		qtyBtn.TextSize = px(9)
		qtyBtn.ZIndex = 10
		qtyBtn.ClearTextOnFocus = true
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
		qtyBtn.FocusLost:Connect(function()
			local n = tonumber(qtyBtn.Text)
			if n and n >= 1 then
				buyQuantity = math.floor(n)
			end
			qtyBtn.Text = tostring(buyQuantity)
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

			-- 直接用缓存 ID，没有就报错不试错
			local cachedId = npcIdCache[storeName]
			if not cachedId then
				pcall(function()
					if fundsConn then fundsConn:Disconnect() end
				end)
				print("[Yutong] 无缓存ID store=", storeName, "请先靠近NPC")
				notify(storeName .. " 无NPC ID，请先靠近商店", "warn")
				return false, nil
			end
			print("[Yutong] 使用缓存 ID=", cachedId, storeName, npcIdConfirmed[storeName] and "(confirmed)" or "(promptchat)")
			if tryId(cachedId) then
				npcIdCache[storeName] = cachedId
				npcIdConfirmed[storeName] = true
				pcall(function()
					if fundsConn then fundsConn:Disconnect() end
				end)
				print("[Yutong] 命中并锁定 ID=", cachedId, storeName)
				pcall(function() notify(storeName .. " ID锁定:" .. tostring(cachedId), "success") end)
				return true, cachedId
			end
			pcall(function()
				playerChatted:InvokeServer(ctx, "EndChat")
			end)
			pcall(function()
				if setVal then setVal:InvokeServer(0) end
			end)
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
					local counter = getStoreCounter(s.name)
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
						task.wait(0.05)

						hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							hrp.CFrame = CFrame.new(counter + Vector3.new(0, 3, 5), counter)
						end
						task.wait(0.05)

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

