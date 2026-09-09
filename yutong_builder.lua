-- Yutong Builder: Pyramid + JuroShop + Scanner 整合脚本
-- 作者: jjyy1234
-- 仓库: jjyy1234/yutongg

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- 授权
local AUTH = {["gccgbxfnb0"]=true,["hxa1010"]=true,["gccgbxfnb4"]=true,["gccgbxfnb3"]=true,["xiguayyds"]=true,["xiaojun1221"]=true,["X8jone"]=true}
if not AUTH[lp.Name] then
	lp:Kick("Unauthorized")
	return
end

-- Remote
local placeRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

-- 颜色
local C_BG = Color3.fromRGB(235,225,233)
local C_TITLE = Color3.fromRGB(112,91,145)
local C_SEL = Color3.fromRGB(112,91,145)
local C_UNSEL = Color3.fromRGB(200,185,215)
local C_GREEN = Color3.fromRGB(80,180,90)
local C_RED = Color3.fromRGB(210,80,80)
local C_BLUE = Color3.fromRGB(80,130,210)
local C_WHITE = Color3.fromRGB(255,255,255)
local C_DARK = Color3.fromRGB(60,50,70)
local C_DIV = Color3.fromRGB(180,165,195)

-- 通知
local function notify(title, text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = dur or 3,
		})
	end)
end

-- 状态变量
local running = false
local pyramidData = nil
local blueprintData = nil
local selOwner = nil        -- JuroShop 选中
local selectedOwner = nil   -- Scanner 选中

-- 清理旧 GUI
local old = pg:FindFirstChild("YutongBuilder")
if old then old:Destroy() end

-- ===== 主 UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "YutongBuilder"
gui.ResetOnSpawn = false
gui.Parent = pg

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 250, 0, 200)
main.Position = UDim2.new(0.5, -125, 0.5, -100)
main.BackgroundColor3 = C_BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = false
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = C_TITLE
stroke.Thickness = 1.5
stroke.Parent = main

-- 标题栏
local titlebar = Instance.new("TextLabel")
titlebar.Name = "TitleBar"
titlebar.Size = UDim2.new(1, 0, 0, 26)
titlebar.Position = UDim2.new(0, 0, 0, 0)
titlebar.BackgroundColor3 = C_TITLE
titlebar.BorderSizePixel = 0
titlebar.Text = "Yutong Builder"
titlebar.TextColor3 = C_WHITE
titlebar.Font = Enum.Font.GothamBold
titlebar.TextSize = 13
titlebar.Parent = main

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 8)
tbc.Parent = titlebar

-- 拖动
local dragging = false
local dragStart, startPos
titlebar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
titlebar.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- 选项卡按钮容器
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -10, 0, 22)
tabBar.Position = UDim2.new(0, 5, 0, 28)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Padding = UDim.new(0, 3)
tabList.Parent = tabBar

local tabNames = {"Pyramid", "JuroShop", "Scanner"}
local tabButtons = {}
local contentFrames = {}

for i, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 73, 0, 20)
	btn.BackgroundColor3 = (i == 1) and C_SEL or C_UNSEL
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = (i == 1) and C_WHITE or C_DARK
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.AutoButtonColor = false
	btn.Parent = tabBar

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = btn

	tabButtons[name] = btn
end

-- 内容区
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -10, 1, -58)
contentArea.Position = UDim2.new(0, 5, 0, 54)
contentArea.BackgroundTransparency = 1
contentArea.Parent = main

-- ===== 选项卡1: Pyramid =====
local pyFrame = Instance.new("Frame")
pyFrame.Name = "PyramidContent"
pyFrame.Size = UDim2.new(1, 0, 1, 0)
pyFrame.BackgroundTransparency = 1
pyFrame.Visible = true
pyFrame.Parent = contentArea

local pyProgress = Instance.new("TextLabel")
pyProgress.Size = UDim2.new(1, 0, 0, 16)
pyProgress.Position = UDim2.new(0, 0, 0, 0)
pyProgress.BackgroundTransparency = 1
pyProgress.Text = "Place: 0/3681"
pyProgress.TextColor3 = C_DARK
pyProgress.Font = Enum.Font.Gotham
pyProgress.TextSize = 11
pyProgress.TextXAlignment = Enum.TextXAlignment.Left
pyProgress.Parent = pyFrame

local colorBox = Instance.new("TextBox")
colorBox.Size = UDim2.new(0.5, -2, 0, 20)
colorBox.Position = UDim2.new(0, 0, 0, 18)
colorBox.BackgroundColor3 = C_WHITE
colorBox.BorderSizePixel = 0
colorBox.Text = "Birch"
colorBox.PlaceholderText = "Color"
colorBox.TextColor3 = C_DARK
colorBox.Font = Enum.Font.Gotham
colorBox.TextSize = 11
colorBox.ClearTextOnFocus = false
colorBox.Parent = pyFrame

local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 4)
cbc.Parent = colorBox

-- Pyramid 按钮行
local pyBtnRow = Instance.new("Frame")
pyBtnRow.Size = UDim2.new(1, 0, 0, 22)
pyBtnRow.Position = UDim2.new(0, 0, 0, 40)
pyBtnRow.BackgroundTransparency = 1
pyBtnRow.Parent = pyFrame

local pyBtnList = Instance.new("UIListLayout")
pyBtnList.FillDirection = Enum.FillDirection.Horizontal
pyBtnList.Padding = UDim.new(0, 3)
pyBtnList.Parent = pyBtnRow

local pyStartBtn = Instance.new("TextButton")
pyStartBtn.Size = UDim2.new(0.33, -2, 0, 22)
pyStartBtn.BackgroundColor3 = C_GREEN
pyStartBtn.BorderSizePixel = 0
pyStartBtn.Text = "Start"
pyStartBtn.TextColor3 = C_WHITE
pyStartBtn.Font = Enum.Font.GothamBold
pyStartBtn.TextSize = 11
pyStartBtn.AutoButtonColor = false
pyStartBtn.Parent = pyBtnRow
Instance.new("UICorner", pyStartBtn).CornerRadius = UDim.new(0, 4)

local pyStopBtn = Instance.new("TextButton")
pyStopBtn.Size = UDim2.new(0.33, -2, 0, 22)
pyStopBtn.BackgroundColor3 = C_RED
pyStopBtn.BorderSizePixel = 0
pyStopBtn.Text = "Stop"
pyStopBtn.TextColor3 = C_WHITE
pyStopBtn.Font = Enum.Font.GothamBold
pyStopBtn.TextSize = 11
pyStopBtn.AutoButtonColor = false
pyStopBtn.Parent = pyBtnRow
Instance.new("UICorner", pyStopBtn).CornerRadius = UDim.new(0, 4)

local pyPaintBtn = Instance.new("TextButton")
pyPaintBtn.Size = UDim2.new(0.34, -2, 0, 22)
pyPaintBtn.BackgroundColor3 = C_BLUE
pyPaintBtn.BorderSizePixel = 0
pyPaintBtn.Text = "Paint"
pyPaintBtn.TextColor3 = C_WHITE
pyPaintBtn.Font = Enum.Font.GothamBold
pyPaintBtn.TextSize = 11
pyPaintBtn.AutoButtonColor = false
pyPaintBtn.Parent = pyBtnRow
Instance.new("UICorner", pyPaintBtn).CornerRadius = UDim.new(0, 4)

local pyStatus = Instance.new("TextLabel")
pyStatus.Size = UDim2.new(1, 0, 0, 16)
pyStatus.Position = UDim2.new(0, 0, 0, 66)
pyStatus.BackgroundTransparency = 1
pyStatus.Text = "Ready"
pyStatus.TextColor3 = C_DARK
pyStatus.Font = Enum.Font.Gotham
pyStatus.TextSize = 11
pyStatus.TextXAlignment = Enum.TextXAlignment.Left
pyStatus.Parent = pyFrame

-- ===== 选项卡2: JuroShop =====
local jsFrame = Instance.new("Frame")
jsFrame.Name = "JuroShopContent"
jsFrame.Size = UDim2.new(1, 0, 1, 0)
jsFrame.BackgroundTransparency = 1
jsFrame.Visible = false
jsFrame.Parent = contentArea

-- Owner 滚动列表
local jsOwnerScroll = Instance.new("ScrollingFrame")
jsOwnerScroll.Size = UDim2.new(1, 0, 0, 44)
jsOwnerScroll.Position = UDim2.new(0, 0, 0, 0)
jsOwnerScroll.BackgroundColor3 = C_WHITE
jsOwnerScroll.BorderSizePixel = 0
jsOwnerScroll.ScrollBarThickness = 3
jsOwnerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
jsOwnerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
jsOwnerScroll.Parent = jsFrame
Instance.new("UICorner", jsOwnerScroll).CornerRadius = UDim.new(0, 4)

local jsOwnerList = Instance.new("UIListLayout")
jsOwnerList.Padding = UDim.new(0, 1)
jsOwnerList.Parent = jsOwnerScroll

local jsScanBtn = Instance.new("TextButton")
jsScanBtn.Size = UDim2.new(1, 0, 0, 18)
jsScanBtn.Position = UDim2.new(0, 0, 0, 46)
jsScanBtn.BackgroundColor3 = C_BLUE
jsScanBtn.BorderSizePixel = 0
jsScanBtn.Text = "Scan Owners"
jsScanBtn.TextColor3 = C_WHITE
jsScanBtn.Font = Enum.Font.GothamBold
jsScanBtn.TextSize = 11
jsScanBtn.AutoButtonColor = false
jsScanBtn.Parent = jsFrame
Instance.new("UICorner", jsScanBtn).CornerRadius = UDim.new(0, 4)

-- 分割线
local jsDiv = Instance.new("Frame")
jsDiv.Size = UDim2.new(1, 0, 0, 1)
jsDiv.Position = UDim2.new(0, 0, 0, 66)
jsDiv.BackgroundColor3 = C_DIV
jsDiv.BorderSizePixel = 0
jsDiv.Parent = jsFrame

local jsProgress = Instance.new("TextLabel")
jsProgress.Size = UDim2.new(1, 0, 0, 14)
jsProgress.Position = UDim2.new(0, 0, 0, 69)
jsProgress.BackgroundTransparency = 1
jsProgress.Text = "Place: 0/2678"
jsProgress.TextColor3 = C_DARK
jsProgress.Font = Enum.Font.Gotham
jsProgress.TextSize = 11
jsProgress.TextXAlignment = Enum.TextXAlignment.Left
jsProgress.Parent = jsFrame

-- JuroShop 按钮行
local jsBtnRow = Instance.new("Frame")
jsBtnRow.Size = UDim2.new(1, 0, 0, 20)
jsBtnRow.Position = UDim2.new(0, 0, 0, 85)
jsBtnRow.BackgroundTransparency = 1
jsBtnRow.Parent = jsFrame

local jsBtnList = Instance.new("UIListLayout")
jsBtnList.FillDirection = Enum.FillDirection.Horizontal
jsBtnList.Padding = UDim.new(0, 3)
jsBtnList.Parent = jsBtnRow

local jsStartBtn = Instance.new("TextButton")
jsStartBtn.Size = UDim2.new(0.33, -2, 0, 20)
jsStartBtn.BackgroundColor3 = C_GREEN
jsStartBtn.BorderSizePixel = 0
jsStartBtn.Text = "Start"
jsStartBtn.TextColor3 = C_WHITE
jsStartBtn.Font = Enum.Font.GothamBold
jsStartBtn.TextSize = 11
jsStartBtn.AutoButtonColor = false
jsStartBtn.Parent = jsBtnRow
Instance.new("UICorner", jsStartBtn).CornerRadius = UDim.new(0, 4)

local jsStopBtn = Instance.new("TextButton")
jsStopBtn.Size = UDim2.new(0.33, -2, 0, 20)
jsStopBtn.BackgroundColor3 = C_RED
jsStopBtn.BorderSizePixel = 0
jsStopBtn.Text = "Stop"
jsStopBtn.TextColor3 = C_WHITE
jsStopBtn.Font = Enum.Font.GothamBold
jsStopBtn.TextSize = 11
jsStopBtn.AutoButtonColor = false
jsStopBtn.Parent = jsBtnRow
Instance.new("UICorner", jsStopBtn).CornerRadius = UDim.new(0, 4)

local jsPaintBtn = Instance.new("TextButton")
jsPaintBtn.Size = UDim2.new(0.34, -2, 0, 20)
jsPaintBtn.BackgroundColor3 = C_BLUE
jsPaintBtn.BorderSizePixel = 0
jsPaintBtn.Text = "Paint"
jsPaintBtn.TextColor3 = C_WHITE
jsPaintBtn.Font = Enum.Font.GothamBold
jsPaintBtn.TextSize = 11
jsPaintBtn.AutoButtonColor = false
jsPaintBtn.Parent = jsBtnRow
Instance.new("UICorner", jsPaintBtn).CornerRadius = UDim.new(0, 4)

local jsStatus = Instance.new("TextLabel")
jsStatus.Size = UDim2.new(1, 0, 0, 14)
jsStatus.Position = UDim2.new(0, 0, 0, 107)
jsStatus.BackgroundTransparency = 1
jsStatus.Text = "Ready"
jsStatus.TextColor3 = C_DARK
jsStatus.Font = Enum.Font.Gotham
jsStatus.TextSize = 11
jsStatus.TextXAlignment = Enum.TextXAlignment.Left
jsStatus.Parent = jsFrame

-- ===== 选项卡3: Scanner =====
local scFrame = Instance.new("Frame")
scFrame.Name = "ScannerContent"
scFrame.Size = UDim2.new(1, 0, 1, 0)
scFrame.BackgroundTransparency = 1
scFrame.Visible = false
scFrame.Parent = contentArea

-- Owner 滚动列表
local scOwnerScroll = Instance.new("ScrollingFrame")
scOwnerScroll.Size = UDim2.new(1, 0, 0, 60)
scOwnerScroll.Position = UDim2.new(0, 0, 0, 0)
scOwnerScroll.BackgroundColor3 = C_WHITE
scOwnerScroll.BorderSizePixel = 0
scOwnerScroll.ScrollBarThickness = 3
scOwnerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scOwnerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scOwnerScroll.Parent = scFrame
Instance.new("UICorner", scOwnerScroll).CornerRadius = UDim.new(0, 4)

local scOwnerList = Instance.new("UIListLayout")
scOwnerList.Padding = UDim.new(0, 1)
scOwnerList.Parent = scOwnerScroll

-- (me) 默认选项
local meBtn = Instance.new("TextButton")
meBtn.Size = UDim2.new(1, 0, 0, 16)
meBtn.BackgroundColor3 = C_SEL
meBtn.BorderSizePixel = 0
meBtn.Text = "(me)"
meBtn.TextColor3 = C_WHITE
meBtn.Font = Enum.Font.Gotham
meBtn.TextSize = 11
meBtn.AutoButtonColor = false
meBtn.Parent = scOwnerScroll
selectedOwner = lp

local scScanOwnerBtn = Instance.new("TextButton")
scScanOwnerBtn.Size = UDim2.new(1, 0, 0, 18)
scScanOwnerBtn.Position = UDim2.new(0, 0, 0, 62)
scScanOwnerBtn.BackgroundColor3 = C_BLUE
scScanOwnerBtn.BorderSizePixel = 0
scScanOwnerBtn.Text = "Scan Owners"
scScanOwnerBtn.TextColor3 = C_WHITE
scScanOwnerBtn.Font = Enum.Font.GothamBold
scScanOwnerBtn.TextSize = 11
scScanOwnerBtn.AutoButtonColor = false
scScanOwnerBtn.Parent = scFrame
Instance.new("UICorner", scScanOwnerBtn).CornerRadius = UDim.new(0, 4)

local scScanBPBtn = Instance.new("TextButton")
scScanBPBtn.Size = UDim2.new(1, 0, 0, 18)
scScanBPBtn.Position = UDim2.new(0, 0, 0, 82)
scScanBPBtn.BackgroundColor3 = C_GREEN
scScanBPBtn.BorderSizePixel = 0
scScanBPBtn.Text = "Scan Blueprints"
scScanBPBtn.TextColor3 = C_WHITE
scScanBPBtn.Font = Enum.Font.GothamBold
scScanBPBtn.TextSize = 11
scScanBPBtn.AutoButtonColor = false
scScanBPBtn.Parent = scFrame
Instance.new("UICorner", scScanBPBtn).CornerRadius = UDim.new(0, 4)

local scCopyBtn = Instance.new("TextButton")
scCopyBtn.Size = UDim2.new(1, 0, 0, 18)
scCopyBtn.Position = UDim2.new(0, 0, 0, 102)
scCopyBtn.BackgroundColor3 = C_TITLE
scCopyBtn.BorderSizePixel = 0
scCopyBtn.Text = "Copy Result"
scCopyBtn.TextColor3 = C_WHITE
scCopyBtn.Font = Enum.Font.GothamBold
scCopyBtn.TextSize = 11
scCopyBtn.AutoButtonColor = false
scCopyBtn.Parent = scFrame
Instance.new("UICorner", scCopyBtn).CornerRadius = UDim.new(0, 4)

local scCount = Instance.new("TextLabel")
scCount.Size = UDim2.new(1, 0, 0, 14)
scCount.Position = UDim2.new(0, 0, 0, 122)
scCount.BackgroundTransparency = 1
scCount.Text = "Total: 0"
scCount.TextColor3 = C_DARK
scCount.Font = Enum.Font.Gotham
scCount.TextSize = 11
scCount.TextXAlignment = Enum.TextXAlignment.Left
scCount.Parent = scFrame

local scStatus = Instance.new("TextLabel")
scStatus.Size = UDim2.new(1, 0, 0, 14)
scStatus.Position = UDim2.new(0, 0, 0, 138)
scStatus.BackgroundTransparency = 1
scStatus.Text = "Ready"
scStatus.TextColor3 = C_DARK
scStatus.Font = Enum.Font.Gotham
scStatus.TextSize = 11
scStatus.TextXAlignment = Enum.TextXAlignment.Left
scStatus.Parent = scFrame

contentFrames["Pyramid"] = pyFrame
contentFrames["JuroShop"] = jsFrame
contentFrames["Scanner"] = scFrame

-- ===== 选项卡切换 =====
for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		for n, b in pairs(tabButtons) do
			if n == name then
				b.BackgroundColor3 = C_SEL
				b.TextColor3 = C_WHITE
			else
				b.BackgroundColor3 = C_UNSEL
				b.TextColor3 = C_DARK
			end
		end
		for n, f in pairs(contentFrames) do
			f.Visible = (n == name)
		end
	end)
end

-- ===== 数据加载 =====
task.spawn(function()
	local ok, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/pyramid_data.lua"))()
	end)
	if ok and type(result) == "table" then
		pyramidData = result
		pyProgress.Text = "Place: 0/" .. #result
		pyStatus.Text = "Pyramid data loaded: " .. #result
	else
		pyStatus.Text = "Pyramid data load failed"
		notify("Yutong Builder", "Pyramid data load failed", 3)
	end
end)

task.spawn(function()
	local ok, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"))()
	end)
	if ok and type(result) == "table" then
		blueprintData = result
		jsProgress.Text = "Place: 0/" .. #result
		jsStatus.Text = "Blueprint data loaded: " .. #result
	else
		jsStatus.Text = "Blueprint data load failed"
		notify("Yutong Builder", "Blueprint data load failed", 3)
	end
end)

-- ===== Pyramid 逻辑 =====
local function buildCFrame(d)
	return CFrame.new(d.x, d.y, d.z, d.r00, d.r01, d.r02, d.r10, d.r11, d.r12, d.r20, d.r21, d.r22)
end

pyStartBtn.MouseButton1Click:Connect(function()
	if running then return end
	if not pyramidData then pyStatus.Text = "No data" return end
	running = true
	pyStatus.Text = "Placing..."
	notify("Pyramid", "Start placing " .. #pyramidData, 2)
	task.spawn(function()
		local count = 0
		for i, d in ipairs(pyramidData) do
			if not running then break end
			pcall(function()
				placeRemote:FireServer(d.n, buildCFrame(d), lp)
			end)
			count = count + 1
			if count % 50 == 0 then
				pyProgress.Text = "Place: " .. count .. "/" .. #pyramidData
			end
			task.wait(0.01)
		end
		pyProgress.Text = "Place: " .. count .. "/" .. #pyramidData
		pyStatus.Text = "Done: " .. count
		running = false
		notify("Pyramid", "Done: " .. count, 3)
	end)
end)

pyStopBtn.MouseButton1Click:Connect(function()
	running = false
	pyStatus.Text = "Stopped"
end)

pyPaintBtn.MouseButton1Click:Connect(function()
	if running then return end
	running = true
	pyStatus.Text = "Painting..."
	local colorName = colorBox.Text
	notify("Pyramid", "Painting " .. colorName, 2)
	task.spawn(function()
		-- 建坐标哈希索引
		local hash = {}
		if pyramidData then
			for _, d in ipairs(pyramidData) do
				local key = math.floor(d.x + 0.5) .. "," .. math.floor(d.y + 0.5) .. "," .. math.floor(d.z + 0.5)
				hash[key] = true
			end
		end
		local count = 0
		for _, model in ipairs(Workspace:GetChildren()) do
			if not running then break end
			if model:IsA("Model") then
				local ov = model:FindFirstChild("Owner")
				if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value.Name == lp.Name then
					local cf = model:GetPivot()
					local key = math.floor(cf.X + 0.5) .. "," .. math.floor(cf.Y + 0.5) .. "," .. math.floor(cf.Z + 0.5)
					if hash[key] or not pyramidData then
						pcall(function()
							paintRemote:FireServer(model, colorName)
						end)
						count = count + 1
						if count % 50 == 0 then
							pyProgress.Text = "Paint: " .. count
						end
						task.wait(0.01)
					end
				end
			end
		end
		pyProgress.Text = "Paint: " .. count
		pyStatus.Text = "Paint done: " .. count
		running = false
		notify("Pyramid", "Paint done: " .. count, 3)
	end)
end)

-- ===== JuroShop 逻辑 =====
local function clearOwnerList(scroll)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

jsScanBtn.MouseButton1Click:Connect(function()
	clearOwnerList(jsOwnerScroll)
	local seen = {}
	local count = 0
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") then
			local ov = model:FindFirstChild("Owner")
			if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("Player") then
				local pname = ov.Value.Name
				if not seen[pname] then
					seen[pname] = true
					count = count + 1
					local obtn = Instance.new("TextButton")
					obtn.Size = UDim2.new(1, 0, 0, 16)
					obtn.BackgroundColor3 = C_WHITE
					obtn.BorderSizePixel = 0
					obtn.Text = pname
					obtn.TextColor3 = C_DARK
					obtn.Font = Enum.Font.Gotham
					obtn.TextSize = 11
					obtn.AutoButtonColor = false
					obtn.Parent = jsOwnerScroll
					obtn.MouseButton1Click:Connect(function()
						selOwner = ov.Value
						for _, c in ipairs(jsOwnerScroll:GetChildren()) do
							if c:IsA("TextButton") then
								c.BackgroundColor3 = C_WHITE
								c.TextColor3 = C_DARK
							end
						end
						obtn.BackgroundColor3 = C_SEL
						obtn.TextColor3 = C_WHITE
						jsStatus.Text = "Selected: " .. pname
					end)
				end
			end
		end
	end
	jsOwnerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 17)
	jsStatus.Text = "Found " .. count .. " owners"
end)

jsStartBtn.MouseButton1Click:Connect(function()
	if running then return end
	if not blueprintData then jsStatus.Text = "No data" return end
	running = true
	jsStatus.Text = "Placing..."
	notify("JuroShop", "Start placing " .. #blueprintData, 2)
	task.spawn(function()
		local count = 0
		for i, d in ipairs(blueprintData) do
			if not running then break end
			if d.n ~= "Property" then
				pcall(function()
					placeRemote:FireServer(d.n, buildCFrame(d), lp)
				end)
				count = count + 1
				if count % 50 == 0 then
					jsProgress.Text = "Place: " .. count .. "/" .. #blueprintData
				end
				task.wait(0.01)
			end
		end
		jsProgress.Text = "Place: " .. count .. "/" .. #blueprintData
		jsStatus.Text = "Done: " .. count
		running = false
		notify("JuroShop", "Done: " .. count, 3)
	end)
end)

jsStopBtn.MouseButton1Click:Connect(function()
	running = false
	jsStatus.Text = "Stopped"
end)

jsPaintBtn.MouseButton1Click:Connect(function()
	if running then return end
	if not selOwner then jsStatus.Text = "Select owner first" return end
	running = true
	jsStatus.Text = "Painting..."
	notify("JuroShop", "Painting for " .. selOwner.Name, 2)
	task.spawn(function()
		-- 建坐标哈希索引
		local hash = {}
		if blueprintData then
			for _, d in ipairs(blueprintData) do
				local key = math.floor(d.x + 0.5) .. "," .. math.floor(d.y + 0.5) .. "," .. math.floor(d.z + 0.5)
				hash[key] = d.wood
			end
		end
		local count = 0
		for _, model in ipairs(Workspace:GetChildren()) do
			if not running then break end
			if model:IsA("Model") then
				local ov = model:FindFirstChild("Owner")
				if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("Player") and ov.Value.Name == selOwner.Name then
					local cf = model:GetPivot()
					local key = math.floor(cf.X + 0.5) .. "," .. math.floor(cf.Y + 0.5) .. "," .. math.floor(cf.Z + 0.5)
					local wood = hash[key]
					if wood and wood ~= "?" then
						pcall(function()
							paintRemote:FireServer(model, wood)
						end)
						count = count + 1
						if count % 50 == 0 then
							jsProgress.Text = "Paint: " .. count
						end
						task.wait(0.01)
					end
				end
			end
		end
		jsProgress.Text = "Paint: " .. count
		jsStatus.Text = "Paint done: " .. count
		running = false
		notify("JuroShop", "Paint done: " .. count, 3)
	end)
end)

-- ===== Scanner 逻辑 =====
meBtn.MouseButton1Click:Connect(function()
	selectedOwner = lp
	for _, c in ipairs(scOwnerScroll:GetChildren()) do
		if c:IsA("TextButton") then
			c.BackgroundColor3 = C_WHITE
			c.TextColor3 = C_DARK
		end
	end
	meBtn.BackgroundColor3 = C_SEL
	meBtn.TextColor3 = C_WHITE
	scStatus.Text = "Selected: (me)"
end)

scScanOwnerBtn.MouseButton1Click:Connect(function()
	-- 清除除 meBtn 外的
	for _, child in ipairs(scOwnerScroll:GetChildren()) do
		if child:IsA("TextButton") and child ~= meBtn then
			child:Destroy()
		end
	end
	local seen = {}
	local count = 1 -- me 算一个
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") then
			local ov = model:FindFirstChild("Owner")
			if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("Player") then
				local pname = ov.Value.Name
				if not seen[pname] then
					seen[pname] = true
					count = count + 1
					local obtn = Instance.new("TextButton")
					obtn.Size = UDim2.new(1, 0, 0, 16)
					obtn.BackgroundColor3 = C_WHITE
					obtn.BorderSizePixel = 0
					obtn.Text = pname
					obtn.TextColor3 = C_DARK
					obtn.Font = Enum.Font.Gotham
					obtn.TextSize = 11
					obtn.AutoButtonColor = false
					obtn.Parent = scOwnerScroll
					obtn.MouseButton1Click:Connect(function()
						selectedOwner = ov.Value
						for _, c in ipairs(scOwnerScroll:GetChildren()) do
							if c:IsA("TextButton") then
								c.BackgroundColor3 = C_WHITE
								c.TextColor3 = C_DARK
							end
						end
						obtn.BackgroundColor3 = C_SEL
						obtn.TextColor3 = C_WHITE
						scStatus.Text = "Selected: " .. pname
					end)
				end
			end
		end
	end
	scOwnerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 17)
	scStatus.Text = "Found " .. count .. " owners"
end)

local lastResult = ""

scScanBPBtn.MouseButton1Click:Connect(function()
	if not selectedOwner then scStatus.Text = "Select owner first" return end
	scStatus.Text = "Scanning..."
	task.spawn(function()
		local lines = {}
		local count = 0
		for _, model in ipairs(Workspace:GetChildren()) do
			if model:IsA("Model") then
				local ov = model:FindFirstChild("Owner")
				if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("Player") and ov.Value.Name == selectedOwner.Name then
					count = count + 1
					local cf = model:GetPivot()
					local wood = "?"
					local woodVal = model:FindFirstChild("Wood")
					if woodVal and woodVal:IsA("StringValue") then
						wood = woodVal.Value
					end
					local line = string.format("[%d] \"%s\" | Wood: %s | CFrame.new(%.2f, %.2f, %.2f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",
						count, model.Name, wood,
						cf.X, cf.Y, cf.Z,
						cf.Rotation.X, cf.Rotation.Y, cf.Rotation.Z,
						cf.Rotation.X, cf.Rotation.Y, cf.Rotation.Z)
					table.insert(lines, line)
				end
			end
		end
		lastResult = table.concat(lines, "\n")
		for _, line in ipairs(lines) do
			print(line)
		end
		scCount.Text = "Total: " .. count
		scStatus.Text = "Scan done: " .. count
		notify("Scanner", "Found " .. count .. " blueprints", 3)
	end)
end)

scCopyBtn.MouseButton1Click:Connect(function()
	if lastResult == "" then
		scStatus.Text = "No result to copy"
		return
	end
	pcall(function()
		setclipboard(lastResult)
	end)
	scStatus.Text = "Copied to clipboard"
	notify("Scanner", "Copied to clipboard", 2)
end)

notify("Yutong Builder", "Loaded successfully", 3)
