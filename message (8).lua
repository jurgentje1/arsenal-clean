-- ============================================================
-- NoSkill Arsenal version 1.9 | by no vitamin d team
-- ============================================================

local CoreGui = game:GetService("StarterGui")
CoreGui:SetCore("SendNotification", {
  Title = "NoSkill Arsenal",
  Text = "Working For Mobile and PC Executor",
  Duration = 8,
})

game:GetService("StarterGui"):SetCore("SendNotification", {
  Title = "Maded By:",
  Text = "no vitamin d team",
  Duration = 8,
})

-- ============================================================
-- GLOBAL SERVICES & STATE
-- ============================================================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_SETTINGS = { Enabled = false, Boxes = false, Names = false, Tracers = false, TeamCheck = false, Color = Color3.fromRGB(255, 255, 255) }
local AIMBOT_SETTINGS = { Enabled = false, TeamCheck = true, AimPart = "Head", Smoothness = 0.5, FOV = 100, ShowFOV = false, FOVColor = Color3.fromRGB(255, 255, 255) }
local HITBOX_SETTINGS = { Enabled = false, Size = 21, Transparency = 6, TeamCheck = "FFA" }
local WALKSPEED_SETTINGS = { Enabled = false, Power = 16, Method = "Velocity" }
local GUN_SETTINGS = { InfiniteAmmo = false, NoSpread = false, NoRecoil = false, Original = { Spread = {}, Recoil = {} } }

-- ============================================================
-- FLY MODULE
-- ============================================================
local flySettings = { fly = false, flyspeed = 50 }
local flyBtn = { W = false, S = false, A = false, D = false, Moving = false }
local flying = false
local c, h, bv, bav

local startFly = function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") or flying then return end
    c = LocalPlayer.Character
    h = c.Humanoid
    h.PlatformStand = true
    bv = Instance.new("BodyVelocity")
    bav = Instance.new("BodyAngularVelocity")
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(10000,10000,10000)
    bv.P = 1000
    bav.AngularVelocity = Vector3.new(0,0,0)
    bav.MaxTorque = Vector3.new(10000,10000,10000)
    bav.P = 1000
    bv.Parent = c.Head
    bav.Parent = c.Head
    flying = true
    h.Died:Connect(function() flying = false end)
end

local endFly = function()
    if not LocalPlayer.Character or not flying then return end
    h.PlatformStand = false
    if bv then bv:Destroy() end
    if bav then bav:Destroy() end
    flying = false
end

UserInputService.InputBegan:Connect(function(input, GPE)
    if GPE then return end
    if input.KeyCode == Enum.KeyCode.W then flyBtn.W = true flyBtn.Moving = true
    elseif input.KeyCode == Enum.KeyCode.S then flyBtn.S = true flyBtn.Moving = true
    elseif input.KeyCode == Enum.KeyCode.A then flyBtn.A = true flyBtn.Moving = true
    elseif input.KeyCode == Enum.KeyCode.D then flyBtn.D = true flyBtn.Moving = true end
end)

UserInputService.InputEnded:Connect(function(input, GPE)
    if GPE then return end
    if input.KeyCode == Enum.KeyCode.W then flyBtn.W = false
    elseif input.KeyCode == Enum.KeyCode.S then flyBtn.S = false
    elseif input.KeyCode == Enum.KeyCode.A then flyBtn.A = false
    elseif input.KeyCode == Enum.KeyCode.D then flyBtn.D = false end
    flyBtn.Moving = flyBtn.W or flyBtn.S or flyBtn.A or flyBtn.D
end)

RunService.Heartbeat:Connect(function(step)
    if flying and c and c.PrimaryPart then
        local p_pos = c.PrimaryPart.Position
        local cf = workspace.CurrentCamera.CFrame
        local ax, ay, az = cf:ToEulerAnglesXYZ()
        c:SetPrimaryPartCFrame(CFrame.new(p_pos.x, p_pos.y, p_pos.z) * CFrame.Angles(ax, ay, az))
        if flyBtn.Moving then
            local t = Vector3.new()
            local speed = flySettings.flyspeed
            if flyBtn.W then t = t + (cf.LookVector * speed) end
            if flyBtn.S then t = t - (cf.LookVector * speed) end
            if flyBtn.A then t = t - (cf.RightVector * speed) end
            if flyBtn.D then t = t + (cf.RightVector * speed) end
            c:TranslateBy(t * step)
        end
    end
end)

-- ============================================================
-- HITBOX MODULE
-- ============================================================
local original_hitbox_props = {}
local function savedPart(player, part)
    if not original_hitbox_props[player] then original_hitbox_props[player] = {} end
    if not original_hitbox_props[player][part.Name] then
        original_hitbox_props[player][part.Name] = { CanCollide = part.CanCollide, Transparency = part.Transparency, Size = part.Size }
    end
end
local function restoredPart(player)
    if original_hitbox_props[player] then
        for partName, props in pairs(original_hitbox_props[player]) do
            local part = player.Character and player.Character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = props.CanCollide
                part.Transparency = props.Transparency
                part.Size = props.Size
            end
        end
    end
end
local function updateHitboxes()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local isEnemy = (HITBOX_SETTINGS.TeamCheck == "FFA" or HITBOX_SETTINGS.TeamCheck == "Everyone" or v.Team ~= LocalPlayer.Team)
            if isEnemy and HITBOX_SETTINGS.Enabled then
                for _, partName in ipairs({ "UpperTorso", "Head", "HumanoidRootPart" }) do
                    local part = v.Character:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        savedPart(v, part)
                        part.CanCollide = true
                        part.Transparency = HITBOX_SETTINGS.Transparency / 10
                        part.Size = Vector3.new(HITBOX_SETTINGS.Size, HITBOX_SETTINGS.Size, HITBOX_SETTINGS.Size)
                    end
                end
            else
                restoredPart(v)
            end
        end
    end
end
task.spawn(function()
    while true do
        if HITBOX_SETTINGS.Enabled then updateHitboxes() end
        task.wait(0.5)
    end
end)

-- ============================================================
-- ESP & AIMBOT MODULE (from scratch)
-- ============================================================
local TrackedPlayers = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

local function CreateESP(player)
    local esp = { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Tracer = Drawing.new("Line") }
    esp.Box.Thickness = 1; esp.Box.Filled = false; esp.Box.Transparency = 1
    esp.Name.Size = 18; esp.Name.Center = true; esp.Name.Outline = true
    esp.Tracer.Thickness = 1; esp.Tracer.Transparency = 1
    TrackedPlayers[player] = esp
end
local function RemoveESP(player)
    if TrackedPlayers[player] then
        for _, drw in pairs(TrackedPlayers[player]) do drw.Visible = false; drw:Remove() end
        TrackedPlayers[player] = nil
    end
end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end

local function GetClosestPlayerToCursor()
    local closestDist = AIMBOT_SETTINGS.FOV
    local closestPlayer = nil
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(AIMBOT_SETTINGS.AimPart) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if AIMBOT_SETTINGS.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local partPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character[AIMBOT_SETTINGS.AimPart].Position)
            if onScreen and partPos.Z > 0 then
                local dist = (Vector2.new(partPos.X, partPos.Y) - mousePos).Magnitude
                if dist < closestDist then closestDist = dist; closestPlayer = p end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = AIMBOT_SETTINGS.FOV
    FOVCircle.Visible = AIMBOT_SETTINGS.ShowFOV and AIMBOT_SETTINGS.Enabled
    FOVCircle.Color = AIMBOT_SETTINGS.FOVColor

    if AIMBOT_SETTINGS.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayerToCursor()
        if target and target.Character and target.Character:FindFirstChild(AIMBOT_SETTINGS.AimPart) then
            local targetPos = target.Character[AIMBOT_SETTINGS.AimPart].Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), AIMBOT_SETTINGS.Smoothness)
        end
    end

    for player, esp in pairs(TrackedPlayers) do
        local visible = false
        if ESP_SETTINGS.Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not (ESP_SETTINGS.TeamCheck and player.Team == LocalPlayer.Team) then
                local hrp = player.Character.HumanoidRootPart
                local vec, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and vec.Z > 0 then
                    visible = true
                    local top, _ = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                    local bottom, _ = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                    local bHeight = math.abs(top.Y - bottom.Y)
                    local bWidth = bHeight * 0.6
                    if ESP_SETTINGS.Boxes then
                        esp.Box.Size = Vector2.new(bWidth, bHeight)
                        esp.Box.Position = Vector2.new(vec.X - bWidth / 2, top.Y)
                        esp.Box.Color = ESP_SETTINGS.Color; esp.Box.Visible = true
                    else esp.Box.Visible = false end
                    if ESP_SETTINGS.Names then
                        esp.Name.Text = player.Name .. " [" .. math.floor((Camera.CFrame.Position - hrp.Position).Magnitude) .. "s]"
                        esp.Name.Position = Vector2.new(vec.X, top.Y - 20)
                        esp.Name.Color = ESP_SETTINGS.Color; esp.Name.Visible = true
                    else esp.Name.Visible = false end
                    if ESP_SETTINGS.Tracers then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(vec.X, vec.Y)
                        esp.Tracer.Color = ESP_SETTINGS.Color; esp.Tracer.Visible = true
                    else esp.Tracer.Visible = false end
                end
            end
        end
        if not visible then esp.Box.Visible = false; esp.Name.Visible = false; esp.Tracer.Visible = false end
    end
end)

-- ============================================================
-- TRIGGERBOT & MOVEMENTS
-- ============================================================
getgenv().triggerb = false
RunService.RenderStepped:Connect(function()
    if getgenv().triggerb then
        local target = LocalPlayer:GetMouse().Target
        if target and target.Parent:FindFirstChild("Humanoid") then
            local p_target = Players:GetPlayerFromCharacter(target.Parent)
            if p_target and p_target.Team ~= LocalPlayer.Team then
                mouse1press(); task.wait(0.05); mouse1release()
            end
        end
    end
end)

RunService.Stepped:Connect(function(dt)
    if WALKSPEED_SETTINGS.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character.Humanoid
        hrp.Velocity = Vector3.new(hum.MoveDirection.X * WALKSPEED_SETTINGS.Power, hrp.Velocity.Y, hum.MoveDirection.Z * WALKSPEED_SETTINGS.Power)
    end
end)

-- ============================================================
-- RAYFIELD UI SETUP
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "NoSkill | Arsenal | v1.9",
   Icon = 0,
   LoadingTitle = "NoSkill Arsenal",
   LoadingSubtitle = "by no vitamin d team",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({ Name = "Enable Aimbot (Hold RMB)", Flag = "AimbotToggle", Callback = function(v) AIMBOT_SETTINGS.Enabled = v end })
CombatTab:CreateSlider({ Name = "Smoothness", Range = {1, 10}, CurrentValue = 5, Callback = function(v) AIMBOT_SETTINGS.Smoothness = v/10 end })
CombatTab:CreateSlider({ Name = "FOV", Range = {10, 500}, CurrentValue = 100, Callback = function(v) AIMBOT_SETTINGS.FOV = v end })
CombatTab:CreateToggle({ Name = "Show FOV", Callback = function(v) AIMBOT_SETTINGS.ShowFOV = v end })
CombatTab:CreateSection("Triggerbot")
CombatTab:CreateToggle({ Name = "Enable Triggerbot", Callback = function(v) getgenv().triggerb = v end })
CombatTab:CreateSection("Hitbox")
CombatTab:CreateToggle({ Name = "Enable Hitbox", Callback = function(v) HITBOX_SETTINGS.Enabled = v end })
CombatTab:CreateSlider({ Name = "Size", Range = {1, 25}, CurrentValue = 21, Callback = function(v) HITBOX_SETTINGS.Size = v end })

local VisualsTab = Window:CreateTab("Visuals")
VisualsTab:CreateToggle({ Name = "Enable ESP", Callback = function(v) ESP_SETTINGS.Enabled = v end })
VisualsTab:CreateToggle({ Name = "Boxes", Callback = function(v) ESP_SETTINGS.Boxes = v end })
VisualsTab:CreateToggle({ Name = "Names", Callback = function(v) ESP_SETTINGS.Names = v end })
VisualsTab:CreateToggle({ Name = "Tracers", Callback = function(v) ESP_SETTINGS.Tracers = v end })
VisualsTab:CreateToggle({ Name = "Full Bright", Callback = function(v)
    game:GetService("Lighting").Ambient = v and Color3.new(1,1,1) or Color3.new(0.5,0.5,0.5)
end })

local WeaponTab = Window:CreateTab("Weaponry")
WeaponTab:CreateToggle({ Name = "Infinite Ammo", Callback = function(v)
    getgenv().InfAmmo = v
    task.spawn(function()
        while getgenv().InfAmmo do
            pcall(function() LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 99 end)
            task.wait()
        end
    end)
end })
WeaponTab:CreateToggle({ Name = "No Spread", Callback = function(v)
    for _, w in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do if w.Name == "MaxSpread" or w.Name == "Spread" then w.Value = v and 0 or 1 end end
end })

local MoveTab = Window:CreateTab("Movement")
MoveTab:CreateToggle({ Name = "Fly", Callback = function(v) if v then startFly() else endFly() end end })
MoveTab:CreateSlider({ Name = "Fly Speed", Range = {10, 500}, CurrentValue = 50, Callback = function(v) flySettings.flyspeed = v end })
MoveTab:CreateToggle({ Name = "Custom Speed", Callback = function(v) WALKSPEED_SETTINGS.Enabled = v end })
MoveTab:CreateSlider({ Name = "Speed Power", Range = {16, 300}, CurrentValue = 16, Callback = function(v) WALKSPEED_SETTINGS.Power = v end })

local UtilTab = Window:CreateTab("Utility")
UtilTab:CreateButton({ Name = "Server Hop", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end })
UtilTab:CreateButton({ Name = "Rejoin", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end })
UtilTab:CreateSlider({ Name = "TimeScale", Range = {1, 10}, CurrentValue = 1, Callback = function(v) game:GetService("ReplicatedStorage").wkspc.TimeScale.Value = v end })
