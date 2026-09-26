local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local placeRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA = nil
pcall(function()
    DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/rabbit_data.lua", true))()
end)
if not DATA then warn("Failed to load rabbit_data") return end
local TOTAL = #DATA

local function notify(t, tx) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=tx,Duration=3}) end) end

local old = lp.PlayerGui:FindFirstChild("RabbitGui")
if old then old:Destroy() end
local sg = Instance.new("ScreenGui", lp.PlayerGui)
sg.Name = "RabbitGui"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local mf = Instance.new("Frame", sg)
mf.Size = UDim2.new(0,220,0,160)
mf.Position = UDim2.new(0,20,0.5,-80)
mf.BackgroundColor3 = Color3.fromRGB(245,248,252)
mf.BorderSizePixel = 0; mf.Active = true
Instance.new("UICorner",mf).CornerRadius = UDim.new(0,8)
local s = Instance.new("UIStroke",mf); s.Color=Color3.fromRGB(200,210,225); s.Thickness=1

local tb = Instance.new("Frame",mf)
tb.Size=UDim2.new(1,0,0,28); tb.BackgroundColor3=Color3.fromRGB(80,160,80); tb.BorderSizePixel=0
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
local tl=Instance.new("TextLabel",tb)
tl.Size=UDim2.new(1,-10,1,0); tl.Position=UDim2.new(0,10,0,0)
tl.BackgroundTransparency=1; tl.Text="Rabbit Builder  "..TOTAL.." blocks"
tl.TextColor3=Color3.fromRGB(255,255,255); tl.Font=Enum.Font.GothamBold; tl.TextSize=13
tl.TextXAlignment=Enum.TextXAlignment.Left

local drag,ds,sp=false
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; ds=i.Position; sp=mf.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
tb.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-ds
        mf.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)

local pl=Instance.new("TextLabel",mf)
pl.Size=UDim2.new(1,-16,0,16); pl.Position=UDim2.new(0,8,0,34)
pl.BackgroundTransparency=1; pl.Text="Ready: 0/"..TOTAL
pl.TextColor3=Color3.fromRGB(60,70,85); pl.Font=Enum.Font.Gotham; pl.TextSize=11
pl.TextXAlignment=Enum.TextXAlignment.Left

local sl=Instance.new("TextLabel",mf)
sl.Size=UDim2.new(1,-16,0,14); sl.Position=UDim2.new(0,8,0,54)
sl.BackgroundTransparency=1; sl.Text="Idle"
sl.TextColor3=Color3.fromRGB(120,130,145); sl.Font=Enum.Font.Gotham; sl.TextSize=10
sl.TextXAlignment=Enum.TextXAlignment.Left

local BW=math.floor((220-16-8)/3)
local function mkBtn(x,bg,txt)
    local b=Instance.new("TextButton",mf)
    b.Size=UDim2.new(0,BW,0,28); b.Position=UDim2.new(0,x,0,74)
    b.BackgroundColor3=bg; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local startBtn=mkBtn(8,Color3.fromRGB(76,175,80),"Build")
local stopBtn=mkBtn(8+BW+4,Color3.fromRGB(244,67,54),"Stop")
local paintBtn=mkBtn(8+(BW+4)*2,Color3.fromRGB(33,150,243),"Paint")

local closeBtn=Instance.new("TextButton",mf)
closeBtn.Size=UDim2.new(1,-16,0,22); closeBtn.Position=UDim2.new(0,8,0,110)
closeBtn.BackgroundColor3=Color3.fromRGB(150,150,160); closeBtn.BorderSizePixel=0
closeBtn.Text="Close"; closeBtn.TextColor3=Color3.fromRGB(255,255,255)
closeBtn.Font=Enum.Font.Gotham; closeBtn.TextSize=11
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,5)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local running=false

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running=true; sl.Text="Building..."
    notify("Rabbit Builder","Placing "..TOTAL.." blocks")
    task.spawn(function()
        local cnt=0
        for i,d in ipairs(DATA) do
            if not running then break end
            local cf=CFrame.new(d.x,d.y,d.z,d.r00,d.r01,d.r02,d.r10,d.r11,d.r12,d.r20,d.r21,d.r22)
            pcall(function() placeRemote:FireServer(d.n,cf,lp) end)
            cnt=cnt+1
            if cnt%20==0 then
                pl.Text="Place: "..cnt.."/"..TOTAL
                task.wait()
            end
        end
        pl.Text="Place: "..cnt.."/"..TOTAL
        sl.Text=running and "Done! "..cnt.." placed" or "Stopped: "..cnt
        if running then notify("Rabbit Builder","Done! "..cnt.." placed") end
        running=false
    end)
end)

paintBtn.MouseButton1Click:Connect(function()
    if running then return end
    running=true; sl.Text="Indexing..."
    notify("Rabbit Builder","Painting...")
    task.spawn(function()
        local idx={}
        for _,m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") then
                local ov=m:FindFirstChild("Owner")
                if ov and typeof(ov.Value)=="Instance" and ov.Value:IsA("Player") and ov.Value==lp then
                    local pp=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        local p=pp.Position
                        local k=math.floor(p.X+0.5).."_"..math.floor(p.Y+0.5).."_"..math.floor(p.Z+0.5)
                        idx[k]=m
                    end
                end
            end
        end
        local painted,skip=0,0
        for i,d in ipairs(DATA) do
            if not running then break end
            if d.wood and d.wood~="?" then
                local k=math.floor(d.x+0.5).."_"..math.floor(d.y+0.5).."_"..math.floor(d.z+0.5)
                local m=idx[k]
                if m then
                    pcall(function() paintRemote:FireServer(m,d.wood) end)
                    painted=painted+1
                else skip=skip+1 end
                if painted%20==0 then
                    pl.Text="Paint: "..painted.."/"..TOTAL
                    task.wait()
                end
            end
        end
        pl.Text="Paint: "..painted.."/"..TOTAL
        sl.Text=running and "Paint done: "..painted.." skip:"..skip or "Stopped"
        if running then notify("Rabbit Builder","Paint done! "..painted) end
        running=false
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running=false; sl.Text="Stopped"
    notify("Rabbit Builder","Stopped")
end)

notify("Rabbit Builder","Loaded "..TOTAL.." blocks")
sl.Text="Ready"