local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local AUTH = {}
do
    local ok, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/whitelist.txt", true)
    end)
    if ok and result then
        for name in result:gmatch("[^\r\n]+") do
            name = name:match("^%s*(.-)%s*$")
            if #name > 0 then AUTH[name] = true end
        end
    end
end
if not AUTH[lp.Name] then lp:Kick("Unauthorized") return end

local placeRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("ClientPlacedBlueprint")
local paintRemote = ReplicatedStorage:WaitForChild("PlaceStructure"):WaitForChild("PaintTool")

local DATA = nil
pcall(function()
    DATA = loadstring(game:HttpGet("https://raw.githubusercontent.com/jjyy1234/yutongg/main/blueprint_data.lua"))()
end)
if not DATA then warn("Failed to load blueprint_data") return end
local TOTAL = #DATA

local function notify(t, tx) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=tx,Duration=3}) end) end

-- UI
local old = lp.PlayerGui:FindFirstChild("CBGui")
if old then old:Destroy() end
local sg = Instance.new("ScreenGui", lp.PlayerGui)
sg.Name = "CBGui"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local mf = Instance.new("Frame", sg)
mf.Size = UDim2.new(0,220,0,210)
mf.Position = UDim2.new(0,20,0.5,-105)
mf.BackgroundColor3 = Color3.fromRGB(245,248,252)
mf.BorderSizePixel = 0; mf.Active = true
Instance.new("UICorner",mf).CornerRadius = UDim.new(0,8)
local s = Instance.new("UIStroke",mf); s.Color=Color3.fromRGB(200,210,225); s.Thickness=1

-- Title
local tb = Instance.new("Frame",mf)
tb.Size=UDim2.new(1,0,0,28); tb.BackgroundColor3=Color3.fromRGB(72,132,168); tb.BorderSizePixel=0
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
local tl=Instance.new("TextLabel",tb)
tl.Size=UDim2.new(1,-10,1,0); tl.Position=UDim2.new(0,10,0,0)
tl.BackgroundTransparency=1; tl.Text="Copy Builder"
tl.TextColor3=Color3.fromRGB(255,255,255); tl.Font=Enum.Font.GothamBold; tl.TextSize=13
tl.TextXAlignment=Enum.TextXAlignment.Left

-- Drag
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

-- Owner label
local ol=Instance.new("TextLabel",mf)
ol.Size=UDim2.new(1,-16,0,14); ol.Position=UDim2.new(0,8,0,34)
ol.BackgroundTransparency=1; ol.Text="Owner: (none selected)"
ol.TextColor3=Color3.fromRGB(60,70,85); ol.Font=Enum.Font.Gotham; ol.TextSize=10
ol.TextXAlignment=Enum.TextXAlignment.Left

-- Owner scroll
local os2=Instance.new("ScrollingFrame",mf)
os2.Size=UDim2.new(1,-16,0,44); os2.Position=UDim2.new(0,8,0,50)
os2.BackgroundColor3=Color3.fromRGB(235,240,248); os2.BorderSizePixel=0
os2.ScrollBarThickness=4; os2.AutomaticCanvasSize=Enum.AutomaticSize.Y
os2.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UICorner",os2).CornerRadius=UDim.new(0,5)
local ul=Instance.new("UIListLayout",os2); ul.Padding=UDim.new(0,2)

-- Scan Owners btn
local sob=Instance.new("TextButton",mf)
sob.Size=UDim2.new(1,-16,0,22); sob.Position=UDim2.new(0,8,0,98)
sob.BackgroundColor3=Color3.fromRGB(33,150,243); sob.BorderSizePixel=0
sob.Text="Scan Owners"; sob.TextColor3=Color3.fromRGB(255,255,255)
sob.Font=Enum.Font.GothamBold; sob.TextSize=11
Instance.new("UICorner",sob).CornerRadius=UDim.new(0,5)

-- Divider
local dv=Instance.new("Frame",mf)
dv.Size=UDim2.new(1,-16,0,1); dv.Position=UDim2.new(0,8,0,126)
dv.BackgroundColor3=Color3.fromRGB(200,210,225); dv.BorderSizePixel=0

-- Progress
local pl=Instance.new("TextLabel",mf)
pl.Size=UDim2.new(1,-16,0,16); pl.Position=UDim2.new(0,8,0,132)
pl.BackgroundTransparency=1; pl.Text="Ready: 0/"..TOTAL
pl.TextColor3=Color3.fromRGB(60,70,85); pl.Font=Enum.Font.Gotham; pl.TextSize=11
pl.TextXAlignment=Enum.TextXAlignment.Left

-- 3 buttons
local BW=math.floor((220-16-8)/3)
local function mkBtn(x,bg,txt)
    local b=Instance.new("TextButton",mf)
    b.Size=UDim2.new(0,BW,0,26); b.Position=UDim2.new(0,x,0,152)
    b.BackgroundColor3=bg; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local startBtn=mkBtn(8,Color3.fromRGB(76,175,80),"Start")
local stopBtn=mkBtn(8+BW+4,Color3.fromRGB(244,67,54),"Stop")
local paintBtn=mkBtn(8+(BW+4)*2,Color3.fromRGB(33,150,243),"Paint")

-- Status
local sl=Instance.new("TextLabel",mf)
sl.Size=UDim2.new(1,-16,0,14); sl.Position=UDim2.new(0,8,0,184)
sl.BackgroundTransparency=1; sl.Text="Idle"
sl.TextColor3=Color3.fromRGB(120,130,145); sl.Font=Enum.Font.Gotham; sl.TextSize=10
sl.TextXAlignment=Enum.TextXAlignment.Left

-- Logic
local running=false
local selOwner=nil

sob.MouseButton1Click:Connect(function()
    for _,c in ipairs(os2:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local seen={}
    for _,m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") then
            local ov=m:FindFirstChild("Owner")
            if ov and typeof(ov.Value)=="Instance" and ov.Value:IsA("Player") and not seen[ov.Value.Name] then
                seen[ov.Value.Name]=ov.Value
                local p=ov.Value
                local b=Instance.new("TextButton",os2)
                b.Size=UDim2.new(1,-4,0,16); b.BackgroundColor3=Color3.fromRGB(210,220,235)
                b.BorderSizePixel=0; b.Text=p.Name
                b.TextColor3=Color3.fromRGB(50,60,80); b.Font=Enum.Font.Gotham; b.TextSize=10
                b.AutoButtonColor=false
                Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
                b.MouseButton1Click:Connect(function()
                    selOwner=p; ol.Text="Owner: "..p.Name
                    for _,c2 in ipairs(os2:GetChildren()) do
                        if c2:IsA("TextButton") then
                            c2.BackgroundColor3=Color3.fromRGB(210,220,235)
                            c2.TextColor3=Color3.fromRGB(50,60,80)
                        end
                    end
                    b.BackgroundColor3=Color3.fromRGB(72,132,168)
                    b.TextColor3=Color3.fromRGB(255,255,255)
                end)
            end
        end
    end
    local n=0; for _ in pairs(seen) do n=n+1 end
    sl.Text="Found "..n.." owners"
end)

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    if not selOwner then sl.Text="Select an owner first!" return end
    running=true; sl.Text="Building..."
    notify("Copy Builder","Placing "..TOTAL.." blueprints")
    task.spawn(function()
        local cnt=0
        for i,d in ipairs(DATA) do
            if not running then break end
            if d.n~="Property" then
                local cf=CFrame.new(d.x,d.y,d.z,d.r00,d.r01,d.r02,d.r10,d.r11,d.r12,d.r20,d.r21,d.r22)
                pcall(function() placeRemote:FireServer(d.n,cf,lp) end)
                cnt=cnt+1; pl.Text="Place: "..cnt.."/"..TOTAL
                task.wait(0.01)
            end
        end
        sl.Text=running and "Build done: "..cnt or "Stopped: "..cnt
        if running then notify("Copy Builder","Done! "..cnt.." placed") end
        running=false
    end)
end)

paintBtn.MouseButton1Click:Connect(function()
    if running then return end
    if not selOwner then sl.Text="Select an owner first!" return end
    running=true; sl.Text="Indexing..."
    notify("Copy Builder","Painting...")
    task.spawn(function()
        local idx={}
        local ownerName = selOwner and selOwner.Name or ""
        for _,m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") then
                local ov=m:FindFirstChild("Owner")
                local match = false
                if ov then
                    if typeof(ov.Value)=="Instance" and ov.Value:IsA("Player") and ov.Value.Name==ownerName then
                        match=true
                    elseif typeof(ov.Value)=="string" and ov.Value==ownerName then
                        match=true
                    end
                end
                if match then
                    local pp=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        local p=pp.Position
                        local k=math.floor(p.X+0.5).."_"..math.floor(p.Y+0.5).."_"..math.floor(p.Z+0.5)
                        idx[k]=m
                    end
                end
            end
        end
        local idxCount=0; for _ in pairs(idx) do idxCount=idxCount+1 end
        sl.Text="Indexed: "..idxCount.." models"
        task.wait(0.5)
        local painted,skip=0,0
        for i,d in ipairs(DATA) do
            if not running then break end
            if d.n~="Property" and d.wood and d.wood~="?" then
                local k=math.floor(d.x+0.5).."_"..math.floor(d.y+0.5).."_"..math.floor(d.z+0.5)
                local m=idx[k]
                if not m then
                    for dx=-2,2 do for dy=-2,2 do for dz=-2,2 do
                        local k2=(math.floor(d.x+0.5)+dx).."_"..(math.floor(d.y+0.5)+dy).."_"..(math.floor(d.z+0.5)+dz)
                        if idx[k2] then m=idx[k2] break end
                    end if m then break end end if m then break end end
                end
                if m then pcall(function() paintRemote:FireServer(m,d.wood) end) painted=painted+1
                else skip=skip+1 end
                task.wait(0.01)
            end
            if i%100==0 then
                pl.Text="Paint: "..i.."/"..TOTAL
                sl.Text="Painted:"..painted.." Skip:"..skip
            end
        end
        pl.Text="Paint: "..TOTAL.."/"..TOTAL
        sl.Text=running and "Paint done: "..painted or "Stopped"
        if running then notify("Copy Builder","Paint done! "..painted) end
        running=false
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running=false; sl.Text="Stopped"
    notify("Copy Builder","Stopped")
end)

notify("Copy Builder","Loaded "..TOTAL.." blueprints")
sl.Text="Ready"
