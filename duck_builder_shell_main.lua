--[[
  Duck Builder 薄壳主文件
  数据请上传到你的 GitHub，再改下面 DATA_BASE

  推荐上传（轻量）：
    shell_lite_1.lua ~ shell_lite_5.lua   → 约 16928 块（2 倍格距表面）
  完整 1 格壳（仍较多）：
    shell_1.lua ~ shell_18.lua           → 约 68382 块

  为什么 1 格壳还有好几万？
  鸭子外表面积大（约 33×121×78 外形），表面每一格都是一块，
  不是「厚度」问题，是「表面积」问题。
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local placeEvent = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

-- ★ 改成你上传后的 raw 目录（末尾要有 /）
local DATA_BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/duck_shell/"

-- lite = 约 1.7 万块；full = 约 6.8 万块
local USE_LITE = true
local LITE_FILES = 5
local FULL_FILES = 18

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
titleBar.Text = "Duck 薄壳 · GitHub"
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
statusLabel.Text = USE_LITE and "轻量薄壳 ~1.7万块\n点 Load Data" or "完整薄壳 ~6.8万块\n点 Load Data"
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

local function loadData()
	if dataLoaded and shellData then return shellData end
	shellData = {}
	local prefix = USE_LITE and "shell_lite_" or "shell_"
	local nFiles = USE_LITE and LITE_FILES or FULL_FILES
	for i = 1, nFiles do
		statusLabel.Text = string.format("加载 %s%d / %d ...", prefix, i, nFiles)
		local url = DATA_BASE .. prefix .. i .. ".lua"
		local ok, chunk = pcall(function()
			return loadstring(game:HttpGet(url))()
		end)
		if ok and type(chunk) == "table" then
			for _, v in ipairs(chunk) do
				table.insert(shellData, v)
			end
		else
			statusLabel.Text = "加载失败: " .. prefix .. i
			warn("[DuckShell] fail", url, chunk)
			return nil
		end
	end
	dataLoaded = true
	statusLabel.Text = string.format("薄壳就绪：%d 块", #shellData)
	print("[DuckShell] loaded", #shellData)
	return shellData
end

local function updateStatus()
	if not dataLoaded or not shellData then return end
	local total = #shellData
	local done = _G.DuckProgress or 0
	statusLabel.Text = string.format("已建 %d / %d", done, total)
	if total > 0 then
		progFill.Size = UDim2.new(math.clamp(done / total, 0, 1), 0, 1, 0)
	end
end

local function startBuild()
	if not dataLoaded or not shellData then
		statusLabel.Text = "请先 Load Data"
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
			local cf = CFrame.new(
				v.x, v.y, v.z,
				v.r00 or 1, v.r01 or 0, v.r02 or 0,
				v.r10 or 0, v.r11 or 1, v.r12 or 0,
				v.r20 or 0, v.r21 or 0, v.r22 or 1
			)
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
			statusLabel.Text = string.format("完成！%d 块", total)
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
	statusLabel.Text = dataLoaded and string.format("已重置，共 %d 块", #shellData) or "未加载"
end

local function paintAll()
	if not dataLoaded or not shellData then
		statusLabel.Text = "请先 Load Data"
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
							statusLabel.Text = "喷漆 " .. painted
							task.wait(0.01)
						end
					end
				end
			end
		end
		painting = false
		statusLabel.Text = "喷漆完成 " .. painted
	end)
end

loadBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		_G.DuckProgress = 0
		local ok, err = pcall(loadData)
		if not ok then
			statusLabel.Text = "错误: " .. tostring(err):sub(1, 50)
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

print("[DuckShell] main ready | USE_LITE=", USE_LITE)
