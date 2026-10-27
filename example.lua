-- DollarUI CS2 Neverlose-style UI Library Example
-- GitHub: https://github.com/oaniggggga/DollarUI

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/oaniggggga/DollarUI/main/Library.lua"))()

-- 1. СЕКЦИИ ДЛЯ ВКЛАДКИ RAGE
local RageTab = Library:GetTab("rage")

local RagebotSec = RageTab:CreateSection("left", "RAGEBOT")
RagebotSec:AddToggle({ Name = "enabled", Default = true, IsLast = true })

local TargetingSec = RageTab:CreateSection("left", "TARGETING")
TargetingSec:AddSlider({ Name = "hit chance", Min = 0, Max = 100, Default = 53, Suffix = "%" })
TargetingSec:AddSlider({ Name = "min damage", Min = 0, Max = 100, Default = 70 })
TargetingSec:AddDropdown({ Name = "hitboxes", Options = { "all", "head", "chest", "arms" }, Default = "all" })
TargetingSec:AddSlider({ Name = "point scale", Min = 0, Max = 100, Default = 60, Suffix = "%" })
TargetingSec:AddToggle({ Name = "force body aim", Default = false, IsLast = true })

local FiringSec = RageTab:CreateSection("right", "FIRING")
FiringSec:AddToggle({ Name = "silent", Default = true })
FiringSec:AddToggle({ Name = "no spread", Default = true })
FiringSec:AddToggle({ Name = "force shot in air", Default = false })
FiringSec:AddToggle({ Name = "force shot on ground", Default = false })
FiringSec:AddToggle({ Name = "auto stop", Default = false, IsLast = true })

local AntiAimSec = RageTab:CreateSection("right", "ANTI AIM")
AntiAimSec:AddToggle({ Name = "anti aim", Default = false })
AntiAimSec:AddDropdown({ Name = "pitch", Options = { "down", "up", "zero" }, Default = "down" })
AntiAimSec:AddDropdown({ Name = "base", Options = { "backward", "forward", "freestanding" }, Default = "backward" })
AntiAimSec:AddSlider({ Name = "yaw offset", Min = -180, Max = 180, Default = 34, Suffix = "°", IsLast = true })

-- 2. СЕКЦИИ ДЛЯ ВКЛАДКИ LEGIT
local LegitTab = Library:GetTab("legit")
local LegitMain = LegitTab:CreateSection("left", "LEGITBOT")
LegitMain:AddToggle({ Name = "enabled", Default = false })
LegitMain:AddSlider({ Name = "field of view", Min = 0, Max = 30, Default = 6, Suffix = "°" })
LegitMain:AddSlider({ Name = "smooth", Min = 1, Max = 20, Default = 8, IsLast = true })

local TriggerSec = LegitTab:CreateSection("right", "TRIGGERBOT")
TriggerSec:AddToggle({ Name = "triggerbot", Default = false })
TriggerSec:AddSlider({ Name = "reaction delay", Min = 0, Max = 200, Default = 30, Suffix = "ms", IsLast = true })

-- 3. СЕКЦИИ ДЛЯ ВКЛАДКИ VISUALS
local VisualsTab = Library:GetTab("visuals")
local EspSec = VisualsTab:CreateSection("left", "PLAYERS")
EspSec:AddToggle({ Name = "bounding box", Default = true })
EspSec:AddToggle({ Name = "player name", Default = true })
EspSec:AddToggle({ Name = "health bar", Default = true })
EspSec:AddToggle({ Name = "chams", Default = false, IsLast = true })

local WorldSec = VisualsTab:CreateSection("right", "WORLD")
WorldSec:AddToggle({ Name = "bullet tracers", Default = true })
WorldSec:AddToggle({ Name = "nightmode", Default = false, IsLast = true })

-- 4. СЕКЦИИ ДЛЯ ВКЛАДКИ MISCELLANEOUS
local MiscTab = Library:GetTab("miscellaneous")
local MiscMain = MiscTab:CreateSection("left", "MAIN")
MiscMain:AddToggle({ Name = "auto bhop", Default = true })
MiscMain:AddToggle({ Name = "fast ladder", Default = false, IsLast = true })

local ServerSec = MiscTab:CreateSection("right", "SERVER")
ServerSec:AddToggle({ Name = "anti kick", Default = true, IsLast = true })


