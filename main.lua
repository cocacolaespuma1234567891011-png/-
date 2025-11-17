-- main.lua parte 1
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/DerekLuaU/example/refs/heads/main/Library.lua"))(), "Failed to load Library")
local ThemeManager = assert(loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))(), "Failed to load ThemeManager")
local SaveManager = assert(loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))(), "Failed to load SaveManager")
local Options, Toggles = Library.Options, Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- UI WINDOW
local Window = Library:CreateWindow({
    Title = "DupeSide Hub",
    Footer = "version: 3.0.5",
    Icon = 123532668007594,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- UI TABS
local Tabs = {
    Main = Window:AddTab("Main", "layout-dashboard"),
    Visual = Window:AddTab("Visual", "eye"),
    Player = Window:AddTab("Movement", "zap"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- GROUPBOXES
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

-- DEFAULTS
getgenv().FlyEnabled = getgenv().FlyEnabled == nil and false or getgenv().FlyEnabled
getgenv().FlySpeed = getgenv().FlySpeed or 20
getgenv().NoclipEnabled = getgenv().NoclipEnabled == nil and false or getgenv().NoclipEnabled
getgenv().AutoParryEnabled = getgenv().AutoParryEnabled == nil and false or getgenv().AutoParryEnabled

-- main.lua parte 2

-- Fly Toggle
PlayerLeft:AddToggle("FlyToggle", {
    Text = "Fly Toggle",
    Default = getgenv().FlyEnabled,
    Callback = function(v)
        getgenv().FlyEnabled = v
        pcall(function()
            if v then getgenv().StartFly() else getgenv().StopFly() end
        end)
    end
})

-- Noclip Toggle
PlayerLeft:AddToggle("NoclipToggle", {
    Text = "Noclip Toggle",
    Default = getgenv().NoclipEnabled,
    Callback = function(v)
        getgenv().NoclipEnabled = v
        pcall(function() getgenv().Noclip() end)
    end
})

-- Speed Toggle & Slider
getgenv().SpeedActive = getgenv().SpeedActive == nil and false or getgenv().SpeedActive
getgenv().SpeedValue = getgenv().SpeedValue or 50

PlayerLeft:AddToggle("SpeedActive", {
    Text = "Speed[B] Toggle",
    Default = getgenv().SpeedActive,
    Callback = function(v)
        getgenv().SpeedActive = v
        pcall(function() getgenv().SpeedB() end)
    end
})

PlayerLeft:AddSlider("SpeedValue", {
    Text = "Speed[B] Slider",
    Default = getgenv().SpeedValue,
    Min = 1,
    Max = 500,
    Rounding = 1,
    Callback = function(v) getgenv().SpeedValue = v end
})

-- main.lua parte 3

-- AutoParry UI
MainRight:AddToggle("AutoParryEnabled", {
    Text = "Enable AutoParry",
    Default = getgenv().AutoParryEnabled,
    Callback = function(v)
        getgenv().AutoParryEnabled = v
        pcall(function() getgenv().AutoParry() end)
    end
})

getgenv().ParryRange = getgenv().ParryRange or 30
getgenv().ParryCooldown = getgenv().ParryCooldown or 0.5
getgenv().ParryCritDelay = getgenv().ParryCritDelay or 0.2

MainRight:AddSlider("ParryRange", {
    Text = "Parry Range",
    Default = getgenv().ParryRange, Min = 5, Max = 200, Rounding = 1,
    Callback = function(v) getgenv().ParryRange = v end,
})

MainRight:AddSlider("ParryCooldown", {
    Text = "Parry Cooldown",
    Default = getgenv().ParryCooldown, Min = 0.05, Max = 5, Rounding = 2,
    Callback = function(v) getgenv().ParryCooldown = v end,
})

MainRight:AddSlider("ParryCritDelay", {
    Text = "Parry [Critical] Cooldown",
    Default = getgenv().ParryCritDelay, Min = 0.01, Max = 5, Rounding = 2,
    Callback = function(v) getgenv().ParryCritDelay = v end,
})

-- AutoFarm UI
MainLeft:AddToggle("TeleportToggle", {
    Text = "Teleport Toggle",
    Default = getgenv().TeleportActive or false,
    Callback = function(v) getgenv().TeleportActive = v end
})

MainLeft:AddToggle("AutoCampfire", {
    Text = "Auto Campfire",
    Default = false,
})

getgenv().AutoStartDungeon = getgenv().AutoStartDungeon or false
MainLeft:AddToggle("AutoStartDungeon", {
    Text = "Auto Start Dungeon",
    Default = getgenv().AutoStartDungeon,
    Callback = function(value)
        getgenv().AutoStartDungeon = value
        pcall(function() getgenv().AutoStartDungeonFunc() end)
    end
})

getgenv().AutoContinueDungeon = getgenv().AutoContinueDungeon or false
MainLeft:AddToggle("AutoContinueDungeon", {
    Text = "Auto Continue Dungeon",
    Default = getgenv().AutoContinueDungeon,
    Callback = function(value)
        getgenv().AutoContinueDungeon = value
        pcall(function() getgenv().AutoContinueDungeonFunc() end)
    end
})

MainLeft:AddToggle("AutoEquipSword", {
    Text = "Auto Equip Sword",
    Default = false,
    Callback = function(v) getgenv().AutoEquipSword = v end
})

MainLeft:AddToggle("AutoAttack", {
    Text = "Auto Attack [M1]",
    Default = getgenv().AutoAttack or false,
    Callback = function(v) getgenv().AutoAttack = v end
})

MainLeft:AddToggle("AntiKillBricks", {
    Text = "Anti Kill Bricks",
    Default = getgenv().AntiKillBricks or false,
    Callback = function(v) getgenv().AntiKillBricks = v end
})


-- main.lua parte 5

-- ESP Player
VisualLeft:AddToggle("ESPEnabled", { Text = "ESP Enable", Default = getgenv().ESPSettings.Enabled, Callback = function(v) getgenv().ESPSettings.Enabled = v end })
VisualLeft:AddToggle("ESPBox", { Text = "ESP Box", Default = getgenv().ESPSettings.ShowBox, Callback = function(v) getgenv().ESPSettings.ShowBox = v end })
VisualLeft:AddToggle("ESPName", { Text = "ESP Name", Default = getgenv().ESPSettings.ShowName, Callback = function(v) getgenv().ESPSettings.ShowName = v end })
VisualLeft:AddToggle("ESPHealth", { Text = "ESP Health", Default = getgenv().ESPSettings.ShowHealth, Callback = function(v) getgenv().ESPSettings.ShowHealth = v end })
VisualLeft:AddToggle("ESPTracer", { Text = "ESP Tracer", Default = getgenv().ESPSettings.ShowTracer, Callback = function(v) getgenv().ESPSettings.ShowTracer = v end })
VisualLeft:AddToggle("ESPDistance", { Text = "ESP Distance", Default = getgenv().ESPSettings.ShowDistance, Callback = function(v) getgenv().ESPSettings.ShowDistance = v end })

-- SafePlace
SafePlaceRight:AddToggle("SafePlaceToggle", { Text = "Safe Place Toggle", Default = false })
SafePlaceRight:AddToggle("HealtSkill", { Text = "Use Healing Skill", Default = false })
SafePlaceRight:AddInput("SkillInput", {
    Default = "Lesser Heal",
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = false,
    Text = "Skill Name",
    Tooltip = "Type the name of your healing ability",
    Placeholder = "Example: Lesser Heal",
    Callback = function(Value) getgenv().HealSkill = Value print("[DupeSide] Healing skill set:", Value) end,
})
SafePlaceRight:AddSlider("HealtThresholdd", { Text = "Health Threshold", Default = 30, Min = 1, Max = 100, Rounding = 1 })
SafePlaceRight:AddSlider("healthRegenTargett", { Text = "Health Regen Target", Default = 50, Min = 1, Max = 100, Rounding = 1 })

-- Auto Potential
AutoPotentialLeft:AddToggle("AutoPotentialToggle", { Text = "Auto Potential Orb/Card", Default = false, Callback = function(v) getgenv().AutoPotentialEnabled = v end })
AutoPotentialLeft:AddToggle("AutoSelectArcaneToggle", { Text = "Auto Select Arcane/WildCard", Default = false, Callback = function(v) getgenv().AutoSelectArcaneActive = v end })
AutoPotentialLeft:AddDropdown("ArcaneDropdown", {
    Values = { "Disease","Earth","Fire","Frost","Holy","Lightning","Nature","Physical","Shadow","Water","Wind" },
    Default = 5,
    Multi = false,
    Text = "Arcane/Wildcard Type",
    Callback = function(Value) getgenv().SelectedArcane = Value end
})

-- UI SETTINGS
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(v) Library.ShowCustomCursor = v end })
MenuGroup:AddDropdown("NotificationSide", { Values = { "Left","Right" }, Default = "Right", Text = "Notification Side", Callback = function(v) Library:SetNotifySide(v) end })
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%","75%","100%","125%","150%","175%","200%" }, Default = "100%", Text = "DPI Scale", Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%",""))) end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

-- SaveManager Config
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("DupeSideHub/Absolv")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- Notification
Library:Notify({ Title = "DupeSide UI", Description = "DupeSide Successfully Loaded.", Time = 4 })
