local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/DerekLuaU/example/refs/heads/main/Library.lua"))(), "Failed to load Library")
local ThemeManager = assert(loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))(), "Failed to load ThemeManager")
local SaveManager = assert(loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))(), "Failed to load SaveManager")
local Options, Toggles = Library.Options, Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true


-----------------------------------------------------------
-- UI WINDOW
-----------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "DupeSide Hub",
    Footer = "version: 3.0.5",
    Icon = 123532668007594,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-----------------------------------------------------------
-- UI TABS
-----------------------------------------------------------
local Tabs = {
    Main = Window:AddTab("Main", "layout-dashboard"),
    Visual = Window:AddTab("Visual", "eye"),
    Player = Window:AddTab("Movement", "zap"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-----------------------------------------------------------
-- GROUPBOXES
-----------------------------------------------------------
local MainLeft = Tabs.Main:AddLeftGroupbox("Auto Farm Options", "user")
local QualityOfLife = Tabs.Main:AddLeftGroupbox("Quality Of Life", "earth")
local MainRight = Tabs.Main:AddRightGroupbox("Auto Parry [Experimental / Beta]", "shield")
local DungeonGroupBox = Tabs.Main:AddRightGroupbox("Dungeon", "earth")
local VisualLeft = Tabs.Visual:AddLeftGroupbox("ESP Player", "eye")
local VisualLeftItemsEsp = Tabs.Visual:AddLeftGroupbox("ESP Items / Others", "Box")
local VisualRight = Tabs.Visual:AddRightGroupbox("ESP Mobs", "monitor")
local VisualRightBossRoom = Tabs.Visual:AddRightGroupbox("ESP Room", "monitor")
local PlayerLeft = Tabs.Player:AddLeftGroupbox("Movement", "navigation")
local SafePlaceRight = Tabs.Main:AddRightGroupbox("Safe Place Settings", "Setting")
local AutoPotentialLeft = Tabs.Main:AddLeftGroupbox("Auto Potential Card", "Setting")

-- === getgenv defaults para ESP Items ===
getgenv().ItemESPSettings = getgenv().ItemESPSettings or {
    Enabled = false,
    ShowBox = false,
    ShowName = false,
    ShowDistance = false
}




-----------------------------------------------------------
-- DEFAULTS
-----------------------------------------------------------

if getgenv().AutoSprint == nil then
    getgenv().AutoSprint = false
end
getgenv().AutoStartDungeon = getgenv().AutoStartDungeon or false
getgenv().AutoContinueDungeon = getgenv().AutoContinueDungeon or false
getgenv().TeleportActive = getgenv().TeleportActive or false
getgenv().AutoAttack = getgenv().AutoAttack or false
getgenv().AntiKillBricks = getgenv().AntiKillBricks or false
getgenv().DistanceBehind = getgenv().DistanceBehind or 8
getgenv().TeleportSmoothness = getgenv().TeleportSmoothness or 0.15
getgenv().InstantRange = getgenv().InstantRange or 10


getgenv().AutoParryEnabled = getgenv().AutoParryEnabled == nil and false or getgenv().AutoParryEnabled
getgenv().ParryRange = getgenv().ParryRange or 30
getgenv().ParryCooldown = getgenv().ParryCooldown or 0.5
getgenv().ParryCritDelay = getgenv().ParryCritDelay or 0.2
getgenv().ESPSettings = getgenv().ESPSettings or {
    Enabled = false, ShowBox = false, ShowName = false, ShowHealth = false, ShowTracer = false, ShowDistance = false
}
getgenv().NPCESPSettings = getgenv().NPCESPSettings or {
    Enabled = false, ShowBox = false, ShowName = false, ShowHealthNumber = false, ShowTracer = false, ShowDistance = false
}
getgenv().ESPGlow = getgenv().ESPGlow == nil and false or getgenv().ESPGlow
getgenv().ESPName = getgenv().ESPName == nil and false or getgenv().ESPName
getgenv().BossRoomESP = getgenv().BossRoomESP == nil and false or getgenv().BossRoomESP
getgenv().FlyEnabled = getgenv().FlyEnabled == nil and false or getgenv().FlyEnabled
getgenv().FlySpeed = getgenv().FlySpeed or 20
getgenv().SpeedActive = getgenv().SpeedActive == nil and false or getgenv().SpeedActive
getgenv().SpeedValue = getgenv().SpeedValue or 50
getgenv().NoclipEnabled = getgenv().NoclipEnabled == nil and false or getgenv().NoclipEnabled





-----------------------------------------------------------
-- Quality Of Life
-----------------------------------------------------------


local loaded = false 
QualityOfLife:AddToggle("AutoSprint", {
    Text = "Auto Sprint",
    Default = getgenv().AutoSprint,
    Callback = function(value)
        if not loaded then
            -- primera vez: solo marcar como cargado
            loaded = true
            return
        end

        getgenv().AutoSprint = value

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end
        local RequestAction = LocalPlayer:WaitForChild("Remotes"):WaitForChild("RequestAction")

        if value then
            -- activar sprint
            local RemoteArgs = {"Sprint", Enum.UserInputState.Begin, [4] = "Start"}
            pcall(function()
                RequestAction:InvokeServer(unpack(RemoteArgs, 1, table.maxn(RemoteArgs)))
            end)
        else
            -- desactivar sprint
            local RemoteArgs = {"Sprint", Enum.UserInputState.End, [4] = "End"}
            pcall(function()
                RequestAction:InvokeServer(unpack(RemoteArgs, 1, table.maxn(RemoteArgs)))

            end)
        end
    end,
})


-----------------------------------------------------------
-- Auto Potential ui
-----------------------------------------------------------

local AutoPotentialEnabled = false
AutoPotentialLeft:AddToggle("AutoPotentialToggle", {
    Text = "Auto Potential Orb/Card",
    Default = false,
    Callback = function(v) AutoPotentialEnabled = v end
})


AutoPotentialLeft:AddToggle("AutoSelectArcaneToggle", {
    Text = "Auto Select Arcane/WildCard ",
    Default = false,

    Callback = function(state)
        AutoSelectArcaneActive = state
        print("Auto Arcane:", state)
    end
})

AutoPotentialLeft:AddDropdown("ArcaneDropdown", {
	Values = { "Disease", "Earth", "Fire", "Frost", "Holy", "Lightning", "Nature", "Physical", "Shadow", "Water", "Wind" },
	Default = 5,
	Multi = false,
	Text = "Arcane/Wildcard Type",
	Tooltip = "Select Your Arcane/WildCard",
	Searchable = false,

	Callback = function(Value)
		SelectedArcane = Value
		print("WildCard/Arcane:", SelectedArcane)
	end
})

AutoPotentialLeft:AddLabel(
	"Auto Select Arcane/WildCard is currently in development (Disabled. In Development)",
	true
)


-----------------------------------------------------------
-- SAFEPLACE UI
-----------------------------------------------------------
SafePlaceRight:AddToggle("SafePlaceToggle", {
    Text = "Safe Place Toggle",
    Default = false,
})


SafePlaceRight:AddToggle("HealtSkill", {
    Text = "Use Healing Skill",
    Default = false,
})

SafePlaceRight:AddInput("SkillInput", {
    Default = "Lesser Heal",
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = false,

    Text = "Skill Name",
    Tooltip = "Type the name of your healing ability",
    Placeholder = "Example: Lesser Heal",

    Callback = function(Value)
        print("[DupeSide] Healing skill set to:", Value)
    end,
})


SafePlaceRight:AddSlider("HealtThresholdd", {
    Text = "Health Threshold",
    Default = 30,
    Min = 1,
    Max = 100,
    Rounding = 1,
})

SafePlaceRight:AddSlider("healthRegenTargett", {
    Text = "Health Regen Target",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 1,
})



-----------------------------------------------------------
-- AUTO FARM UI
-----------------------------------------------------------

MainLeft:AddToggle("TeleportToggle", {
    Text = "Teleport Toggle",
    Default = getgenv().TeleportActive,
    Callback = function(v) getgenv().TeleportActive = v end
})


MainLeft:AddToggle("AutoCampfire", {
    Text = "Auto Campfire",
    Default = false,
})


MainLeft:AddToggle("AutoStartDungeon", {
    Text = "Auto Start Dungeon",
    Default = false,
    Callback = function(value)
        getgenv().AutoStartDungeon = value

        if value then
            task.spawn(function()
                local player = game:GetService("Players").LocalPlayer
                local gui = player.PlayerGui:WaitForChild("AffixNumSelection")
                local readyRemote = game:GetService("ReplicatedStorage")
                    :WaitForChild("RemoteEvents")
                    :WaitForChild("ReadyUp")

                local alreadyExecuted = false

                while getgenv().AutoStartDungeon do
                    -- Detectar si el GUI está enabled
                    if gui.Enabled == true then
                        if not alreadyExecuted then
                            alreadyExecuted = true

                            -- Esperar cooldown de 3 segundos
                            task.wait(3)

                            -- Ejecutar remote event
                            readyRemote:FireServer({})

                            -- Notificación
                            Library:Notify({
                                Title = "DupeSide",
                                Description = "Dungeon Started!",
                                Time = 4
                            })
                        end
                    else
                        -- Resetear para permitir ejecución la próxima vez
                        alreadyExecuted = false
                    end

                    task.wait(0.2)
                end
            end)
        end
    end
})


MainLeft:AddToggle("AutoContinueDungeon", {
    Text = "Auto Continue Dungeon",
    Default = false,
    Callback = function(value)
        getgenv().AutoContinueDungeon = value

        if value then
            task.spawn(function()
                local player = game:GetService("Players").LocalPlayer
                local gui = player:WaitForChild("PlayerGui")

                local lastState = false -- Para detectar cambios

                while getgenv().AutoContinueDungeon do
                    local layerComplete = gui:FindFirstChild("LayerComplete")
                    local currentState = layerComplete and layerComplete.Enabled

                    -- Detectar transición: disabled → enabled
                    if currentState and not lastState then
                        -- Esperar 3 segundos
                        task.wait(3)

                        -- Ejecutar remote una sola vez
                        local success = pcall(function()
                            return player
                                :WaitForChild("Remotes")
                                :WaitForChild("DungeonCompleted")
                                :InvokeServer("Continue")
                        end)

                        -- Notificación si se ejecutó bien
                        if success then
                            Library:Notify({
                                Title = "DupeSide",
                                Description = "Continuing dungeon.",
                                Time = 4
                            })
                        end
                    end

                    -- Guardar el estado actual para detectar nuevos eventos
                    lastState = currentState

                    task.wait(0.2)
                end
            end)
        end
    end
})


MainLeft:AddToggle("AutoEquipSword", {
    Text = "Auto Equip Sword",
    Default = false,
    Callback = function(value)
        autoEquipSword = value
    end
})


MainLeft:AddToggle("AutoAttack", {
    Text = "Auto Attack [M1]",
    Default = getgenv().AutoAttack,
    Callback = function(v) getgenv().AutoAttack = v end
})

MainLeft:AddToggle("AntiKillBricks", {
    Text = "Anti Kill Bricks",
    Default = getgenv().AntiKillBricks,
    Callback = function(v) getgenv().AntiKillBricks = v end
})


local AutoUseToggle = MainLeft:AddToggle("AutoUseAttackSkill", {
    Text = "Auto Use Skill",
    Default = false,
})


local Skill1 = ""
local Skill2 = ""
MainLeft:AddInput("SkillAttackinput1", {
    Default = "",
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = false,
    Text = "Skill #1",
    Tooltip = "Type the name of your Attack ability",
    Placeholder = "Example: Updraft",
    Callback = function(Value)
        Skill1 = Value
        print("[DupeSide] Attack Skill 1 set:", Skill1)
    end,
})

MainLeft:AddInput("SkillAttackinput2", {
    Default = "",
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = false,
    Text = "Skill #2",
    Tooltip = "Type the name of your Attack ability",
    Placeholder = "Example: Magentic Pulse",
    Callback = function(Value)
        Skill2 = Value
        print("[DupeSide] Attack Skill 2 set:", Skill2)
    end,
})



local teleportMethod = "Above"

MainLeft:AddDropdown("TeleportMethod", {
    Values = { "Behind", "Above", "Below" },
    Default = 1,
    Multi = false,
    Text = "Teleport Method",
    Callback = function(v)
        teleportMethod = v
    end
})

-- SLIDER CORREGIDO (FALTABA ROUNDING)
MainLeft:AddSlider("DistanceBehind", {
    Text = "Teleport Distance",
    Default = getgenv().DistanceBehind,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(v)
        getgenv().DistanceBehind = v
    end
})

MainLeft:AddSlider("TeleportSmoothness", {
    Text = "Teleport Smoothness",
    Default = getgenv().TeleportSmoothness,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        getgenv().TeleportSmoothness = v
    end
})

MainLeft:AddSlider("NearbyDistance", {
    Text = "Nearby Distance",
    Default = getgenv().InstantRange,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        getgenv().InstantRange = v
    end
})

-----------------------------------------------------------
-- auto parry UI
-----------------------------------------------------------

-- Auto Parry
MainRight:AddToggle("AutoParryEnabled", {
    Text = "Enable [AP]",
    Default = getgenv().AutoParryEnabled,
    Callback = function(value) getgenv().AutoParryEnabled = value end,
})
MainRight:AddSlider("ParryRange", {
    Text = "Parry Range",
    Default = getgenv().ParryRange, Min = 5, Max = 200, Rounding = 1,
    Callback = function(value) getgenv().ParryRange = value end,
})
MainRight:AddSlider("ParryCooldown", {
    Text = "Parry Cooldown",
    Default = getgenv().ParryCooldown, Min = 0.05, Max = 5, Rounding = 2,
    Callback = function(value) getgenv().ParryCooldown = value end,
})
MainRight:AddSlider("ParryCritDelay", {
    Text = "Parry [Critical] Cooldown",
    Default = getgenv().ParryCritDelay, Min = 0.01, Max = 5, Rounding = 2,
    Callback = function(value) getgenv().ParryCritDelay = value end,
})

-----------------------------------------------------------
-- Dungeon GroupBox UI
-----------------------------------------------------------

local MyButton = DungeonGroupBox:AddButton({
	Text = "Potential Teleport",
	Func = function()
		-- === TELEPORT AL ROOM MÁS CERCANO ===
		local Players = game:GetService("Players")
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")

		local potentials = workspace:FindFirstChild("Potentials")
		if not potentials then

			return
		end

		local closestPart = nil
		local shortestDistance = math.huge

		-- Buscar la parte más cercana que empiece con "Room"
		for _, part in pairs(potentials:GetChildren()) do
			if part:IsA("BasePart") and part.Name:lower():match("^room") then
				local distance = (hrp.Position - part.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestPart = part
				end
			end
		end

		if closestPart then
			-- Teleport una sola vez
			hrp.CFrame = closestPart.CFrame + Vector3.new(0, 5, 0)

		else

		end
	end,

	DoubleClick = false,
	Tooltip = "Teleport to potential",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
	Risky = false,
})


local BossDoorButton = DungeonGroupBox:AddButton({
	Text = "Boss Room Teleport",
	Func = function()
		-- === TELEPORT A ROOM999.BossDoor ===
		local Players = game:GetService("Players")
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")

		local bossDoor = workspace:FindFirstChild("MAP") 
			and workspace.MAP:FindFirstChild("Room999")
			and workspace.MAP.Room999:FindFirstChild("BossDoor")

		if bossDoor and bossDoor:IsA("BasePart") then
			hrp.CFrame = bossDoor.CFrame + Vector3.new(0, 5, 0)
		else

		end
	end,

	DoubleClick = false,
	Tooltip = "Teleport To Boss Door",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
	Risky = false,
})


local OtherCharsButton = DungeonGroupBox:AddButton({
	Text = "Item Teleport",
	Func = function()
		-- === TELEPORT AL MODEL MÁS CERCANO EN workspace.OtherChars ===
		local Players = game:GetService("Players")
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")

		local otherChars = workspace:FindFirstChild("OtherChars")
		if not otherChars then
			warn("No se encontró 'workspace.OtherChars'")
			return
		end

		local closestModel = nil
		local shortestDistance = math.huge

		-- Buscar el model más cercano (usando PrimaryPart o posición promedio)
		for _, model in pairs(otherChars:GetChildren()) do
			if model:IsA("Model") then
				local targetPos

				-- Usa PrimaryPart si existe, si no calcula el centro promedio
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
					local distance = (hrp.Position - targetPos).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestModel = model
					end
				end
			end
		end

		-- Teleport si se encontró un model
		if closestModel then
			local pos
			if closestModel.PrimaryPart then
				pos = closestModel.PrimaryPart.CFrame
			else
				-- Si no tiene PrimaryPart, intenta usar la primera parte válida
				local firstPart = closestModel:FindFirstChildWhichIsA("BasePart")
				if firstPart then
					pos = firstPart.CFrame
				end
			end

			if pos then
				hrp.CFrame = pos + Vector3.new(0, 5, 0)
			else
			end
		else
		end
	end,

	DoubleClick = false,
	Tooltip = "Teleport To Closest item/otherchar",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
	Risky = false,
})





-----------------------------------------------------------
-- Esp UI
-----------------------------------------------------------


-- Visual toggles (players only)
VisualLeft:AddToggle("ESPEnabled", { Text = "ESP Enable", Default = getgenv().ESPSettings.Enabled, Callback = function(v) getgenv().ESPSettings.Enabled = v end })
VisualLeft:AddToggle("ESPBox", { Text = "ESP Box", Default = getgenv().ESPSettings.ShowBox, Callback = function(v) getgenv().ESPSettings.ShowBox = v end })
VisualLeft:AddToggle("ESPName", { Text = "ESP Name", Default = getgenv().ESPSettings.ShowName, Callback = function(v) getgenv().ESPSettings.ShowName = v end })
VisualLeft:AddToggle("ESPHealth", { Text = "ESP Health", Default = getgenv().ESPSettings.ShowHealth, Callback = function(v) getgenv().ESPSettings.ShowHealth = v end })
VisualLeft:AddToggle("ESPTracer", { Text = "ESP Tracer", Default = getgenv().ESPSettings.ShowTracer, Callback = function(v) getgenv().ESPSettings.ShowTracer = v end })
VisualLeft:AddToggle("ESPDistance", { Text = "ESP Distance", Default = getgenv().ESPSettings.ShowDistance, Callback = function(v) getgenv().ESPSettings.ShowDistance = v end })

-- ESP Items toggles
VisualLeftItemsEsp:AddToggle("ItemESPEnabled", {
    Text = "ESP Enable",
    Default = getgenv().ItemESPSettings.Enabled,
    Callback = function(v)
        getgenv().ItemESPSettings.Enabled = v
        if ITEMesp and type(ITEMesp.SetEnabled) == "function" then pcall(function() ITEMesp.SetEnabled(v) end) end
    end
})
VisualLeftItemsEsp:AddToggle("ItemESPBox", {
    Text = "ESP Box",
    Default = getgenv().ItemESPSettings.ShowBox,
    Callback = function(v)
        getgenv().ItemESPSettings.ShowBox = v
        if ITEMesp and type(ITEMesp.SetBoxEnabled) == "function" then pcall(function() ITEMesp.SetBoxEnabled(v) end) end
    end
})
VisualLeftItemsEsp:AddToggle("ItemESPName", {
    Text = "ESP Name",
    Default = getgenv().ItemESPSettings.ShowName,
    Callback = function(v)
        getgenv().ItemESPSettings.ShowName = v
        if ITEMesp and type(ITEMesp.SetNameEnabled) == "function" then pcall(function() ITEMesp.SetNameEnabled(v) end) end
    end
})
VisualLeftItemsEsp:AddToggle("ItemESPDistance", {
    Text = "ESP Distance",
    Default = getgenv().ItemESPSettings.ShowDistance,
    Callback = function(v)
        getgenv().ItemESPSettings.ShowDistance = v
        if ITEMesp and type(ITEMesp.SetDistanceEnabled) == "function" then pcall(function() ITEMesp.SetDistanceEnabled(v) end) end
    end
})

-- NPC ESP toggles
VisualRight:AddToggle("NPCESPEnabled", { Text = "ESP Enable", Default = getgenv().NPCESPSettings.Enabled, Callback = function(v) getgenv().NPCESPSettings.Enabled = v end })
VisualRight:AddToggle("NPCESPBox", { Text = "ESP Box", Default = getgenv().NPCESPSettings.ShowBox, Callback = function(v) getgenv().NPCESPSettings.ShowBox = v end })
VisualRight:AddToggle("NPCESPName", { Text = "ESP Name", Default = getgenv().NPCESPSettings.ShowName, Callback = function(v) getgenv().NPCESPSettings.ShowName = v end })
VisualRight:AddToggle("NPCESPHealth", { Text = "ESP Health", Default = getgenv().NPCESPSettings.ShowHealthNumber, Callback = function(v) getgenv().NPCESPSettings.ShowHealthNumber = v end })
VisualRight:AddToggle("NPCESPTracer", { Text = "ESP Tracer", Default = getgenv().NPCESPSettings.ShowTracer, Callback = function(v) getgenv().NPCESPSettings.ShowTracer = v end })
VisualRight:AddToggle("NPCESPDistance", { Text = "ESP Distance", Default = getgenv().NPCESPSettings.ShowDistance, Callback = function(v) getgenv().NPCESPSettings.ShowDistance = v end })

-- Boss Room ESP Toggle
VisualRightBossRoom:AddToggle("BossRoomESP", {
    Text = "Esp Boss Room",
    Default = getgenv().BossRoomESP,
    Callback = function(value) 
        getgenv().BossRoomESP = value 
        -- Si está desactivado, eliminar ESPs existentes
        if not value then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "BossDoor" and obj:IsA("BasePart") then
                    local esp = obj:FindFirstChild("SixSeven")
                    if esp then esp:Destroy() end
                end
            end
        end
    end,
})





-----------------------------------------------------------
-- Player Movement UI
-----------------------------------------------------------

-- store currently selected key names (strings like "K", "V", "N") so we can handle presses ourselves
local FlyKey = "K"
local SpeedKey = "V"
local NoclipKey = "N"

PlayerLeft:AddToggle("FlyToggle", { Text = "Fly Toggle", Default = getgenv().FlyEnabled, Callback = function(v) getgenv().FlyEnabled = v end }):AddKeyPicker("FlyKeyPicker", { Default = "K", SyncToggleState = true, Mode = "Toggle", Text = "Fly Key", NoUI = false, Callback = function(Value) getgenv().FlyEnabled = Value if Toggles and Toggles.FlyToggle then Toggles.FlyToggle:SetValue(Value) end end, ChangedCallback = function(New) if New then FlyKey = tostring(New):gsub("Enum.KeyCode.", "") end print("[cb] Fly Keybind changed! ->", FlyKey) end })
PlayerLeft:AddToggle("SpeedActive", { Text = "Speed[B] Toggle", Default = getgenv().SpeedActive, Callback = function(v) getgenv().SpeedActive = v end }):AddKeyPicker("SpeedKeyPicker", { Default = "V", SyncToggleState = true, Mode = "Toggle", Text = "Speed Key", NoUI = false, Callback = function(Value) getgenv().SpeedActive = Value if Toggles and Toggles.SpeedActive then Toggles.SpeedActive:SetValue(Value) end end, ChangedCallback = function(New) if New then SpeedKey = tostring(New):gsub("Enum.KeyCode.", "") end print("[cb] Speed Keybind changed! ->", SpeedKey) end })
PlayerLeft:AddToggle("NoclipToggle", { Text = "Noclip Toggle", Default = getgenv().NoclipEnabled, Callback = function(v) getgenv().NoclipEnabled = v end }):AddKeyPicker("NoclipKeyPicker", { Default = "N", SyncToggleState = true, Mode = "Toggle", Text = "Noclip Key", NoUI = false, Callback = function(Value) getgenv().NoclipEnabled = Value if Toggles and Toggles.NoclipToggle then Toggles.NoclipToggle:SetValue(Value) end end, ChangedCallback = function(New) if New then NoclipKey = tostring(New):gsub("Enum.KeyCode.", "") end print("[cb] Noclip Keybind changed! ->", NoclipKey) end })


PlayerLeft:AddSlider("FlySpeed", { Text = "Fly Speed", Default = getgenv().FlySpeed, Min = 1, Max = 200, Rounding = 1, Callback = function(v) getgenv().FlySpeed = v end })
PlayerLeft:AddSlider("SpeedValue", { Text = "Speed[B] Slider", Default = getgenv().SpeedValue, Min = 1, Max = 500, Rounding = 1, Callback = function(v) getgenv().SpeedValue = v end })




-----------------------------------------------------------
-- UI SETTINGS SYSTEM
-----------------------------------------------------------


-- === UI Settings section (intact) ===
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value) Library:SetNotifySide(Value) end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

-- Managers

SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("DupeSideHub/Absolv")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:Notify({ Title = "DupeSide UI", Description = "DupeSide Succefully Loaded.", Time = 4 })
