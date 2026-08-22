--[[
  LT2 抓 ConfirmPurchase（安全版）
  - 尽量只监听，不打断拖拽/对话
  - 出问题点「卸载监控」恢复
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

pcall(function()
	local o = pg:FindFirstChild("LT2CapturePurchase")
	if o then o:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "LT2CapturePurchase"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 360)
frame.Position = UDim2.new(0, 12, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

do
	local drag, s0, p0
	frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag, s0, p0 = true, i.Position, frame.Position
		end
	end)
	frame.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - s0
			frame.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end
	end)
end

local function lbl(y, text, size)
	local t = Instance.new("TextLabel")
	t.Parent = frame
	t.BackgroundTransparency = 1
	t.Position = UDim2.new(0, 10, 0, y)
	t.Size = UDim2.new(1, -20, 0, size or 20)
	t.Text = text
	t.Font = Enum.Font.Gotham
	t.TextSize = 12
	t.TextColor3 = Color3.fromRGB(120, 90, 110)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	return t
end

local title = lbl(6, "抓购买参数（安全版）", 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(145, 103, 134)

local status = lbl(30, "先点「开始监控」，再手动买一次", 36)

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = frame
scroll.Position = UDim2.new(0, 10, 0, 70)
scroll.Size = UDim2.new(1, -20, 1, -150)
scroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
scroll.BackgroundTransparency = 0.12
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local out = Instance.new("TextBox")
out.Parent = scroll
out.Size = UDim2.new(1, -8, 0, 0)
out.AutomaticSize = Enum.AutomaticSize.Y
out.Position = UDim2.new(0, 4, 0, 4)
out.BackgroundTransparency = 1
out.ClearTextOnFocus = false
out.MultiLine = true
out.TextWrapped = true
out.TextEditable = true
out.Font = Enum.Font.Code
out.TextSize = 11
out.TextColor3 = Color3.fromRGB(40, 30, 50)
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Text = "日志...\n"

local log = out.Text
local function append(s)
	log = log .. s .. "\n"
	if #log > 60000 then log = log:sub(-45000) end
	out.Text = log
end

local function dumpVal(v, depth, prefix)
	depth = depth or 0
	prefix = prefix or ""
	if depth > 6 then return prefix .. "...\n" end
	local ty = typeof(v)
	if ty == "Instance" then
		return prefix .. "Instance=" .. v:GetFullName() .. " (" .. v.ClassName .. ")\n"
	elseif ty == "table" then
		local s = prefix .. "{\n"
		local n = 0
		for k, val in pairs(v) do
			n = n + 1
			if n > 50 then
				s = s .. prefix .. "  ...\n"
				break
			end
			local ks = type(k) == "string" and string.format("%q", k) or tostring(k)
			s = s .. prefix .. "  [" .. ks .. "] = "
			if typeof(val) == "table" then
				s = s .. "\n" .. dumpVal(val, depth + 1, prefix .. "    ")
			elseif typeof(val) == "Instance" then
				s = s .. val:GetFullName() .. "\n"
			elseif type(val) == "string" then
				s = s .. string.format("%q", val) .. "\n"
			else
				s = s .. tostring(val) .. "\n"
			end
		end
		return s .. prefix .. "}\n"
	elseif type(v) == "string" then
		return prefix .. string.format("%q", v) .. "\n"
	else
		return prefix .. tostring(v) .. " (" .. ty .. ")\n"
	end
end

local function onChatted(...)
	local args = {...}
	append("===== PlayerChatted " .. os.date("%H:%M:%S") .. " =====")
	append("argc=" .. #args)
	for i, a in ipairs(args) do
		append("-- arg[" .. i .. "]")
		append(dumpVal(a))
	end
	status.Text = "已抓到 PlayerChatted！请复制结果"
	print("[Capture] PlayerChatted", #args)
end

local oldNamecall = nil
local hooked = false
local targetRF = nil

pcall(function()
	local npc = ReplicatedStorage:FindFirstChild("NPCDialog")
	targetRF = npc and npc:FindFirstChild("PlayerChatted")
	if targetRF then
		append("[info] 找到 " .. targetRF:GetFullName())
	else
		append("[warn] 未找到 NPCDialog.PlayerChatted")
	end
end)

local function startHook()
	if hooked then
		status.Text = "已经在监控"
		return
	end
	local ok, err = pcall(function()
		-- 优先 hookmetamethod（比直接改 mt 稳）
		if hookmetamethod then
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				local method = getnamecallmethod()
				-- 只记录，必须原样返回
				if method == "InvokeServer" and targetRF and self == targetRF then
					pcall(onChatted, ...)
				elseif method == "InvokeServer" then
					local n = ""
					pcall(function() n = self.Name end)
					if n == "PlayerChatted" then
						pcall(onChatted, ...)
					elseif n == "SetChattingValue" then
						local a = {...}
						append("[SetChattingValue] " .. tostring(a[1]))
					end
				end
				return oldNamecall(self, ...)
			end)
			hooked = true
			return
		end

		-- 备选 getrawmetatable
		local mt = getrawmetatable(game)
		oldNamecall = mt.__namecall
		if setreadonly then setreadonly(mt, false) end
		local function wrap(self, ...)
			local method = getnamecallmethod()
			if method == "InvokeServer" then
				local n = ""
				pcall(function() n = self.Name end)
				if n == "PlayerChatted" or (targetRF and self == targetRF) then
					pcall(onChatted, ...)
				end
			end
			return oldNamecall(self, ...)
		end
		if newcclosure then
			mt.__namecall = newcclosure(wrap)
		else
			mt.__namecall = wrap
		end
		if setreadonly then setreadonly(mt, true) end
		hooked = true
	end)
	if ok and hooked then
		append("[info] 监控已开启")
		status.Text = "监控中：请拖货→聊天→Yes"
	else
		append("[error] Hook失败: " .. tostring(err))
		status.Text = "Hook失败（执行器可能不支持）"
	end
end

local function stopHook()
	pcall(function()
		if not oldNamecall then
			status.Text = "没有可卸载的Hook"
			return
		end
		if restorefunction and hooked then
			-- 部分执行器
			pcall(function() restorefunction(oldNamecall) end)
		end
		local mt = getrawmetatable(game)
		if mt and oldNamecall then
			if setreadonly then setreadonly(mt, false) end
			mt.__namecall = oldNamecall
			if setreadonly then setreadonly(mt, true) end
		end
		hooked = false
		append("[info] 已卸载Hook")
		status.Text = "已卸载，应可正常拖货/对话"
	end)
end

local function mkBtn(text, xScale, xOff, bg, tc)
	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Position = UDim2.new(xScale, xOff, 1, -70)
	b.Size = UDim2.new(0.5, -14, 0, 28)
	b.BackgroundColor3 = bg
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = tc
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local startBtn = mkBtn("开始监控", 0, 10, Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88))
local stopBtn = mkBtn("卸载监控", 0.5, 4, Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101))
stopBtn.Position = UDim2.new(0.5, 4, 1, -70)

local copyBtn = mkBtn("复制结果", 0, 10, Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140))
copyBtn.Position = UDim2.new(0, 10, 1, -36)
local clearBtn = mkBtn("清空", 0.5, 4, Color3.fromRGB(230, 220, 228), Color3.fromRGB(110, 100, 120))
clearBtn.Position = UDim2.new(0.5, 4, 1, -36)

startBtn.MouseButton1Click:Connect(startHook)
stopBtn.MouseButton1Click:Connect(stopHook)
copyBtn.MouseButton1Click:Connect(function()
	local okc = false
	pcall(function() if setclipboard then setclipboard(log) okc = true end end)
	pcall(function() if toclipboard then toclipboard(log) okc = true end end)
	status.Text = okc and "已复制" or "请手动复制文本框"
	if not okc then out:CaptureFocus() end
end)
clearBtn.MouseButton1Click:Connect(function()
	log = ""
	out.Text = ""
	status.Text = "已清空"
end)

append("说明: 默认不Hook，点「开始监控」后再买")
append("若拖不了/聊不了 → 点「卸载监控」")
print("[LT2Capture] UI ready (safe, hook off by default)")
