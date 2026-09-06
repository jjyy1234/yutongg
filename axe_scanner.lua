-- Dynamic Axe Scanner
-- Based on existing v8 get_axe_damage/get_axe_cooldown logic
-- Scans Backpack + Character, matches AxeClass from LoadedAssets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- 清理旧 UI
local old = PlayerGui:FindFirstChild("AxeScannerUI")
if old then old:Destroy() end

-- ===== UI =====
local sg = Instance.new("ScreenGui")
sg.Name = "AxeScannerUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 200, 0, 200)
frame.Position = UDim2.new(0.5, -100, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(245, 240, 248)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(210, 190, 225)
stroke.Thickness = 1.2
stroke.Parent = frame

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 26)
titleBar.BackgroundColor3 = Color3.fromRGB(180, 150, 210)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(180, 150, 210)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -8, 1, 0)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Dynamic Axe Scanner"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Scan 按钮
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -16, 0, 22)
scanBtn.Position = UDim2.new(0, 8, 0, 30)
scanBtn.BackgroundColor3 = Color3.fromRGB(160, 120, 200)
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 11
scanBtn.Text = "[ SCAN ]"
scanBtn.BorderSizePixel = 0
scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

-- 状态行
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 14)
statusLabel.Position = UDim2.new(0, 8, 0, 56)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Press SCAN to start"
statusLabel.TextColor3 = Color3.fromRGB(140, 100, 170)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- 结果区 ScrollingFrame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 0, 118)
scroll.Position = UDim2.new(0, 4, 0, 74)
scroll.BackgroundColor3 = Color3.fromRGB(238, 232, 245)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 150, 210)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scroll
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)

local listPad = Instance.new("UIPadding")
listPad.Parent = scroll
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 4)

-- 复制按钮
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, -16, 0, 16)
copyBtn.Position = UDim2.new(0, 8, 1, -20)
copyBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 220)
copyBtn.TextColor3 = Color3.fromRGB(80, 50, 110)
copyBtn.Font = Enum.Font.Gotham
copyBtn.TextSize = 10
copyBtn.Text = "Copy Results"
copyBtn.BorderSizePixel = 0
copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)

-- ===== 工具函数 =====

local function addLine(text, color, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(60, 40, 80)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 9
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order or 0
	lbl.Parent = scroll
	return lbl
end

local function clearResults()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
end

-- 找 AxeClass：优先 LoadedAssets，fallback AxeModules
local function findAxeClass(toolName)
	local la = ReplicatedStorage:FindFirstChild("LoadedAssets")
	if la then
		-- 格式1: ToolName + AxeClass (e.g. AxeBlurpleAxeClass)
		local c1 = la:FindFirstChild(toolName .. "AxeClass")
		if c1 then return c1, toolName .. "AxeClass" end
		-- 格式2: Axe + stripped + AxeClass (e.g. AxeBlurple -> BlurpleAxeClass)
		local stripped = toolName:gsub("^Axe", "")
		local c2 = la:FindFirstChild("Axe" .. stripped .. "AxeClass")
		if c2 then return c2, "Axe" .. stripped .. "AxeClass" end
		-- 格式3: 模糊匹配
		for _, v in ipairs(la:GetChildren()) do
			if v.Name:lower():find(toolName:lower()) and v:IsA("ModuleScript") then
				return v, v.Name
			end
		end
	end
	-- fallback: AxeModules
	local am = ReplicatedStorage:FindFirstChild("AxeModules")
	if am then
		for _, v in ipairs(am:GetChildren()) do
			if v.Name:lower():find(toolName:lower()) and v:IsA("ModuleScript") then
				return v, v.Name
			end
		end
	end
	return nil, nil
end

-- 从 AxeClass ModuleScript 读取参数
local function readAxeClass(moduleScript)
	local ok, result = pcall(function()
		return require(moduleScript)
	end)
	if not ok then return nil, tostring(result) end
	local tbl = result
	if type(result) == "table" and type(result.new) == "function" then
		local ok2, inst = pcall(function() return result.new() end)
		if ok2 and inst then tbl = inst end
	end
	return tbl, nil
end

-- ===== 扫描逻辑 =====
local lastResultText = ""

local function doScan()
	clearResults()
	statusLabel.Text = "Scanning..."
	scanBtn.Active = false
	lastResultText = ""

	local found = {}
	local char = lp.Character
	local bp = lp:FindFirstChild("Backpack")

	if char then
		for _, obj in ipairs(char:GetChildren()) do
			if obj:IsA("Tool") or (obj:FindFirstChild("ToolName") and obj:IsA("Model")) then
				table.insert(found, {tool = obj, location = "Character"})
			end
		end
	end
	if bp then
		for _, obj in ipairs(bp:GetChildren()) do
			if obj:IsA("Tool") or obj:FindFirstChild("ToolName") then
				table.insert(found, {tool = obj, location = "Backpack"})
			end
		end
	end

	local axes = {}
	for _, entry in ipairs(found) do
		local t = entry.tool
		local isCutting = t:FindFirstChild("CuttingTool") ~= nil
		local tn = t:FindFirstChild("ToolName")
		local name = (tn and tn.Value) or t.Name
		local isAxe = isCutting or name:lower():find("axe") or name:lower():find("hatchet") or name:lower():find("saw")
		if isAxe then
			table.insert(axes, entry)
		end
	end

	if #axes == 0 then
		statusLabel.Text = "Found: 0 axes"
		addLine("No axes found in Backpack or Character.", Color3.fromRGB(180, 100, 100), 1)
		scanBtn.Active = true
		return
	end

	statusLabel.Text = "Found: " .. #axes .. " axe(s)"
	local resultLines = {}
	local order = 0

	for i, entry in ipairs(axes) do
		local t = entry.tool
		local loc = entry.location

		local toolNameVal = t:FindFirstChild("ToolName")
		local itemNameVal = t:FindFirstChild("ItemName")
		local cuttingVal  = t:FindFirstChild("CuttingTool")
		local rangeVal    = t:FindFirstChild("Range")

		local toolName = (toolNameVal and toolNameVal.Value) or t.Name
		local itemName = (itemNameVal and itemNameVal.Value) or "N/A"
		local cuttingClass = (cuttingVal and cuttingVal.Value) or "N/A"
		local rangeRaw = (rangeVal and tostring(rangeVal.Value)) or "N/A"

		order = order + 1
		local headerColor = loc == "Character"
			and Color3.fromRGB(120, 60, 180)
			or Color3.fromRGB(80, 120, 180)
		local locTag = loc == "Character" and " [EQUIPPED]" or " [Backpack]"
		addLine("[" .. i .. "] " .. toolName .. locTag, headerColor, order)
		table.insert(resultLines, "[" .. i .. "] " .. toolName .. locTag)

		order = order + 1
		addLine("  ItemName: " .. itemName, Color3.fromRGB(100, 100, 100), order)
		table.insert(resultLines, "  ItemName: " .. itemName)

		order = order + 1
		addLine("  CuttingClass: " .. cuttingClass, Color3.fromRGB(100, 100, 100), order)
		table.insert(resultLines, "  CuttingClass: " .. cuttingClass)

		local classModule, className = findAxeClass(toolName)
		if not classModule then
			classModule, className = findAxeClass(itemName)
		end

		if classModule then
			order = order + 1
			addLine("  Class: " .. className, Color3.fromRGB(80, 150, 80), order)
			table.insert(resultLines, "  Class: " .. className)

			local axeTbl, err = readAxeClass(classModule)
			if axeTbl then
				local dmg = axeTbl.Damage or "UNKNOWN"
				local cd  = axeTbl.SwingCooldown or "UNKNOWN"
				local rng = axeTbl.Range or rangeRaw

				order = order + 1
				addLine("  Damage: " .. tostring(dmg), Color3.fromRGB(200, 80, 80), order)
				table.insert(resultLines, "  Damage: " .. tostring(dmg))

				order = order + 1
				addLine("  Cooldown: " .. tostring(cd), Color3.fromRGB(200, 130, 50), order)
				table.insert(resultLines, "  Cooldown: " .. tostring(cd))

				order = order + 1
				addLine("  Range: " .. tostring(rng), Color3.fromRGB(80, 130, 200), order)
				table.insert(resultLines, "  Range: " .. tostring(rng))

				if axeTbl.SpecialTrees and next(axeTbl.SpecialTrees) then
					order = order + 1
					addLine("  SpecialTrees:", Color3.fromRGB(100, 160, 100), order)
					table.insert(resultLines, "  SpecialTrees:")
					for treeName, treeData in pairs(axeTbl.SpecialTrees) do
						local td = type(treeData) == "table"
							and ("Dmg=" .. tostring(treeData.Damage or "?") .. " CD=" .. tostring(treeData.SwingCooldown or "?"))
							or tostring(treeData)
						order = order + 1
						addLine("    " .. treeName .. ": " .. td, Color3.fromRGB(100, 160, 100), order)
						table.insert(resultLines, "    " .. treeName .. ": " .. td)
					end
				else
					order = order + 1
					addLine("  SpecialTrees: None", Color3.fromRGB(150, 150, 150), order)
					table.insert(resultLines, "  SpecialTrees: None")
				end
			else
				order = order + 1
				addLine("  require() failed: " .. tostring(err), Color3.fromRGB(200, 80, 80), order)
				table.insert(resultLines, "  require() failed: " .. tostring(err))
			end
		else
			order = order + 1
			addLine("  Class: NOT FOUND", Color3.fromRGB(200, 80, 80), order)
			addLine("  Damage: UNKNOWN", Color3.fromRGB(180, 100, 100), order + 1)
			addLine("  Cooldown: UNKNOWN", Color3.fromRGB(180, 100, 100), order + 2)
			addLine("  Range: " .. rangeRaw, Color3.fromRGB(180, 100, 100), order + 3)
			addLine("  SpecialTrees: UNKNOWN", Color3.fromRGB(180, 100, 100), order + 4)
			table.insert(resultLines, "  Class: NOT FOUND")
			table.insert(resultLines, "  Damage: UNKNOWN")
			order = order + 4
		end

		order = order + 1
		addLine("  ─────────────────", Color3.fromRGB(200, 180, 220), order)
		table.insert(resultLines, "---")
	end

	lastResultText = table.concat(resultLines, "\n")
	scanBtn.Active = true
end

-- ===== 按钮事件 =====
scanBtn.MouseButton1Click:Connect(function()
	task.spawn(doScan)
end)

copyBtn.MouseButton1Click:Connect(function()
	if lastResultText ~= "" then
		pcall(function() setclipboard(lastResultText) end)
		copyBtn.Text = "Copied!"
		task.delay(1.5, function() copyBtn.Text = "Copy Results" end)
	else
		copyBtn.Text = "No data"
		task.delay(1.5, function() copyBtn.Text = "Copy Results" end)
	end
end)
