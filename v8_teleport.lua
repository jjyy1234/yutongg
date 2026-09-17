-- v8_teleport.lua — 传送到玩家/观察玩家页 + 传送地点页
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Players = V8.Players
local Workspace = V8.Workspace
local RunService = V8.RunService
local ReplicatedStorage = V8.ReplicatedStorage
local Mouse = V8.Mouse
local createToggle = V8.createToggle
local getItemModel = V8.getItemModel
local isOwnedByMe = V8.isOwnedByMe
local CleanupFly = V8.CleanupFly
local nowe = V8.nowe
local teleportPoint = V8.teleportPoint
local markerBall = V8.markerBall
local selectMode = V8.selectMode
local selectedItems = V8.selectedItems
local selectionBoxes = V8.selectionBoxes
local itemNotifyFrame = V8.itemNotifyFrame
local PlayerGui = V8.PlayerGui
local TweenService = V8.TweenService
local Lighting = V8.Lighting

-- ===== 传送到玩家 / 观察玩家 =====
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

local itemBtn
do
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
	itemBtn = Instance.new("TextButton")
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
					pcall(function()
						dragRemote:FireServer("Begin", item, 5)
						dragRemote:FireServer("Refresh", item, 5)
						dragRemote:FireServer("End", item, 5)
					end)
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
end

