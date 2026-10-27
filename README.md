# DollarUI

Pixel-perfect, high-performance **CS2 Neverlose-style** UI Library for Roblox.

![CS2 Neverlose Style](https://raw.githubusercontent.com/lucide-icons/lucide/master/icons/crosshair.svg)

## Features
- **CS2 Neverlose Aesthetics**: Authentic glass blur, Gotham typography, custom shaders and responsive cards.
- **Lucide Icons**: Built-in vector icons mapped from the official Lucide atlas.
- **Independent Scrollable Pages**: Smooth scrolling per category with zero stroke clipping.
- **Tactile Physics Animations**: Squash & stretch toggle switches, elastic sliders, and pop-down accordions.
- **Fingerprint Actions**: Minimalist Lucide fingerprint action buttons.
- **Full-featured Config Manager**: File-based presets (`configs/`), autoload on inject, and clipboard import/export.
- **Secret Settings Page**: Unload menu, glass blur intensity, scaling, and credits.

## Quick Start (Example)

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mullaxuldev/DollarUI/master/Library.lua"))()

-- Get category tab
local RageTab = Library:GetTab("rage")

-- Create section card (left or right column)
local RagebotSec = RageTab:CreateSection("left", "RAGEBOT")

-- Add elements
RagebotSec:AddToggle({
    Name = "enabled",
    Default = true,
    Callback = function(state)
        print("Ragebot:", state)
    end
})

RagebotSec:AddSlider({
    Name = "hit chance",
    Min = 0,
    Max = 100,
    Default = 50,
    Suffix = "%",
    Callback = function(val)
        print("Hit chance:", val)
    end
})

RagebotSec:AddDropdown({
    Name = "hitboxes",
    Options = { "all", "head", "chest", "arms" },
    Default = "all",
    Callback = function(opt)
        print("Hitbox:", opt)
    end
})

RagebotSec:AddInput({
    Name = "custom tag",
    Placeholder = "enter tag...",
    Callback = function(text)
        print("Tag:", text)
    end
})

RagebotSec:AddButton({
    Name = "quick action",
    Callback = function()
        print("Action executed!")
    end
})
```

## Config Manager API
- `Library:SaveConfig(name)` — saves current settings to `configs/<name>.json`.
- `Library:LoadConfig(name)` — loads settings from file or memory.
- `Library:SetAutoLoad(name)` — sets default config to load automatically on script inject.
- `Library:SetConfigsVisible(bool)` — toggle visibility of the configs tab.
- `Library.Unload()` — unloads UI and disconnects all events.
