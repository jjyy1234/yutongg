--[[
  Duck Builder thin-shell (compact stride2 ~8342 blocks)
  Data: https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_shell/
  Files: s_1.lua ... s_17.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA_BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_shell/"
local N_FILES = 17

if not _G.DuckProgress then _G.DuckProgress = 0 end

local shellData = nil
local dataLoaded = false
local building, painting = false, false
local buildThread, paintThread = nil, nil

local old = CoreGui:FindFirstChild("DuckBuilderUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DuckBuilderUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 300)
frame.Position = UDim2.new(0.5, -160, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
titleBar.BorderSizePixel = 0
titleBar.Text = "Duck Shell ~8k"
titleBar.TextColor3 = Color3.fromRGB(30, 30, 35)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 18
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
titleBar.InputChanged:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
		local d = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 36)
statusLabel.Position = UDim2.new(0, 10, 0, 44)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Shell ~8342 blocks\nClick Load Data"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local progBg = Instance.new("Frame")
progBg.Size = UDim2.new(1, -20, 0, 16)
progBg.Position = UDim2.new(0, 10, 0, 86)
progBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
progBg.BorderSizePixel = 0
progBg.Parent = frame
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 4)

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
progFill.BorderSizePixel = 0
progFill.Parent = progBg
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 4)

local function makeBtn(text, x, y, w, col)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, w, 0, 38)
	btn.Position = UDim2.new(0, x, 0, y)
	btn.BackgroundColor3 = col
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local loadBtn  = makeBtn("Load Data", 10,  112, 145, Color3.fromRGB(80, 120, 200))
local startBtn = makeBtn("Start",     165, 112, 145, Color3.fromRGB(80, 200, 120))
local stopBtn  = makeBtn("Stop",      10,  160, 145, Color3.fromRGB(220, 80, 80))
local resetBtn = makeBtn("Reset",     165, 160, 145, Color3.fromRGB(200, 120, 60))
local paintBtn = makeBtn("Paint All", 10,  208, 145, Color3.fromRGB(160, 100, 200))
local closeBtn = makeBtn("Close",     165, 208, 145, Color3.fromRGB(100, 100, 100))

local function expandChunk(chunk)
	local out = {}
	for _, v in ipairs(chunk) do
		if type(v) == "table" then
			if v.n and v.x then
				table.insert(out, v)
			elseif v[1] and v[2] and v[3] then
				table.insert(out, {
					n = "Floor1Tiny",
					x = v[1],
					y = v[2],
					z = v[3],
					color = v[4] or "Candy",
				})
			end
		end
	end
	return out
end

local function loadData()
	if dataLoaded and shellData then return shellData end
	shellData = {}
	for i = 1, N_FILES do
		statusLabel.Text = string.format("Loading s_%d / %d ...", i, N_FILES)
		local url = DATA_BASE .. "s_" .. i .. ".lua"
		local ok, chunk = pcall(function()
			return loadstring(game:HttpGet(url))()
		end)
		if ok and type(chunk) == "table" then
			for _, v in ipairs(expandChunk(chunk)) do
				table.insert(shellData, v)
			end
		else
			statusLabel.Text = "Fail: s_" .. i
			warn("[DuckShell] fail", url, chunk)
			return nil
		end
	end
	dataLoaded = true
	statusLabel.Text = string.format("Ready: %d blocks", #shellData)
	print("[DuckShell] loaded", #shellData)
	return shellData
end

local function updateStatus()
	if not dataLoaded or not shellData then return end
	local total = #shellData
	local done = _G.DuckProgress or 0
	statusLabel.Text = string.format("Built %d / %d", done, total)
	if total > 0 then
		progFill.Size = UDim2.new(math.clamp(done / total, 0, 1), 0, 1, 0)
	end
end

local function startBuild()
	if not dataLoaded or not shellData then
		statusLabel.Text = "Load Data first"
		return
	end
	if building then return end
	building = true
	local total = #shellData
	local startIdx = (_G.DuckProgress or 0) + 1
	buildThread = task.spawn(function()
		for i = startIdx, total do
			if not building then break end
			local v = shellData[i]
			local cf = CFrame.new(v.x, v.y, v.z)
			pcall(function()
				placeEvent:FireServer(v.n or "Floor1Tiny", cf, lp)
			end)
			_G.DuckProgress = i
			if i % 40 == 0 then updateStatus() end
			task.wait(0.01)
		end
		building = false
		updateStatus()
		if (_G.DuckProgress or 0) >= total then
			statusLabel.Text = string.format("Done! %d blocks", total)
		end
	end)
end

local function stopBuild()
	building = false
	if buildThread then task.cancel(buildThread) buildThread = nil end
	updateStatus()
end

local function resetProgress()
	stopBuild()
	_G.DuckProgress = 0
	updateStatus()
	statusLabel.Text = dataLoaded and string.format("Reset, total %d", #shellData) or "Not loaded"
end

local function paintAll()
	if not dataLoaded or not shellData then
		statusLabel.Text = "Load Data first"
		return
	end
	if painting then return end
	painting = true
	paintThread = task.spawn(function()
		local coordMap = {}
		for _, v in ipairs(shellData) do
			coordMap[string.format("%.1f,%.1f,%.1f", v.x, v.y, v.z)] = v.color
		end
		local painted = 0
		for _, obj in ipairs(workspace:GetDescendants()) do
			if not painting then break end
			if obj:IsA("Model") then
				local okp, cf = pcall(function() return obj:GetPivot() end)
				if okp and cf then
					local p = cf.Position
					local color = coordMap[string.format("%.1f,%.1f,%.1f", p.X, p.Y, p.Z)]
					if color then
						pcall(function() paintRemote:FireServer(obj, color) end)
						painted = painted + 1
						if painted % 40 == 0 then
							statusLabel.Text = "Paint " .. painted
							task.wait(0.01)
						end
					end
				end
			end
		end
		painting = false
		statusLabel.Text = "Paint done " .. painted
	end)
end

loadBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		_G.DuckProgress = 0
		local ok, err = pcall(loadData)
		if not ok then
			statusLabel.Text = "Error: " .. tostring(err):sub(1, 50)
		else
			updateStatus()
		end
	end)
end)
startBtn.MouseButton1Click:Connect(startBuild)
stopBtn.MouseButton1Click:Connect(stopBuild)
resetBtn.MouseButton1Click:Connect(resetProgress)
paintBtn.MouseButton1Click:Connect(paintAll)
closeBtn.MouseButton1Click:Connect(function()
	building = false
	painting = false
	if buildThread then task.cancel(buildThread) end
	if paintThread then task.cancel(paintThread) end
	gui:Destroy()
end)

print("[DuckShell] compact main ready N_FILES=", N_FILES)
