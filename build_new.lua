-- YUTONG-AutoBuild by YUTONGG
-- Uses ClientPlacedBlueprint to auto-build from blueprint data
-- Building data loaded from GitHub via HttpGet
-- v2: added Fill (Floor1Tiny ground fill) and Paint (PaintTool) functions

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- 从 GitHub 加载白名单
local WHITELIST = {}
do
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
end

if not WHITELIST[lp.Name] then
	lp:Kick("Unauthorized")
	return
end

local placeRemote = ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint
local paintRemote = ReplicatedStorage.PlaceStructure.PaintTool

-- 从 GitHub 加载建筑数据
local DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data_new.lua", true))()
local dataCount = #DATA

local function notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 3,
		})
	end)
end

-- 构建坐标→wood 查找表（用于 Paint 按最近坐标匹配颜色）
local woodLookup = {}
do
	for i, d in ipairs(DATA) do
		if d.wood and d.wood ~= "?" then
			table.insert(woodLookup, {x = d.x, y = d.y, z = d.z, wood = d.wood})
		end
	end
end

local function findNearestWood(x, y, z)
	local best = nil
	local bestDist = math.huge
	for _, w in ipairs(woodLookup) do
		local dx = w.x - x
		local dy = w.y - y
		local dz = w.z - z
		local dist = dx*dx + dy*dy + dz*dz
		if dist < bestDist then
			bestDist = dist
			best = w.wood
		end
	end
	return best
end

local W = Color3.fromRGB(255,255,255)
local TEXT = Color3.fromRGB(0,0,0)
local SUBTEXT = Color3.fromRGB(60,60,60)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YUTONG_AutoBuild"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,240,0,320)
main.Position = UDim2.new(0,10,0.5,-160)
main.BackgroundColor3 = W
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = W
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,12)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,0,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "YUTONG AutoBuild"
titleLbl.TextColor3 = TEXT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = titleBar

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,0,40)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Ready (" .. dataCount .. " blocks)"
statusLbl.TextColor3 = SUBTEXT
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

local progressLbl = Instance.new("TextLabel")
progressLbl.Size = UDim2.new(1,-16,0,18)
progressLbl.Position = UDim2.new(0,8,0,60)
progressLbl.BackgroundTransparency = 1
progressLbl.Text = "Progress: 0/" .. dataCount
progressLbl.TextColor3 = TEXT
progressLbl.TextSize = 11
progressLbl.Font = Enum.Font.GothamBold
progressLbl.TextXAlignment = Enum.TextXAlignment.Left
progressLbl.Parent = main

-- helper: create a button row with optional input box beside it
local function makeBtnWithInput(btnText, inputText, inputDefault, y)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,100,0,30)
	btn.Position = UDim2.new(0,8,0,y)
	btn.BackgroundColor3 = W
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 0
	btn.Text = btnText
	btn.TextColor3 = TEXT
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = main
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1,-120,0,30)
	box.Position = UDim2.new(0,116,0,y)
	box.BackgroundColor3 = W
	box.BackgroundTransparency = 0.4
	box.BorderSizePixel = 0
	box.Text = inputDefault or ""
	box.PlaceholderText = inputText or ""
	box.TextColor3 = TEXT
	box.PlaceholderColor3 = SUBTEXT
	box.TextSize = 11
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.Parent = main
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)

	return btn, box
end

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
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
	return btn
end

-- Build button (full width)
local buildBtn = makeBtn("Build", 88)

-- Fill button + range input
local fillBtn, fillBox = makeBtnWithInput("Fill", "Range", "10", 126)

-- Paint button + color input
local paintBtn, paintBox = makeBtnWithInput("Paint", "Color", "LoneCave", 164)

-- Stop button (full width)
local stopBtn = makeBtn("Stop", 202)

local running = false

-- Build: place all blueprint data blocks
buildBtn.MouseButton1Click:Connect(function()
	if running then
		notify("YUTONG", "Already running, press Stop first", 2)
		return
	end
	running = true
	buildBtn.Text = "Building..."
	statusLbl.Text = "Building..."
	notify("YUTONG", "Build started: " .. dataCount .. " blocks", 3)
	local cnt = 0
	task.spawn(function()
		for i, d in ipairs(DATA) do
			if not running then break end
			pcall(function()
				placeRemote:FireServer(d.n, CFrame.new(d.x, d.y, d.z,
					d.r00, d.r01, d.r02,
					d.r10, d.r11, d.r12,
					d.r20, d.r21, d.r22), lp)
			end)
			cnt = cnt + 1
			progressLbl.Text = "Progress: " .. cnt .. "/" .. dataCount
			task.wait(0.01)
		end
		statusLbl.Text = running and ("Done! " .. cnt .. "/" .. dataCount) or "Stopped at " .. cnt .. "/" .. dataCount
		if running then
			notify("YUTONG", "Build complete: " .. cnt .. " blocks", 4)
		end
		buildBtn.Text = "Build"
		running = false
	end)
end)

-- Fill: place Floor1Tiny in a grid centered on player position
fillBtn.MouseButton1Click:Connect(function()
	if running then
		notify("YUTONG", "Already running, press Stop first", 2)
		return
	end
	local range = tonumber(fillBox.Text) or 10
	if range < 1 then range = 1 end
	if range > 200 then range = 200 end
	local total = range * range
	running = true
	fillBtn.Text = "Filling..."
	statusLbl.Text = "Filling " .. total .. " blocks..."
	notify("YUTONG", "Fill started: " .. total .. " Floor1Tiny", 3)
	local cnt = 0
	task.spawn(function()
		local char = lp.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then
			notify("YUTONG", "Character not found", 3)
			fillBtn.Text = "Fill"
			running = false
			return
		end
		local pos = char.HumanoidRootPart.Position
		local cx = math.floor(pos.X / 2 + 0.5) * 2
		local cz = math.floor(pos.Z / 2 + 0.5) * 2
		local half = math.floor(range / 2)
		for ix = -half, range - half - 1 do
			for iz = -half, range - half - 1 do
				if not running then break end
				local x = cx + ix * 2
				local z = cz + iz * 2
				pcall(function()
					placeRemote:FireServer("Floor1Tiny",
						CFrame.new(x, 0.2, z, 1, 0, 0, 0, 1, 0, 0, 0, 1), lp)
				end)
				cnt = cnt + 1
				progressLbl.Text = "Progress: " .. cnt .. "/" .. total
				task.wait(0.01)
			end
			if not running then break end
		end
		statusLbl.Text = running and ("Fill done! " .. cnt .. "/" .. total) or "Stopped at " .. cnt .. "/" .. total
		if running then
			notify("YUTONG", "Fill complete: " .. cnt .. " blocks", 4)
		end
		fillBtn.Text = "Fill"
		running = false
	end)
end)

-- Paint: scan workspace for models owned by lp and paint them
paintBtn.MouseButton1Click:Connect(function()
	if running then
		notify("YUTONG", "Already running, press Stop first", 2)
		return
	end
	running = true
	paintBtn.Text = "Painting..."
	statusLbl.Text = "Scanning workspace..."
	notify("YUTONG", "Paint started", 3)
	local cnt = 0
	task.spawn(function()
		local playerModels = workspace:FindFirstChild("PlayerModels")
		if not playerModels then
			-- fallback: scan all workspace children
			playerModels = workspace
		end
		-- collect all models with Owner == lp
		local targets = {}
		for _, obj in ipairs(playerModels:GetChildren()) do
			if obj:IsA("Model") then
				local owner = obj:FindFirstChild("Owner")
				if owner and owner:IsA("ObjectValue") and owner.Value == lp then
					table.insert(targets, obj)
				end
			end
		end
		local total = #targets
		statusLbl.Text = "Found " .. total .. " models to paint"
		progressLbl.Text = "Progress: 0/" .. total
		local defaultColor = paintBox.Text
		if not defaultColor or #defaultColor == 0 then
			defaultColor = "LoneCave"
		end
		for i, model in ipairs(targets) do
			if not running then break end
			-- determine color: try nearest data entry's wood, fallback to input box
			local colorName = defaultColor
			local primary = model.PrimaryPart
			if primary then
				local pos = primary.Position
				local nearestWood = findNearestWood(pos.X, pos.Y, pos.Z)
				if nearestWood then
					colorName = nearestWood
				end
			end
			pcall(function()
				paintRemote:FireServer(model, colorName)
			end)
			cnt = cnt + 1
			progressLbl.Text = "Progress: " .. cnt .. "/" .. total
			task.wait(0.01)
		end
		statusLbl.Text = running and ("Paint done! " .. cnt .. "/" .. total) or "Stopped at " .. cnt .. "/" .. total
		if running then
			notify("YUTONG", "Paint complete: " .. cnt .. " models", 4)
		end
		paintBtn.Text = "Paint"
		running = false
	end)
end)

-- Stop button
stopBtn.MouseButton1Click:Connect(function()
	if running then
		running = false
		statusLbl.Text = "Stopped"
		notify("YUTONG", "Stopped", 2)
	else
		notify("YUTONG", "Not running", 2)
	end
end)

notify("YUTONG", "AutoBuild loaded: " .. dataCount .. " blocks", 3)
print("[YUTONG-AutoBuild] Loaded, data entries: " .. dataCount)
