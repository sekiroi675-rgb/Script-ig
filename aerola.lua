local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting") -- Исправлено: Lighting вместо Camera для Blur
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not Drawing then return end

local GuiEnv = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "AerolaScriptsV9"
pcall(function()
    if protectgui then protectgui(Gui)
    elseif syn and syn.protect_gui then syn.protect_gui(Gui) end
end)
Gui.Parent = GuiEnv

local Themes = {
    Purple = Color3.fromRGB(140, 95, 255),
    Red = Color3.fromRGB(255, 75, 75),
    Blue = Color3.fromRGB(75, 160, 255),
    Green = Color3.fromRGB(80, 220, 110),
    Orange = Color3.fromRGB(255, 165, 50)
}

local Settings = {
    Aim = { On = false, FOV = 100, Team = true, Wall = true, Rainbow = false, Part = "HumanoidRootPart", Smooth = 50 },
    ESP = { On = false, Team = true, Wall = false, Color = Themes.Purple },
    Vis = { Chams = false, HealthBar = false, Distance = false, Crosshair = false, CrosshairSize = 8, ARStretch = false, Stretch43 = false, NightMode = false },
    Misc = { Spinbot = false, SpinSpeed = 20 },
    Theme = "Purple"
}

local UIRefs = { 
    Indicators = {}, Fills = {}, Values = {}, Toggles = {}, Title = nil, ToggleStroke = nil, TabButtons = {},
    BgFrames = {}, ElemFrames = {}, Strokes = {}, TextLabels = {}
}

local function ApplyTheme(name)
    local c = Themes[name]
    if not c then return end
    Settings.Theme = name
    Settings.ESP.Color = c
    
    for _, ind in pairs(UIRefs.Indicators) do ind.BackgroundColor3 = c end
    for _, fill in pairs(UIRefs.Fills) do 
        fill.BackgroundColor3 = c 
        if fill.Gradient then fill.Gradient.Color = ColorSequence.new({Color3.new(0,0,0), c}) end
    end
    for _, val in pairs(UIRefs.Values) do val.TextColor3 = c end
    for _, tog in pairs(UIRefs.Toggles) do tog.Knob.BackgroundColor3 = c end
    if UIRefs.Title then UIRefs.Title.TextColor3 = c end
    if UIRefs.ToggleStroke then UIRefs.ToggleStroke.Color = c end
    
    local isDark = Settings.Vis.NightMode
    local bgCol = isDark and Color3.fromRGB(5, 5, 8) or Color3.fromRGB(18, 18, 22)
    local elemCol = isDark and Color3.fromRGB(12, 12, 16) or Color3.fromRGB(25, 25, 30)
    local strokeCol = isDark and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(35, 35, 42)
    local textCol = isDark and Color3.fromRGB(150, 150, 160) or Color3.fromRGB(210, 210, 220)
    
    for _, f in pairs(UIRefs.BgFrames) do f.BackgroundColor3 = bgCol end
    for _, f in pairs(UIRefs.ElemFrames) do f.BackgroundColor3 = elemCol end
    for _, s in pairs(UIRefs.Strokes) do s.Color = strokeCol end
    for _, t in pairs(UIRefs.TextLabels) do t.TextColor3 = textCol end
    
    for _, tab in pairs(UIRefs.TabButtons) do
        if tab.IsActive then
            tab.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.Btn.BackgroundColor3 = isDark and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(32, 32, 40)
        else
            tab.Btn.TextColor3 = textCol
            tab.Btn.BackgroundColor3 = elemCol
        end
    end
end

local OriginalFOV = Camera.FieldOfView or 70
local function SetARStretch(enabled) Camera.FieldOfView = enabled and 120 or OriginalFOV end
local BaseFOV = OriginalFOV

local function Get43StretchedFOV()
    local sw = Camera.ViewportSize.X
    local sh = Camera.ViewportSize.Y
    if sh == 0 or sw == 0 then return BaseFOV end
    local currentAspect = sw / sh
    local targetAspect = 4 / 3
    local stretchFactor = currentAspect / targetAspect
    local radFov = math.rad(BaseFOV)
    local stretchedRad = 2 * math.atan(math.tan(radFov / 2) * stretchFactor)
    return math.clamp(math.deg(stretchedRad), 1, 130)
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Filled = false
FOVCircle.ZIndex = 999
FOVCircle.Transparency = 1

local FOVLines = {}
for i = 1, 4 do
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    l.ZIndex = 999
    l.Transparency = 1
    table.insert(FOVLines, l)
end

local useFallbackFOV = true
pcall(function()
    FOVCircle.Radius = 50
    FOVCircle.Position = Vector2.new(200, 200)
    FOVCircle.Visible = true
    FOVCircle.Color = Color3.new(1, 1, 1)
end)

local fovCheckDone = false

local function UpdateFOV(pos, radius, visible, color)
    if not fovCheckDone then
        fovCheckDone = true
        task.spawn(function()
            task.wait(0.1)
            pcall(function()
                useFallbackFOV = (FOVCircle.Radius ~= 50 or not FOVCircle.Visible)
            end)
        end)
    end
    if useFallbackFOV then
        FOVCircle.Visible = false
        for _, l in pairs(FOVLines) do l.Visible = visible; l.Color = color end
        if visible then
            local r = radius
            FOVLines[1].From = Vector2.new(pos.X - r, pos.Y - r)
            FOVLines[1].To = Vector2.new(pos.X + r, pos.Y - r)
            FOVLines[2].From = Vector2.new(pos.X + r, pos.Y - r)
            FOVLines[2].To = Vector2.new(pos.X + r, pos.Y + r)
            FOVLines[3].From = Vector2.new(pos.X + r, pos.Y + r)
            FOVLines[3].To = Vector2.new(pos.X - r, pos.Y + r)
            FOVLines[4].From = Vector2.new(pos.X - r, pos.Y + r)
            FOVLines[4].To = Vector2.new(pos.X - r, pos.Y - r)
        end
    else
        for _, l in pairs(FOVLines) do l.Visible = false end
        FOVCircle.Position = pos
        FOVCircle.Radius = radius
        FOVCircle.Visible = visible
        FOVCircle.Color = color
    end
end

local CH = { Dot = Drawing.new("Circle"), H = Drawing.new("Line"), V = Drawing.new("Line") }
CH.Dot.Filled = true
CH.Dot.NumSides = 12
CH.Dot.Thickness = 1
CH.Dot.ZIndex = 998
CH.H.Thickness = 1.5
CH.H.ZIndex = 998
CH.V.Thickness = 1.5
CH.V.ZIndex = 998

local ESPCache = {}

local function GetESP(plr)
    if not ESPCache[plr] then
        ESPCache[plr] = {
            Box = Drawing.new("Square"), Name = Drawing.new("Text"), Line = Drawing.new("Line"),
            HPBar = Drawing.new("Line"), HPBg = Drawing.new("Line"), Dist = Drawing.new("Text")
        }
        local e = ESPCache[plr]
        e.Box.Filled = false
        e.Box.Thickness = 1
        e.Name.Center = true
        e.Name.Size = 13
        e.Name.Font = 1
        e.Name.Outline = true
        e.Line.Thickness = 1
        e.HPBar.Thickness = 2
        e.HPBar.ZIndex = 2
        e.HPBg.Thickness = 2
        e.HPBg.Color = Color3.new(0, 0, 0)
        e.HPBg.ZIndex = 1
        e.Dist.Center = true
        e.Dist.Size = 11
        e.Dist.Font = 1
        e.Dist.Outline = true
    end
    return ESPCache[plr]
end

local function UpdateChams(plr, enabled, color)
    if not plr.Character then return end
    local highlight = plr.Character:FindFirstChild("AerolaChams")
    if enabled then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "AerolaChams"
            highlight.Parent = plr.Character
        end
        highlight.Adornee = plr.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = color
        highlight.FillTransparency = 0.4
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.1
        highlight.Enabled = true
    else
        if highlight then highlight.Enabled = false end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    if ESPCache[plr] then
        for _, o in pairs(ESPCache[plr]) do pcall(function() o:Remove() end) end
        ESPCache[plr] = nil
    end
    if plr.Character and plr.Character:FindFirstChild("AerolaChams") then
        plr.Character.AerolaChams:Destroy()
    end
end)

local spinAngle = 0

RunService.RenderStepped:Connect(function()
    local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local isMob = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local aimPos = isMob and sc or UIS:GetMouseLocation()
    if aimPos.X == 0 and aimPos.Y == 0 then aimPos = sc end

    local tc = Themes[Settings.Theme] or Color3.new(1, 1, 1)
    local fc = Settings.Aim.Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or tc
    UpdateFOV(aimPos, Settings.Aim.FOV, Settings.Aim.On, fc)

    local chV = Settings.Vis.Crosshair
    local chS = Settings.Vis.CrosshairSize
    CH.Dot.Visible = chV
    CH.H.Visible = chV
    CH.V.Visible = chV
    if chV then
        CH.Dot.Position = aimPos
        CH.Dot.Radius = 2
        CH.Dot.Color = tc
        CH.H.From = Vector2.new(aimPos.X - chS, aimPos.Y)
        CH.H.To = Vector2.new(aimPos.X + chS, aimPos.Y)
        CH.H.Color = tc
        CH.V.From = Vector2.new(aimPos.X, aimPos.Y - chS)
        CH.V.To = Vector2.new(aimPos.X, aimPos.Y + chS)
        CH.V.Color = tc
    end

    if Settings.Vis.Stretch43 then
        BaseFOV = Settings.Vis.ARStretch and 120 or OriginalFOV
        Camera.FieldOfView = Get43StretchedFOV()
    elseif Settings.Vis.ARStretch then
        Camera.FieldOfView = 120
    else
        Camera.FieldOfView = OriginalFOV
    end

    if Settings.Misc.Spinbot and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            spinAngle = (spinAngle + Settings.Misc.SpinSpeed) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        end
    end

    local Closest = nil
    local ClosestDist = Settings.Aim.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.Aim.Part)
                or plr.Character:FindFirstChild("HumanoidRootPart")
                or plr.Character:FindFirstChild("Head")

            if hum and hum.Health > 0 and part then
                local pos, onScr = Camera:WorldToViewportPoint(part.Position)
                local e = GetESP(plr)
                local tChk = not Settings.ESP.Team or plr.Team ~= LocalPlayer.Team

                local ewc = true
                if Settings.ESP.Wall then
                    local ok, res = pcall(function()
                        local p = RaycastParams.new()
                        p.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        p.FilterType = Enum.RaycastFilterType.Exclude
                        return workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, p)
                    end)
                    ewc = not ok or not res or res.Instance:IsDescendantOf(plr.Character)
                end

                local awc = true
                if Settings.Aim.Wall then
                    local ok, res = pcall(function()
                        local p = RaycastParams.new()
                        p.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        p.FilterType = Enum.RaycastFilterType.Exclude
                        return workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, p)
                    end)
                    awc = not ok or not res or res.Instance:IsDescendantOf(plr.Character)
                end

                UpdateChams(plr, Settings.Vis.Chams and tChk, tc)

                if Settings.ESP.On and tChk and ewc and onScr then
                    local dist = (Camera.CFrame.Position - part.Position).Magnitude
                    local f = 1000 / dist
                    local w = 2 * f
                    local h = 3.5 * f

                    e.Box.Visible = true
                    e.Box.Position = Vector2.new(pos.X - w / 2, pos.Y - h / 2)
                    e.Box.Size = Vector2.new(w, h)
                    e.Box.Color = Settings.ESP.Color

                    e.Name.Visible = true
                    e.Name.Text = plr.Name
                    e.Name.Position = Vector2.new(pos.X, pos.Y - h / 2 - 14)
                    e.Name.Color = Settings.ESP.Color

                    e.Line.Visible = true
                    e.Line.From = Vector2.new(sc.X, Camera.ViewportSize.Y)
                    e.Line.To = Vector2.new(pos.X, pos.Y)
                    e.Line.Color = Settings.ESP.Color

                    if Settings.Vis.HealthBar then
                        local hr = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local bx = pos.X - w / 2 - 5
                        e.HPBg.Visible = true
                        e.HPBg.From = Vector2.new(bx, pos.Y - h / 2)
                        e.HPBg.To = Vector2.new(bx, pos.Y + h / 2)
                        e.HPBar.Visible = true
                        e.HPBar.From = Vector2.new(bx, pos.Y + h / 2)
                        e.HPBar.To = Vector2.new(bx, pos.Y + h / 2 - (h * hr))
                        e.HPBar.Color = Color3.fromRGB(255 * (1 - hr), 255 * hr, 0)
                    else
                        e.HPBg.Visible = false
                        e.HPBar.Visible = false
                    end

                    if Settings.Vis.Distance then
                        e.Dist.Visible = true
                        e.Dist.Text = string.format("[%dm]", math.floor(dist))
                        e.Dist.Position = Vector2.new(pos.X, pos.Y + h / 2 + 10)
                        e.Dist.Color = Settings.ESP.Color
                    else
                        e.Dist.Visible = false
                    end
                else
                    e.Box.Visible = false
                    e.Name.Visible = false
                    e.Line.Visible = false
                    e.HPBg.Visible = false
                    e.HPBar.Visible = false
                    e.Dist.Visible = false
                end

                if Settings.Aim.On and onScr and (not Settings.Aim.Team or plr.Team ~= LocalPlayer.Team) and awc then
                    local dx = aimPos.X - pos.X
                    local dy = aimPos.Y - pos.Y
                    local d = math.sqrt(dx * dx + dy * dy)
                    if d < ClosestDist then
                        ClosestDist = d
                        Closest = part
                    end
                end
            else
                UpdateChams(plr, false, tc)
            end
        end
    end

    local shouldAim = Settings.Aim.On and (isMob or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if Closest and shouldAim then
        local sf = math.max(math.clamp(Settings.Aim.Smooth, 1, 100) / 100, 0.05)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, Closest.Position), sf)
    end
end)

-- ========================================== --
-- PREMIUM UI DESIGN & ANIMATIONS
-- ========================================== --

local MenuBlur = Instance.new("BlurEffect")
MenuBlur.Size = 0
MenuBlur.Parent = Lighting -- Исправлено

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 450)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(35, 35, 42)
MainStroke.Thickness = 1
table.insert(UIRefs.Strokes, MainStroke)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
table.insert(UIRefs.BgFrames, TopBar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 42, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AEROLA.WIN"
Title.TextColor3 = Themes.Purple
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar
UIRefs.Title = Title

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 18, 0, 18)
Logo.Position = UDim2.new(0, 14, 0.5, -9)
Logo.BackgroundColor3 = Themes.Purple
Logo.BorderSizePixel = 0
Logo.Parent = TopBar
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)

local LogoGlow = Instance.new("UIStroke", Logo)
LogoGlow.Color = Themes.Purple
LogoGlow.Thickness = 1.5
LogoGlow.Transparency = 0.5
table.insert(UIRefs.Indicators, Logo)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -22)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
ToggleBtn.Text = ""
ToggleBtn.Parent = Gui
ToggleBtn.Visible = false
ToggleBtn.AutoButtonColor = false
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Themes.Purple
tStroke.Thickness = 1.5
UIRefs.ToggleStroke = tStroke

local TBtnLogo = Instance.new("Frame")
TBtnLogo.Size = UDim2.new(0, 16, 0, 16)
TBtnLogo.Position = UDim2.new(0.5, -8, 0.5, -8)
TBtnLogo.BackgroundColor3 = Themes.Purple
TBtnLogo.BorderSizePixel = 0
TBtnLogo.Parent = ToggleBtn
Instance.new("UICorner", TBtnLogo).CornerRadius = UDim.new(1, 0)
table.insert(UIRefs.Indicators, TBtnLogo)

local dragging = false
local dragInput, dragStart, startPos

local function setupDrag(frame, handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
end

setupDrag(Main, TopBar)
setupDrag(ToggleBtn, ToggleBtn)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        if dragging == true and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            if ToggleBtn.Parent == Gui and math.abs(d.X) > 15 or math.abs(d.Y) > 15 then
               ToggleBtn.Position = UDim2.new(0, startPos.X.Offset + d.X, 0, startPos.Y.Offset + d.Y)
            elseif Main.Parent == Gui then
               Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end
end)

local isAnimating = false
local menuOpen = false

local function ToggleMenu()
    if isAnimating then return end
    isAnimating = true
    
    if not menuOpen then
        Main.Visible = true
        menuOpen = true
        TweenService:Create(MenuBlur, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 12}):Play()
        Main.Size = UDim2.new(0, 0, 0, 0)
        Main.BackgroundTransparency = 1
        local tween = TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 450)})
        tween:Play()
        task.spawn(function()
            task.wait(0.2)
            TweenService:Create(Main, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        end)
        tween.Completed:Wait()
    else
        menuOpen = false
        TweenService:Create(MenuBlur, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = 0}):Play()
        local tween = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        Main.Visible = false
    end
    isAnimating = false
end

ToggleBtn.MouseButton1Click:Connect(ToggleMenu)

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, -24, 0, 30)
Tabs.Position = UDim2.new(0, 12, 0, 46)
Tabs.BackgroundTransparency = 1
Tabs.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -90)
Content.Position = UDim2.new(0, 12, 0, 84)
Content.BackgroundTransparency = 1
Content.Parent = Main

local AimFrame = Instance.new("ScrollingFrame")
AimFrame.Size = UDim2.new(1, 0, 1, 0)
AimFrame.BackgroundTransparency = 1
AimFrame.BorderSizePixel = 0
AimFrame.ScrollBarThickness = 0
AimFrame.Visible = true
AimFrame.CanvasSize = UDim2.new(0, 0, 0, 255)
AimFrame.Parent = Content

local VisFrame = Instance.new("ScrollingFrame")
VisFrame.Size = UDim2.new(1, 0, 1, 0)
VisFrame.BackgroundTransparency = 1
VisFrame.BorderSizePixel = 0
VisFrame.ScrollBarThickness = 0
VisFrame.Visible = false
VisFrame.CanvasSize = UDim2.new(0, 0, 0, 460)
VisFrame.Parent = Content

local MiscFrame = Instance.new("ScrollingFrame")
MiscFrame.Size = UDim2.new(1, 0, 1, 0)
MiscFrame.BackgroundTransparency = 1
MiscFrame.BorderSizePixel = 0
MiscFrame.ScrollBarThickness = 0
MiscFrame.Visible = false
MiscFrame.CanvasSize = UDim2.new(0, 0, 0, 90)
MiscFrame.Parent = Content

local function MakeTab(name, frame, x, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(width, -4, 1, 0)
    b.Position = UDim2.new(x, 2, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    b.BackgroundTransparency = 1
    b.Text = name
    b.TextColor3 = Color3.fromRGB(150, 150, 160)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = Tabs
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    table.insert(UIRefs.ElemFrames, b)
    
    local tabInfo = { Btn = b, Frame = frame, IsActive = false }
    table.insert(UIRefs.TabButtons, tabInfo)
    
    b.MouseButton1Click:Connect(function()
        for _, t in pairs(UIRefs.TabButtons) do
            t.Frame.Visible = false
            t.Btn.BackgroundTransparency = 1
            t.IsActive = false
        end
        frame.Visible = true
        b.BackgroundTransparency = 0
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabInfo.IsActive = true
        ApplyTheme(Settings.Theme)
    end)
    return b
end

local Tab1 = MakeTab("AIMBOT", AimFrame, 0, 0.33)
MakeTab("VISUALS", VisFrame, 0.33, 0.33)
MakeTab("MISC", MiscFrame, 0.66, 0.34)
Tab1.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1.BackgroundTransparency = 0
UIRefs.TabButtons[1].IsActive = true

local function Toggle(parent, name, getter, setter, y)
    local Frm = Instance.new("Frame")
    Frm.Size = UDim2.new(1, -4, 0, 34)
    Frm.Position = UDim2.new(0, 2, 0, y)
    Frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frm.BorderSizePixel = 0
    Frm.Parent = parent
    Instance.new("UICorner", Frm).CornerRadius = UDim.new(0, 6)
    table.insert(UIRefs.ElemFrames, Frm)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -60, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frm
    table.insert(UIRefs.TextLabels, Lbl)

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 36, 0, 18)
    Switch.Position = UDim2.new(1, -48, 0.5, -9)
    Switch.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Switch.BorderSizePixel = 0
    Switch.Text = ""
    Switch.Parent = Frm
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = getter() and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Knob.BackgroundColor3 = Themes[Settings.Theme]
    Knob.BorderSizePixel = 0
    Knob.Parent = Switch
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
    table.insert(UIRefs.Indicators, Knob)

    local tabInfo = { Knob = Knob, Frm = Frm }
    table.insert(UIRefs.Toggles, tabInfo)

    Switch.MouseButton1Click:Connect(function() 
        local v = not getter(); setter(v); 
        TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
    end)
end

local function Slider(parent, name, min, max, getter, setter, y)
    local Frm = Instance.new("Frame")
    Frm.Size = UDim2.new(1, -4, 0, 40)
    Frm.Position = UDim2.new(0, 2, 0, y)
    Frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frm.BorderSizePixel = 0
    Frm.Parent = parent
    Instance.new("UICorner", Frm).CornerRadius = UDim.new(0, 6)
    table.insert(UIRefs.ElemFrames, Frm)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -50, 0, 16)
    Lbl.Position = UDim2.new(0, 12, 0, 4)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frm
    table.insert(UIRefs.TextLabels, Lbl)

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0, 40, 0, 16)
    Val.Position = UDim2.new(1, -48, 0, 4)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(math.floor(getter()))
    Val.TextColor3 = Themes[Settings.Theme]
    Val.Font = Enum.Font.GothamBold
    Val.TextSize = 11
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.Parent = Frm
    table.insert(UIRefs.Values, Val)

    local Bar = Instance.new("TextButton")
    Bar.Size = UDim2.new(1, -24, 0, 4)
    Bar.Position = UDim2.new(0, 12, 0, 28)
    Bar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Bar.BorderSizePixel = 0
    Bar.AutoButtonColor = false
    Bar.Text = ""
    Bar.Parent = Frm
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Themes[Settings.Theme]
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Grad = Instance.new("UIGradient", Fill)
    Grad.Color = ColorSequence.new({Color3.fromRGB(255,255,255), Themes[Settings.Theme]})
    Grad.Rotation = 90
    Fill.Gradient = Grad
    table.insert(UIRefs.Fills, Fill)

    local drag = false
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            setter(math.floor(min + (max - min) * rel))
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Val.Text = tostring(math.floor(getter()))
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            setter(math.floor(min + (max - min) * rel))
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Val.Text = tostring(math.floor(getter()))
        end
    end)
end

local function Cycle(parent, name, options, getter, setter, y)
    local Frm = Instance.new("Frame")
    Frm.Size = UDim2.new(1, -4, 0, 34)
    Frm.Position = UDim2.new(0, 2, 0, y)
    Frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frm.BorderSizePixel = 0
    Frm.Parent = parent
    Instance.new("UICorner", Frm).CornerRadius = UDim.new(0, 6)
    table.insert(UIRefs.ElemFrames, Frm)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -90, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frm
    table.insert(UIRefs.TextLabels, Lbl)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 80, 0, 22)
    Btn.Position = UDim2.new(1, -92, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Btn.BorderSizePixel = 0
    Btn.Text = getter()
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 10
    Btn.Parent = Frm
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
    table.insert(UIRefs.Indicators, Btn)

    Btn.MouseButton1Click:Connect(function()
        local cur = getter()
        local idx = table.find(options, cur) or 1
        idx = idx % #options + 1
        setter(options[idx])
        Btn.Text = options[idx]
        ApplyTheme(Settings.Theme)
    end)
end

Toggle(AimFrame, "Enable Aimbot", function() return Settings.Aim.On end, function(v) Settings.Aim.On = v end, 0)
Toggle(AimFrame, "Team Check", function() return Settings.Aim.Team end, function(v) Settings.Aim.Team = v end, 40)
Toggle(AimFrame, "Wall Check", function() return Settings.Aim.Wall end, function(v) Settings.Aim.Wall = v end, 80)
Toggle(AimFrame, "Rainbow FOV", function() return Settings.Aim.Rainbow end, function(v) Settings.Aim.Rainbow = v end, 120)
Slider(AimFrame, "FOV Radius", 10, 500, function() return Settings.Aim.FOV end, function(v) Settings.Aim.FOV = v end, 160)
Slider(AimFrame, "Smoothness", 1, 100, function() return Settings.Aim.Smooth end, function(v) Settings.Aim.Smooth = v end, 210)
Cycle(AimFrame, "Target Part", {"Head", "HumanoidRootPart", "Torso"}, function() return Settings.Aim.Part end, function(v) Settings.Aim.Part = v end, 260)

Toggle(VisFrame, "Enable ESP", function() return Settings.ESP.On end, function(v) Settings.ESP.On = v end, 0)
Toggle(VisFrame, "ESP Team Check", function() return Settings.ESP.Team end, function(v) Settings.ESP.Team = v end, 40)
Toggle(VisFrame, "ESP Wall Check", function() return Settings.ESP.Wall end, function(v) Settings.ESP.Wall = v end, 80)
Toggle(VisFrame, "Chams (Highlight)", function() return Settings.Vis.Chams end, function(v) Settings.Vis.Chams = v end, 120)
Toggle(VisFrame, "Health Bar", function() return Settings.Vis.HealthBar end, function(v) Settings.Vis.HealthBar = v end, 160) 
Toggle(VisFrame, "Distance", function() return Settings.Vis.Distance end, function(v) Settings.Vis.Distance = v end, 200)
Toggle(VisFrame, "Crosshair", function() return Settings.Vis.Crosshair end, function(v) Settings.Vis.Crosshair = v end, 240)
Slider(VisFrame, "Crosshair Size", 3, 30, function() return Settings.Vis.CrosshairSize end, function(v) Settings.Vis.CrosshairSize = v end, 280)
Toggle(VisFrame, "AR Stretch (Wide)", function() return Settings.Vis.ARStretch end, function(v) Settings.Vis.ARStretch = v; SetARStretch(v) end, 330)
Toggle(VisFrame, "4:3 Stretch (CS2)", function() return Settings.Vis.Stretch43 end, function(v) Settings.Vis.Stretch43 = v end, 370)
Toggle(VisFrame, "Night Mode", function() return Settings.Vis.NightMode end, function(v) Settings.Vis.NightMode = v; ApplyTheme(Settings.Theme) end, 410)
Cycle(VisFrame, "Theme", {"Purple", "Red", "Blue", "Green", "Orange"}, function() return Settings.Theme end, function(v) ApplyTheme(v) end, 450)

Toggle(MiscFrame, "Spinbot", function() return Settings.Misc.Spinbot end, function(v) Settings.Misc.Spinbot = v end, 0)
Slider(MiscFrame, "Spin Speed", 1, 100, function() return Settings.Misc.SpinSpeed end, function(v) Settings.Misc.SpinSpeed = v end, 40)

ApplyTheme("Purple")

-- ========================================== --
-- INJECT SCREEN (FATALITY / NEVERLOSE STYLE)
-- ========================================== --

local function ShowInjectScreen(onComplete)
    local InjectGui = Instance.new("ScreenGui")
    InjectGui.Name = "AerolaInject"
    InjectGui.Parent = GuiEnv
    InjectGui.IgnoreGuiInset = true

    local DarkBg = Instance.new("Frame")
    DarkBg.Size = UDim2.new(1, 0, 1, 0)
    DarkBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    DarkBg.BackgroundTransparency = 1
    DarkBg.Parent = InjectGui
    
    local InjBlur = Instance.new("BlurEffect")
    InjBlur.Size = 0
    InjBlur.Parent = Lighting -- Исправлено

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, 360, 0, 180)
    Bg.Position = UDim2.new(0.5, -180, 0.5, -90)
    Bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    Bg.BackgroundTransparency = 1
    Bg.BorderSizePixel = 0
    Bg.Parent = InjectGui
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", Bg)
    Stroke.Color = Themes.Purple
    Stroke.Thickness = 1
    Stroke.Transparency = 1

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 20)
    Title.Position = UDim2.new(0, 14, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = "aerola.win"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTransparency = 1
    Title.Parent = Bg

    local Console = Instance.new("TextLabel")
    Console.Size = UDim2.new(1, -28, 0, 100)
    Console.Position = UDim2.new(0, 14, 0, 44)
    Console.BackgroundTransparency = 1
    Console.Text = ""
    Console.RichText = true
    Console.TextColor3 = Color3.fromRGB(150, 150, 160)
    Console.Font = Enum.Font.Code
    Console.TextSize = 12
    Console.TextXAlignment = Enum.TextXAlignment.Left
    Console.TextYAlignment = Enum.TextYAlignment.Top
    Console.TextTransparency = 1
    Console.Parent = Bg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -28, 0, 3)
    BarBg.Position = UDim2.new(0, 14, 1, -18)
    BarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    BarBg.BorderSizePixel = 0
    BarBg.BackgroundTransparency = 1
    BarBg.Parent = Bg
    Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Themes.Purple
    BarFill.BorderSizePixel = 0
    BarFill.BackgroundTransparency = 1
    BarFill.Parent = BarBg
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
    
    local BarGrad = Instance.new("UIGradient", BarFill)
    BarGrad.Color = ColorSequence.new({Themes.Purple, Color3.fromRGB(255, 255, 255)})
    BarGrad.Rotation = 0

    task.spawn(function()
        TweenService:Create(InjBlur, TweenInfo.new(0.5), {Size = 24}):Play()
        TweenService:Create(DarkBg, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
        TweenService:Create(Bg, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.5), {Transparency = 0}):Play()
        TweenService:Create(Title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        TweenService:Create(Console, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        TweenService:Create(BarBg, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
        TweenService:Create(BarFill, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
        
        local messages = {
            "<font color='#8F5FFF'>[sys]</font> Initializing modules...",
            "<font color='#8F5FFF'>[sys]</font> Bypassing anti-cheat...",
            "<font color='#8F5FFF'>[sys]</font> Loading visuals...",
            "<font color='#8F5FFF'>[sys]</font> Hooking functions...",
            "<font color='#8F5FFF'>[ok]</font>  Build: 9.0.4",
            "<font color='#8F5FFF'>[ok]</font>  Success!"
        }

        local progress = 0
        for i, msg in ipairs(messages) do
            Console.Text = Console.Text .. msg .. "\n"
            progress = i / #messages
            TweenService:Create(BarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
            TweenService:Create(BarGrad, TweenInfo.new(0.2), {Offset = Vector2.new(1, 0)}):Play()
            task.wait(0.2)
        end
        
        task.wait(0.5)
        
        TweenService:Create(InjBlur, TweenInfo.new(0.5), {Size = 0}):Play()
        TweenService:Create(DarkBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        local fadeOut = TweenService:Create(Bg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        TweenService:Create(Stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
        TweenService:Create(Title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(Console, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(BarBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(BarFill, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        fadeOut:Play()
        fadeOut.Completed:Wait()
        
        InjectGui:Destroy()
        InjBlur:Destroy()
        onComplete()
    end)
end

ShowInjectScreen(function()
    ToggleBtn.Visible = true
    ToggleBtn.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(ToggleBtn, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.new(0, 44, 0, 44)}):Play()
end)
