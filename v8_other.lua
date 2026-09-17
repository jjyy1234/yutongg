-- v8_other.lua — 其他页（合成恶魔鸭、星空鸭、Doom剑、Doom核心、炸基地等）
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Workspace = V8.Workspace
local ReplicatedStorage = V8.ReplicatedStorage
local Players = V8.Players
local RunService = V8.RunService
local isOwnedByMe = V8.isOwnedByMe
local isUnowned = V8.isUnowned
local teleportOneItem = V8.teleportOneItem
local findOwnedItem = V8.findOwnedItem
local findUnownedItem = V8.findUnownedItem
local findUnownedDuckAngel = V8.findUnownedDuckAngel
local identifyMaterials = V8.identifyMaterials
local getStoreCounter = V8.getStoreCounter
local getMoney = V8.getMoney
local getStoreBaseIds = V8.getStoreBaseIds
local npcIdCache = V8.npcIdCache
local npcCtxCache = V8.npcCtxCache
local npcIdConfirmed = V8.npcIdConfirmed
local createOtherBtn = V8.createOtherBtn
local currentY = V8.currentY
local otherPage = V8.otherPage
local Mouse = V8.Mouse
local TweenService = V8.TweenService
local Lighting = V8.Lighting
local TeleportService = V8.TeleportService
local VirtualUser = V8.VirtualUser

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
										pcall(function()
											dragRemote:FireServer("Begin", target, 5)
											dragRemote:FireServer("Refresh", target, 5)
											dragRemote:FireServer("End", target, 5)
										end)
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

			local counter = getStoreCounter(storeName)

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
					local cachedId = npcIdCache[storeName]
					if not cachedId then
						print("[Yutong] 兜底购买: 无缓存ID store=", storeName)
					else
						local ctx = npcCtxCache[storeName] or {
							Character = thom,
							Name = thom.Name,
							ID = cachedId,
							Dialog = thom:FindFirstChild("Dialog"),
						}
						ctx.ID = cachedId
						local before = getMoney() or moneyBefore
						pcall(function() playerChatted:InvokeServer(ctx, "Initiate") end)
						task.wait(0.05)
						pcall(function() playerChatted:InvokeServer(ctx, "ConfirmPurchase") end)
						local t0 = tick()
						while tick() - t0 < 0.22 do
							local m = getMoney()
							if type(before) == "number" and type(m) == "number" and m < before - 0.5 then
								bought, hitId = true, cachedId
								npcIdCache[storeName] = cachedId
								npcIdConfirmed[storeName] = true
								break
							end
							task.wait(0.05)
						end
						pcall(function()
							playerChatted:InvokeServer(ctx, "EndChat")
							if setVal then setVal:InvokeServer(0) end
						end)
					end
				end
			end

			if bought then
				pcall(function() notify("已购 " .. matName .. (hitId and (" ID:" .. hitId) or ""), "success") end)
			else
				pcall(function() notify("购买失败 " .. matName, "warn") end)
			end
			task.wait(0.04)
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
				if clientDragging then
					clientDragging:FireServer("Begin", target, 5)
					clientDragging:FireServer("Refresh", target, 5)
					clientDragging:FireServer("End", target, 5)
				end
			end)
			task.wait(0.2)
			pcall(function()
				if clientDragging then
					clientDragging:FireServer("Begin", target, 5)
					clientDragging:FireServer("Refresh", target, 5)
					clientDragging:FireServer("End", target, 5)
				end
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

-- ===== 刷粉车功能 =====
do
    local pinkSectionY = currentY

    -- ---- 车位选择区 ----
    local pinkSpotCard = Instance.new("Frame")
    pinkSpotCard.Name = "PinkSpotCard"
    pinkSpotCard.Parent = otherPage
    pinkSpotCard.Size = UDim2.new(1, -px(8), 0, px(56))
    pinkSpotCard.Position = UDim2.new(0, px(4), 0, pinkSectionY)
    pinkSpotCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pinkSpotCard.BorderSizePixel = 0
    Instance.new("UICorner", pinkSpotCard).CornerRadius = UDim.new(0, px(6))
    do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(220, 220, 228) s.Thickness = 1 s.Parent = pinkSpotCard end

    local pinkSpotLabel = Instance.new("TextLabel")
    pinkSpotLabel.Parent = pinkSpotCard
    pinkSpotLabel.BackgroundTransparency = 1
    pinkSpotLabel.Size = UDim2.new(1, -px(58), 0, px(14))
    pinkSpotLabel.Position = UDim2.new(0, px(4), 0, px(4))
    pinkSpotLabel.Text = "选择车位 (Select Spot)"
    pinkSpotLabel.TextColor3 = Color3.fromRGB(80, 80, 88)
    pinkSpotLabel.Font = Enum.Font.GothamMedium
    pinkSpotLabel.TextSize = px(9)
    pinkSpotLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- 刷新车位按钮
    local pinkRefreshBtn = Instance.new("TextButton")
    pinkRefreshBtn.Parent = pinkSpotCard
    pinkRefreshBtn.Size = UDim2.new(0, px(50), 0, px(14))
    pinkRefreshBtn.Position = UDim2.new(1, -px(54), 0, px(4))
    pinkRefreshBtn.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
    pinkRefreshBtn.BorderSizePixel = 0
    pinkRefreshBtn.Text = "↻ 刷新"
    pinkRefreshBtn.TextColor3 = Color3.fromRGB(50, 50, 58)
    pinkRefreshBtn.Font = Enum.Font.GothamMedium
    pinkRefreshBtn.TextSize = px(10)
    pinkRefreshBtn.AutoButtonColor = false
    Instance.new("UICorner", pinkRefreshBtn).CornerRadius = UDim.new(0, px(3))

    -- 车位按钮容器（滚动）
    local pinkSpotList = Instance.new("ScrollingFrame")
    pinkSpotList.Name = "PinkSpotList"
    pinkSpotList.Parent = pinkSpotCard
    pinkSpotList.Size = UDim2.new(1, -px(8), 0, px(34))
    pinkSpotList.Position = UDim2.new(0, px(4), 0, px(20))
    pinkSpotList.BackgroundTransparency = 1
    pinkSpotList.BorderSizePixel = 0
    pinkSpotList.ScrollBarThickness = px(2)
    pinkSpotList.ScrollBarImageColor3 = Color3.fromRGB(220, 220, 228)
    pinkSpotList.CanvasSize = UDim2.new(0, 0, 0, 0)
    pinkSpotList.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local pinkSpotListLayout = Instance.new("UIListLayout")
    pinkSpotListLayout.Parent = pinkSpotList
    pinkSpotListLayout.Padding = UDim.new(0, px(4))
    pinkSpotListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    pinkSectionY = pinkSectionY + px(60)

    -- ---- 状态显示区 ----
    local pinkStatusCard = Instance.new("Frame")
    pinkStatusCard.Name = "PinkStatusCard"
    pinkStatusCard.Parent = otherPage
    pinkStatusCard.Size = UDim2.new(1, -px(8), 0, px(56))
    pinkStatusCard.Position = UDim2.new(0, px(4), 0, pinkSectionY)
    pinkStatusCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pinkStatusCard.BorderSizePixel = 0
    Instance.new("UICorner", pinkStatusCard).CornerRadius = UDim.new(0, px(6))
    do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(220, 220, 228) s.Thickness = 1 s.Parent = pinkStatusCard end

    local pinkStatusLabel = Instance.new("TextLabel")
    pinkStatusLabel.Parent = pinkStatusCard
    pinkStatusLabel.BackgroundTransparency = 1
    pinkStatusLabel.Size = UDim2.new(1, -px(8), 0, px(14))
    pinkStatusLabel.Position = UDim2.new(0, px(4), 0, px(4))
    pinkStatusLabel.Text = "状态 (Status)"
    pinkStatusLabel.TextColor3 = Color3.fromRGB(80, 80, 88)
    pinkStatusLabel.Font = Enum.Font.GothamMedium
    pinkStatusLabel.TextSize = px(9)
    pinkStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- 当前颜色
    local pinkColorRow = Instance.new("TextLabel")
    pinkColorRow.Parent = pinkStatusCard
    pinkColorRow.BackgroundTransparency = 1
    pinkColorRow.Size = UDim2.new(1, -px(8), 0, px(13))
    pinkColorRow.Position = UDim2.new(0, px(4), 0, px(18))
    pinkColorRow.Text = "当前颜色: —"
    pinkColorRow.TextColor3 = Color3.fromRGB(40, 40, 48)
    pinkColorRow.Font = Enum.Font.Gotham
    pinkColorRow.TextSize = px(9)
    pinkColorRow.TextXAlignment = Enum.TextXAlignment.Left

    -- 已刷次数
    local pinkCountRow = Instance.new("TextLabel")
    pinkCountRow.Parent = pinkStatusCard
    pinkCountRow.BackgroundTransparency = 1
    pinkCountRow.Size = UDim2.new(1, -px(8), 0, px(13))
    pinkCountRow.Position = UDim2.new(0, px(4), 0, px(31))
    pinkCountRow.Text = "已刷次数: 0"
    pinkCountRow.TextColor3 = Color3.fromRGB(40, 40, 48)
    pinkCountRow.Font = Enum.Font.Gotham
    pinkCountRow.TextSize = px(9)
    pinkCountRow.TextXAlignment = Enum.TextXAlignment.Left

    -- 运行状态
    local pinkRunRow = Instance.new("TextLabel")
    pinkRunRow.Parent = pinkStatusCard
    pinkRunRow.BackgroundTransparency = 1
    pinkRunRow.Size = UDim2.new(1, -px(8), 0, px(13))
    pinkRunRow.Position = UDim2.new(0, px(4), 0, px(44))
    pinkRunRow.Text = "运行: 待机"
    pinkRunRow.TextColor3 = Color3.fromRGB(40, 40, 48)
    pinkRunRow.Font = Enum.Font.GothamMedium
    pinkRunRow.TextSize = px(9)
    pinkRunRow.TextXAlignment = Enum.TextXAlignment.Left

    pinkSectionY = pinkSectionY + px(60)

    -- ---- 按钮区 ----
    local pinkBtnRow = Instance.new("Frame")
    pinkBtnRow.Name = "PinkButtonRow"
    pinkBtnRow.Parent = otherPage
    pinkBtnRow.Size = UDim2.new(1, 0, 0, px(22))
    pinkBtnRow.Position = UDim2.new(0, px(4), 0, pinkSectionY)
    pinkBtnRow.BackgroundTransparency = 1

    local pinkBtnLayout = Instance.new("UIListLayout")
    pinkBtnLayout.Parent = pinkBtnRow
    pinkBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    pinkBtnLayout.Padding = UDim.new(0, px(4))
    pinkBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pinkStartBtn = Instance.new("TextButton")
    pinkStartBtn.Parent = pinkBtnRow
    pinkStartBtn.Size = UDim2.new(0.5, -px(2), 1, 0)
    pinkStartBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    pinkStartBtn.BorderSizePixel = 0
    pinkStartBtn.Text = "Start"
    pinkStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pinkStartBtn.Font = Enum.Font.GothamBold
    pinkStartBtn.TextSize = px(10)
    pinkStartBtn.AutoButtonColor = false
    Instance.new("UICorner", pinkStartBtn).CornerRadius = UDim.new(0, px(4))

    local pinkStopBtn = Instance.new("TextButton")
    pinkStopBtn.Parent = pinkBtnRow
    pinkStopBtn.Size = UDim2.new(0.5, -px(2), 1, 0)
    pinkStopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    pinkStopBtn.BorderSizePixel = 0
    pinkStopBtn.Text = "Stop"
    pinkStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pinkStopBtn.Font = Enum.Font.GothamBold
    pinkStopBtn.TextSize = px(10)
    pinkStopBtn.AutoButtonColor = false
    Instance.new("UICorner", pinkStopBtn).CornerRadius = UDim.new(0, px(4))

    pinkSectionY = pinkSectionY + px(26)
    currentY = pinkSectionY

    -- ---- 车位列表渲染 ----
    local function pinkClearSpotButtons()
        for _, entry in ipairs(pinkCarSpotButtons) do
            if entry.button and entry.button.Parent then
                entry.button:Destroy()
            end
        end
        pinkCarSpotButtons = {}
    end

    local function pinkHighlightSpotButton(btn)
        for _, entry in ipairs(pinkCarSpotButtons) do
            entry.button.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
            entry.button.TextColor3 = Color3.fromRGB(50, 50, 58)
        end
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    local function pinkRenderSpots()
        pinkClearSpotButtons()
        local spots = pinkCarFindSpots()
        if #spots == 0 then
            local empty = Instance.new("TextLabel")
            empty.Parent = pinkSpotList
            empty.Size = UDim2.new(1, 0, 0, px(14))
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextSize = px(9)
            empty.TextColor3 = Color3.fromRGB(80, 80, 88)
            empty.Text = "未找到车位，点刷新重试"
            return
        end
        for i, spot in ipairs(spots) do
            local btn = Instance.new("TextButton")
            btn.Parent = pinkSpotList
            btn.Size = UDim2.new(1, 0, 0, px(18))
            btn.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = px(9)
            btn.TextColor3 = Color3.fromRGB(50, 50, 58)
            btn.Text = spot.Name
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, px(3))
            do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(220, 220, 228) s.Thickness = 0.5 s.Parent = btn end

            btn.MouseButton1Click:Connect(function()
                pinkCarSelectedSpot = spot
                pinkHighlightSpotButton(btn)
            end)

            table.insert(pinkCarSpotButtons, {button = btn, spot = spot})
        end
    end

    pinkRefreshBtn.MouseButton1Click:Connect(function()
        pinkRenderSpots()
    end)

    -- 初始渲染
    pinkRenderSpots()

    -- ---- 状态更新 ----
    local function pinkUpdateStatus(colorText, countText, runText, statusColor)
        pinkColorRow.Text = "当前颜色: " .. colorText
        pinkCountRow.Text = "已刷次数: " .. tostring(countText)
        pinkRunRow.Text = "运行: " .. runText
        if statusColor then
            pinkStatusCard.BackgroundColor3 = statusColor
        else
            pinkStatusCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    -- ---- 主循环逻辑 ----
    local function pinkRunFarmLoop()
        if not pinkCarSelectedSpot then
            pinkUpdateStatus("—", pinkCarAttemptCount, "请先选择车位!", Color3.fromRGB(255, 230, 230))
            return
        end

        pinkCarRunning = true
        pinkCarAttemptCount = 0
        pinkUpdateStatus("—", pinkCarAttemptCount, "运行中...", Color3.fromRGB(220, 235, 255))

        while pinkCarRunning do
            local spot = pinkCarSelectedSpot
            if not spot or not spot.Parent then
                pinkUpdateStatus("—", pinkCarAttemptCount, "车位已消失，停止", Color3.fromRGB(255, 230, 230))
                pinkCarRunning = false
                break
            end

            local fireBtn = spot:FindFirstChild("ButtonRemote_SpawnButton")
            if not fireBtn then
                pinkUpdateStatus("—", pinkCarAttemptCount, "车位按钮丢失!", Color3.fromRGB(255, 230, 230))
                pinkCarRunning = false
                break
            end

            pcall(function()
                ReplicatedStorage.Interaction.RemoteProxy:FireServer(fireBtn)
            end)

            local newCar = pinkCarWaitForNewCar(15)
            if not newCar then
                pinkUpdateStatus("超时", pinkCarAttemptCount, "等待超时，重试...", Color3.fromRGB(220, 235, 255))
                task.wait(0.5)
            else
                local colorName = pinkCarGetColorName(newCar)
                pinkCarAttemptCount = pinkCarAttemptCount + 1

                if pinkCarIsPink(newCar) then
                    pinkUpdateStatus("Hot pink ★", pinkCarAttemptCount, "Found! Hot pink car spawned!", Color3.fromRGB(220, 245, 230))
                    pinkCarRunning = false
                    break
                else
                    pinkUpdateStatus(colorName, pinkCarAttemptCount, "运行中...", Color3.fromRGB(220, 235, 255))
                    task.wait(0.5)
                end
            end
        end

        if not pinkCarRunning then
            if not pinkColorRow.Text:find("Hot pink") then
                pinkUpdateStatus(pinkColorRow.Text:gsub("^当前颜色: ", ""), pinkCarAttemptCount, "已停止", Color3.fromRGB(255, 255, 255))
            end
        end
    end

    -- ---- 按钮事件 ----
    pinkStartBtn.MouseButton1Click:Connect(function()
        if pinkCarRunning then return end
        task.spawn(function()
            pinkRunFarmLoop()
        end)
    end)

    pinkStopBtn.MouseButton1Click:Connect(function()
        pinkCarRunning = false
        pinkUpdateStatus(pinkColorRow.Text:gsub("^当前颜色: ", ""), pinkCarAttemptCount, "已停止", Color3.fromRGB(255, 255, 255))
    end)

    -- 初始状态
    pinkUpdateStatus("—", 0, "待机", Color3.fromRGB(255, 255, 255))
end

-- ===== 岩浆陷阱功能 =====
do
    local magmaY = currentY

    -- 标题
    local magmaTitle = Instance.new("TextLabel")
    magmaTitle.Name = "MagmaTrapTitle"
    magmaTitle.Parent = otherPage
    magmaTitle.BackgroundTransparency = 1
    magmaTitle.Position = UDim2.new(0, px(4), 0, magmaY)
    magmaTitle.Size = UDim2.new(1, -px(8), 0, px(14))
    magmaTitle.Text = "Magma Trap"
    magmaTitle.TextColor3 = Color3.fromRGB(145, 103, 134)
    magmaTitle.Font = Enum.Font.GothamBold
    magmaTitle.TextSize = px(9)
    magmaTitle.TextXAlignment = Enum.TextXAlignment.Left
    magmaY = magmaY + px(16)

    -- 玩家选择卡
    local magmaPlayerCard = Instance.new("Frame")
    magmaPlayerCard.Name = "MagmaPlayerCard"
    magmaPlayerCard.Parent = otherPage
    magmaPlayerCard.Size = UDim2.new(1, -px(8), 0, px(80))
    magmaPlayerCard.Position = UDim2.new(0, px(4), 0, magmaY)
    magmaPlayerCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    magmaPlayerCard.BorderSizePixel = 0
    Instance.new("UICorner", magmaPlayerCard).CornerRadius = UDim.new(0, px(6))
    do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(220, 220, 228) s.Thickness = 1 s.Parent = magmaPlayerCard end

    local magmaPlayerLabel = Instance.new("TextLabel")
    magmaPlayerLabel.Parent = magmaPlayerCard
    magmaPlayerLabel.BackgroundTransparency = 1
    magmaPlayerLabel.Size = UDim2.new(1, -px(50), 0, px(14))
    magmaPlayerLabel.Position = UDim2.new(0, px(4), 0, px(4))
    magmaPlayerLabel.Text = "目标玩家"
    magmaPlayerLabel.TextColor3 = Color3.fromRGB(80, 80, 88)
    magmaPlayerLabel.Font = Enum.Font.GothamMedium
    magmaPlayerLabel.TextSize = px(9)
    magmaPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left

    local magmaRefreshBtn = Instance.new("TextButton")
    magmaRefreshBtn.Parent = magmaPlayerCard
    magmaRefreshBtn.Size = UDim2.new(0, px(40), 0, px(12))
    magmaRefreshBtn.Position = UDim2.new(1, -px(44), 0, px(4))
    magmaRefreshBtn.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
    magmaRefreshBtn.BorderSizePixel = 0
    magmaRefreshBtn.Text = "↻ 刷新"
    magmaRefreshBtn.TextColor3 = Color3.fromRGB(90, 70, 85)
    magmaRefreshBtn.Font = Enum.Font.GothamMedium
    magmaRefreshBtn.TextSize = px(8)
    magmaRefreshBtn.AutoButtonColor = false
    Instance.new("UICorner", magmaRefreshBtn).CornerRadius = UDim.new(0, px(3))

    local magmaSelectedLbl = Instance.new("TextLabel")
    magmaSelectedLbl.Parent = magmaPlayerCard
    magmaSelectedLbl.BackgroundTransparency = 1
    magmaSelectedLbl.Size = UDim2.new(1, -px(8), 0, px(12))
    magmaSelectedLbl.Position = UDim2.new(0, px(4), 0, px(18))
    magmaSelectedLbl.Text = "未选择"
    magmaSelectedLbl.TextColor3 = Color3.fromRGB(145, 103, 134)
    magmaSelectedLbl.Font = Enum.Font.Gotham
    magmaSelectedLbl.TextSize = px(8)
    magmaSelectedLbl.TextXAlignment = Enum.TextXAlignment.Left

    local magmaPlayerScroll = Instance.new("ScrollingFrame")
    magmaPlayerScroll.Parent = magmaPlayerCard
    magmaPlayerScroll.Size = UDim2.new(1, -px(8), 0, px(36))
    magmaPlayerScroll.Position = UDim2.new(0, px(4), 0, px(32))
    magmaPlayerScroll.BackgroundTransparency = 1
    magmaPlayerScroll.BorderSizePixel = 0
    magmaPlayerScroll.ScrollBarThickness = px(2)
    magmaPlayerScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 180, 195)
    magmaPlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    magmaPlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local magmaScrollLayout = Instance.new("UIListLayout")
    magmaScrollLayout.Parent = magmaPlayerScroll
    magmaScrollLayout.Padding = UDim.new(0, px(2))

    local magma_targetPlayer = nil

    local function magma_renderPlayers()
        for _, c in ipairs(magmaPlayerScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= speaker then
                local btn = Instance.new("TextButton")
                btn.Parent = magmaPlayerScroll
                btn.Size = UDim2.new(1, 0, 0, px(14))
                btn.BackgroundColor3 = Color3.fromRGB(235, 225, 233)
                btn.BorderSizePixel = 0
                btn.Font = Enum.Font.GothamMedium
                btn.TextSize = px(8)
                btn.TextColor3 = Color3.fromRGB(90, 70, 85)
                btn.Text = p.Name
                btn.AutoButtonColor = false
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, px(3))
                btn.MouseButton1Click:Connect(function()
                    magma_targetPlayer = p
                    magmaSelectedLbl.Text = "→ " .. p.Name
                end)
            end
        end
    end
    magmaRefreshBtn.MouseButton1Click:Connect(magma_renderPlayers)
    magma_renderPlayers()

    magmaY = magmaY + px(84)

    -- 状态卡
    local magmaStatusCard = Instance.new("Frame")
    magmaStatusCard.Name = "MagmaStatusCard"
    magmaStatusCard.Parent = otherPage
    magmaStatusCard.Size = UDim2.new(1, -px(8), 0, px(22))
    magmaStatusCard.Position = UDim2.new(0, px(4), 0, magmaY)
    magmaStatusCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    magmaStatusCard.BorderSizePixel = 0
    Instance.new("UICorner", magmaStatusCard).CornerRadius = UDim.new(0, px(6))
    do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(220, 220, 228) s.Thickness = 1 s.Parent = magmaStatusCard end

    local magmaStatusLbl = Instance.new("TextLabel")
    magmaStatusLbl.Parent = magmaStatusCard
    magmaStatusLbl.BackgroundTransparency = 1
    magmaStatusLbl.Size = UDim2.new(1, -px(8), 1, 0)
    magmaStatusLbl.Position = UDim2.new(0, px(4), 0, 0)
    magmaStatusLbl.Text = "状态: 待机"
    magmaStatusLbl.TextColor3 = Color3.fromRGB(100, 80, 95)
    magmaStatusLbl.Font = Enum.Font.GothamMedium
    magmaStatusLbl.TextSize = px(9)
    magmaStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    magmaY = magmaY + px(26)

    -- 按钮行
    local magmaBtnRow = Instance.new("Frame")
    magmaBtnRow.Name = "MagmaButtonRow"
    magmaBtnRow.Parent = otherPage
    magmaBtnRow.Size = UDim2.new(1, 0, 0, px(20))
    magmaBtnRow.Position = UDim2.new(0, px(4), 0, magmaY)
    magmaBtnRow.BackgroundTransparency = 1

    local magmaBtnLayout = Instance.new("UIListLayout")
    magmaBtnLayout.Parent = magmaBtnRow
    magmaBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    magmaBtnLayout.Padding = UDim.new(0, px(4))

    local magmaAimBtn = Instance.new("TextButton")
    magmaAimBtn.Parent = magmaBtnRow
    magmaAimBtn.Size = UDim2.new(0.5, -px(2), 1, 0)
    magmaAimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    magmaAimBtn.BorderSizePixel = 0
    magmaAimBtn.Text = "对准"
    magmaAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    magmaAimBtn.Font = Enum.Font.GothamBold
    magmaAimBtn.TextSize = px(10)
    magmaAimBtn.AutoButtonColor = false
    Instance.new("UICorner", magmaAimBtn).CornerRadius = UDim.new(0, px(4))

    local magmaCancelBtn = Instance.new("TextButton")
    magmaCancelBtn.Parent = magmaBtnRow
    magmaCancelBtn.Size = UDim2.new(0.5, -px(2), 1, 0)
    magmaCancelBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    magmaCancelBtn.BorderSizePixel = 0
    magmaCancelBtn.Text = "取消"
    magmaCancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    magmaCancelBtn.Font = Enum.Font.GothamBold
    magmaCancelBtn.TextSize = px(10)
    magmaCancelBtn.AutoButtonColor = false
    Instance.new("UICorner", magmaCancelBtn).CornerRadius = UDim.new(0, px(4))

    magmaY = magmaY + px(24)
    currentY = magmaY

    -- ---- 核心逻辑 ----
    local magma_occupantConn = nil
    local magma_isWaiting = false

    magmaAimBtn.MouseButton1Click:Connect(function()
        if not magma_targetPlayer then
            magmaStatusLbl.Text = "状态: 请先选择目标！"
            return
        end
        local tChar = magma_targetPlayer.Character
        local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            magmaStatusLbl.Text = "状态: 找不到目标位置"
            return
        end

        local car, _, passSeat = magma_findMyCar()
        if not car then
            magmaStatusLbl.Text = "状态: 找不到你的车！"
            return
        end
        if not passSeat then
            magmaStatusLbl.Text = "状态: 找不到 Seat！"
            return
        end

        -- 算副驾(Seat)相对车整体的偏移，把车移过去让 Seat 贴到目标 HRP
        local carPivot = car:GetPivot()
        local seatLocalOffset = carPivot:ToObjectSpace(passSeat.CFrame)
        local newCarCF = tHRP.CFrame * seatLocalOffset:Inverse()

        pcall(function()
            local _r = ReplicatedStorage.Interaction.ClientIsDragging
            _r:FireServer("Begin", car, 5)
            _r:FireServer("Refresh", car, 5)
            _r:FireServer("End", car, 5)
            car:PivotTo(newCarCF)
        end)

        magmaStatusLbl.Text = "状态: 已对准，等待上车..."
        pcall(function() notify("Magma Trap: 副驾已对准 " .. magma_targetPlayer.Name, "info") end)
        magma_isWaiting = true

        if magma_occupantConn then magma_occupantConn:Disconnect(); magma_occupantConn = nil end

        magma_occupantConn = passSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if not magma_isWaiting then return end
            local occ = passSeat.Occupant
            if occ and occ.Parent and occ.Parent.Name == magma_targetPlayer.Name then
                magma_isWaiting = false
                magma_occupantConn:Disconnect(); magma_occupantConn = nil
                magmaStatusLbl.Text = "状态: 上车！→ 岩浆"
                pcall(function() notify(magma_targetPlayer.Name .. " 上车！", "success") end)
                task.spawn(function()
                    for i = 1, 20 do
                        pcall(function()
                            local _r = ReplicatedStorage.Interaction.ClientIsDragging
                            _r:FireServer("Begin", car, 5)
                            _r:FireServer("Refresh", car, 5)
                            _r:FireServer("End", car, 5)
                            car:PivotTo(MAGMA_CF + Vector3.new(0, 2, 0))
                        end)
                        task.wait(0.03)
                    end
                    magmaStatusLbl.Text = "状态: 完成！"
                    pcall(function() notify("Magma Trap 完成！", "success") end)
                end)
            end
        end)
    end)

    magmaCancelBtn.MouseButton1Click:Connect(function()
        magma_isWaiting = false
        if magma_occupantConn then magma_occupantConn:Disconnect(); magma_occupantConn = nil end
        magmaStatusLbl.Text = "状态: 已取消"
    end)
end

