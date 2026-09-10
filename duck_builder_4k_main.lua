--[[
  Duck Builder 4k 薄壳 (Floor1Tiny only)
  ~4180 块 | 慢放 | 可暂停
  数据: https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_shell_4k/all.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA_URL = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_shell_4k/all.lua"
local PLACE_WAIT = 0.06

if not _G.DuckProgress then _G.DuckProgress = 0 end
if _G.DuckPaused == nil then _G.DuckPaused = false end

local shellData = nil
local dataLoaded = false
local building, painting = false, false

local old = CoreGui:FindFirstChild("DuckBuilder4kUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DuckBuilder4kUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 340)
frame.Position = UDim2.new(0.5, -160, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
titleBar.BorderSizePixel = 0
titleBar.Text = "Duck 薄壳 · ~4k Tiny"
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
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Floor1Tiny · ~4180 块\n先 Load Data"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

local progBg = Instance.new("Frame")
progBg.Size = UDim2.new(1, -20, 0, 14)
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
	btn.Size = UDim2.new(0, w, 0, 36)
	btn.Position = UDim2.new(0, x, 0, y)
	btn.BackgroundColor3 = col
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local loadBtn   = makeBtn("Load Data", 10,  110, 145, Color3.fromRGB(80, 120, 200))
local startBtn  = makeBtn("Start",     165, 110, 145, Color3.fromRGB(80, 200, 120))
local pauseBtn  = makeBtn("Pause",     10,  154, 145, Color3.fromRGB(220, 160, 60))
local stopBtn   = makeBtn("Stop",      165, 154, 145, Color3.fromRGB(220, 80, 80))
local resetBtn  = makeBtn("Reset",     10,  198, 145, Color3.fromRGB(200, 120, 60))
local paintBtn  = makeBtn("Paint All", 165, 198, 145, Color3.fromRGB(160, 100, 200))
local closeBtn  = makeBtn("Close",     10,  242, 300, Color3.fromRGB(100, 100, 100))

local tip = Instance.new("TextLabel")
tip.Size = UDim2.new(1, -20, 0, 40)
tip.Position = UDim2.new(0, 10, 0, 288)
tip.BackgroundTransparency = 1
tip.Text = "建议空服 · 间隔 0.06s\n暂停后可再 Start 续建"
tip.TextColor3 = Color3.fromRGB(180, 180, 190)
tip.Font = Enum.Font.SourceSans
tip.TextSize = 12
tip.TextXAlignment = Enum.TextXAlignment.Left
tip.Parent = frame

local function expandChunk(chunk)
	local out = {}
	for _, v in ipairs(chunk) do
		if type(v) == "table" and v[1] and v[2] and v[3] then
			table.insert(out, {
				n = "Floor1Tiny",
				x = v[1],
				y = v[2],
				z = v[3],
				color = v[4] or "Candy",
			})
		end
	end
	return out
end

local function loadData()
	if dataLoaded and shellData then
		statusLabel.Text = string.format("已加载 %d 块", #shellData)
		return shellData
	end
	shellData = {}
	statusLabel.Text = "加载 all.lua ..."
	local ok, chunk = pcall(function()
		return loadstring(game:HttpGet(DATA_URL))()
	end)
	if not ok or type(chunk) ~= "table" then
		statusLabel.Text = "加载失败 all.lua"
		warn("[Duck4k] fail", DATA_URL, chunk)
		return nil
	end
	for _, v in ipairs(expandChunk(chunk)) do
		table.insert(shellData, v)
	end
	dataLoaded = true
	statusLabel.Text = string.format("就绪：%d 块 (Floor1Tiny)", #shellData)
	print("[Duck4k] loaded", #shellData)
	return shellData
end

local function updateStatus()
	if not dataLoaded or not shellData then return end
	local total = #shellData
	local done = _G.DuckProgress or 0
	local tag = _G.DuckPaused and " [暂停]" or (building and " [建造中]" or "")
	statusLabel.Text = string.format("已建 %d / %d%s", done, total, tag)
	if total > 0 then
		progFill.Size = UDim2.new(math.clamp(done / total, 0, 1), 0, 1, 0)
	end
end

local function startBuild()
	if not dataLoaded or not shellData then
		statusLabel.Text = "请先 Load Data"
		return
	end
	if building then
		_G.DuckPaused = false
		pauseBtn.Text = "Pause"
		updateStatus()
		return
	end
	building = true
	_G.DuckPaused = false
	pauseBtn.Text = "Pause"
	local total = #shellData
	local startIdx = (_G.DuckProgress or 0) + 1
	task.spawn(function()
		for i = startIdx, total do
			if not building then break end
			while _G.DuckPaused and building do
				updateStatus()
				task.wait(0.2)
			end
			if not building then break end
			local v = shellData[i]
			local cf = CFrame.new(v.x, v.y, v.z)
			pcall(function()
				placeEvent:FireServer(v.n or "Floor1Tiny", cf, lp)
			end)
			_G.DuckProgress = i
			if i % 25 == 0 then updateStatus() end
			task.wait(PLACE_WAIT)
		end
		building = false
		updateStatus()
		if (_G.DuckProgress or 0) >= total then
			statusLabel.Text = string.format("完成！%d 块", total)
		end
	end)
end

loadBtn.MouseButton1Click:Connect(function()
	task.spawn(loadData)
end)

startBtn.MouseButton1Click:Connect(startBuild)

pauseBtn.MouseButton1Click:Connect(function()
	if not building then
		statusLabel.Text = "未在建造"
		return
	end
	_G.DuckPaused = not _G.DuckPaused
	pauseBtn.Text = _G.DuckPaused and "Resume" or "Pause"
	updateStatus()
end)

stopBtn.MouseButton1Click:Connect(function()
	building = false
	_G.DuckPaused = false
	pauseBtn.Text = "Pause"
	statusLabel.Text = string.format("已停止 @ %d", _G.DuckProgress or 0)
end)

resetBtn.MouseButton1Click:Connect(function()
	building = false
	_G.DuckPaused = false
	_G.DuckProgress = 0
	pauseBtn.Text = "Pause"
	progFill.Size = UDim2.new(0, 0, 1, 0)
	statusLabel.Text = dataLoaded and string.format("已重置，共 %d 块", #shellData) or "已重置"
end)

paintBtn.MouseButton1Click:Connect(function()
	if not dataLoaded or not shellData then
		statusLabel.Text = "请先 Load Data"
		return
	end
	if painting then return end
	painting = true
	task.spawn(function()
		local total = #shellData
		for i, v in ipairs(shellData) do
			if not painting then break end
			pcall(function()
				paintRemote:FireServer(v.color or "Candy")
			end)
			if i % 30 == 0 then
				statusLabel.Text = string.format("喷漆 %d / %d", i, total)
			end
			task.wait(0.02)
		end
		painting = false
		statusLabel.Text = "喷漆结束（若无效请手动喷）"
	end)
end)

closeBtn.MouseButton1Click:Connect(function()
	building = false
	painting = false
	gui:Destroy()
end)

print("[Duck4k] ready — ~4180 Floor1Tiny, wait=", PLACE_WAIT)
