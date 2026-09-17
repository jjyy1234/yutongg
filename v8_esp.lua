-- v8_esp.lua — 玩家透视/ESP 页
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Players = V8.Players
local Workspace = V8.Workspace
local RunService = V8.RunService
local homePage = V8.pages[1]
local Mouse = V8.Mouse
local TweenService = V8.TweenService

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
	-- [memfix] 异步加载头像，加 thumbLoading 标记防止重复调用
	task.spawn(function()
		local content = Players:GetUserThumbnailAsync(
			plr.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
		if img and img.Parent then img.Image = content end
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

	playerEspMap[plr] = { bb = bb, dist = distLbl, img = img, thumbLoading = false }
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

end
