local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local KeepInfYield = true
local TeleportCheck = false
if queueteleport then
	game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
		if KeepInfYield and not TeleportCheck then
			TeleportCheck = true
			queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/jjyy1234/yutongg/main/autoduck_fixed.lua'))()")
		end
	end)
end

task.spawn(function()
	while true do
		pcall(function()
			local player = game:GetService("Players").LocalPlayer
			local gui = player.PlayerGui:FindFirstChild("PropertyPurchasingGUI")
			if not gui then return end
			local selectPurchase = gui:FindFirstChild("SelectPurchase")
			local confirmPurchase = gui:FindFirstChild("ConfirmPurchase")
			if not selectPurchase or not confirmPurchase then return end
			local textLabel = selectPurchase:FindFirstChild("Purchase") and selectPurchase.Purchase:FindFirstChild("TextLabel")
			local rightButton = selectPurchase:FindFirstChild("Right")
			if textLabel and textLabel.Text == "Unlock" and rightButton then
				firesignal(rightButton.MouseButton1Click)
				task.wait(0.1)
			elseif textLabel and textLabel.Text == "Select" then
				local purchaseBtn = selectPurchase:FindFirstChild("Purchase")
				local confirmBtn = confirmPurchase:FindFirstChild("Purchase")
				if purchaseBtn then firesignal(purchaseBtn.MouseButton1Click) end
				if confirmBtn then firesignal(confirmBtn.MouseButton1Click) end
			end
		end)
		task.wait(1)
	end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local lp = Players.LocalPlayer
local PAYLOAD = "Ifyouarereadingthisstophackingbrolegitalsokrnlisbadbtw432rewdWdwFe432432rwDWDAVWdawgdGWAYDFGYTUW"
local Interaction = ReplicatedStorage:WaitForChild("Interaction")
local ClientIsDragging = Interaction:WaitForChild("ClientIsDragging")
local ClientInteracted = Interaction:WaitForChild("ClientInteracted")
local activeDragConnections = {}

function notify(title, text, dur)
	dur = dur or 3
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = dur
		})
	end)
end

function tp(pos)
	local char = lp.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local root = char.HumanoidRootPart
		if typeof(pos) == "CFrame" then
			root.CFrame = pos
		elseif typeof(pos) == "Vector3" then
			root.CFrame = CFrame.new(pos)
		end
		root.Velocity = Vector3.new()
		root.RotVelocity = Vector3.new()
	end
end

function getPlayerModels()
	local c = Workspace:FindFirstChild("PlayerModels")
	if not c then
		c = Instance.new("Folder")
		c.Name = "PlayerModels"
		c.Parent = Workspace
	end
	return c
end

function clearDragConnections()
	for _, conn in ipairs(activeDragConnections) do
		pcall(function() conn:Disconnect() end)
	end
	activeDragConnections = {}
end

function waitForLand()
	notify("等待", "正在加载土地...")
	while true do
		local props = Workspace:FindFirstChild("Properties")
		if props then
			for _, p in ipairs(props:GetChildren()) do
				local owner = p:FindFirstChild("Owner")
				if owner and owner.Value == lp then
					local origin = p:FindFirstChild("OriginSquare")
					if origin and origin:IsA("BasePart") then
						notify("成功", "土地已加载")
						return origin.CFrame
					end
				end
			end
		end
		task.wait(0.05)
	end
end

-- 拿永恒剑
function grabEternalSword()
	notify("永恒剑", "正在获取永恒剑...")
	local eternal = ReplicatedStorage:FindFirstChild("Eternal")
	if not eternal then
		notify("错误", "ReplicatedStorage 找不到 Eternal")
		return false
	end
	tp(CFrame.new(-700.3, 22.1, -252.7))
	task.wait(0.5)
	local ok, err = pcall(function()
		ClientInteracted:FireServer(eternal, "Pick up tool")
	end)
	if ok then
		notify("永恒剑", "永恒剑已获取！")
		return true
	else
		notify("错误", "拿剑失败: " .. tostring(err))
		return false
	end
end

-- 等服务器初始化完成（MenuGUI.Open 出现）
local open = lp.PlayerGui:WaitForChild("MenuGUI", 60):WaitForChild("Open", 60)
repeat task.wait() until open.Visible == true

local rs = game:GetService("ReplicatedStorage")
local req = rs:FindFirstChild("LoadSaveRequests")
if req and req:FindFirstChild("RequestLoad") then
	local ok = pcall(function() req.RequestLoad:InvokeServer(1) end)
	if ok then notify("加载成功", "存档槽位1已加载", 3) end
end

task.wait(1)
local homeCF = waitForLand()

function goToCashier()
	local store = Workspace.Stores:FindFirstChild("PlantomicsChoice")
	if not store then return false end
	local parts = store:FindFirstChild("Parts")
	if not parts then return false end
	local controller = parts:FindFirstChild("Controller")
	if not controller then return false end
	local y = controller:FindFirstChild("yes")
	if not y then return false end
	tp(CFrame.new(189.32, 15.2, -2662.76))
	task.wait(0.5)
	return true, y
end

function getClickSequence(y)
	return {
		y.Up.ClickDetector,
		y.Up.ClickDetector,
		y.Down.ClickDetector,
		y.Down.ClickDetector,
		y.Left.ClickDetector,
		y.Right.ClickDetector,
		y.Left.ClickDetector,
		y.Right.ClickDetector,
		y.B.ClickDetector,
		y.A.ClickDetector,
		y.Start.ClickDetector
	}
end

function handleDuck(duckModel)
	if not duckModel or not duckModel.Parent then return false end
	local char = lp.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
	local hrp = char.HumanoidRootPart
	local mainPart = duckModel:FindFirstChild("Main")
	if not mainPart then notify("错误", "找不到 Main 零件") return false end

	clearDragConnections()
	notify("成功", "监听到天堂鸭，开始建立拖拽...")
	local duckPos = mainPart.Position
	hrp.CFrame = CFrame.new(duckPos + Vector3.new(0, 2, 0))
	hrp.Velocity = Vector3.new()
	hrp.RotVelocity = Vector3.new()
	task.wait(0.2)

	local dragConn = RunService.Heartbeat:Connect(function()
		if duckModel and duckModel.Parent then
			ClientIsDragging:FireServer(duckModel, PAYLOAD)
		end
	end)
	table.insert(activeDragConnections, dragConn)

	for i = 1, 100 do
		if not duckModel.Parent then break end
		ClientIsDragging:FireServer(duckModel, PAYLOAD)
		task.wait(0.01)
	end

	if not duckModel.Parent then
		clearDragConnections()
		notify("错误", "鸭子在建立连接时消失")
		return false
	end

	notify("提示", "连接已建立，开始传送回基地...")
	local tpConn = RunService.Heartbeat:Connect(function()
		if duckModel and duckModel.Parent then
			ClientIsDragging:FireServer(duckModel, PAYLOAD)
			mainPart.CFrame = homeCF + Vector3.new(0, 1, 0)
			duckModel:PivotTo(homeCF + Vector3.new(0, 1, 0))
		end
	end)
	table.insert(activeDragConnections, tpConn)

	hrp.CFrame = homeCF + Vector3.new(0, 5, 0)
	hrp.Velocity = Vector3.new()
	hrp.RotVelocity = Vector3.new()

	for i = 1, 120 do
		if not duckModel.Parent then break end
		ClientIsDragging:FireServer(duckModel, PAYLOAD)
		mainPart.CFrame = homeCF + Vector3.new(0, 1, 0)
		duckModel:PivotTo(homeCF + Vector3.new(0, 1, 0))
		RunService.Heartbeat:Wait()
	end

	clearDragConnections()
	if duckModel and duckModel.Parent then
		mainPart.CFrame = homeCF + Vector3.new(0, 1, 0)
		duckModel:PivotTo(homeCF + Vector3.new(0, 1, 0))
	end
	notify("完成", "天堂鸭已传回基地！")
	return true
end

task.spawn(function()
	task.wait()
	notify("开始", "正在获取天堂鸭...")
	for round = 1, 3 do
		notify("提示", "第 " .. round .. "/3 轮尝试...")
		local ok, y = goToCashier()
		if not ok then
			task.wait()
		else
			local pm = getPlayerModels()
			local seq = getClickSequence(y)
			local duckFound = false
			local connection
			connection = pm.ChildAdded:Connect(function(child)
				if child.Name == "DuckAngel" and child:IsA("Model") then
					task.wait()
					if child.Parent then
						duckFound = true
						pcall(function() connection:Disconnect() end)
						handleDuck(child)
					end
				end
			end)

			for _, c in ipairs(seq) do
				if c and c:IsA("ClickDetector") then
					c.MaxActivationDistance = math.huge
					fireclickdetector(c)
				end
				task.wait(0.12)
			end

			local waitStart = tick()
			while tick() - waitStart < 6 do
				if duckFound then
					pcall(function() connection:Disconnect() end)
					-- 拿到鸭了，再去拿永恒剑
					task.wait(1)
					grabEternalSword()
					task.wait(0.5)
					notify("完成", "天堂鸭+永恒剑已获取，3秒后踢出...")
					task.wait(3)
					lp:Kick("天堂鸭已获取，请重进私人服")
					return
				end
				task.wait(0.1)
			end
			pcall(function() connection:Disconnect() end)
		end
		task.wait(0.5)
	end
	notify("未找到", "5秒后踢出，请重进私人服...")
	task.wait(5)
	lp:Kick("未找到天堂鸭，请重进私人服")
end)
