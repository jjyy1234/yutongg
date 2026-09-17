-- v8_fly.lua — 飞行功能页
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local RunService = V8.RunService
local nowe = V8.nowe
local CleanupFly = V8.CleanupFly
local StartFly = V8.StartFly
local lavaDeleteEnabled = V8.lavaDeleteEnabled
local StartLavaDelete = V8.StartLavaDelete
local StopLavaDelete = V8.StopLavaDelete
local speeds = V8.speeds
local Mouse = V8.Mouse
local TweenService = V8.TweenService
local Workspace = V8.Workspace
local UserInputService = V8.UserInputService

do
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
end

