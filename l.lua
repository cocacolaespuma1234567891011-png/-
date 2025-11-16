
-----------------------------------------------------------
-- ⭐ FIX CRÍTICO DE LINORIA ⭐
-----------------------------------------------------------
task.wait(1)


-- === CORE SCRIPT SETUP ===
local AutoSelectArcaneActive = false
local SelectedArcane = "Holy" -- valor por defecto del dropdown
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- update character on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- NPC folder setup
local npcFolder = Workspace:FindFirstChild("NPCs")
if not npcFolder then
    npcFolder = Instance.new("Folder")
    npcFolder.Name = "NPCs"
    npcFolder.Parent = Workspace
end

-- ==== NPC Scanner ====
local currentNPC = nil
local lastUpdate = 0
local UPDATE_RATE = 1/60

local function getNearestNPC(origin)
    local closest = nil
    local shortest = math.huge

    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local npcHRP = npc:FindFirstChild("HumanoidRootPart")
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if npcHRP and hum and hum.Health > 0 then
                local dist = (npcHRP.Position - origin).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = npc
                end
            end
        end
    end

    return closest
end

-- ============================================
-- STATIC TELEPORT (no physics issues)
-- ============================================
local function staticTeleport(targetCF)
    if not hrp or not character then return end

    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero

    pcall(function()
        character:SetPrimaryPartCFrame(targetCF)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = false
        end
    end)
end

-- ==================================================
-- TELEPORT TO NPC LOGIC (Behind / Above / Below)
-- ==================================================
local function updatePosition()
    if not Toggles.TeleportToggle.Value then return end
    if not hrp then return end

    if not currentNPC or not currentNPC.Parent then
        currentNPC = getNearestNPC(hrp.Position)
        return
    end

    local now = time()
    if now - lastUpdate < UPDATE_RATE then return end
    lastUpdate = now

    local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
    if not npcHRP then return end

    local npcCF = npcHRP.CFrame
    local distance = Options.DistanceBehind.Value

    local targetCF

    if teleportMethod == "Behind" then
        local pos = npcCF.Position - npcCF.LookVector * distance
        targetCF = CFrame.lookAt(pos, npcCF.Position, Vector3.new(0,1,0))

    elseif teleportMethod == "Above" then
        local pos = npcCF.Position + Vector3.new(0, distance, 0)
        targetCF = CFrame.lookAt(pos, npcCF.Position, Vector3.new(0,1,0))

    elseif teleportMethod == "Below" then
        local pos = npcCF.Position - Vector3.new(0, distance, 0)
        targetCF = CFrame.lookAt(pos, npcCF.Position, Vector3.new(0,1,0))

    else
        local pos = npcCF.Position - npcCF.LookVector * distance
        targetCF = CFrame.lookAt(pos, npcCF.Position, Vector3.new(0,1,0))
    end

    staticTeleport(targetCF)
end

RunService.RenderStepped:Connect(updatePosition)

-- Auto-switch NPC on death
task.spawn(function()
    while true do
        task.wait(0.3)

        if Toggles.TeleportToggle.Value then
            if not currentNPC or not currentNPC.Parent then
                currentNPC = getNearestNPC(hrp.Position)
            else
                local hum = currentNPC:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    local lastPos = currentNPC:FindFirstChild("HumanoidRootPart") and currentNPC.HumanoidRootPart.Position or hrp.Position
                    currentNPC = getNearestNPC(lastPos)
                    if currentNPC then
                        local cf = currentNPC:FindFirstChild("HumanoidRootPart").CFrame
                        TweenService:Create(hrp, TweenInfo.new(0.25), {CFrame = cf}):Play()
                    end
                end
            end
        end
    end
end)



-- ============================
-- AUTO ATTACK (M1)
-- ============================
task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.AutoAttack.Value then
            local remotes = player:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestAction") then
                pcall(function()
                    remotes.RequestAction:InvokeServer("Weapon", Enum.UserInputState.Begin)
                end)
            end
        end
    end
end)

-- ============================
-- ANTI KILLBRICKS
-- ============================
local MAP = Workspace:FindFirstChild("MAP")
if not MAP then
    MAP = Instance.new("Folder", Workspace)
    MAP.Name = "MAP"
end

local removedTouch = {}
local cleanerThread = nil

local function removeTouchFrom(obj)
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TouchTransmitter") or d.Name == "TouchInterest" then
            local p = d.Parent
            if p and p:IsA("BasePart") then
                removedTouch[p] = true
            end
            pcall(function() d:Destroy() end)
        end
    end
end

local function restoreTouch()
    for part,_ in pairs(removedTouch) do
        if part and part.Parent then
            local ti = Instance.new("TouchTransmitter")
            ti.Parent = part
        end
    end
    removedTouch = {}
end

local function startCleaner()
    if cleanerThread then return end
    cleanerThread = task.spawn(function()
        while Toggles.AntiKillBricks.Value do
            removeTouchFrom(MAP)
            task.wait(3)
        end
    end)

    MAP.DescendantAdded:Connect(function(obj)
        if Toggles.AntiKillBricks.Value then
            if obj:IsA("TouchTransmitter") or obj.Name == "TouchInterest" then
                local p = obj.Parent
                if p and p:IsA("BasePart") then
                    removedTouch[p] = true
                end
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AntiKillBricks.Value then
            startCleaner()
            removeTouchFrom(MAP)
        else
            cleanerThread = nil
            restoreTouch()
        end
    end
end)

-- =========================================================
-- SAFEPLACE SYSTEM (BASE DEFINITIONS)
-- =========================================================

local SAFE_PLATFORM_NAME = "__SAFEPLACE_PLATFORM__"
local safeActive = false
local safeThread = nil
local originalPosition = nil
local wasTeleportToggleOn = false

local boss_keywords = {
    "larimar",
    "rogue stonewatcher",
    "humanoidboss"
}

local room998_path = "MAP.Room998"
local room999_path = "MAP.Room999"
local room1_path   = "MAP.Room1"

local function getOption(opt)
    return Options[opt] and Options[opt].Value
end

local function getToggle(t)
    return Toggles[t] and Toggles[t].Value
end

local function setToggle(t,val)
    if Toggles[t] then
        local ok = pcall(function()
            Toggles[t]:SetValue(val)
        end)
        if not ok then
            Toggles[t].Value = val
        end
    end
end

-- Model path finder
local function findModel(path)
    local comp = {}
    for p in string.gmatch(path, "[^%.]+") do table.insert(comp,p) end
    local cur = Workspace
    for _,part in ipairs(comp) do
        cur = cur:FindFirstChild(part)
        if not cur then return nil end
    end
    return cur
end

-- Get CFrame from model
local function getModelCF(m)
    if not m then return nil end
    if m.PrimaryPart then
        return m.PrimaryPart.CFrame
    end
    local hr = m:FindFirstChild("HumanoidRootPart")
    if hr then return hr.CFrame end
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then
            return d.CFrame
        end
    end
    return nil
end

-- Detect bosses
local function detectBosses()
    local npcs = Workspace:FindFirstChild("NPCs")
    if not npcs then return false end
    for _,obj in ipairs(npcs:GetChildren()) do
        local n = obj.Name:lower()
        for _,kw in ipairs(boss_keywords) do
            if string.find(n, kw, 1, true) then
                return true
            end
        end
    end
    return false
end

-- Choose safeplace destination
local function chooseSafeDest()
    if detectBosses() then
        local r998 = findModel(room998_path)
        if r998 then
            local cf = getModelCF(r998)
            if cf then return cf.Position end
        end
    end

    local r999 = findModel(room999_path)
    if r999 then
        local cf = getModelCF(r999)
        if cf then return cf.Position end
    end

    local r1 = findModel(room1_path)
    if r1 then
        local cf = getModelCF(r1)
        if cf then return cf.Position end
    end

    return nil
end

-- Create safe platform
local function createPlatform()
    local e = Workspace:FindFirstChild(SAFE_PLATFORM_NAME)
    if e then return e end

    local p = Instance.new("Part")
    p.Name = SAFE_PLATFORM_NAME
    p.Size = Vector3.new(4,1,4)
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 0.5
    p.Material = Enum.Material.SmoothPlastic
    p.Parent = Workspace

    p.CFrame = CFrame.new(hrp.Position - Vector3.new(0,2.2,0))
    return p
end

local function removePlatform()
    local p = Workspace:FindFirstChild(SAFE_PLATFORM_NAME)
    if p then p:Destroy() end
end


-- =========================================================
-- SAFEPLACE — TELEPORT LOOP
-- =========================================================

-- SAFEPLACE — TELEPORT LOOP
local function startSafeLoop()
    if safeActive then return end
    safeActive = true

    originalPosition = hrp.CFrame

    wasTeleportToggleOn = getToggle("TeleportToggle")
    if wasTeleportToggleOn then
        setToggle("TeleportToggle", false)
    end

    createPlatform()

    safeThread = task.spawn(function()
        while safeActive do
            task.wait(0.10)

            -- ❗ EVITAR SAFEPLACE SI ESTOY UTILIZANDO CAMPFIRE
            if usingCampfire then
                continue
            end

            local dest = chooseSafeDest()
            if dest then
                pcall(function()
                    hrp.CFrame = CFrame.new(dest + Vector3.new(0,2,0))
                end)
            end
        end
    end)
end


---------------------------------------------------------------------
-- HEAL SKILL AUTOCAST WHILE IN SAFEPLACE
-- Repite cada 1 segundo mientras safeActive y toggle HealtSkill esté ON
---------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1) -- intervalo; ajustalo si querés menos/más spam

        if safeActive then
            -- Asegurarnos de que el toggle y el input ya existen
            local okToggle = Toggles and Toggles.HealtSkill and Toggles.HealtSkill.Value
            local skillName = (Options and Options.SkillInput and Options.SkillInput.Value) or "Lesser Heal"

            if okToggle then
                -- encontrar el remote de habilidades de forma segura
                local remotes = player:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("RequestAction") then
                    pcall(function()
                        remotes.RequestAction:InvokeServer(skillName, Enum.UserInputState.Begin)
                    end)
                end
            end
        end
    end
end)

-- =========================================================
-- SAFEPLACE — STOP LOOP + RESTORE POSITION
-- =========================================================

local function stopSafeLoop()
    if not safeActive then return end
    safeActive = false

    -- Quitar plataforma
    removePlatform()

    -- Restaurar Toggle de Teleport si estaba activa antes
    if wasTeleportToggleOn then
        setToggle("TeleportToggle", true)
    end

    -- Restaurar posición original
    if originalPosition then
        pcall(function()
            hrp.CFrame = originalPosition
        end)
    end

    originalPosition = nil
end

-- =========================================================
-- SAFEPLACE — HEALTH MONITOR (NO GOTO)
-- =========================================================

local function ensureHumanoidMonitor()
    task.spawn(function()
        while true do
            task.wait(0.15)

            if not character then continue end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum then continue end
            if hum.MaxHealth <= 0 then continue end

            local percent = (hum.Health / hum.MaxHealth) * 100
            local threshold = getOption("HealtThresholdd") or 80
            local regenTarget = getOption("healthRegenTargett") or 100
            local safeToggle = getToggle("SafePlaceToggle")

            -- Activar SafePlace
            if safeToggle and percent <= threshold then
                if not safeActive then
                    startSafeLoop()
                end
            end

            -- Desactivar SafePlace cuando regenere la vida
            if safeActive and percent >= regenTarget then
                stopSafeLoop()
            end
        end
    end)
end

ensureHumanoidMonitor()

-- ============================================================
-- ROOM999 — AUTO DOOR LOGIC
-- Cuando NO queden NPCs y detecte Room1, ir a Room999 y abrir puerta
-- ============================================================

local autoDoorActive = false
local autoDoorThread = nil

-- Detectar si quedan NPCs vivos
local function npcsRemaining()
    local folder = Workspace:FindFirstChild("NPCs")
    if not folder then return false end
    for _,npc in ipairs(folder:GetChildren()) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return true
        end
    end
    return false
end

-- Obtener model Room1
local function getRoom1()
    return findModel(room1_path)
end

-- Obtener model Room999 + BossDoor Remote
local function getRoom999Door()
    local r999 = findModel(room999_path)
    if not r999 then return nil end

    local door = r999:FindFirstChild("BossDoor")
    if not door then return nil end

    local rf = door:FindFirstChild("RemoteFunction")
    if not rf then return nil end

    return r999, door, rf
end

-- Movimiento hacia Room999
local function moveToRoom999()
    local r999 = findModel(room999_path)
    if not r999 then return end

    local cf = getModelCF(r999)
    if not cf then return end

    -- Teleport cerca
    pcall(function()
        hrp.CFrame = cf + Vector3.new(0,2,0)
    end)
end

-- ========== AUTO DOOR CORE LOOP ==========
local function startAutoDoorLoop()
    if autoDoorActive then return end
    autoDoorActive = true

    autoDoorThread = task.spawn(function()
        while autoDoorActive do
            task.wait(0.20)

            local room1 = getRoom1()
            local hasNPCs = npcsRemaining()

            -- Condición principal: NO hay NPCs + SI existe Room1
            if (not hasNPCs) and room1 then

                -- Ir a Room999
                moveToRoom999()

                wait(4) -- esperar a llegar

                -- Intentar abrir la puerta
                local r999, door, rf = getRoom999Door()
                if rf then
                    
                    -- ⛔ Notify antes de interactuar
                    Library:Notify({
                        Title = "DupeSide",
                        Description = "Starting Boss Fight....",
                        Time = 4
                    })
                    -- Intentar el invoke
                    local success, result = pcall(function()
                        return rf:InvokeServer()
                    end)

                    -- Si el invoke funcionó
                    if success then
                        Library:Notify({
                            Title = "DupeSide",
                            Description = "Boss Fight Started!!!.",
                            Time = 4
                        })
                    end
                end

            else
                -- Si Room1 ya no existe, detener auto door
                if not room1 then
                    autoDoorActive = false
                    break
                end
            end
        end
    end)
end


local function stopAutoDoorLoop()
    autoDoorActive = false
end

-- Monitor para activar AutoDoor SOLO cuando TeleportToggle esté ON
task.spawn(function()
    while true do
        task.wait(0.5)

        if Toggles.TeleportToggle.Value then
            startAutoDoorLoop()
        else
            stopAutoDoorLoop()
        end
    end
end)

-- ============================================================
-- FINAL REFINEMENTS / SAFETY SYSTEM
-- Protección contra nils, respawn, HRP pérdida, etc.
-- ============================================================

-- Actualizar character y HRP en respawn
player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.2)
    hrp = char:WaitForChild("HumanoidRootPart")

    -- Si estabas en safeplace y morís, se resetea correctamente
    if safeActive then
        stopSafeLoop()
    end
end)

-- =============================================
-- HRP Watchdog — evita errores cuando desaparece
-- =============================================
task.spawn(function()
    while true do
        task.wait(0.2)

        if not character or not character.Parent then continue end

        if not hrp or not hrp.Parent then
            local found = character:FindFirstChild("HumanoidRootPart")
            if found then
                hrp = found
            end
        end
    end
end)

-- ============================================================
-- COLLISION STABILITY (evita que el personaje rebote o caiga)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)

        if hrp then
            hrp.CanCollide = false
        end
    end
end)

-- ============================================================
-- SAFEPLACE PLATFORM AUTO-FOLLOW (si se mueve ligeramente)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)

        if safeActive then
            local plat = Workspace:FindFirstChild(SAFE_PLATFORM_NAME)
            if plat and hrp then
                plat.CFrame = CFrame.new(hrp.Position - Vector3.new(0,2.2,0))
            end
        end
    end
end)

-- ============================================================
-- FAIL SAFE: impedir que SafePlace se quede bugueado
-- ============================================================
task.spawn(function()
    while true do
        task.wait(2)

        if safeActive then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                stopSafeLoop()
            end
        end
    end
end)

-- ============================================================
-- FAIL SAFE EXTRA: si no hay destino, se detiene el safeplace
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)

        if safeActive then
            local dest = chooseSafeDest()
            if not dest then
                stopSafeLoop()
            end
        end
    end
end)

-- ============================================================
-- AUTO CORRECTION: prevenir teleports inválidos
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.2)

        if Toggles.TeleportToggle.Value and currentNPC then
            local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
            if npcHRP and (npcHRP.Position - hrp.Position).Magnitude > 500 then
                -- NPC muy lejos → buscar otro
                currentNPC = getNearestNPC(hrp.Position)
            end
        end
    end
end)


-- ============================================================
-- AUTOFARM — NPC TARGET STABILITY & AUTO-RECOVERY
-- ============================================================

-- Evita que currentNPC quede apuntando a algo inválido
task.spawn(function()
    while true do
        task.wait(0.25)

        if not Toggles.TeleportToggle.Value then continue end
        if not hrp then continue end

        -- Si no hay NPC actual → buscar
        if not currentNPC or not currentNPC.Parent then
            currentNPC = getNearestNPC(hrp.Position)
            continue
        end

        -- Si el NPC tiene humanoide muerto → cambiar target
        local hum = currentNPC:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            local lastPos = nil
            local hrpNPC = currentNPC:FindFirstChild("HumanoidRootPart")
            if hrpNPC then lastPos = hrpNPC.Position end

            -- Buscar siguiente NPC cercano
            currentNPC = getNearestNPC(lastPos or hrp.Position)
            continue
        end

        -- Protección: si NPC está teletransportándose o moviéndose entre zonas
        local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
        if npcHRP then
            local distance = (npcHRP.Position - hrp.Position).Magnitude

            -- Si está demasiado lejos, buscar otro NPC cercano
            if distance > 600 then
                currentNPC = getNearestNPC(hrp.Position)
                continue
            end
        end
    end
end)

-- ============================================================
-- AUTO-SWITCH NPC WHEN TELEPORT METHOD IS BEHIND
-- Mejora la estabilidad al colocarse detrás del NPC.
-- ============================================================

task.spawn(function()
    while true do
        task.wait(0.2)

        if Toggles.TeleportToggle.Value then
            if currentNPC then
                local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    local dist = (npcHRP.Position - hrp.Position).Magnitude

                    -- Si estás demasiado lejos del NPC, volver a buscar
                    if dist > 150 then
                        currentNPC = getNearestNPC(hrp.Position)
                    end
                end
            else
                currentNPC = getNearestNPC(hrp.Position)
            end
        end
    end
end)

-- ============================================================
-- CLEAN NPC TARGET IF MAP RESETS
-- Si la carpeta NPCs se borra y se regenera, esto evita errores.
-- ============================================================

Workspace.ChildRemoved:Connect(function(child)
    if child.Name == "NPCs" then
        currentNPC = nil
    end
end)

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        task.wait(1)
        currentNPC = getNearestNPC(hrp.Position)
    end
end)

-- ============================================================
-- AUTOFARM — FAILSAFE: COMPENSAR SI TELEPORT NO FUNCIONA
-- ============================================================

task.spawn(function()
    while true do
        task.wait(0.35)

        if Toggles.TeleportToggle.Value and currentNPC then
            local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
            if npcHRP then
                local dist = (npcHRP.Position - hrp.Position).Magnitude

                -- Si la distancia se estanca por más de 2s → reposicionar
                if dist > 120 then
                    staticTeleport(npcHRP.CFrame)
                end
            end
        end
    end
end)



-- ============================================================
-- FINAL UI RESTORE + END OF SCRIPT
-- ============================================================

-- Rehabilitar AutoRotate cuando TeleportToggle se apaga
task.spawn(function()
    while true do
        task.wait(0.25)
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                if Toggles.TeleportToggle.Value then
                    hum.AutoRotate = false
                else
                    hum.AutoRotate = true
                end
            end
        end
    end
end)

-- Control automático de orientación frente al NPC
task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.TeleportToggle.Value and currentNPC then
            local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChildOfClass("Humanoid")
            if npcHRP and hum then
                hum.AutoRotate = false
                hrp.CFrame = CFrame.lookAt(hrp.Position, npcHRP.Position)
            end
        end
    end
end)

-- ============================================================
-- Seguridad contra mapas con gravedad modificada
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            Workspace.Gravity = 196.2
        end)
    end
end)



-----------------------------------------------------------
-- Campfire System.lua
-----------------------------------------------------------
-----------------------------------------------------------
-- 🔵 DETECTAR SI ESTAMOS EN TUNDRA
-----------------------------------------------------------

local function getTundraUI()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local overlay = pg:FindFirstChild("TundraFrostOverlay")
    if not overlay then return nil end
    local tundra = overlay:FindFirstChild("Tundra")
    return tundra
end

-----------------------------------------------------------
-- 🔵 CALCULAR PORCENTAJE REAL (1 = 100%)
-----------------------------------------------------------

local function getTundraPercent(tundraUI)
    local t = tundraUI.ImageTransparency
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    return t * 100
end

-----------------------------------------------------------
-- 🔥 BUSCAR CAMPFIRE SEGURA (PRIORIDAD ROOM1)
-----------------------------------------------------------

local function findSafeCampfire()
    local map = workspace:FindFirstChild("MAP")
    if not map then return nil end

    local prioritizedRooms = {"Room1"}
    local checkedRooms = {}

    -- Primero revisar Room1
    for _, roomName in ipairs(prioritizedRooms) do
        local room = map:FindFirstChild(roomName)
        if room and room:IsA("Model") then
            local camp = room:FindFirstChild("Campfire")
            if camp then
                local cf = camp:FindFirstChild("Icosphere") or camp.PrimaryPart
                if cf then
                    local safe = true
                    for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                        local hrpN = npc:FindFirstChild("HumanoidRootPart")
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if hrpN and hum and hum.Health > 0 then
                            if (hrpN.Position - cf.Position).Magnitude <= 60 then
                                safe = false
                                break
                            end
                        end
                    end
                    if safe then
                        return camp, roomName
                    end
                end
            end
        end
        table.insert(checkedRooms, roomName)
    end

    -- Luego revisar el resto de las rooms
    for _, room in ipairs(map:GetChildren()) do
        if room:IsA("Model") and room.Name:match("^Room") and not table.find(checkedRooms, room.Name) then
            local camp = room:FindFirstChild("Campfire")
            if camp then
                local cf = camp:FindFirstChild("Icosphere") or camp.PrimaryPart
                if cf then
                    local safe = true
                    for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                        local hrpN = npc:FindFirstChild("HumanoidRootPart")
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if hrpN and hum and hum.Health > 0 then
                            if (hrpN.Position - cf.Position).Magnitude <= 60 then
                                safe = false
                                break
                            end
                        end
                    end
                    if safe then
                        return camp, room.Name
                    end
                end
            end
        end
    end

    return nil
end

-----------------------------------------------------------
-- 🔥 ACTIVAR REMOTE EVENT DE LA CAMPFIRE
-----------------------------------------------------------

local function igniteCampfire(roomName)
    local map = workspace:WaitForChild("MAP")
    local room = map:FindFirstChild(roomName)
    if not room then return end
    local camp = room:FindFirstChild("Campfire")
    if not camp then return end
    local ico = camp:FindFirstChild("Icosphere")
    if not ico then return end

    pcall(function()
        map:WaitForChild("LayerScripts")
           :WaitForChild("TundraFrost")
           :WaitForChild("Campfire")
           :InvokeServer(ico)
    end)
end

-----------------------------------------------------------
-- 🔥 AUTO CAMPFIRE LOOP
-----------------------------------------------------------

local campfireUsed = false
local campPausedTeleport = false
local campPausedSafeplace = false
local campPausedAutoAttack = false
local campPausedAutoUse = false
local usingCampfire = false
local notifyState = nil

task.spawn(function()
    while true do
        task.wait(0.15)

        if not Toggles.AutoCampfire.Value then
            continue
        end

        -- verificar tundra ui
        local tundraUI = getTundraUI()
        if not tundraUI then
            while Toggles.AutoCampfire.Value and not getTundraUI() do
                task.wait(0.2)
            end
            tundraUI = getTundraUI()
            if not tundraUI then
                continue
            end
        end

        local percent = getTundraPercent(tundraUI)

        -- arriba del 60%
        if percent > 60 then
            if percent >= 99.9 then
                if campPausedTeleport then
                    Toggles.TeleportToggle:SetValue(true)
                    campPausedTeleport = false
                end
                if campPausedSafeplace then
                    Toggles.SafePlaceToggle:SetValue(true)
                    campPausedSafeplace = false
                end
                if campPausedAutoAttack then
                    Toggles.AutoAttack:SetValue(true)
                    campPausedAutoAttack = false
                end
                if campPausedAutoUse then
                    AutoUseToggle:SetValue(true)
                    campPausedAutoUse = false
                end

                campfireUsed = false
            end
            continue
        end

        -- bajo 60% → activar campfire
        if Toggles.TeleportToggle.Value then
            campPausedTeleport = true
            Toggles.TeleportToggle:SetValue(false)
        end
        if Toggles.SafePlaceToggle.Value then
            campPausedSafeplace = true
            Toggles.SafePlaceToggle:SetValue(false)
        end
        if Toggles.AutoAttack.Value then
            campPausedAutoAttack = true
            Toggles.AutoAttack:SetValue(false)
        end
        if AutoUseToggle.Value then
            campPausedAutoUse = true
            AutoUseToggle:SetValue(false)
        end

        if campfireUsed then
            continue
        end

        -- buscar campfire segura
        local campfire, roomName = findSafeCampfire()
        if campfire then
            local cf = campfire:FindFirstChild("Icosphere")
            if cf then

                -- teleport
                local maxTries = 60
                local tries = 0
                while true do
                    local dist = (hrp.Position - cf.Position).Magnitude
                    if dist <= 7 then break end
                    pcall(function()
                        hrp.CFrame = cf.CFrame + Vector3.new(0,3,0)
                    end)
                    tries += 1
                    if tries >= maxTries then break end
                    task.wait(0.1)
                end

                -- *** NUEVO: verificar si realmente estamos cerca de una campfire ***
                local isNear = (hrp.Position - cf.Position).Magnitude <= 12

                if isNear then
                    Library:Notify({
                        Title = "DupeSide",
                        Description = "Auto Campfire Loading...",
                        Time = 4
                    })
                end

                task.wait(5)
                igniteCampfire(roomName)
                campfireUsed = true

                if isNear then
                    Library:Notify({
                        Title = "DupeSide",
                        Description = "Campfire Loaded Successfully! "..roomName,
                        Time = 4
                    })
                end

                -- loop de sentado
                task.spawn(function()
                    while Toggles.AutoCampfire.Value do
                        task.wait(0.2)
                        if not campfireUsed then break end

                        local canSprint = character:GetAttribute("CanSprint")
                        if canSprint ~= false then
                            local campRetry, roomRetry = findSafeCampfire()
                            if campRetry and roomRetry then
                                local cfRetry = campRetry:FindFirstChild("Icosphere")
                                if cfRetry then
                                    pcall(function()
                                        hrp.CFrame = cfRetry.CFrame + Vector3.new(0,3,0)
                                    end)
                                    task.wait(0.2)
                                    igniteCampfire(roomRetry)
                                end
                            end
                        end

                        local tundraUI2 = getTundraUI()
                        if tundraUI2 then
                            local percent2 = getTundraPercent(tundraUI2)
                            if percent2 >= 100 then
                                break
                            end
                        end
                    end
                end)

                -- loop de NPCS
                task.spawn(function()
                    while Toggles.AutoCampfire.Value do
                        task.wait(0.2)
                        if not campfireUsed then break end

                        local danger = false
                        for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                            local hrpN = npc:FindFirstChild("HumanoidRootPart")
                            local hum = npc:FindFirstChildOfClass("Humanoid")
                            if hrpN and hum and hum.Health > 0 then
                                if (hrpN.Position - hrp.Position).Magnitude <= 50 then
                                    danger = true
                                    break
                                end
                            end
                        end

                        if not danger then continue end

                        local newCamp, newRoom = findSafeCampfire()
                        if newCamp and newRoom then
                            local newCF = newCamp:FindFirstChild("Icosphere")
                            if newCF then
                                local tries2 = 0
                                local max2 = 60
                                while Toggles.AutoCampfire.Value do
                                    local d2 = (hrp.Position - newCF.Position).Magnitude
                                    if d2 <= 7 then break end
                                    pcall(function()
                                        hrp.CFrame = newCF.CFrame + Vector3.new(0,3,0)
                                    end)
                                    tries2 += 1
                                    if tries2 >= max2 then break end
                                    task.wait(0.1)
                                end
                                task.wait(0.5)

                                igniteCampfire(newRoom)
                                campfireUsed = true
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- ============================================================
-- auto potential.lua
-- ============================================================


local rarityColors = {
    Legendary = Color3.fromRGB(189, 138, 19),
    Epic      = Color3.fromRGB(132, 13, 79),
    Rare      = Color3.fromRGB(35, 57, 134),
    Uncommon  = Color3.fromRGB(24, 68, 34),
    Common    = Color3.fromRGB(103, 103, 103)
}

local rarityOrder = {
    Legendary = 5,
    Epic      = 4,
    Rare      = 3,
    Uncommon  = 2,
    Common    = 1
}

local player = game:GetService("Players").LocalPlayer
local remote = player:WaitForChild("Remotes"):WaitForChild("Potential")

-- =========================================================
-- UTILS
-- =========================================================

local function colorDistance(a, b)
    local dr = a.R - b.R
    local dg = a.G - b.G
    local db = a.B - b.B
    return math.sqrt(dr*dr + dg*dg + db*db)
end

local function GetRarityFromColor(color)
    local bestMatch, bestDist = nil, 1e9
    for rarity, col in pairs(rarityColors) do
        local d = colorDistance(color, col)
        if d < bestDist then bestDist, bestMatch = d, rarity end
    end
    if bestDist <= 0.05 then return bestMatch end
    return nil
end

local function FindPotentialsGUI()
    local gui = player.PlayerGui:FindFirstChild("Potentials")
    if gui and gui:FindFirstChild("Potentials") then
        return gui.Potentials
    end

    if player.PlayerGui then
        for _, desc in ipairs(player.PlayerGui:GetDescendants()) do
            if desc:FindFirstChild("1") and desc["1"]:FindFirstChild("Base") then
                return desc
            end
        end
    end
    return nil
end

local function GetBestCard()
    local gui = FindPotentialsGUI()
    if not gui then return nil end

    local bestCard, bestValue = nil, -1
    for i = 1,3 do
        local slot = gui:FindFirstChild(tostring(i))
        if slot then
            local base = slot:FindFirstChild("Base")
            if base then
                local color = base.ImageColor3 or base.BackgroundColor3 or Color3.new(1,1,1)
                local rarity = GetRarityFromColor(color)
                if rarity then
                    local value = rarityOrder[rarity]
                    if value > bestValue then
                        bestValue, bestCard = value, i
                    end
                end
            end
        end
    end
    return bestCard
end

local function GetRoom()
    local potentials = workspace:FindFirstChild("Potentials")
    if not potentials then return nil end

    for _, obj in pairs(potentials:GetChildren()) do
        if obj.Name:match("^Room%d+_%d+$") then
            return obj
        end
    end
    return nil
end

local function TriggerPrompt(prompt)
    if type(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
    elseif type(firesignal) == "function" and prompt.Triggered then
        firesignal(prompt.Triggered)
    elseif prompt:IsA("ProximityPrompt") then
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end
end

-- =========================================================
-- SISTEMA ANTI-SPAM
-- =========================================================

local roomSpamCount = {}      -- RoomName → count
local MAX_SPAM = 6            -- máximo permitido

local function RegisterRoomInvoke(roomName)
    roomSpamCount[roomName] = (roomSpamCount[roomName] or 0) + 1

    print("[AntiSpam] Room:", roomName, "Count:", roomSpamCount[roomName])

    if roomSpamCount[roomName] >= MAX_SPAM then
        warn("[AntiSpam] Destruyendo Room por spam:", roomName)
        local obj = workspace.Potentials:FindFirstChild(roomName)
        if obj then obj:Destroy() end
        roomSpamCount[roomName] = 0
        return true
    end

    return false
end

-- =========================================================
-- MAIN LOOP
-- =========================================================

task.spawn(function()
    while true do
        task.wait(0.25)

        if not AutoPotentialEnabled then continue end

        pcall(function()
            local roomObj = GetRoom()
            if not roomObj then return end

            local roomName = roomObj.Name

            local prompt = roomObj:FindFirstChild("InteractPrompt")
            if prompt then
                TriggerPrompt(prompt)
            else
                return
            end

            task.wait(0.25)

            local bestCard = GetBestCard()
            if not bestCard then return end

            -- antispam
            if RegisterRoomInvoke(roomName) then
                print("[AutoPotential] Room destruida, invoke cancelado.")
                return
            end

            -- invoke
            print("[AutoPotential] Invoke -> Room:", roomName, "Card:", bestCard)
            remote:InvokeServer(roomName, bestCard)
        end)
    end
end)

-- =====================================================
-- LOOP AUTOMÁTICO [Arcane/Wildcard Selection]
-- =====================================================

task.spawn(function()
    while task.wait(0.1) do
        if AutoSelectArcaneActive then
            local args = {
                "WildCard",
                SelectedArcane -- ← el valor del dropdown
            }

            local remote = LocalPlayer:WaitForChild("Remotes"):WaitForChild("Potential")

            pcall(function()
                remote:InvokeServer(unpack(args))
            end)
        end
    end
end)


-- =====================================================
-- LOOP AUTOMÁTICO [Auto Equip Sword]
-- =====================================================

-- Función para obtener el EquippedWeld
local function getEquippedWeld()
    local chars = workspace:WaitForChild("Characters")
    local myChar = chars:WaitForChild(player.Name)

    local equippedFolder = myChar:WaitForChild("Equipped")
    local weaponFolder = equippedFolder:WaitForChild("Weapon")
    local weaponModel = weaponFolder:WaitForChild("Weapon1Main")

    return weaponModel:WaitForChild("EquippedWeld")
end

-- Remote
local remote = player:WaitForChild("Remotes"):WaitForChild("RequestAction")

local function autoEquip()
    local weld = getEquippedWeld()

    if weld and weld.Enabled == false then
        local args = {
            "Equip",
            Enum.UserInputState.Begin,
        }
        remote:InvokeServer(unpack(args))
    end
end

-- Loop controlador
task.spawn(function()
    while task.wait(0.2) do
        if autoEquipSword then
            autoEquip()
        end
    end
end)


-- ============================================================
-- player movement.lua
-- ============================================================


-- ========== Movement: Fly (FULL 3D) / Noclip / Speed ==========
local bodyVelocity, bodyGyro
local flying = false
local savedRotation = CFrame.new()
local flyControls = {W=false, A=false, S=false, D=false, Up=false, Down=false}
local cam = workspace.CurrentCamera

local function createBodyMovers()
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.new(0,0,0)
    bv.P = 1250
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    return bv, bg
end

local function attachBodyMovers(hrpInst)
    if not bodyVelocity or not bodyGyro then
        bodyVelocity, bodyGyro = createBodyMovers()
    end
    bodyVelocity.Parent = hrpInst
    bodyGyro.Parent = hrpInst
end

local function detachBodyMovers()
    if bodyVelocity then bodyVelocity.Parent = nil end
    if bodyGyro then bodyGyro.Parent = nil end
end

local function getCharacterParts()
    local char = player.Character
    if not char then return end
    local hrpLocal = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if hrpLocal and humanoid then return char, hrpLocal, humanoid end
end

local function startFlying()
    local _, hrpLocal, humanoid = getCharacterParts()
    if not hrpLocal or not humanoid then return end
    flying = true
    savedRotation = hrpLocal.CFrame - hrpLocal.CFrame.p
    attachBodyMovers(hrpLocal)
    humanoid.PlatformStand = false
    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end)
end

local function stopFlying()
    flying = false
    detachBodyMovers()
    local _, _, humanoid = getCharacterParts()
    if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end) end
end

-- Noclip
local NoclipConn
local function startNoclip()
    if NoclipConn then return end
    NoclipConn = RunService.Stepped:Connect(function()
        if game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
end

-- Input handling for fly controls (WASD + Space + Ctrl)
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.W then flyControls.W = true end
        if key == Enum.KeyCode.A then flyControls.A = true end
        if key == Enum.KeyCode.S then flyControls.S = true end
        if key == Enum.KeyCode.D then flyControls.D = true end
        if key == Enum.KeyCode.Space then flyControls.Up = true end
        if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then flyControls.Down = true end
    end
end)
UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.W then flyControls.W = false end
        if key == Enum.KeyCode.A then flyControls.A = false end
        if key == Enum.KeyCode.S then flyControls.S = false end
        if key == Enum.KeyCode.D then flyControls.D = false end
        if key == Enum.KeyCode.Space then flyControls.Up = false end
        if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then flyControls.Down = false end
    end
end)

-- RenderStepped driver for movement (Fly/Speed/Noclip)
RunService.RenderStepped:Connect(function(dt)
    -- update camera ref
    cam = workspace.CurrentCamera or cam

    -- Fly logic
    if Toggles.FlyToggle and Toggles.FlyToggle.Value then
        if not flying then startFlying() end
        local _, hrpLocal = getCharacterParts()
        if hrpLocal and bodyVelocity then
            local speed = Options.FlySpeed and Options.FlySpeed.Value or getgenv().FlySpeed or 20
            -- compute direction from camera
            local forward = (flyControls.W and 1 or 0) - (flyControls.S and 1 or 0)
            local right = (flyControls.D and 1 or 0) - (flyControls.A and 1 or 0)
            local upv = (flyControls.Up and 1 or 0) - (flyControls.Down and 1 or 0)

            local camCFrame = cam and cam.CFrame or hrpLocal.CFrame
            local lookVector = camCFrame.LookVector
            local rightVector = camCFrame.RightVector

            local moveVector = (lookVector * forward) + (rightVector * right) + (Vector3.new(0,1,0) * upv)
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
            end
            bodyVelocity.Velocity = moveVector * speed
            if bodyGyro then
                bodyGyro.CFrame = CFrame.new(hrpLocal.Position) * (savedRotation or CFrame.new())
            end
        end
    else
        if flying then stopFlying() end
    end

    -- Speed (B style)
    if Toggles.SpeedActive and Toggles.SpeedActive.Value then
        local spd = Options.SpeedValue and Options.SpeedValue.Value or getgenv().SpeedValue or 50
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                local hrpLocal = char.HumanoidRootPart
                hrpLocal.CFrame = hrpLocal.CFrame + humanoid.MoveDirection * (spd * dt)
            end
        end
    end

    -- Noclip
    if Toggles.NoclipToggle and Toggles.NoclipToggle.Value then
        startNoclip()
    else
        stopNoclip()
    end
end)

-- ========== Keybind behavior for Fly / Speed / Noclip (UI KeyPickers) ==========
if Options.FlyKeyPicker then
    Options.FlyKeyPicker:OnClick(function()
        if Toggles.FlyToggle then Toggles.FlyToggle:SetValue(not Toggles.FlyToggle.Value) end
    end)
end

if Options.SpeedKeyPicker then
    Options.SpeedKeyPicker:OnClick(function()
        if Toggles.SpeedActive then Toggles.SpeedActive:SetValue(not Toggles.SpeedActive.Value) end
    end)
    -- Hold-mode management
    task.spawn(function()
        while true do
            task.wait(0.08)
            local held = Options.SpeedKeyPicker and Options.SpeedKeyPicker:GetState()
            if held and Toggles.SpeedActive and not Toggles.SpeedActive.Value then
                Toggles.SpeedActive:SetValue(true)
            elseif (not held) and Toggles.SpeedActive and Toggles.SpeedActive.Value and (not (Options.SpeedKeyPicker and Options.SpeedKeyPicker:GetState())) then
                Toggles.SpeedActive:SetValue(false)
            end
            if Library.Unloaded then break end
        end
    end)
end

if Options.NoclipKeyPicker then
    Options.NoclipKeyPicker:OnClick(function()
        if Toggles.NoclipToggle then Toggles.NoclipToggle:SetValue(not Toggles.NoclipToggle.Value) end
    end)
end

-- Fallback input handler: listen for actual key presses and toggle UI state
-- This is a minimal, non-invasive fallback in case the KeyPicker implementation
-- doesn't toggle the UI when keys are pressed.
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UIS and UIS:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        -- compare against current selections
        if keyName == FlyKey then
            print("[keybind] detected FlyKey press:", keyName)
            if Toggles.FlyToggle then print("[keybind] toggling FlyToggle (was)", Toggles.FlyToggle.Value) Toggles.FlyToggle:SetValue(not Toggles.FlyToggle.Value) end
        elseif keyName == SpeedKey then
            print("[keybind] detected SpeedKey press:", keyName)
            if Toggles.SpeedActive then print("[keybind] toggling SpeedActive (was)", Toggles.SpeedActive.Value) Toggles.SpeedActive:SetValue(not Toggles.SpeedActive.Value) end
        elseif keyName == NoclipKey then
            print("[keybind] detected NoclipKey press:", keyName)
            if Toggles.NoclipToggle then print("[keybind] toggling NoclipToggle (was)", Toggles.NoclipToggle.Value) Toggles.NoclipToggle:SetValue(not Toggles.NoclipToggle.Value) end
        end
    end
end)


-- Final notify

-- ============================================================
-- Boss Room Esp.lua
-- ============================================================


-- Boss Room ESP
local function createBossRoomESP(part)
    if not part or part:FindFirstChild("SixSeven") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SixSeven"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = part

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = "Boss Room🥀🐺"
    textLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
    textLabel.TextStrokeTransparency = 0.2
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard
    
    billboard.Parent = part
end

-- Boss Room ESP loop
task.spawn(function()
    while true do
        task.wait(2)
        if Toggles.BossRoomESP and Toggles.BossRoomESP.Value then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "BossDoor" and obj:IsA("BasePart") then
                    createBossRoomESP(obj)
                end
            end
        end
    end
end)


-- ============================================================
-- TeleporToggle Fixes.lua
-- ============================================================


-- === Fix: evitar salto/impulso al apagar el teleport ===
if Toggles.TeleportToggle then
    Toggles.TeleportToggle:OnChanged(function(value)
        if not value then
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
            if hrp then
                hrp.Anchored = false
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end

-- ============================================================
-- esp.lua
-- ============================================================

-- ---------- ESP (Players / NPCs / items esp) ----------
local success_esp, ESPlib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/linemaster2/esp-library/main/library.lua"))()
end)
local success_npc_esp, NPCesp = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/iusedoneyed-hub/example/refs/heads/main/npc_esp.lua"))()
end)

local success_item_esp, ITEMesp = pcall(function()
     return loadstring(game:HttpGet("https://raw.githubusercontent.com/DerekLuaU/example/refs/heads/main/esp_items.lua"))()
end)

local success_item_esp, ITEMesp = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DerekLuaU/example/refs/heads/main/esp_items.lua"))()
end)


if not success_esp then
    ESPlib = { Enabled = false, ShowBox = false, ShowName = false, ShowHealth = false, ShowTracer = false, ShowDistance = false }
end
if not success_npc_esp then
    NPCesp = { Enabled = false, ShowBox = false, ShowName = false, ShowHealthNumber = false, ShowTracer = false, ShowDistance = false }
end

-- helper caches
local highlighted = {}
local nameTags = {}
local espCache = { highlights = {}, billboards = {} }

-- functions for player ESP (simple highlight + billboard)
local function createHighlightForModel(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end
    if highlighted[model] then return end
    local highlight = table.remove(espCache.highlights) or Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = model
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255,255,255)
    highlight.Parent = model
    highlighted[model] = highlight
end

local function removeHighlightForModel(model)
    local h = highlighted[model]
    if h then
        if typeof(h) == "Instance" and h.Parent then
            h.Parent = nil
            table.insert(espCache.highlights, h)
        end
        highlighted[model] = nil
    end
end

local function createNameTagForModel(model)
    if nameTags[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0,120,0,40)
    billboard.StudsOffset = Vector3.new(0,2.5,0)
    billboard.AlwaysOnTop = true
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Text = model.Name
    txt.TextColor3 = Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency = 0
    txt.TextScaled = true
    txt.Parent = billboard
    billboard.Parent = head
    nameTags[model] = billboard
end

local function removeNameTagForModel(model)
    if nameTags[model] then
        if typeof(nameTags[model]) == "Instance" and nameTags[model].Parent then
            nameTags[model]:Destroy()
        end
        nameTags[model] = nil
    end
end

-- sync ESP based on toggles
task.spawn(function()
    while true do
        task.wait(0.6)
        -- Players
        local espEnabled = (Options.ESPEnabled and Options.ESPEnabled.Value) or getgenv().ESPSettings.Enabled
        local espShowBox = (Options.ESPBox and Options.ESPBox.Value) or getgenv().ESPSettings.ShowBox
        local espShowName = (Options.ESPName and Options.ESPName.Value) or getgenv().ESPSettings.ShowName

        -- Use ESPlib if available for players
        if ESPlib then
            ESPlib.Enabled = espEnabled
            ESPlib.ShowBox = espShowBox
            ESPlib.ShowName = espShowName
            ESPlib.ShowHealth = (Options.ESPHealth and Options.ESPHealth.Value) or getgenv().ESPSettings.ShowHealth
            ESPlib.ShowTracer = (Options.ESPTracer and Options.ESPTracer.Value) or getgenv().ESPSettings.ShowTracer
            ESPlib.ShowDistance = (Options.ESPDistance and Options.ESPDistance.Value) or getgenv().ESPSettings.ShowDistance
        else
            -- fallback internal simple ESP for players only
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local model = pl.Character
                    if espEnabled and espShowBox then
                        createHighlightForModel(model)
                    else
                        removeHighlightForModel(model)
                    end
                    if espEnabled and espShowName then
                        createNameTagForModel(model)
                    else
                        removeNameTagForModel(model)
                    end
                end
            end
        end

        -- NPCs via NPCesp if available
        if NPCesp then
            NPCesp.Enabled = getgenv().NPCESPSettings.Enabled
            NPCesp.ShowBox = getgenv().NPCESPSettings.ShowBox
            NPCesp.ShowName = getgenv().NPCESPSettings.ShowName
            NPCesp.ShowHealthNumber = getgenv().NPCESPSettings.ShowHealthNumber
            NPCesp.ShowTracer = getgenv().NPCESPSettings.ShowTracer
            NPCesp.ShowDistance = getgenv().NPCESPSettings.ShowDistance
        end
            -- Items ESP via ITEMesp if available (use provided API functions)
            if ITEMesp then
                if type(ITEMesp.SetEnabled) == "function" then pcall(function() ITEMesp.SetEnabled(getgenv().ItemESPSettings.Enabled) end) end
                if type(ITEMesp.SetBoxEnabled) == "function" then pcall(function() ITEMesp.SetBoxEnabled(getgenv().ItemESPSettings.ShowBox) end) end
                if type(ITEMesp.SetNameEnabled) == "function" then pcall(function() ITEMesp.SetNameEnabled(getgenv().ItemESPSettings.ShowName) end) end
                if type(ITEMesp.SetDistanceEnabled) == "function" then pcall(function() ITEMesp.SetDistanceEnabled(getgenv().ItemESPSettings.ShowDistance) end) end
            end
    end
end)

-- ============================================================
-- auto attack skill.lua
-- ============================================================

-- Función para detectar NPCs cercanos
local function IsNPCNearby(range)
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = player.Character.HumanoidRootPart
    for _, npc in pairs(workspace.NPCs:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
            local distance = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
            if distance <= range then
                return true
            end
        end
    end
    return false
end

-- Función para usar habilidad mediante RemoteEvent
local function UseSkill(skillName)
    if skillName ~= "" then
        local args = {skillName, Enum.UserInputState.Begin}
        game:GetService("Players").LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction"):InvokeServer(unpack(args))
        print("[DupeSide] Used skill:", skillName)
    end
end

-- loop
spawn(function()
    while true do
        if AutoUseToggle.Value then
            if IsNPCNearby(20) then
                UseSkill(Skill1)
                task.wait(1)
                UseSkill(Skill2)
                task.wait(1)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)
-- ============================================================
-- auto parry.lua
-- ============================================================

-- ---------- Auto Parry ----------
local NPCFolder = npcFolder
local LocalPlayer = Players.LocalPlayer
local lastParryTime = 0

local keywords = {
    "attack","swing","crit","skill","slash","pierce","impact",
    "arrow release","hit","kick","stoneslashes","projectile",
    "fireball","iceblast","shockwave","charge","meteor","aoe","fist","FrozenCore","Beam"
}
local function checkKeyword(name)
    local nameLower = name:lower()
    for _, key in pairs(keywords) do
        if string.find(nameLower, key) then
            return key:upper()
        end
    end
    return nil
end

local function doParry()
    local args = {[1] = "Parry", [2] = Enum.UserInputState.Begin}
    if LocalPlayer and LocalPlayer:FindFirstChild("Remotes") and LocalPlayer.Remotes:FindFirstChild("RequestAction") then
        pcall(function() LocalPlayer.Remotes.RequestAction:InvokeServer(unpack(args)) end)
    end
end

local function checkAndParry(obj, keyType, npc)
    if not (Toggles.AutoParryEnabled and Toggles.AutoParryEnabled.Value) then return end
    local root = (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Sound") and obj.Parent and obj.Parent:IsA("BasePart") then
        pos = obj.Parent.Position
    elseif obj:IsA("AnimationTrack") and npc:FindFirstChild("HumanoidRootPart") then
        pos = npc.HumanoidRootPart.Position
    else
        return
    end

    local PARSE_RANGE = Options.ParryRange and Options.ParryRange.Value or getgenv().ParryRange or 30
    local PARSE_COOLDOWN = Options.ParryCooldown and Options.ParryCooldown.Value or getgenv().ParryCooldown or 0.5
    local CRIT_DELAY = Options.ParryCritDelay and Options.ParryCritDelay.Value or getgenv().ParryCritDelay or 0.2

    if (pos - root.Position).Magnitude <= PARSE_RANGE then
        local currentTime = tick()
        if currentTime - lastParryTime >= PARSE_COOLDOWN then
            lastParryTime = currentTime
            local delayTime = 0
            if keyType == "CRIT" then delayTime = CRIT_DELAY end
            task.delay(delayTime, doParry)
        end
    end
end

local function watchNPC(npc)
    local hrpLocal = npc:FindFirstChild("HumanoidRootPart")
    if not hrpLocal then return end
    for _, child in pairs(hrpLocal:GetChildren()) do
        local key = checkKeyword(child.Name)
        if key then checkAndParry(child, key, npc) end
    end
    hrpLocal.ChildAdded:Connect(function(child)
        local key = checkKeyword(child.Name)
        if key then checkAndParry(child, key, npc) end
    end)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            animator.AnimationPlayed:Connect(function(track)
                local key = checkKeyword(track.Name)
                if key then checkAndParry(track, key, npc) end
            end)
        end
    end
end

for _, npc in pairs(NPCFolder:GetChildren()) do if npc:IsA("Model") then watchNPC(npc) end end
NPCFolder.ChildAdded:Connect(function(npc) if npc:IsA("Model") then task.wait(0.2); watchNPC(npc) end end)

Library:OnUnload(function()
    for model, _ in pairs(highlighted) do removeHighlightForModel(model) end
    for model, _ in pairs(nameTags) do removeNameTagForModel(model) end
    restoreTouchInterests()
    stopNoclip()
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    print("DupeSide merged UI unloaded.")
end)

Library:Notify({ Title = "DupeSide", Description = "Succesfully loaded.", Time = 4 })
-- ============================================================
-- Mensaje de carga completa
-- ============================================================
task.delay(1, function()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("SendNotification", {
        Title = "DupeSide Hub",
        Text = "discord.gg/mcPTS824Fc",
        Duration = 6
    })
end)
-- ▬▬▬ FIN ▬▬▬

