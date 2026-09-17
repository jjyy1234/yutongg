-- v8_debug.lua — 调试页
local V8 = _G.V8
local notify = V8.notify
local px = V8.px
local speaker = V8.speaker
local pages = V8.pages
local Workspace = V8.Workspace
local ReplicatedStorage = V8.ReplicatedStorage
local PlayerGui = V8.PlayerGui
local Mouse = V8.Mouse
local TweenService = V8.TweenService
local Lighting = V8.Lighting
local TeleportService = V8.TeleportService
local VirtualUser = V8.VirtualUser

do
-- ===================== 调试页 =====================
task.spawn(function()
	local ok, err = pcall(function()
		local debugPage = pages[7]
		if not debugPage then
			-- 若只有5页则挂到其他
			debugPage = pages[6]
		end
		if not debugPage then error("no debug page") end

		local dbgLog = ""
		local remoteOn = false
		local clickOn = false
		local guiOn = false
		local remoteHooked = false
		local maxLog = 60000

		local function dbgAppend(line)
			dbgLog = dbgLog .. line .. "\n"
			if #dbgLog > maxLog then dbgLog = dbgLog:sub(-math.floor(maxLog * 0.7)) end
		end

		local title = Instance.new("TextLabel")
		title.Parent = debugPage
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -px(8), 0, px(14))
		title.Position = UDim2.new(0, px(4), 0, px(2))
		title.Text = "调试监控"
		title.TextColor3 = Color3.fromRGB(145, 103, 134)
		title.Font = Enum.Font.GothamBold
		title.TextSize = px(9)
		title.TextXAlignment = Enum.TextXAlignment.Left

		local function mkBtn(text, y, bg, tc)
			local b = Instance.new("TextButton")
			b.Parent = debugPage
			b.Size = UDim2.new(1, -px(8), 0, px(16))
			b.Position = UDim2.new(0, px(4), 0, y)
			b.BackgroundColor3 = bg
			b.BorderSizePixel = 0
			b.Text = text
			b.TextColor3 = tc
			b.Font = Enum.Font.GothamBold
			b.TextSize = px(8)
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, px(3))
			return b
		end

		local y0 = px(18)
		local remoteBtn = mkBtn("Remote监控: 关", y0, Color3.fromRGB(230, 220, 228), Color3.fromRGB(145, 103, 134))
		local clickBtn = mkBtn("ClickDetector扫描", y0 + px(18), Color3.fromRGB(190, 224, 242), Color3.fromRGB(76, 116, 140))
		local guiBtn = mkBtn("扫描ChatGUI/Yes", y0 + px(36), Color3.fromRGB(210, 201, 239), Color3.fromRGB(112, 91, 145))
		local storesBtn = mkBtn("扫描Stores目录", y0 + px(54), Color3.fromRGB(191, 226, 205), Color3.fromRGB(72, 108, 88))
		local copyBtn = mkBtn("复制调试日志", y0 + px(72), Color3.fromRGB(255, 230, 180), Color3.fromRGB(140, 100, 40))
		local clearBtn = mkBtn("清空日志", y0 + px(90), Color3.fromRGB(247, 202, 211), Color3.fromRGB(146, 83, 101))

		local status = Instance.new("TextLabel")
		status.Parent = debugPage
		status.BackgroundTransparency = 1
		status.Position = UDim2.new(0, px(4), 0, y0 + px(108))
		status.Size = UDim2.new(1, -px(8), 0, px(40))
		status.Text = "打开Remote后，手动买一次可抓参数"
		status.TextColor3 = Color3.fromRGB(120, 100, 120)
		status.Font = Enum.Font.Gotham
		status.TextSize = px(7)
		status.TextWrapped = true
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.TextYAlignment = Enum.TextYAlignment.Top

		local function tryCopy(text)
			local okc = false
			pcall(function() if setclipboard then setclipboard(text) okc = true end end)
			pcall(function() if toclipboard then toclipboard(text) okc = true end end)
			if okc then
				status.Text = "已复制 " .. #text .. " 字符"
				pcall(function() notify("调试日志已复制", "success") end)
			else
				status.Text = "无剪贴板API，看Console print"
				print(text)
			end
		end

		local function pathOf(inst)
			local t = {}
			local c = inst
			local n = 0
			while c and c ~= game and n < 30 do
				table.insert(t, 1, c.Name)
				c = c.Parent
				n = n + 1
			end
			return table.concat(t, ".")
		end

		local function shortArgs(...)
			local a = {...}
			local parts = {}
			for i = 1, math.min(#a, 8) do
				local v = a[i]
				local s
				if typeof(v) == "Instance" then
					s = "I:" .. v:GetFullName()
				elseif type(v) == "string" then
					s = string.format("%q", v:sub(1, 80))
				elseif type(v) == "table" then
					s = "{table}"
				else
					s = tostring(v)
				end
				table.insert(parts, s)
			end
			if #a > 8 then table.insert(parts, "...") end
			return table.concat(parts, ", ")
		end

		local function hookRemotes()
			if remoteHooked then return true end
			local okHook = false
			pcall(function()
				local mt = getrawmetatable(game)
				if not mt then return end
				local old = mt.__namecall
				if setreadonly then setreadonly(mt, false) end
				local wrapper = function(self, ...)
					local method = getnamecallmethod()
					if remoteOn and (method == "FireServer" or method == "InvokeServer") then
						local name = ""
						pcall(function() name = self:GetFullName() end)
						local nlow = string.lower(name)
						-- 过滤噪音可选：只记对话/交互相关时取消注释
						local line = string.format("[%s] %s\n  args: %s", method, name, shortArgs(...))
						dbgAppend(line)
						print("[DBG]", method, name, shortArgs(...))
					end
					return old(self, ...)
				end
				if newcclosure then
					mt.__namecall = newcclosure(wrapper)
				else
					mt.__namecall = wrapper
				end
				if setreadonly then setreadonly(mt, true) end
				okHook = true
				remoteHooked = true
			end)
			-- 备用：逐个 hook 已知对话
			pcall(function()
				local function hookInst(inst)
					if not inst then return end
					if inst:IsA("RemoteEvent") then
						local oldFire = inst.FireServer
						-- 无法简单替换 FireServer 在部分执行器
					end
				end
				local npc = ReplicatedStorage:FindFirstChild("NPCDialog")
				if npc then
					dbgAppend("[info] 发现 NPCDialog")
					for _, c in ipairs(npc:GetChildren()) do
						dbgAppend("  " .. c.ClassName .. " " .. c.Name)
					end
				end
				local inter = ReplicatedStorage:FindFirstChild("Interaction")
				if inter then
					dbgAppend("[info] 发现 Interaction 子项数 " .. #inter:GetChildren())
				end
			end)
			return okHook
		end

		remoteBtn.MouseButton1Click:Connect(function()
			remoteOn = not remoteOn
			if remoteOn then
				local okh = hookRemotes()
				remoteBtn.Text = "Remote监控: 开"
				remoteBtn.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
				status.Text = okh and "Remote监控已开，请手动买一次" or "Hook失败，仍记录已知目录"
				dbgAppend("===== Remote ON =====")
				pcall(function() notify("Remote监控开", "success") end)
			else
				remoteBtn.Text = "Remote监控: 关"
				remoteBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 228)
				status.Text = "Remote监控已关"
				dbgAppend("===== Remote OFF =====")
			end
		end)

		clickBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== ClickDetector 扫描 =====")
			local n = 0
			local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			local origin = hrp and hrp.Position
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("ClickDetector") then
					local parent = d.Parent
					local pos = parent and parent:IsA("BasePart") and parent.Position
					local dist = (origin and pos) and (pos - origin).Magnitude or -1
					if dist < 0 or dist < 120 then
						dbgAppend(string.format("CD %.0f %s", dist, pathOf(d)))
						n = n + 1
						if n > 80 then break end
					end
				end
			end
			status.Text = "ClickDetector 约 " .. n .. " 条"
			dbgAppend("合计 " .. n)
			pcall(function() notify("CD扫描完成", "info") end)
		end)

		guiBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== ChatGUI =====")
			local cg = PlayerGui:FindFirstChild("ChatGUI")
			if not cg then
				dbgAppend("无 ChatGUI")
				status.Text = "无 ChatGUI"
				return
			end
			dbgAppend("ChatGUI Enabled=" .. tostring(cg.Enabled))
			for _, d in ipairs(cg:GetDescendants()) do
				if d:IsA("TextButton") or d:IsA("TextLabel") then
					local t = tostring(d.Text or "")
					if t ~= "" or d.Name:find("Prompt") or d.Name:find("Choice") or d.Name:find("Chat") then
						dbgAppend(string.format("%s %s Text=%q", d.ClassName, pathOf(d), t:sub(1, 60)))
					end
				end
			end
			status.Text = "ChatGUI 已写入日志"
			pcall(function() notify("ChatGUI已扫描", "info") end)
		end)

		storesBtn.MouseButton1Click:Connect(function()
			dbgAppend("===== Stores =====")
			local stores = Workspace:FindFirstChild("Stores")
			if not stores then
				dbgAppend("无 Workspace.Stores")
				status.Text = "无 Stores"
				return
			end
			for _, store in ipairs(stores:GetChildren()) do
				local items = store:FindFirstChild("ShopItems")
				local count = items and #items:GetChildren() or 0
				dbgAppend(string.format("店 %s ShopItems=%d", store.Name, count))
				if items then
					local i = 0
					for _, it in ipairs(items:GetChildren()) do
						i = i + 1
						if i <= 15 then
							dbgAppend("  - " .. it.Name .. " (" .. it.ClassName .. ")")
						end
					end
					if count > 15 then dbgAppend("  ...") end
				end
			end
			status.Text = "Stores 已扫描"
			pcall(function() notify("Stores已扫描", "info") end)
		end)

		copyBtn.MouseButton1Click:Connect(function()
			tryCopy(dbgLog)
		end)
		clearBtn.MouseButton1Click:Connect(function()
			dbgLog = ""
			status.Text = "日志已清空"
		end)

		print("[Yutong] 调试页 OK")
	end)
	if not ok then warn("[Yutong] 调试页失败", err) end
end)

