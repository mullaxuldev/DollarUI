local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mullaxuldev/DollarUI/master/Library.lua"))()

-- Назначаем уникальную папку под наш хаб (чтобы конфиги разных игр/скриптов не смешивались)
Library:SetConfigFolder("LoneSurvival_Configs")

-- Управление окном: RightShift или Insert (можно переназначить)
-- Library:SetToggleKey(Enum.KeyCode.F)
-- Library:ToggleUI() -- программное скрытие/показ

-- =========================================================================
-- RAGE
-- =========================================================================
local RageTab = Library:GetTab("rage")

local RagebotSec = RageTab:CreateSection("left", "RAGEBOT")
RagebotSec:AddToggle({
    Name = "enabled",
    Default = true,
    Callback = function(state)
        print("Ragebot:", state)
    end
})
RagebotSec:AddKeybind({
    Name = "aimbot key",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("Aimbot bound to:", key.Name)
    end
})

local TargetingSec = RageTab:CreateSection("left", "TARGETING")
TargetingSec:AddMultiDropdown({
    Name = "hitboxes",
    Options = { "all", "head", "chest", "arms", "legs" },
    Default = { "head", "chest" },
    Callback = function(list)
        print("Hitboxes:", table.concat(list, ", "))
    end
})
TargetingSec:AddSlider({
    Name = "hit chance",
    Min = 0,
    Max = 100,
    Default = 53,
    Suffix = "%",
    Callback = function(val)
        print("Hit chance:", val)
    end
})

local FiringSec = RageTab:CreateSection("right", "FIRING")
FiringSec:AddToggle({ Name = "silent", Default = true })
FiringSec:AddToggle({ Name = "no spread", Default = true })
FiringSec:AddToggle({ Name = "auto stop", Default = false, IsLast = true })

local VisualSec = RageTab:CreateSection("right", "INDICATORS")
VisualSec:AddColorPicker({
    Name = "accent color",
    Default = Color3.fromRGB(220, 220, 225),
    Callback = function(color)
        print("Color:", color)
    end
})

-- =========================================================================
-- VISUALS
-- =========================================================================
local VisualsTab = Library:GetTab("visuals")

local EspSec = VisualsTab:CreateSection("left", "ESP")
EspSec:AddToggle({ Name = "enabled", Default = true })
EspSec:AddColorPicker({
    Name = "box color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(color)
        print("ESP color:", color)
    end
})
EspSec:AddMultiDropdown({
    Name = "drawings",
    Options = { "box", "skeleton", "health", "name", "weapon" },
    Default = { "box", "name" },
    IsLast = true
})

-- =========================================================================
-- MISC
-- =========================================================================
local MiscTab = Library:GetTab("miscellaneous")

local MoveSec = MiscTab:CreateSection("left", "MOVEMENT")
MoveSec:AddToggle({ Name = "auto bhop", Default = true })
MoveSec:AddKeybind({
    Name = "fly key",
    Default = Enum.KeyCode.F,
    IsLast = true,
    Callback = function(key)
        print("Fly bound to:", key.Name)
    end
})
