local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local speaker = Players.LocalPlayer
local PlayerGui = speaker:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("HellfireGrabUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "HellfireGrabUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 70)
frame.Position = UDim2.new(0.5, -100, 0.5, -35)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text = "HellFire Grab"
title.TextColor3 = Color3.fromRGB(255, 160, 120)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 32)
btn.Position = UDim2.new(0, 10, 0, 28)
btn.BackgroundColor3 = Color3.fromRGB(255, 100, 60)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.Text = "Grab HellFire"
btn.BorderSizePixel = 0
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 16)
status.Position = UDim2.new(0, 0, 1, 4)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = frame

local function setStatus(text, color)
	status.Text = text
	status.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

btn.MouseButton1Click:Connect(function()
	btn.Active = false
	btn.Text = "..."
	btn.BackgroundColor3 = Color3.fromRGB(120, 80, 60)
	setStatus("传送中...", Color3.fromRGB(255, 200, 100))

	task.spawn(function()
		local char = speaker.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local originCF = hrp and hrp.CFrame

		if hrp then
			hrp.CFrame = CFrame.new(-1684.1, 348.9, 1477.7)
		end
		task.wait(0.3)

		setStatus("发包拿剑...", Color3.fromRGB(255, 200, 100))

		local ok, err = pcall(function()
			ReplicatedStorage.Interaction.ClientInteracted:FireServer(
				ReplicatedStorage:WaitForChild("HellFire"), "Pick up tool"
			)
		end)

		task.wait(0.5)

		local c2 = speaker.Character
		local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
		if r2 and originCF then
			r2.CFrame = originCF
		end

		if ok then
			setStatus("成功！", Color3.fromRGB(100, 220, 130))
			btn.Text = "✓ 成功"
			btn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
		else
			setStatus("失败: " .. tostring(err), Color3.fromRGB(220, 100, 100))
			btn.Text = "失败"
			btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		end

		task.wait(2)
		btn.Text = "Grab HellFire"
		btn.BackgroundColor3 = Color3.fromRGB(255, 100, 60)
		btn.Active = true
		setStatus("")
	end)
end)
