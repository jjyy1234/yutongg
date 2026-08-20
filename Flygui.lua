--========================================================--
-- YUTONG FLY
-- Original Flight Logic + Swimming + Silent Swim Sound
-- Mobile Joystick Support
-- Macaron UI
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local speaker = Players.LocalPlayer
local PlayerGui = speaker:WaitForChild("PlayerGui")

--========================================================--
-- 清理旧 GUI
--========================================================--

local old = PlayerGui:FindFirstChild("YutongFlyUI")
if old then
	old:Destroy()
end

--========================================================--
-- GUI（自适应手机屏幕 + 控件不超出边框）
--========================================================--

local main = Instance.new("ScreenGui")
main.Name = "YutongFlyUI"
main.Parent = PlayerGui
main.ResetOnSpawn = false
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.IgnoreGuiInset = true

-- 根据屏幕短边自适应缩放（手机友好）
local function getUIScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local short = math.min(vp.X, vp.Y)
	-- 以 500 为基准，限制在 0.75 ~ 1.35
	return math.clamp(short / 500, 0.75, 1.35)
end

local S = getUIScale()

local function px(n)
	return math.floor(n * S + 0.5)
end

local FRAME_W = px(220)
local FRAME_H = px(108)

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Parent = main
Frame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
Frame.Position = UDim2.new(0.08, 0, 0.38, 0)
Frame.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
Frame.BackgroundTransparency = 0.04
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true -- 防止子控件画出边框

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, px(14))
frameCorner.Parent = Frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Parent = Frame
frameStroke.Color = Color3.fromRGB(225, 198, 215)
frameStroke.Thickness = math.max(1, S * 1.2)
frameStroke.Transparency = 0.15

--========================================================--
-- YUTONG 标题
--========================================================--

local TextLabel = Instance.new("TextLabel")
TextLabel.Name = "Title"
TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1
TextLabel.Position = UDim2.new(0, px(12), 0, px(6))
TextLabel.Size = UDim2.new(0, px(88), 0, px(28))
TextLabel.Text = "Yutong"
TextLabel.TextColor3 = Color3.fromRGB(145, 103, 134)
TextLabel.Font = Enum.Font.Cartoon
TextLabel.TextSize = px(24)
TextLabel.TextXAlignment = Enum.TextXAlignment.Left

local titleGradient = Instance.new("UIGradient")
titleGradient.Parent = TextLabel
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(157, 112, 145)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 153, 187))
})

local SubTitle = Instance.new("TextLabel")
SubTitle.Name = "SubTitle"
SubTitle.Parent = Frame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, px(13), 0, px(32))
SubTitle.Size = UDim2.new(0, px(100), 0, px(14))
SubTitle.Text = "FLY  •  CONTROL"
SubTitle.TextColor3 = Color3.fromRGB(173, 144, 163)
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextSize = px(8)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

--========================================================--
-- FLY（右上角内侧）
--========================================================--

local onof = Instance.new("TextButton")
onof.Name = "Fly"
onof.Parent = Frame
onof.Position = UDim2.new(1, -px(120), 0, px(10))
onof.Size = UDim2.new(0, px(56), 0, px(28))
onof.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
onof.BorderSizePixel = 0
onof.Text = "FLY"
onof.TextColor3 = Color3.fromRGB(72, 108, 88)
onof.Font = Enum.Font.GothamBold
onof.TextSize = px(11)
onof.AutoButtonColor = false

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(1, 0)
flyCorner.Parent = onof

--========================================================--
-- 最小化 / 关闭（全部在框内右上）
--========================================================--

local mini = Instance.new("TextButton")
mini.Name = "minimize"
mini.Parent = Frame
mini.Position = UDim2.new(1, -px(54), 0, px(10))
mini.Size = UDim2.new(0, px(22), 0, px(22))
mini.BackgroundColor3 = Color3.fromRGB(215, 202, 232)
mini.BorderSizePixel = 0
mini.Text = "−"
mini.TextColor3 = Color3.fromRGB(110, 91, 130)
mini.Font = Enum.Font.GothamBold
mini.TextSize = px(14)
mini.ZIndex = 2
mini.AutoButtonColor = false

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(1, 0)
miniCorner.Parent = mini

local closebutton = Instance.new("TextButton")
closebutton.Name = "Close"
closebutton.Parent = Frame
closebutton.Position = UDim2.new(1, -px(28), 0, px(10))
closebutton.Size = UDim2.new(0, px(22), 0, px(22))
closebutton.BackgroundColor3 = Color3.fromRGB(245, 179, 188)
closebutton.BorderSizePixel = 0
closebutton.Text = "×"
closebutton.TextColor3 = Color3.fromRGB(125, 75, 85)
closebutton.Font = Enum.Font.GothamBold
closebutton.TextSize = px(14)
closebutton.ZIndex = 2
closebutton.AutoButtonColor = false

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closebutton

--========================================================--
-- Controls（底部一排，全部在框内）
--========================================================--

local Controls = Instance.new("Frame")
Controls.Name = "Controls"
Controls.Parent = Frame
Controls.BackgroundTransparency = 1
Controls.Position = UDim2.new(0, px(10), 0, px(58))
Controls.Size = UDim2.new(1, -px(20), 0, px(34))

-- UP
local up = Instance.new("TextButton")
up.Name = "up"
up.Parent = Controls
up.Position = UDim2.new(0, 0, 0, 0)
up.Size = UDim2.new(0, px(40), 0, px(30))
up.BackgroundColor3 = Color3.fromRGB(190, 224, 242)
up.BorderSizePixel = 0
up.Text = "↑"
up.TextColor3 = Color3.fromRGB(76, 116, 140)
up.Font = Enum.Font.GothamBold
up.TextSize = px(17)
up.AutoButtonColor = false

local upCorner = Instance.new("UICorner")
upCorner.CornerRadius = UDim.new(0, px(9))
upCorner.Parent = up

-- DOWN
local down = Instance.new("TextButton")
down.Name = "down"
down.Parent = Controls
down.Position = UDim2.new(0, px(45), 0, 0)
down.Size = UDim2.new(0, px(40), 0, px(30))
down.BackgroundColor3 = Color3.fromRGB(210, 201, 239)
down.BorderSizePixel = 0
down.Text = "↓"
down.TextColor3 = Color3.fromRGB(112, 91, 145)
down.Font = Enum.Font.GothamBold
down.TextSize = px(17)
down.AutoButtonColor = false

local downCorner = Instance.new("UICorner")
downCorner.CornerRadius = UDim.new(0, px(9))
downCorner.Parent = down

-- SPEED
local speed = Instance.new("TextLabel")
speed.Name = "speed"
speed.Parent = Controls
speed.Position = UDim2.new(0, px(90), 0, 0)
speed.Size = UDim2.new(0, px(34), 0, px(30))
speed.BackgroundColor3 = Color3.fromRGB(255, 224, 190)
speed.BorderSizePixel = 0
speed.Text = "1"
speed.TextColor3 = Color3.fromRGB(147, 105, 75)
speed.Font = Enum.Font.GothamBold
speed.TextSize = px(13)

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, px(9))
speedCorner.Parent = speed

-- -
local mine = Instance.new("TextButton")
mine.Name = "mine"
mine.Parent = Controls
mine.Position = UDim2.new(0, px(129), 0, 0)
mine.Size = UDim2.new(0, px(28), 0, px(30))
mine.BackgroundColor3 = Color3.fromRGB(247, 202, 211)
mine.BorderSizePixel = 0
mine.Text = "−"
mine.TextColor3 = Color3.fromRGB(146, 83, 101)
mine.Font = Enum.Font.GothamBold
mine.TextSize = px(16)
mine.AutoButtonColor = false

local mineCorner = Instance.new("UICorner")
mineCorner.CornerRadius = UDim.new(0, px(9))
mineCorner.Parent = mine

-- +
local plus = Instance.new("TextButton")
plus.Name = "plus"
plus.Parent = Controls
plus.Position = UDim2.new(0, px(162), 0, 0)
plus.Size = UDim2.new(0, px(28), 0, px(30))
plus.BackgroundColor3 = Color3.fromRGB(194, 231, 211)
plus.BorderSizePixel = 0
plus.Text = "+"
plus.TextColor3 = Color3.fromRGB(74, 125, 94)
plus.Font = Enum.Font.GothamBold
plus.TextSize = px(16)
plus.AutoButtonColor = false

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, px(9))
plusCorner.Parent = plus

-- MINI2（缩小态）
local mini2 = Instance.new("TextButton")
mini2.Name = "minimize2"
mini2.Parent = main
mini2.Position = Frame.Position
mini2.Size = UDim2.new(0, px(52), 0, px(34))
mini2.BackgroundColor3 = Color3.fromRGB(250, 238, 245)
mini2.BorderSizePixel = 0
mini2.Text = "Y"
mini2.TextColor3 = Color3.fromRGB(145, 105, 135)
mini2.Font = Enum.Font.Cartoon
mini2.TextSize = px(20)
mini2.Visible = false

local mini2Corner = Instance.new("UICorner")
mini2Corner.CornerRadius = UDim.new(0, px(12))
mini2Corner.Parent = mini2

-- 屏幕尺寸变化时重新缩放（可选，旋转屏幕时更新）
local function applyScale()
	S = getUIScale()
	-- 尺寸已在创建时按 S 计算；若需实时重算可在此扩展
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(applyScale)
end)

--========================================================--
-- 状态
--========================================================--

local speeds = 1
local nowe = false
local tpwalking = false

local swimSoundConnections = {}

--========================================================--
-- 游泳声音静音
--========================================================--

local function IsSwimSound(obj)

	if not obj:IsA("Sound") then
		return false
	end
	local n = string.lower(obj.Name)
	return
		string.find(n, "swim")
		or string.find(n, "splash")
		or string.find(n, "water")
		or string.find(n, "underwater")

end

local function MuteSwimmingSounds()

	local character = speaker.Character
	if not character then
		return
	end
	for _, obj in ipairs(character:GetDescendants()) do
		if IsSwimSound(obj) then
			obj.Volume = 0
			obj:Stop()
		end
	end

end

local function StartSwimmingSoundMute()

	MuteSwimmingSounds()
	local character = speaker.Character
	if not character then
		return
	end
	if swimSoundConnections.DescendantAdded then
		swimSoundConnections.DescendantAdded:Disconnect()
	end
	swimSoundConnections.DescendantAdded =
		character.DescendantAdded:Connect(function(obj)
			if IsSwimSound(obj) then
				obj.Volume = 0
				obj:Stop()
			end
		end)

end

local function StopSwimmingSoundMute()

	if swimSoundConnections.DescendantAdded then
		swimSoundConnections.DescendantAdded:Disconnect()
		swimSoundConnections.DescendantAdded = nil
	end

end

--========================================================--
-- 通知
--========================================================--

pcall(function()

	StarterGui:SetCore("SendNotification", {
		Title = "YUTONG FLY",
		Text = "Flight system loaded",
		Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
		Duration = 5
	})

end)

--========================================================--
-- UI 防误触拖动
--========================================================--

local dragging = false
local dragStart
local startPos
local dragInput

local function updateDrag(input)

	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)

end

Frame.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		-- 两指触控时不开始拖动
		if #UserInputService:GetTouches() > 1 then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end

end)

Frame.InputChanged:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end

end)

UserInputService.InputChanged:Connect(function(input)

	if input == dragInput and dragging then
		if #UserInputService:GetTouches() <= 1 then
			updateDrag(input)
		end
	end

end)

--========================================================--
-- 原飞行按钮
--========================================================--

onof.MouseButton1Down:Connect(function()

	local character = speaker.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if nowe == true then
		nowe = false
		StopSwimmingSoundMute()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
		humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		onof.Text = "FLY"
		onof.BackgroundColor3 = Color3.fromRGB(191, 226, 205)
	else
		nowe = true
		StartSwimmingSoundMute()
		onof.Text = "ON"
		onof.BackgroundColor3 = Color3.fromRGB(170, 220, 191)
		--================================================--
		-- 原 TranslateBy 逻辑
		--================================================--
		for i = 1, speeds do
			task.spawn(function()
				local hb = RunService.Heartbeat
				tpwalking = true
				local chr = speaker.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking
					and hb:Wait()
					and chr
					and hum
					and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
		local animate = character:FindFirstChild("Animate")
		if animate then
			animate.Disabled = true
		end
		local Hum =
			character:FindFirstChildOfClass("Humanoid")
			or character:FindFirstChildOfClass("AnimationController")
		if Hum then
			for _, v in next, Hum:GetPlayingAnimationTracks() do
				v:AdjustSpeed(0)
			end
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
		humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end
	--========================================================--
	-- R6
	--========================================================--
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local plr = speaker
		local torso = plr.Character.Torso
		local ctrl = {
			f = 0,
			b = 0,
			l = 0,
			r = 0
		}
		local lastctrl = {
			f = 0,
			b = 0,
			l = 0,
			r = 0
		}
		local maxspeed = 50
		local flySpeed = 0
		local bg = Instance.new("BodyGyro", torso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9,9e9,9e9)
		bg.cframe = torso.CFrame
		local bv = Instance.new("BodyVelocity", torso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9,9e9,9e9)
		if nowe == true then
			humanoid.PlatformStand = true
		end
		while nowe == true
			or speaker.Character.Humanoid.Health == 0 do
			RunService.RenderStepped:Wait()
			if ctrl.l + ctrl.r ~= 0
				or ctrl.f + ctrl.b ~= 0 then
				flySpeed =
					flySpeed
					+ .5
					+ (flySpeed / maxspeed)
				if flySpeed > maxspeed then
					flySpeed = maxspeed
				end
			elseif flySpeed ~= 0 then
				flySpeed = flySpeed - 1
				if flySpeed < 0 then
					flySpeed = 0
				end
			end
			if ctrl.l + ctrl.r ~= 0
				or ctrl.f + ctrl.b ~= 0 then
				bv.velocity =
					(
						workspace.CurrentCamera.CoordinateFrame.lookVector
						*
						(ctrl.f + ctrl.b)
					)
					+
					(
						(
							workspace.CurrentCamera.CoordinateFrame
							*
							CFrame.new(
								ctrl.l + ctrl.r,
								(ctrl.f + ctrl.b) * .2,
								0
							).p
						)
						-
						workspace.CurrentCamera.CoordinateFrame.p
					)
					*
					flySpeed
				lastctrl = {
					f = ctrl.f,
					b = ctrl.b,
					l = ctrl.l,
					r = ctrl.r
				}
			elseif flySpeed ~= 0 then
				bv.velocity =
					(
						workspace.CurrentCamera.CoordinateFrame.lookVector
						*
						(lastctrl.f + lastctrl.b)
					)
					+
					(
						(
							workspace.CurrentCamera.CoordinateFrame
							*
							CFrame.new(
								lastctrl.l + lastctrl.r,
								(lastctrl.f + lastctrl.b) * .2,
								0
							).p
						)
						-
						workspace.CurrentCamera.CoordinateFrame.p
					)
					*
					flySpeed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe =
				workspace.CurrentCamera.CoordinateFrame
				*
				CFrame.Angles(
					-math.rad(
						(ctrl.f + ctrl.b)
						*
						50
						*
						flySpeed
						/
						maxspeed
					),
					0,
					0
				)
		end
		bg:Destroy()
		bv:Destroy()
		humanoid.PlatformStand = false
		local animate = plr.Character:FindFirstChild("Animate")
		if animate then
			animate.Disabled = false
		end
		tpwalking = false
	--========================================================--
	-- R15
	--========================================================--
	else
		local plr = speaker
		local UpperTorso = plr.Character.UpperTorso
		local ctrl = {
			f = 0,
			b = 0,
			l = 0,
			r = 0
		}
		local lastctrl = {
			f = 0,
			b = 0,
			l = 0,
			r = 0
		}
		local maxspeed = 50
		local flySpeed = 0
		local bg = Instance.new("BodyGyro", UpperTorso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9,9e9,9e9)
		bg.cframe = UpperTorso.CFrame
		local bv = Instance.new("BodyVelocity", UpperTorso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9,9e9,9e9)
		if nowe == true then
			humanoid.PlatformStand = true
		end
		while nowe == true
			or speaker.Character.Humanoid.Health == 0 do
			RunService.RenderStepped:Wait()
			if ctrl.l + ctrl.r ~= 0
				or ctrl.f + ctrl.b ~= 0 then
				flySpeed =
					flySpeed
					+ .5
					+ (flySpeed / maxspeed)
				if flySpeed > maxspeed then
					flySpeed = maxspeed
				end
			elseif flySpeed ~= 0 then
				flySpeed = flySpeed - 1
				if flySpeed < 0 then
					flySpeed = 0
				end
			end
			if ctrl.l + ctrl.r ~= 0
				or ctrl.f + ctrl.b ~= 0 then
				bv.velocity =
					(
						workspace.CurrentCamera.CoordinateFrame.lookVector
						*
						(ctrl.f + ctrl.b)
					)
					+
					(
						(
							workspace.CurrentCamera.CoordinateFrame
							*
							CFrame.new(
								ctrl.l + ctrl.r,
								(ctrl.f + ctrl.b) * .2,
								0
							).p
						)
						-
						workspace.CurrentCamera.CoordinateFrame.p
					)
					*
					flySpeed
				lastctrl = {
					f = ctrl.f,
					b = ctrl.b,
					l = ctrl.l,
					r = ctrl.r
				}
			elseif flySpeed ~= 0 then
				bv.velocity =
					(
						workspace.CurrentCamera.CoordinateFrame.lookVector
						*
						(lastctrl.f + lastctrl.b)
					)
					+
					(
						(
							workspace.CurrentCamera.CoordinateFrame
							*
							CFrame.new(
								lastctrl.l + lastctrl.r,
								(lastctrl.f + lastctrl.b) * .2,
								0
							).p
						)
						-
						workspace.CurrentCamera.CoordinateFrame.p
					)
					*
					flySpeed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe =
				workspace.CurrentCamera.CoordinateFrame
				*
				CFrame.Angles(
					-math.rad(
						(ctrl.f + ctrl.b)
						*
						50
						*
						flySpeed
						/
						maxspeed
					),
					0,
					0
				)
		end
		bg:Destroy()
		bv:Destroy()
		humanoid.PlatformStand = false
		local animate = plr.Character:FindFirstChild("Animate")
		if animate then
			animate.Disabled = false
		end
		tpwalking = false
	end

end)

--========================================================--
-- UP
--========================================================--

local tis

up.MouseButton1Down:Connect(function()

	tis = RunService.Heartbeat:Connect(function()
		if not nowe then
			return
		end
		local character = speaker.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame =
				root.CFrame
				*
				CFrame.new(0,1,0)
		end
	end)

end)

up.MouseButton1Up:Connect(function()

	if tis then
		tis:Disconnect()
		tis = nil
	end

end)

up.MouseLeave:Connect(function()

	if tis then
		tis:Disconnect()
		tis = nil
	end

end)

--========================================================--
-- DOWN
--========================================================--

local dis

down.MouseButton1Down:Connect(function()

	dis = RunService.Heartbeat:Connect(function()
		if not nowe then
			return
		end
		local character = speaker.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame =
				root.CFrame
				*
				CFrame.new(0,-1,0)
		end
	end)

end)

down.MouseButton1Up:Connect(function()

	if dis then
		dis:Disconnect()
		dis = nil
	end

end)

down.MouseLeave:Connect(function()

	if dis then
		dis:Disconnect()
		dis = nil
	end

end)

--========================================================--
-- SPEED +
--========================================================--

plus.MouseButton1Click:Connect(function()

	speeds = speeds + 1
	speed.Text = tostring(speeds)
	if nowe == true then
		tpwalking = false
		for i = 1, speeds do
			task.spawn(function()
				local hb = RunService.Heartbeat
				tpwalking = true
				local chr = speaker.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking
					and hb:Wait()
					and chr
					and hum
					and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
	end

end)

--========================================================--
-- SPEED -
--========================================================--

mine.MouseButton1Click:Connect(function()

	if speeds <= 1 then
		speed.Text = "MIN"
		task.wait(0.7)
		speed.Text = tostring(speeds)
		return
	end
	speeds = speeds - 1
	speed.Text = tostring(speeds)
	if nowe == true then
		tpwalking = false
		for i = 1, speeds do
			task.spawn(function()
				local hb = RunService.Heartbeat
				tpwalking = true
				local chr = speaker.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking
					and hb:Wait()
					and chr
					and hum
					and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
	end

end)

--========================================================--
-- CHARACTER RESPAWN
--========================================================--

speaker.CharacterAdded:Connect(function(char)

	task.wait(0.7)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
	local animate = char:FindFirstChild("Animate")
	if animate then
		animate.Disabled = false
	end
	if nowe then
		nowe = false
		tpwalking = false
		StopSwimmingSoundMute()
	end

end)

--========================================================--
-- CLOSE
--========================================================--

closebutton.MouseButton1Click:Connect(function()

	nowe = false
	tpwalking = false
	StopSwimmingSoundMute()
	main:Destroy()

end)

--========================================================--
-- MINIMIZE
--========================================================--

mini.MouseButton1Click:Connect(function()

	Frame.Visible = false
	mini2.Visible = true
	mini2.Position = Frame.Position

end)

--========================================================--
-- RESTORE
--========================================================--

mini2.MouseButton1Click:Connect(function()

	mini2.Visible = false
	Frame.Visible = true

end)

--========================================================--
-- UI 点击动画
--========================================================--

local function addEffect(button, normal)

	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 =
					normal:Lerp(Color3.new(1,1,1),0.12)
			}
		):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 = normal
			}
		):Play()
	end)

end

addEffect(up,Color3.fromRGB(190,224,242))
addEffect(down,Color3.fromRGB(210,201,239))
addEffect(plus,Color3.fromRGB(194,231,211))
addEffect(mine,Color3.fromRGB(247,202,211))
addEffect(onof,Color3.fromRGB(191,226,205))
