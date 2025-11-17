-- l.lua parte 1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-----------------------------------------------------------
-- FLY FUNCTION
-----------------------------------------------------------
getgenv().Fly = function()
    if not getgenv().FlyEnabled then return end

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000,400000,400000)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Parent = HumanoidRootPart

    local function updateFly()
        if not getgenv().FlyEnabled then
            bodyVelocity:Destroy()
            return
        end

        local camCFrame = workspace.CurrentCamera.CFrame
        local moveVector = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector -= Vector3.new(0,1,0) end

        bodyVelocity.Velocity = moveVector.Unit * getgenv().FlySpeed
    end

    RunService.RenderStepped:Connect(function()
        if getgenv().FlyEnabled then updateFly() end
    end)
end

-----------------------------------------------------------
-- SPEED FUNCTION
-----------------------------------------------------------
getgenv().Speed = function()
    if not getgenv().SpeedActive then return end
    Humanoid.WalkSpeed = getgenv().SpeedValue
end

RunService.RenderStepped:Connect(function()
    if getgenv().SpeedActive then
        pcall(getgenv().Speed)
    else
        if Humanoid.WalkSpeed ~= 16 then Humanoid.WalkSpeed = 16 end
    end
end)

-----------------------------------------------------------
-- NOCLIP FUNCTION
-----------------------------------------------------------
getgenv().Noclip = function()
    if getgenv().NoclipEnabled then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

RunService.Stepped:Connect(function()
    pcall(getgenv().Noclip)
end)

-----------------------------------------------------------
-- AUTOSPRINT FUNCTION
-----------------------------------------------------------
getgenv().AutoSprintFunc = function()
    if not getgenv().AutoSprint then return end
    local Remote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")
    local args = {"Sprint", Enum.UserInputState.Begin, [4] = "Start"}
    pcall(function() Remote:InvokeServer(unpack(args)) end)
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoSprintFunc)
end)


-- l.lua parte 2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-----------------------------------------------------------
-- AUTO PARRY
-----------------------------------------------------------
getgenv().AutoParryFunc = function()
    if not getgenv().AutoParryEnabled then return end

    local parryRemote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("Parry")
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            local dist = (HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist <= getgenv().ParryRange then
                pcall(function()
                    parryRemote:FireServer()
                    task.wait(getgenv().ParryCooldown)
                end)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoParryFunc)
end)

-----------------------------------------------------------
-- AUTO START DUNGEON
-----------------------------------------------------------
getgenv().AutoStartDungeonFunc = function()
    if not getgenv().AutoStartDungeon then return end

    local gui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("AffixNumSelection")
    local readyRemote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ReadyUp")
    if gui.Enabled then
        pcall(function()
            readyRemote:FireServer({})
        end)
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoStartDungeonFunc)
end)

-----------------------------------------------------------
-- AUTO CONTINUE DUNGEON
-----------------------------------------------------------
getgenv().AutoContinueDungeonFunc = function()
    if not getgenv().AutoContinueDungeon then return end

    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local layerComplete = gui:FindFirstChild("LayerComplete")
    if layerComplete and layerComplete.Enabled then
        local success = pcall(function()
            LocalPlayer:WaitForChild("Remotes"):WaitForChild("DungeonCompleted"):InvokeServer("Continue")
        end)
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoContinueDungeonFunc)
end)

-----------------------------------------------------------
-- AUTO ATTACK
-----------------------------------------------------------
getgenv().AutoAttackFunc = function()
    if not getgenv().AutoAttack then return end
    local skill1 = getgenv().Skill1 or ""
    local skill2 = getgenv().Skill2 or ""
    local attackRemote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")

    -- Ejemplo simple: disparar skill1 si existe
    if skill1 ~= "" then
        pcall(function()
            attackRemote:InvokeServer({skill1})
        end)
    end

    if skill2 ~= "" then
        pcall(function()
            attackRemote:InvokeServer({skill2})
        end)
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoAttackFunc)
end)

-----------------------------------------------------------
-- AUTO POTENTIAL
-----------------------------------------------------------
getgenv().AutoPotentialFunc = function()
    if not getgenv().AutoPotentialEnabled then return end

    local potentials = workspace:FindFirstChild("Potentials")
    if not potentials then return end

    for _, obj in pairs(potentials:GetChildren()) do
        if obj:IsA("Model") then
            local dist = (HumanoidRootPart.Position - obj:GetModelCFrame().Position).Magnitude
            if dist <= 10 then -- rango ejemplo
                pcall(function()
                    -- Aquí puedes invocar el remote correspondiente al potential
                    -- Ejemplo:
                    -- LocalPlayer:WaitForChild("Remotes"):WaitForChild("ClaimPotential"):InvokeServer(obj)
                end)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoPotentialFunc)
end)


-- l.lua parte 3

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-----------------------------------------------------------
-- SAFE PLACE / HEALING SKILLS
-----------------------------------------------------------
getgenv().SafePlaceFunc = function()
    if not getgenv().SafePlaceToggle then return end

    local healthThreshold = getgenv().HealtThresholdd or 30
    local regenTarget = getgenv().healthRegenTargett or 50
    local useSkill = getgenv().HealtSkill or false
    local skillName = getgenv().SkillInputValue or "Lesser Heal"

    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return end

    if Humanoid.Health <= healthThreshold then
        if useSkill then
            -- Llamar al remote para curar usando skillName
            local healRemote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")
            pcall(function()
                healRemote:InvokeServer({skillName})
            end)
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().SafePlaceFunc)
end)

-----------------------------------------------------------
-- ESP ITEMS
-----------------------------------------------------------
getgenv().ItemESPFunc = function()
    if not getgenv().ItemESPSettings.Enabled then return end

    local items = workspace:FindFirstChild("OtherChars") or {}
    for _, item in pairs(items:GetChildren()) do
        if item:IsA("Model") then
            -- Lógica para Box, Name, Distance
            -- Se puede usar un BillboardGui o Drawing API
            -- Ejemplo simplificado:
            if getgenv().ItemESPSettings.ShowDistance then
                local dist = (HumanoidRootPart.Position - (item.PrimaryPart and item.PrimaryPart.Position or Vector3.zero)).Magnitude
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().ItemESPFunc)
end)

-----------------------------------------------------------
-- NPC ESP
-----------------------------------------------------------
getgenv().NPCESPFunc = function()
    if not getgenv().NPCESPSettings.Enabled then return end

    for _, npc in pairs(workspace:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            -- Lógica ESP NPC: Box, Health, Tracer, Distance
            -- Simplificado:
            if getgenv().NPCESPSettings.ShowDistance then
                local dist = (HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().NPCESPFunc)
end)

-----------------------------------------------------------
-- BOSS ROOM ESP
-----------------------------------------------------------
getgenv().BossRoomESPFunc = function()
    if not getgenv().BossRoomESP then return end

    local bossRoom = workspace:FindFirstChild("MAP") and workspace.MAP:FindFirstChild("Room999")
    if bossRoom then
        local bossDoor = bossRoom:FindFirstChild("BossDoor")
        if bossDoor then
            -- Agregar ESP visual, ejemplo con un BillboardGui o Drawing
            if not bossDoor:FindFirstChild("SixSeven") then
                local esp = Instance.new("BillboardGui")
                esp.Name = "SixSeven"
                esp.Size = UDim2.new(0,50,0,50)
                esp.Adornee = bossDoor
                esp.Parent = bossDoor
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(getgenv().BossRoomESPFunc)
end)


-- l.lua parte 4

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-----------------------------------------------------------
-- POTENTIAL TELEPORT
-----------------------------------------------------------
getgenv().PotentialTeleportFunc = function()
    local potentials = workspace:FindFirstChild("Potentials")
    if not potentials then return end

    local closestPart = nil
    local shortestDistance = math.huge

    for _, part in pairs(potentials:GetChildren()) do
        if part:IsA("BasePart") and part.Name:lower():match("^room") then
            local distance = (HumanoidRootPart.Position - part.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPart = part
            end
        end
    end

    if closestPart then
        HumanoidRootPart.CFrame = closestPart.CFrame + Vector3.new(0,5,0)
    end
end

-----------------------------------------------------------
-- BOSS ROOM TELEPORT
-----------------------------------------------------------
getgenv().BossRoomTeleportFunc = function()
    local bossDoor = workspace:FindFirstChild("MAP") 
        and workspace.MAP:FindFirstChild("Room999")
        and workspace.MAP.Room999:FindFirstChild("BossDoor")

    if bossDoor and bossDoor:IsA("BasePart") then
        HumanoidRootPart.CFrame = bossDoor.CFrame + Vector3.new(0,5,0)
    end
end

-----------------------------------------------------------
-- CLOSEST ITEM / OTHERCHARS TELEPORT
-----------------------------------------------------------
getgenv().ClosestItemTeleportFunc = function()
    local otherChars = workspace:FindFirstChild("OtherChars")
    if not otherChars then return end

    local closestModel = nil
    local shortestDistance = math.huge

    for _, model in pairs(otherChars:GetChildren()) do
        if model:IsA("Model") then
            local targetPos
            if model.PrimaryPart then
                targetPos = model.PrimaryPart.Position
            else
                local parts = model:GetDescendants()
                local sum, count = Vector3.zero, 0
                for _, p in pairs(parts) do
                    if p:IsA("BasePart") then
                        sum += p.Position
                        count += 1
                    end
                end
                if count > 0 then
                    targetPos = sum / count
                end
            end

            if targetPos then
                local distance = (HumanoidRootPart.Position - targetPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestModel = model
                end
            end
        end
    end

    if closestModel then
        local pos
        if closestModel.PrimaryPart then
            pos = closestModel.PrimaryPart.CFrame
        else
            local firstPart = closestModel:FindFirstChildWhichIsA("BasePart")
            if firstPart then
                pos = firstPart.CFrame
            end
        end
        if pos then
            HumanoidRootPart.CFrame = pos + Vector3.new(0,5,0)
        end
    end
end



-- l.lua parte 5

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-----------------------------------------------------------
-- FLY FUNCTION
-----------------------------------------------------------
getgenv().FlyFunc = function()
    if not getgenv().FlyEnabled then return end

    local flySpeed = getgenv().FlySpeed or 20
    local cam = workspace.CurrentCamera
    local moveDir = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end

    if moveDir.Magnitude > 0 then
        HumanoidRootPart.CFrame += moveDir.Unit * flySpeed * RunService.RenderStepped:Wait()
    end
end

-----------------------------------------------------------
-- SPEED FUNCTION
-----------------------------------------------------------
getgenv().SpeedFunc = function()
    if not getgenv().SpeedActive then return end
    local speed = getgenv().SpeedValue or 50
    Humanoid.WalkSpeed = speed
else
    Humanoid.WalkSpeed = 16 -- default Roblox WalkSpeed
end
end

-----------------------------------------------------------
-- NOCLIP FUNCTION
-----------------------------------------------------------
getgenv().NoclipFunc = function()
    if not getgenv().NoclipEnabled then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        return
    end

    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-----------------------------------------------------------
-- CONNECT FUNCTIONS
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    pcall(getgenv().FlyFunc)
    pcall(getgenv().SpeedFunc)
    pcall(getgenv().NoclipFunc)
end)


-- l.lua parte 6

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-----------------------------------------------------------
-- AUTO ATTACK
-----------------------------------------------------------
getgenv().AutoAttackFunc = function()
    if not getgenv().AutoAttack then return end

    local skill1 = getgenv().Skill1 or ""
    local skill2 = getgenv().Skill2 or ""

    local targets = {}
    -- buscar enemigos en rango
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            local distance = (HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            if distance <= (getgenv().InstantRange or 10) then
                table.insert(targets, npc)
            end
        end
    end

    -- usar remotes para atacar
    for _, target in ipairs(targets) do
        local remote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")
        pcall(function()
            if skill1 ~= "" then
                remote:InvokeServer({skill1, target})
            end
            if skill2 ~= "" then
                remote:InvokeServer({skill2, target})
            end
        end)
    end
end

-----------------------------------------------------------
-- AUTO PARRY
-----------------------------------------------------------
getgenv().AutoParryFunc = function()
    if not getgenv().AutoParryEnabled then return end

    local parryRange = getgenv().ParryRange or 30
    local parryCooldown = getgenv().ParryCooldown or 0.5
    local parryCritDelay = getgenv().ParryCritDelay or 0.2
    local lastParry = getgenv().LastParry or 0
    local currentTime = tick()

    if currentTime - lastParry < parryCooldown then return end

    -- buscar enemigos cercanos
    local enemies = {}
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            local distance = (HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            if distance <= parryRange then
                table.insert(enemies, npc)
            end
        end
    end

    -- hacer parry
    for _, enemy in ipairs(enemies) do
        local parryRemote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")
        pcall(function()
            parryRemote:InvokeServer({"Parry", enemy})
            task.wait(parryCritDelay)
        end)
    end

    getgenv().LastParry = tick()
end

-----------------------------------------------------------
-- CONNECT AUTO FUNCTIONS
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    pcall(getgenv().AutoAttackFunc)
    pcall(getgenv().AutoParryFunc)
end)


-- l.lua parte 7

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-----------------------------------------------------------
-- KEYBIND HANDLER
-----------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode

    -- Fly toggle key
    if tostring(key) == tostring(getgenv().FlyKey) then
        getgenv().FlyEnabled = not getgenv().FlyEnabled
    end

    -- Speed toggle key
    if tostring(key) == tostring(getgenv().SpeedKey) then
        getgenv().SpeedActive = not getgenv().SpeedActive
    end

    -- Noclip toggle key
    if tostring(key) == tostring(getgenv().NoclipKey) then
        getgenv().NoclipEnabled = not getgenv().NoclipEnabled
    end
end)

-----------------------------------------------------------
-- ESP HANDLER
-----------------------------------------------------------
getgenv().ESPUpdateFunc = function()
    -- Players ESP
    if getgenv().ESPSettings.Enabled then
        -- implementar ESP update de players
        -- placeholder: pcall seguro
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        -- actualizar visual ESP
                    end
                end
            end
        end)
    end

    -- NPC ESP
    if getgenv().NPCESPSettings.Enabled then
        pcall(function()
            for _, npc in pairs(workspace:GetChildren()) do
                if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                    -- actualizar NPC ESP
                end
            end
        end)
    end

    -- Items ESP
    if getgenv().ItemESPSettings.Enabled and ITEMesp then
        pcall(function()
            ITEMesp.SetEnabled(getgenv().ItemESPSettings.Enabled)
            ITEMesp.SetBoxEnabled(getgenv().ItemESPSettings.ShowBox)
            ITEMesp.SetNameEnabled(getgenv().ItemESPSettings.ShowName)
            ITEMesp.SetDistanceEnabled(getgenv().ItemESPSettings.ShowDistance)
        end)
    end
end

-----------------------------------------------------------
-- CONNECT ESP & GENERAL UPDATES
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    pcall(getgenv().ESPUpdateFunc)
    -- otras funciones ya conectadas en partes previas (Fly, Speed, Noclip, AutoAttack, AutoParry)
end)
