local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- СИСТЕМА ПОЛНОГО АНЛОАДА ЧЕРЕЗ ГЛОБАЛЬНУЮ ПЕРЕМЕННУЮ PAPA
--------------------------------------------------------------------------------
local Env = (getgenv and getgenv()) or _G

if Env.PAPA and type(Env.PAPA.Unload) == "function" then
    pcall(Env.PAPA.Unload)
end

local Connections = {}
local InstancesToDestroy = {}

local function trackConn(conn)
    table.insert(Connections, conn)
    return conn
end

local function trackInst(inst)
    table.insert(InstancesToDestroy, inst)
    return inst
end

Env.PAPA = {
    Connections = Connections,
    Instances = InstancesToDestroy,
    Unload = function()
        for _, conn in ipairs(Connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        for _, inst in ipairs(InstancesToDestroy) do
            if inst and inst.Parent then
                inst:Destroy()
            end
        end
        table.clear(Connections)
        table.clear(InstancesToDestroy)
        Env.PAPA = nil
    end,
}

local function Cleanup()
    if Env.PAPA and type(Env.PAPA.Unload) == "function" then
        Env.PAPA.Unload()
    end
end

-- На случай если остались старые хвосты без таблицы
for _, parent in ipairs({ PlayerGui, CoreGui, Lighting, workspace.CurrentCamera }) do
    pcall(function()
        if parent:FindFirstChild("DollarhackUI") then parent.DollarhackUI:Destroy() end
        if parent:FindFirstChild("DollarhackBlur") then parent.DollarhackBlur:Destroy() end
        if parent:FindFirstChild("DollarhackGlass") then parent.DollarhackGlass:Destroy() end
        if parent:FindFirstChild("DollarhackDoF") then parent.DollarhackDoF:Destroy() end
    end)
end

--------------------------------------------------------------------------------
-- ШРИФТЫ И ПАЛИТРА (СВЕРКА С РЕФЕРЕНСОМ)
--------------------------------------------------------------------------------
local Fonts = {
    Regular = Font.fromEnum(Enum.Font.GothamMedium),
    Medium = Font.fromEnum(Enum.Font.GothamMedium),
    SemiBold = Font.fromEnum(Enum.Font.GothamMedium),
    Bold = Font.fromEnum(Enum.Font.GothamBold),
}



local Theme = {
    WindowBg = Color3.fromRGB(24, 24, 27),       -- Чистый тёмный графит фона окна (#18181b)
    SidebarBg = Color3.fromRGB(20, 20, 22),      -- Сайдбар
    ContentBg = Color3.fromRGB(24, 24, 27),      -- Контент
    CardFill = Color3.fromRGB(24, 24, 27),       -- Карточки секций: 1 в 1 тон фона окна (#18181b)
    PillBarBg = Color3.fromRGB(28, 28, 32),      -- Капсула оружия (#1c1c20)
    DropdownBg = Color3.fromRGB(20, 20, 23),     -- Внутренность селектора
    PopupBg = Color3.fromRGB(22, 22, 25),        -- Всплывающий список
    SearchBtnBg = Color3.fromRGB(28, 28, 32),    -- Кнопка лупы
    StrokeOuter = Color3.fromRGB(52, 52, 58),    -- Мягкий внешний контур окна
    StrokeInner = Color3.fromRGB(56, 56, 64),    -- Тонкий контур карточек
    Divider = Color3.fromRGB(72, 72, 82),        -- Разделительные линии (светлее, четко видны)
    TextWhite = Color3.fromRGB(246, 246, 248),   -- Основной чистый текст
    TextGray = Color3.fromRGB(188, 188, 192),    -- Неактивные пункты и иконки
    TextMuted = Color3.fromRGB(132, 132, 138),   -- Заголовки RAGEBOT / TARGETING
    TextValues = Color3.fromRGB(178, 178, 182),  -- Цифры 53%, 70 справа
    Accent = Color3.fromRGB(254, 254, 255),      -- Белый акцент
    ActiveText = Color3.fromRGB(24, 24, 26),     -- Темный текст на активном белом
    ToggleOff = Color3.fromRGB(62, 62, 66),      -- Выключенный тумблер
    SliderTrack = Color3.fromRGB(94, 94, 98),    -- Незаполненный трек слайдера
    ToggleKnobOn = Color3.fromRGB(24, 24, 26),   -- Темная точка включенного тумблера
}

local ScreenGui = trackInst(Instance.new("ScreenGui"))
ScreenGui.Name = "DollarhackUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local function getSafeGuiParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if CoreGui and pcall(function() return CoreGui:GetChildren() end) then
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, ScreenGui)
        end
        return CoreGui
    end
    return PlayerGui
end
ScreenGui.Parent = getSafeGuiParent()

-- Хелперы
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.StrokeInner
    s.Thickness = thickness or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function makeBox(parent, pos, size, color, radius, rot, trans)
    local f = Instance.new("Frame")
    f.Position = pos
    f.Size = size
    f.BackgroundColor3 = color
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    if rot then f.Rotation = rot end
    f.Parent = parent
    if radius and radius > 0 then addCorner(f, radius) end
    return f
end

--------------------------------------------------------------------------------
-- ГЛАВНОЕ ОКНО (ОДИН СКРУГЛЕННЫЙ ПОЛУПРОЗРАЧНЫЙ ФОН С ГРАДИЕНТОМ ПРОЗРАЧНОСТИ)
--------------------------------------------------------------------------------
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 860, 0, 560)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
MainWindow.BackgroundColor3 = Theme.WindowBg
MainWindow.BackgroundTransparency = 0.08
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui
addCorner(MainWindow, 16)

local WindowScale = Instance.new("UIScale")
WindowScale.Scale = 1
WindowScale.Parent = MainWindow

-- Объемный внешний контур окна с эффектом преломления света на фаске (сверху ярче)
local mainStroke = addStroke(MainWindow, Theme.StrokeOuter, 1.2, 0.1)
local mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Rotation = 90
mainStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(120, 120, 130)), -- верхняя фаска окна со светом
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(72, 72, 78)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(42, 42, 46)),    -- теневой низ
})
mainStrokeGrad.Parent = mainStroke

--------------------------------------------------------------------------------
-- СТЕКЛЯННАЯ ПОДЛОЖКА ТОЛЬКО ПОД ОКНОМ (МНОГОСЛОЙНЫЙ КАСКАД ДЛЯ МАКСИМАЛЬНОЙ КАШИ)
--------------------------------------------------------------------------------
local Camera = workspace.CurrentCamera

-- Многослойный каскад стекла + преломления (Glass Refraction)
-- В Roblox гласс-материал при высоком Graphic Level даёт физическое преломление (хроматика и искажение света по краям)
local GLASS_LAYERS = 3
local GlassParts = {}

for i = 1, GLASS_LAYERS do
    local p = trackInst(Instance.new("Part"))
    p.Name = "DollarhackGlass_" .. i
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Glass
    p.Transparency = 0.965 -- чуть плотнее для выраженного преломления света и размытия
    p.Color = Color3.fromRGB(245, 245, 252)
    GlassParts[i] = p
end

-- Дополнительный каскад блюра специально для открытого селектора (дропдауна)
local PopupGlassParts = {}
for i = 1, 3 do
    local p = trackInst(Instance.new("Part"))
    p.Name = "DollarhackPopupGlass_" .. i
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Glass
    p.Transparency = 0.965
    p.Color = Color3.fromRGB(245, 245, 252)
    PopupGlassParts[i] = p
end

local activePopup = nil
local activePopupClose = nil

local Library = {}
Library.Registry = {}

-- DoF настроен на максимальное размытие передней плоскости:
local DoF = trackInst(Instance.new("DepthOfFieldEffect"))
DoF.Name = "DollarhackDoF"
DoF.FarIntensity = 0
DoF.NearIntensity = 1
DoF.FocusDistance = 51.6
DoF.InFocusRadius = 50
DoF.Enabled = true
DoF.Parent = Lighting

local GLASS_DEPTH = 1.0
local GLASS_INSET_X = 8
local GLASS_INSET_Y = 8

trackConn(RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    if not MainWindow.Visible then
        for i = 1, GLASS_LAYERS do
            local p = GlassParts[i]
            if p and p.Parent then p.Parent = nil end
        end
        for i = 1, #PopupGlassParts do
            local pp = PopupGlassParts[i]
            if pp and pp.Parent then pp.Parent = nil end
        end
        if DoF and DoF.Parent then DoF.Enabled = false end
        return
    else
        if DoF and DoF.Parent then DoF.Enabled = true end
    end

    local vp = Camera.ViewportSize
    if vp.Y <= 0 then return end

    local pos = MainWindow.AbsolutePosition
    local size = MainWindow.AbsoluteSize

    local topInset = GuiService:GetGuiInset()
    local x1 = pos.X + GLASS_INSET_X
    local y1 = pos.Y + topInset.Y + GLASS_INSET_Y
    local x2 = pos.X + size.X - GLASS_INSET_X
    local y2 = pos.Y + topInset.Y + size.Y - GLASS_INSET_Y

    local rayTL = Camera:ViewportPointToRay(x1, y1)
    local rayBR = Camera:ViewportPointToRay(x2, y2)

    local camCF = Camera.CFrame
    local vTL = camCF:VectorToObjectSpace(rayTL.Direction)
    local vBR = camCF:VectorToObjectSpace(rayBR.Direction)

    if vTL.Z >= 0 or vBR.Z >= 0 then return end

    local scaleTL = -GLASS_DEPTH / vTL.Z
    local scaleBR = -GLASS_DEPTH / vBR.Z

    local localTL = vTL * scaleTL
    local localBR = vBR * scaleBR

    local width = math.max(0.1, math.abs(localBR.X - localTL.X))
    local height = math.max(0.1, math.abs(localTL.Y - localBR.Y))

    for i = 1, GLASS_LAYERS do
        local p = GlassParts[i]
        if p.Parent ~= Camera then p.Parent = Camera end
        -- Микросмещение слоев по глубине умножает размытие DoF в несколько раз
        local depthOffset = (i - 1) * 0.03
        local localCenter = Vector3.new((localTL.X + localBR.X) / 2, (localTL.Y + localBR.Y) / 2, -GLASS_DEPTH - depthOffset)
        p.Size = Vector3.new(width, height, 0.01)
        p.CFrame = camCF * CFrame.new(localCenter)
    end

    -- Дополнительный блюр под открытым выпадающим списком селектора
    if activePopup and activePopup.Visible and activePopup.AbsoluteSize.Y > 10 then
        local pPos = activePopup.AbsolutePosition
        local pSize = activePopup.AbsoluteSize
        local px1 = pPos.X + 1
        local py1 = pPos.Y + topInset.Y + 1
        local px2 = pPos.X + pSize.X - 1
        local py2 = pPos.Y + topInset.Y + pSize.Y - 1

        local prayTL = Camera:ViewportPointToRay(px1, py1)
        local prayBR = Camera:ViewportPointToRay(px2, py2)
        local pvTL = camCF:VectorToObjectSpace(prayTL.Direction)
        local pvBR = camCF:VectorToObjectSpace(prayBR.Direction)

        if pvTL.Z < 0 and pvBR.Z < 0 then
            local pDist = 0.94
            local pScaleTL = -pDist / pvTL.Z
            local pScaleBR = -pDist / pvBR.Z
            local pLocalTL = pvTL * pScaleTL
            local pLocalBR = pvBR * pScaleBR
            local pW = math.max(0.02, math.abs(pLocalBR.X - pLocalTL.X))
            local pH = math.max(0.02, math.abs(pLocalTL.Y - pLocalBR.Y))

            for i = 1, #PopupGlassParts do
                local pp = PopupGlassParts[i]
                if pp.Parent ~= Camera then pp.Parent = Camera end
                local pCenter = Vector3.new((pLocalTL.X + pLocalBR.X) / 2, (pLocalTL.Y + pLocalBR.Y) / 2, -pDist - (i - 1) * 0.025)
                pp.Size = Vector3.new(pW, pH, 0.005)
                pp.CFrame = camCF * CFrame.new(pCenter)
            end
        end
    else
        for i = 1, #PopupGlassParts do
            local pp = PopupGlassParts[i]
            if pp.Parent then pp.Parent = nil end
        end
    end
end))

-- Оверлей для открытых выпадающих списков (висит прямо в MainWindow с наивысшим ZIndex)
local OverlayLayer = Instance.new("Frame")
OverlayLayer.Name = "OverlayLayer"
OverlayLayer.Size = UDim2.new(1, 0, 1, 0)
OverlayLayer.BackgroundTransparency = 1
OverlayLayer.ZIndex = 200
OverlayLayer.Parent = MainWindow

-- Ультраплавное перетаскивание окна (120+ FPS критический демпфер / Exponential Smoothing)
local dragging = false
local dragMouseStart = Vector2.zero
local dragWinStart = Vector2.zero
local currentDragOffset = Vector2.zero
local targetDragOffset = Vector2.zero
local normalPos = UDim2.new(0.5, 0, 0.5, 0)
local normalSize = UDim2.new(0, 860, 0, 560)

trackConn(MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if (input.Position.Y - MainWindow.AbsolutePosition.Y) <= 56 then
            dragging = true
            dragMouseStart = Vector2.new(input.Position.X, input.Position.Y)
            dragWinStart = Vector2.new(MainWindow.Position.X.Offset, MainWindow.Position.Y.Offset)
            currentDragOffset = dragWinStart
            targetDragOffset = dragWinStart
        end
    end
end))

trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

-- Частото-независимая интерполяция 120 FPS (критическое сглаживание без задержек и ступенек)
trackConn(RunService.RenderStepped:Connect(function(dt)
    if dragging then
        local mousePos = UserInputService:GetMouseLocation()
        local topInset = GuiService:GetGuiInset()
        local curMouse = Vector2.new(mousePos.X, mousePos.Y - topInset.Y)
        local deltaX = curMouse.X - dragMouseStart.X
        local deltaY = curMouse.Y - dragMouseStart.Y
        targetDragOffset = dragWinStart + Vector2.new(deltaX, deltaY)
    end

    if dragging or (currentDragOffset - targetDragOffset).Magnitude > 0.05 then
        -- 1 - math.exp(-38 * dt) даёт идеальный шелковистый отклик и на 60, и на 120, и на 240 FPS
        local alpha = 1 - math.exp(-38 * math.clamp(dt, 0.001, 0.05))
        currentDragOffset = currentDragOffset:Lerp(targetDragOffset, alpha)
        normalPos = UDim2.new(MainWindow.Position.X.Scale, currentDragOffset.X, MainWindow.Position.Y.Scale, currentDragOffset.Y)
        MainWindow.Position = normalPos
    end
end))

local function setMenuVisible(vis)
    if isToggling then return end
    if vis == menuOpen then return end
    isToggling = true

    if vis then
        menuOpen = true
        MainWindow.Visible = true
        if DoF and DoF.Parent then
            DoF.Enabled = true
            DoF.NearIntensity = 0
            TweenService:Create(DoF, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { NearIntensity = 1 }):Play()
        end

        local startT = tick()
        local duration = 0.38
        while true do
            local elapsed = tick() - startT
            local alpha = math.clamp(elapsed / duration, 0, 1)
            -- Эластичная интерполяция OutBack
            local t = alpha - 1
            local ease = (t * t * ((1.70158 + 1) * t + 1.70158) + 1)

            -- Воронка: снизу узкое горлышко (pinch), раскрывающееся в нормальный прямоугольник
            local currentScale = 0.4 + 0.6 * ease
            WindowScale.Scale = currentScale

            -- Позиция поднимается снизу
            local curY = 1.2 - 0.7 * ease
            MainWindow.Position = UDim2.new(normalPos.X.Scale, normalPos.X.Offset, curY, normalPos.Y.Offset)

            -- Пропорции: от сплющенной воронки к нормальным размерам
            local curW = normalSize.X.Offset * (0.3 + 0.7 * ease)
            local curH = normalSize.Y.Offset * (0.2 + 0.8 * ease)
            MainWindow.Size = UDim2.new(0, curW, 0, curH)

            if alpha >= 1 then break end
            RunService.RenderStepped:Wait()
        end

        MainWindow.Position = normalPos
        MainWindow.Size = normalSize
        WindowScale.Scale = 1
        isToggling = false
    else
        menuOpen = false
        if activePopup then
            if activePopupClose then activePopupClose() else activePopup.Visible = false end
        end

        if DoF and DoF.Parent then
            TweenService:Create(DoF, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { NearIntensity = 0 }):Play()
        end

        local startT = tick()
        local duration = 0.34
        local originPos = MainWindow.Position
        while true do
            local elapsed = tick() - startT
            local alpha = math.clamp(elapsed / duration, 0, 1)
            -- Ускоряющаяся интерполяция InCubic / InExpo (эффект черной дыры / пылесоса)
            local ease = alpha * alpha * alpha

            -- ВОРОНКА: по мере затягивания вниз ширина сжимается в конус/воронку в разы быстрее, чем высота
            local curW = normalSize.X.Offset * (1 - ease * 0.92)  -- сжимается до 8% от ширины (острие воронки)
            local curH = normalSize.Y.Offset * (1 - ease * 0.75)  -- высота утягивается следом
            local curScale = 1 - ease * 0.65

            -- Центр масс смещается резко вниз к точке всасывания
            local curY = originPos.Y.Scale + (1.25 - originPos.Y.Scale) * ease
            MainWindow.Position = UDim2.new(originPos.X.Scale, originPos.X.Offset, curY, originPos.Y.Offset)
            MainWindow.Size = UDim2.new(0, math.max(10, curW), 0, math.max(10, curH))
            WindowScale.Scale = math.max(0.05, curScale)

            if alpha >= 1 then break end
            RunService.RenderStepped:Wait()
        end

        MainWindow.Visible = false
        MainWindow.Position = normalPos
        MainWindow.Size = normalSize
        WindowScale.Scale = 1
        if DoF and DoF.Parent then DoF.Enabled = false end
        isToggling = false
    end
end

function Library:ToggleUI()
    setMenuVisible(not menuOpen)
end

function Library:SetToggleKey(keyCode)
    if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
        toggleKey = keyCode
    elseif type(keyCode) == "string" and Enum.KeyCode[keyCode] then
        toggleKey = Enum.KeyCode[keyCode]
    end
end

trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Library._KeybindListening then return end
    if input.KeyCode == toggleKey or input.KeyCode == Enum.KeyCode.Insert then
        Library:ToggleUI()
    end
end))


--------------------------------------------------------------------------------
-- ВЕКТОРНЫЕ ИКОНКИ НАВИГАЦИИ И ОРУЖИЯ
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- LUCIDE ICONS ATLAS (ОФИЦИАЛЬНЫЙ LUCIDE-ROBLOX ВЕКТОРНЫЙ ПАКЕТ)
--------------------------------------------------------------------------------
local LucideAtlas = {
    ["crosshair"] = { id = 16898613044, size = Vector2.new(48, 48), offset = Vector2.new(453, 869) },
    ["target"]    = { id = 16898613869, size = Vector2.new(48, 48), offset = Vector2.new(514, 771) },
    ["eye"]       = { id = 16898613353, size = Vector2.new(48, 48), offset = Vector2.new(771, 563) },
    ["settings"]  = { id = 16898613777, size = Vector2.new(48, 48), offset = Vector2.new(771, 257) },
    ["cog"]       = { id = 16898613044, size = Vector2.new(48, 48), offset = Vector2.new(918, 563) },
    ["code"]      = { id = 16898612629, size = Vector2.new(48, 48), offset = Vector2.new(918, 808) },
    ["search"]    = { id = 16898613699, size = Vector2.new(48, 48), offset = Vector2.new(918, 857) },
    ["sliders"]   = { id = 16898613777, size = Vector2.new(48, 48), offset = Vector2.new(404, 771) },
    ["shield"]    = { id = 16898613777, size = Vector2.new(48, 48), offset = Vector2.new(869, 0) },
    ["zap"]       = { id = 16898613869, size = Vector2.new(48, 48), offset = Vector2.new(918, 906) },
    ["activity"]  = { id = 16898612629, size = Vector2.new(48, 48), offset = Vector2.new(514, 771) },
    ["user"]      = { id = 16898613869, size = Vector2.new(48, 48), offset = Vector2.new(661, 869) },
    ["check"]     = { id = 16898617411, size = Vector2.new(256, 256), offset = Vector2.new(257, 0) },
    ["chevron-down"]  = { id = 16898612819, size = Vector2.new(48, 48), offset = Vector2.new(196, 918) },
    ["chevron-right"] = { id = 16898617509, size = Vector2.new(256, 256), offset = Vector2.new(0, 514) },
    ["fingerprint"]   = { id = 16898613353, size = Vector2.new(48, 48), offset = Vector2.new(563, 918) },
}

local function createLucideIcon(parent, iconName, size, color)
    local data = LucideAtlas[iconName] or LucideAtlas["settings"]
    local img = Instance.new("ImageLabel")
    img.Name = "LucideIcon_" .. tostring(iconName)
    img.Size = UDim2.new(0, size, 0, size)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. data.id
    img.ImageRectSize = data.size
    img.ImageRectOffset = data.offset
    img.ImageColor3 = color or Color3.fromRGB(255, 255, 255)
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = parent
    return img
end

local function drawNavIcon(parent, id, color)
    local nameMap = {
        rage = "crosshair",
        legit = "target",
        visuals = "eye",
        inventory = "shield",
        movement = "activity",
        miscellaneous = "settings",
        config = "sliders",
        configs = "sliders",
        scripts = "code",
    }
    local iconKey = nameMap[id] or "settings"
    local icon = createLucideIcon(parent, iconKey, 18, color)
    icon.Position = UDim2.new(0, 14, 0.5, -9)

    return function(newColor)
        icon.ImageColor3 = newColor
    end
end
local function drawWeaponSilhouette(parent, weaponType, color)
    local icon = Instance.new("Frame")
    icon.Name = "WeaponSilhouette"
    icon.Size = UDim2.new(0, 36, 0, 18)
    icon.BackgroundTransparency = 1
    icon.Parent = parent

    local parts = {}
    local function box(x, y, w, h, r, rot)
        local b = makeBox(icon, UDim2.new(0, x, 0, y), UDim2.new(0, w, 0, h), color, r or 1, rot)
        table.insert(parts, b)
        return b
    end

    if weaponType == "pistols" then
        box(8, 4, 15, 4, 1)
        box(8, 7, 4, 7, 1, 16)
        box(13, 8, 4, 1.5, 0)
    elseif weaponType == "heavy_pistol" then
        box(6, 4, 19, 5, 1)
        box(7, 8, 5, 7, 1, 16)
        box(12, 9, 5, 1.5, 0)
    elseif weaponType == "smg" then
        box(5, 5, 17, 4, 1)
        box(22, 6, 6, 2, 0)
        box(8, 9, 4, 6, 1, 10)
        box(15, 9, 3, 6, 0)
        box(2, 6, 4, 2, 0)
    elseif weaponType == "rifle" then
        box(2, 6, 7, 4, 1, 8)
        box(8, 5, 14, 4, 1)
        box(22, 6, 10, 2, 0)
        box(10, 9, 3, 5, 1, 14)
        box(16, 9, 3.5, 6, 1, -18)
    elseif weaponType == "m4" then
        box(2, 5, 6, 5, 1)
        box(8, 5, 13, 4.5, 1)
        box(21, 6, 11, 2, 0)
        box(10, 9, 3, 5, 1, 12)
        box(15, 9, 3.5, 5, 1, -8)
    elseif weaponType == "shotgun" then
        box(2, 7, 8, 3.5, 1, 10)
        box(9, 5, 14, 3.5, 1)
        box(23, 5, 11, 1.5, 0)
        box(23, 7, 8, 1.5, 0)
    elseif weaponType == "scout" then
        box(2, 6, 8, 3.5, 1)
        box(10, 5, 12, 3.5, 1)
        box(22, 6, 13, 1.5, 0)
        box(13, 2, 8, 2, 1)
        box(11, 8.5, 3, 5, 1, 12)
    elseif weaponType == "awp" then
        box(1, 5, 8, 4.5, 1)
        box(9, 5, 13, 4.5, 1)
        box(22, 6, 13, 2, 0)
        box(11, 2, 10, 2, 1)
        box(14, 9.5, 4, 3, 0)
    elseif weaponType == "auto" then
        box(1, 5, 7, 4.5, 1)
        box(8, 4, 14, 4.5, 1)
        box(22, 6, 11, 2, 0)
        box(11, 2, 9, 2, 1)
        box(9, 8.5, 3, 5, 1, 12)
        box(15, 8.5, 4, 5, 0)
    end

    return icon, function(newColor)
        for _, p in ipairs(parts) do
            p.BackgroundColor3 = newColor
        end
    end
end

--------------------------------------------------------------------------------
-- ЛЕВЫЙ САЙДБАР (фон рисует градиент MainWindow, поэтому сам фрейм прозрачный)
--------------------------------------------------------------------------------
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

-- Вертикальная разделительная линия между сайдбаром и правой частью (мягкая заблюренная)
do
    local vLine = Instance.new("Frame")
    vLine.Position = UDim2.new(1, -1, 0, 0)
    vLine.Size = UDim2.new(0, 1, 1, 0)
    vLine.BackgroundColor3 = Theme.Divider
    vLine.BackgroundTransparency = 0.2
    vLine.BorderSizePixel = 0
    vLine.Parent = Sidebar

    local vGrad = Instance.new("UIGradient")
    vGrad.Rotation = 90
    vGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.8),
        NumberSequenceKeypoint.new(0.08, 0.25),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.92, 0.25),
        NumberSequenceKeypoint.new(1.0, 0.8),
    })
    vGrad.Parent = vLine
end

-- Логотип "$ dollarhack"
local LogoSym = Instance.new("TextLabel")
LogoSym.Size = UDim2.new(0, 24, 0, 28)
LogoSym.Position = UDim2.new(0, 18, 0, 16)
LogoSym.BackgroundTransparency = 1
LogoSym.Text = "$"
LogoSym.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
LogoSym.Font = Enum.Font.GothamBold
LogoSym.TextSize = 21
LogoSym.TextColor3 = Theme.Accent
LogoSym.Parent = Sidebar

local LogoTitle = Instance.new("TextLabel")
LogoTitle.Size = UDim2.new(0, 120, 0, 28)
LogoTitle.Position = UDim2.new(0, 44, 0, 16)
LogoTitle.BackgroundTransparency = 1
LogoTitle.Text = "dollarhack"
LogoTitle.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
LogoTitle.Font = Enum.Font.GothamBold
LogoTitle.TextSize = 15
LogoTitle.TextColor3 = Theme.TextWhite
LogoTitle.TextXAlignment = Enum.TextXAlignment.Left
LogoTitle.Parent = Sidebar

-- Навигация
local NavList = Instance.new("Frame")
NavList.Size = UDim2.new(1, -20, 0, 360)
NavList.Position = UDim2.new(0, 10, 0, 74)
NavList.BackgroundTransparency = 1
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavList

local navConfig = {
    { id = "rage", label = "rage", active = true },
    { id = "legit", label = "legit" },
    { id = "visuals", label = "visuals" },
    { id = "inventory", label = "inventory" },
    { id = "movement", label = "movement" },
    { id = "miscellaneous", label = "miscellaneous" },
    { id = "scripts", label = "scripts" },
}

local navMap = {}
local HeaderTitle
local TabPages = {}
local currentTabId = "rage"
local WeaponBar
local ChevronBtn, ChevronIcon

local function switchTab(targetId)
    currentTabId = targetId
    for id, n in pairs(navMap) do
        local isActive = (id == targetId)
        TweenService:Create(n.btn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = isActive and 0 or 1,
            BackgroundColor3 = isActive and Theme.Accent or Color3.fromRGB(18, 18, 20)
        }):Play()
        TweenService:Create(n.lbl, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = isActive and Theme.ActiveText or Theme.TextGray
        }):Play()
        n.setColor(isActive and Theme.ActiveText or Theme.TextGray)

        if TabPages[id] and TabPages[id].Scroll then
            local page = TabPages[id].Scroll
            if isActive then
                page.Visible = true
                local targetY = (id == "rage" or id == "legit") and 126 or 72
                page.Position = UDim2.new(0, 18, 0, targetY + 8)
                TweenService:Create(page, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 18, 0, targetY)
                }):Play()
            else
                page.Visible = false
            end
        end
    end

    -- Если открыта секретная страница настроек
    if TabPages["settings"] and TabPages["settings"].Scroll then
        local isSettings = (targetId == "settings")
        local page = TabPages["settings"].Scroll
        if isSettings then
            page.Visible = true
            page.Position = UDim2.new(0, 18, 0, 80)
            TweenService:Create(page, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 18, 0, 72)
            }):Play()
        else
            page.Visible = false
        end
    end

    if ChevronBtn and ChevronIcon then
        local isSettings = (targetId == "settings")
        TweenService:Create(ChevronBtn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = isSettings and Theme.Accent or Theme.CardFill,
            BackgroundTransparency = isSettings and 0 or 1
        }):Play()
        TweenService:Create(ChevronIcon, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            ImageColor3 = isSettings and Theme.ActiveText or Theme.TextGray,
            Rotation = isSettings and 90 or 0
        }):Play()
    end

    if HeaderTitle then
        HeaderTitle.Text = targetId
    end

    -- Полоска оружия (WeaponBar) с плавной прозрачностью и анимацией появления
    if WeaponBar then
        local showWeapon = (targetId == "rage" or targetId == "legit")
        if showWeapon then
            WeaponBar.Visible = true
            WeaponBar.Position = UDim2.new(0, 20, 0, 68)
            TweenService:Create(WeaponBar, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 20, 0, 72),
                BackgroundTransparency = 0
            }):Play()
        else
            WeaponBar.Visible = false
        end
    end
end

for idx, item in ipairs(navConfig) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = item.active and Theme.Accent or Color3.fromRGB(18, 18, 20)
    btn.BackgroundTransparency = item.active and 0 or 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = idx
    btn.Parent = NavList
    addCorner(btn, 8)

    local initCol = item.active and Theme.ActiveText or Theme.TextGray
    local setIconColor = drawNavIcon(btn, item.id, initCol)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.new(0, 42, 0, 0)
    lbl.RichText = true
    lbl.BackgroundTransparency = 1
    lbl.Text = item.label
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextColor3 = initCol
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    navMap[item.id] = { btn = btn, lbl = lbl, setColor = setIconColor }

    trackConn(btn.MouseButton1Click:Connect(function()
        switchTab(item.id)
    end))
end

-- КНОПКА CONFIGS (ВСЕГДА В САМОМ НИЗУ САЙДБАРА НАД ПРОФИЛЕМ)
local ConfigsBtn = Instance.new("TextButton")
ConfigsBtn.Name = "ConfigsNavBtn"
ConfigsBtn.Size = UDim2.new(1, -20, 0, 36)
ConfigsBtn.Position = UDim2.new(0, 10, 1, -108)
ConfigsBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
ConfigsBtn.BackgroundTransparency = 1
ConfigsBtn.Text = ""
ConfigsBtn.AutoButtonColor = false
ConfigsBtn.Visible = true
ConfigsBtn.Parent = Sidebar
addCorner(ConfigsBtn, 8)

local configsIconColorSetter = drawNavIcon(ConfigsBtn, "configs", Theme.TextGray)

local configsLbl = Instance.new("TextLabel")
configsLbl.Size = UDim2.new(1, -44, 1, 0)
configsLbl.Position = UDim2.new(0, 42, 0, 0)
configsLbl.RichText = true
configsLbl.BackgroundTransparency = 1
configsLbl.Text = "configs"
configsLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
configsLbl.Font = Enum.Font.GothamBold
configsLbl.TextSize = 16
configsLbl.TextColor3 = Theme.TextGray
configsLbl.TextXAlignment = Enum.TextXAlignment.Left
configsLbl.Parent = ConfigsBtn

navMap["configs"] = { btn = ConfigsBtn, lbl = configsLbl, setColor = configsIconColorSetter }

trackConn(ConfigsBtn.MouseButton1Click:Connect(function()
    switchTab("configs")
end))

-- Нижняя секция профиля (с мягкой заблюренной разделительной линией сверху)
do
    local pLine = Instance.new("Frame")
    pLine.Position = UDim2.new(0, 10, 1, -64)
    pLine.Size = UDim2.new(1, -20, 0, 1)
    pLine.BackgroundColor3 = Theme.Divider
    pLine.BackgroundTransparency = 0.25
    pLine.BorderSizePixel = 0
    pLine.Parent = Sidebar

    local pGrad = Instance.new("UIGradient")
    pGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(0.15, 0.35),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.85, 0.35),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })
    pGrad.Parent = pLine
end

local ProfileFrame = Instance.new("Frame")
ProfileFrame.Size = UDim2.new(1, 0, 0, 64)
ProfileFrame.Position = UDim2.new(0, 0, 1, -64)
ProfileFrame.BackgroundTransparency = 1
ProfileFrame.Parent = Sidebar

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 34, 0, 34)
Avatar.Position = UDim2.new(0, 16, 0.5, -17)
Avatar.BackgroundColor3 = Theme.CardFill
Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
Avatar.Parent = ProfileFrame
addCorner(Avatar, 17)

local ProfName = Instance.new("TextLabel")
ProfName.Size = UDim2.new(0, 105, 0, 18)
ProfName.Position = UDim2.new(0, 58, 0, 13)
ProfName.RichText = true
ProfName.BackgroundTransparency = 1
ProfName.Text = (LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name)) or "User"
ProfName.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
ProfName.Font = Enum.Font.GothamBold
ProfName.TextSize = 15
ProfName.TextColor3 = Theme.TextWhite
ProfName.TextXAlignment = Enum.TextXAlignment.Left
ProfName.Parent = ProfileFrame

local ProfSub = Instance.new("TextLabel")
ProfSub.Size = UDim2.new(0, 105, 0, 16)
ProfSub.Position = UDim2.new(0, 58, 0, 33)
ProfSub.RichText = true
ProfSub.BackgroundTransparency = 1
ProfSub.Text = "until 25 days"
ProfSub.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
ProfSub.Font = Enum.Font.GothamBold
ProfSub.TextSize = 13
ProfSub.TextColor3 = Theme.TextValues
ProfSub.TextXAlignment = Enum.TextXAlignment.Left
ProfSub.Parent = ProfileFrame

ChevronBtn = Instance.new("TextButton")
ChevronBtn.Size = UDim2.new(0, 24, 0, 24)
ChevronBtn.Position = UDim2.new(1, -28, 0.5, -12)
ChevronBtn.BackgroundColor3 = Theme.CardFill
ChevronBtn.BackgroundTransparency = 1
ChevronBtn.Text = ""
ChevronBtn.AutoButtonColor = false
ChevronBtn.Parent = ProfileFrame
addCorner(ChevronBtn, 6)

ChevronIcon = createLucideIcon(ChevronBtn, "chevron-right", 16, Theme.TextGray)
ChevronIcon.Position = UDim2.new(0.5, -8, 0.5, -8)

trackConn(ChevronBtn.MouseEnter:Connect(function()
    TweenService:Create(ChevronBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.5 }):Play()
    ChevronIcon.ImageColor3 = Theme.TextWhite
end))
trackConn(ChevronBtn.MouseLeave:Connect(function()
    TweenService:Create(ChevronBtn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
    ChevronIcon.ImageColor3 = Theme.TextGray
end))

-- Клик по шеврону открывает секретную страницу настроек меню и credits
trackConn(ChevronBtn.MouseButton1Click:Connect(function()
    switchTab("settings")
end))

--------------------------------------------------------------------------------
-- ПРАВАЯ ОБЛАСТЬ И ТОПБАР (фон тоже рисует градиент MainWindow)
--------------------------------------------------------------------------------
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -190, 1, 0)
ContentArea.Position = UDim2.new(0, 190, 0, 0)
ContentArea.BackgroundColor3 = Theme.ContentBg
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 54)
TopBar.BackgroundTransparency = 1
TopBar.Parent = ContentArea

local CollapseBox = Instance.new("Frame")
CollapseBox.Size = UDim2.new(0, 16, 0, 14)
CollapseBox.Position = UDim2.new(0, 24, 0.5, -7)
CollapseBox.BackgroundTransparency = 1
CollapseBox.Parent = TopBar
addCorner(CollapseBox, 3)
addStroke(CollapseBox, Theme.TextGray, 1.5)
makeBox(CollapseBox, UDim2.new(0, 5, 0, 0), UDim2.new(0, 1.5, 1, 0), Theme.TextGray, 0)

HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0, 200, 1, 0)
HeaderTitle.Position = UDim2.new(0, 58, 0, 0)
HeaderTitle.RichText = true
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "rage"
HeaderTitle.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 14
HeaderTitle.TextColor3 = Theme.TextWhite
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = TopBar



-- Мягкая разделительная линия под топбаром
do
    local tLine = Instance.new("Frame")
    tLine.Position = UDim2.new(0, 16, 0, 54)
    tLine.Size = UDim2.new(1, -32, 0, 1)
    tLine.BackgroundColor3 = Theme.Divider
    tLine.BackgroundTransparency = 0.25
    tLine.BorderSizePixel = 0
    tLine.Parent = ContentArea

    local tGrad = Instance.new("UIGradient")
    tGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.9),
        NumberSequenceKeypoint.new(0.08, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.92, 0.3),
        NumberSequenceKeypoint.new(1.0, 0.9),
    })
    tGrad.Parent = tLine
end

--------------------------------------------------------------------------------
-- КАПСУЛА ОРУЖИЯ (ВСЕ 9 ОРУЖИЙ ВНУТРИ РАМКИ)
--------------------------------------------------------------------------------
WeaponBar = Instance.new("Frame")
WeaponBar.Size = UDim2.new(1, -40, 0, 42)
WeaponBar.Position = UDim2.new(0, 20, 0, 72)
WeaponBar.BackgroundColor3 = Theme.PillBarBg
WeaponBar.BackgroundTransparency = 0
WeaponBar.ClipsDescendants = true
WeaponBar.Parent = ContentArea
addCorner(WeaponBar, 21)
addStroke(WeaponBar, Theme.StrokeInner, 1, 0.4)

local WeaponLayout = Instance.new("UIListLayout")
WeaponLayout.FillDirection = Enum.FillDirection.Horizontal
WeaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
WeaponLayout.Padding = UDim.new(0, 4)
WeaponLayout.SortOrder = Enum.SortOrder.LayoutOrder
WeaponLayout.Parent = WeaponBar

local WeaponPad = Instance.new("UIPadding")
WeaponPad.PaddingLeft = UDim.new(0, 4)
WeaponPad.PaddingRight = UDim.new(0, 4)
WeaponPad.Parent = WeaponBar

local weaponsList = {
    { id = "pistols", active = true },
    { id = "heavy_pistol" },
    { id = "smg" },
    { id = "rifle" },
    { id = "m4" },
    { id = "shotgun" },
    { id = "scout" },
    { id = "awp" },
    { id = "auto" },
}

local weaponTabRefs = {}
local ACTIVE_W = 116
local INACTIVE_W = 59

for idx, w in ipairs(weaponsList) do
    local tab = Instance.new("TextButton")
    tab.LayoutOrder = idx
    tab.Size = UDim2.new(0, w.active and ACTIVE_W or INACTIVE_W, 0, 34)
    tab.BackgroundColor3 = Theme.Accent
    tab.BackgroundTransparency = w.active and 0 or 1
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.ClipsDescendants = true
    tab.Parent = WeaponBar
    addCorner(tab, 17)

    local initCol = w.active and Color3.fromRGB(20, 20, 22) or Theme.TextGray
    local iconFrame, setSilhouetteColor = drawWeaponSilhouette(tab, w.id, initCol)
    iconFrame.Position = w.active and UDim2.new(0, 12, 0.5, -9) or UDim2.new(0.5, -18, 0.5, -9)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.RichText = true
    nameLbl.Size = UDim2.new(0, 60, 1, 0)
    nameLbl.Position = UDim2.new(0, 52, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = w.id == "heavy_pistol" and "heavy" or w.id
    nameLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Color3.fromRGB(20, 20, 22)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Visible = w.active or false
    nameLbl.Parent = tab

    weaponTabRefs[idx] = {
        tab = tab,
        icon = iconFrame,
        lbl = nameLbl,
        setColor = setSilhouetteColor,
    }

    trackConn(tab.MouseButton1Click:Connect(function()
        for _, ref in ipairs(weaponTabRefs) do
            ref.tab.BackgroundTransparency = 1
            ref.lbl.Visible = false
            ref.setColor(Theme.TextGray)
            TweenService:Create(ref.tab, TweenInfo.new(0.16), { Size = UDim2.new(0, INACTIVE_W, 0, 34) }):Play()
            TweenService:Create(ref.icon, TweenInfo.new(0.16), { Position = UDim2.new(0.5, -18, 0.5, -9) }):Play()
        end
        tab.BackgroundTransparency = 0
        nameLbl.Visible = true
        setSilhouetteColor(Color3.fromRGB(20, 20, 22))
        TweenService:Create(tab, TweenInfo.new(0.16), { Size = UDim2.new(0, ACTIVE_W, 0, 34) }):Play()
        TweenService:Create(iconFrame, TweenInfo.new(0.16), { Position = UDim2.new(0, 12, 0.5, -9) }):Play()
    end))
end

--------------------------------------------------------------------------------
-- СИСТЕМА НЕЗАВИСИМЫХ СТРАНИЦ ВКЛАДОК
--------------------------------------------------------------------------------

local function createTabPage(tabId)
    local hasWeaponBar = (tabId == "rage" or tabId == "legit")
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Page_" .. tostring(tabId)
    scroll.Size = hasWeaponBar and UDim2.new(1, -36, 1, -142) or UDim2.new(1, -36, 1, -88)
    scroll.Position = hasWeaponBar and UDim2.new(0, 18, 0, 126) or UDim2.new(0, 18, 0, 72)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.ScrollBarImageTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ClipsDescendants = true
    scroll.Visible = false
    scroll.Parent = ContentArea

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.Parent = scroll

    local left = Instance.new("Frame")
    left.Name = "LeftColumn"
    left.Size = UDim2.new(0.5, -11, 0, 0)
    left.AutomaticSize = Enum.AutomaticSize.Y
    left.BackgroundTransparency = 1
    left.Parent = scroll

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 14)
    leftLayout.Parent = left

    local right = Instance.new("Frame")
    right.Name = "RightColumn"
    right.Size = UDim2.new(0.5, -11, 0, 0)
    right.Position = UDim2.new(0.5, 3, 0, 0)
    right.AutomaticSize = Enum.AutomaticSize.Y
    right.BackgroundTransparency = 1
    right.Parent = scroll

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Padding = UDim.new(0, 14)
    rightLayout.Parent = right

    TabPages[tabId] = {
        Scroll = scroll,
        Left = left,
        Right = right,
    }

    return TabPages[tabId]
end

local globalOrder = 0
local function nextOrder()
    globalOrder += 1
    return globalOrder
end

-- Разделительная линия между функциями: ширина как у трека слайдера (отступ по 14px слева и справа)
-- Мягкая заблюренная разделительная линия с градиентным затуханием по краям
local function addBottomLine(parent)
    local line = Instance.new("Frame")
    line.Position = UDim2.new(0, 14, 1, -1)
    line.Size = UDim2.new(1, -28, 0, 1)
    line.BackgroundColor3 = Theme.Divider
    line.BackgroundTransparency = 0.05
    line.BorderSizePixel = 0
    line.Parent = parent

    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.9),
        NumberSequenceKeypoint.new(0.08, 0.15),
        NumberSequenceKeypoint.new(0.5, 0.0),
        NumberSequenceKeypoint.new(0.92, 0.15),
        NumberSequenceKeypoint.new(1.0, 0.9),
    })
    grad.Parent = line
    return line
end

-- СЕКЦИЯ-КАРТОЧКА: 1 в 1 тон фона, прозрачность на 0.05 меньше чем само окно (0.08 - 0.05 = 0.03)
local function createSectionCard(column, title)
    local cardWrapper = Instance.new("Frame")
    cardWrapper.Size = UDim2.new(1, 0, 0, 0)
    cardWrapper.AutomaticSize = Enum.AutomaticSize.Y
    cardWrapper.BackgroundColor3 = Theme.CardFill
    cardWrapper.BackgroundTransparency = 0.13
    cardWrapper.LayoutOrder = nextOrder()
    cardWrapper.Parent = column
    addCorner(cardWrapper, 10)

    -- Объемная обводка (сверху аккуратная фаска, снизу темнее)
    local cardStroke = addStroke(cardWrapper, Color3.fromRGB(255, 255, 255), 1, 0)
    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 90
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(78, 78, 88)), -- верхняя светлая фаска
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 56, 64)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(40, 40, 46)), -- низ обводки
    })
    strokeGrad.Parent = cardStroke

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Parent = cardWrapper

    -- Хедер секции
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1
    header.Parent = cardWrapper

    local titleLbl = Instance.new("TextLabel")
    titleLbl.RichText = true
    titleLbl.AnchorPoint = Vector2.new(0, 0.5)
    titleLbl.Size = UDim2.new(1, -28, 0, 20)
    titleLbl.Position = UDim2.new(0, 14, 0.5, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = string.upper(title)
    titleLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = Theme.TextMuted
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    addBottomLine(header)

    -- Список элементов внутри карточки (идёт строго под хедером без наложений)
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Size = UDim2.new(1, 0, 0, 0)
    itemsContainer.LayoutOrder = 2
    itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.Parent = cardWrapper

    local cLayout = Instance.new("UIListLayout")
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Parent = itemsContainer

    return itemsContainer
end

local function addToggle(section, labelText, defaultState, isLast, callback, flag)
    local state = defaultState
    local updateUI = function() end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.7, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("TextButton")
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.Position = UDim2.new(1, -14, 0.5, 0)
    pill.BackgroundColor3 = defaultState and Theme.Accent or Theme.ToggleOff
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row
    addCorner(pill, 10)

    -- Объемная обводка тумблера со светотенью
    local pillStroke = addStroke(pill, Color3.fromRGB(75, 75, 82), 1, 0)
    local pillStrokeGrad = Instance.new("UIGradient")
    pillStrokeGrad.Rotation = 90
    pillStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(110, 110, 118)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(46, 46, 52)),
    })
    pillStrokeGrad.Parent = pillStroke

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultState and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    knob.BackgroundColor3 = defaultState and Theme.ToggleKnobOn or Theme.Accent
    knob.BorderSizePixel = 0
    knob.Parent = pill
    addCorner(knob, 8)

    local state = defaultState
    trackConn(pill.MouseButton1Click:Connect(function()
        state = not state
        -- Премиальная анимация эластичной формы переключателя
        TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
        }):Play()
        
        -- Сжатие и разжатие таблетки (squash & stretch)
        knob.Size = UDim2.new(0, 20, 0, 16)
        TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = state and Theme.ToggleKnobOn or Theme.Accent
        }):Play()

        if callback then pcall(callback, state) end
    end))

    local function setToggle(val)
        if state == val then return end
        state = val
        TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = state and Theme.ToggleKnobOn or Theme.Accent
        }):Play()
        if callback then pcall(callback, state) end
    end

    if flag then
        Library.Registry[flag] = {
            Type = "Toggle",
            Get = function() return state end,
            Set = setToggle
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setToggle, Get = function() return state end }
end

local function addSlider(section, labelText, minVal, maxVal, defaultVal, suffix, decimals, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 58)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local function fmt(v)
        if decimals and decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. (suffix or "")
        end
        return tostring(math.floor(v + 0.5)) .. (suffix or "")
    end

    local valLbl = Instance.new("TextLabel")
    valLbl.RichText = true
    valLbl.Size = UDim2.new(0.4, 0, 0, 20)
    valLbl.Position = UDim2.new(0.6, -14, 0, 10)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = fmt(defaultVal)
    valLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 14
    valLbl.TextColor3 = Theme.TextValues
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local hitBox = Instance.new("TextButton")
    hitBox.Size = UDim2.new(1, -28, 0, 14)
    hitBox.Position = UDim2.new(0, 14, 0, 34)
    hitBox.BackgroundTransparency = 1
    hitBox.Text = ""
    hitBox.Parent = row

    local track = makeBox(hitBox, UDim2.new(0, 0, 0.5, -1.5), UDim2.new(1, 0, 0, 3), Theme.SliderTrack, 2)
    local alpha = (defaultVal - minVal) / (maxVal - minVal)
    local fill = makeBox(track, UDim2.new(0, 0, 0, 0), UDim2.new(alpha, 0, 1, 0), Theme.Accent, 2)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 12, 0, 12)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
    thumb.BackgroundColor3 = Theme.Accent
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    addCorner(thumb, 6)

    local draggingSlider = false
    local function updateSlider(input)
        local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minVal + (maxVal - minVal) * a
        TweenService:Create(fill, TweenInfo.new(0.06, Enum.EasingStyle.Linear), { Size = UDim2.new(a, 0, 1, 0) }):Play()
        TweenService:Create(thumb, TweenInfo.new(0.06, Enum.EasingStyle.Linear), { Position = UDim2.new(a, 0, 0.5, 0) }):Play()
        valLbl.Text = fmt(val)
        if callback then pcall(callback, val) end
    end

    trackConn(hitBox.MouseEnter:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 14, 0, 14)
        }):Play()
        TweenService:Create(valLbl, TweenInfo.new(0.15), { TextColor3 = Theme.Accent }):Play()
    end))
    trackConn(hitBox.MouseLeave:Connect(function()
        if not draggingSlider then
            TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 12, 0, 12)
            }):Play()
            TweenService:Create(valLbl, TweenInfo.new(0.15), { TextColor3 = Theme.TextValues }):Play()
        end
    end))
    trackConn(hitBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 16, 0, 16)
            }):Play()
            updateSlider(input)
        end
    end))
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
            TweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 12, 0, 12)
            }):Play()
            TweenService:Create(valLbl, TweenInfo.new(0.15), { TextColor3 = Theme.TextValues }):Play()
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end))

    local function setSlider(val)
        local clamped = math.clamp(val, minVal, maxVal)
        local a = (clamped - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(a, 0, 1, 0)
        thumb.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = fmt(clamped)
        if callback then pcall(callback, clamped) end
    end

    if flag then
        Library.Registry[flag] = {
            Type = "Slider",
            Get = function()
                local a = fill.Size.X.Scale
                return minVal + (maxVal - minVal) * a
            end,
            Set = setSlider
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setSlider }
end

local function addDropdown(section, labelText, options, selectedOption, hasGear, openByDefault, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.45, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    if hasGear then
        local gearHolder = Instance.new("Frame")
        gearHolder.AnchorPoint = Vector2.new(1, 0.5)
        gearHolder.Size = UDim2.new(0, 18, 0, 18)
        gearHolder.Position = UDim2.new(1, -166, 0.5, 0)
        gearHolder.BackgroundTransparency = 1
        gearHolder.Parent = row
        drawNavIcon(gearHolder, "miscellaneous", Theme.TextGray)
    end

    local box = Instance.new("TextButton")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Size = UDim2.new(0, 144, 0, 28)
    box.Position = UDim2.new(1, -14, 0.5, 0)
    box.BackgroundColor3 = Theme.DropdownBg
    box.BackgroundTransparency = 1
    box.Text = ""
    box.AutoButtonColor = false
    box.Parent = row
    addCorner(box, 6)
    addStroke(box, Theme.StrokeInner, 1, 0)

    local selLbl = Instance.new("TextLabel")
    selLbl.RichText = true
    selLbl.AnchorPoint = Vector2.new(0, 0.5)
    selLbl.Size = UDim2.new(1, -26, 0, 20)
    selLbl.Position = UDim2.new(0, 8, 0.5, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = selectedOption or ""
    selLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    selLbl.Font = Enum.Font.GothamBold
    selLbl.TextSize = 14
    selLbl.TextColor3 = Theme.TextWhite
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.Parent = box

    local arrowIcon = createLucideIcon(box, "chevron-down", 14, Theme.TextGray)
    arrowIcon.AnchorPoint = Vector2.new(1, 0.5)
    arrowIcon.Position = UDim2.new(1, -10, 0.5, 0)

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 144, 0, #options * 32 + 8)
    popup.BackgroundColor3 = Theme.PopupBg
    popup.BackgroundTransparency = 0
    popup.Visible = openByDefault or false
    popup.ZIndex = 250
    popup.Parent = OverlayLayer
    addCorner(popup, 6)
    addStroke(popup, Theme.StrokeOuter, 1, 0.3)

    local pLayout = Instance.new("UIListLayout")
    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pLayout.Padding = UDim.new(0, 2)
    pLayout.Parent = popup

    local pPad = Instance.new("UIPadding")
    pPad.PaddingTop = UDim.new(0, 4)
    pPad.PaddingBottom = UDim.new(0, 4)
    pPad.PaddingLeft = UDim.new(0, 4)
    pPad.PaddingRight = UDim.new(0, 4)
    pPad.Parent = popup

    local curVal = selectedOption
    local optRefs = {}
    local targetH = #options * 32 + 8
    local isOpen = false

    local function syncPos()
        local bp = box.AbsolutePosition
        local bs = box.AbsoluteSize
        local mp = MainWindow.AbsolutePosition
        -- Строго ровно под нижней гранью селектора (+4px зазор) относительно окна
        popup.Position = UDim2.new(0, bp.X - mp.X, 0, (bp.Y - mp.Y) + bs.Y + 4)
    end

    local function closeDropdown()
        if not isOpen then return end
        isOpen = false
        if activePopup == popup then
            activePopup = nil
            activePopupClose = nil
        end
        TweenService:Create(popup, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 144, 0, 0)
        }):Play()
        TweenService:Create(arrowIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = 0,
            ImageColor3 = Theme.TextGray
        }):Play()
        task.delay(0.15, function()
            if not isOpen then
                popup.Visible = false
            end
        end)
    end

    local function openDropdown()
        if isOpen then return end
        if activePopup and activePopup ~= popup then
            if activePopupClose then activePopupClose() else activePopup.Visible = false end
        end
        isOpen = true
        activePopup = popup
        activePopupClose = closeDropdown
        syncPos()
        popup.Visible = true
        popup.Size = UDim2.new(0, 144, 0, 0)
        popup.ClipsDescendants = true
        TweenService:Create(popup, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 144, 0, targetH)
        }):Play()
        TweenService:Create(arrowIcon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 180,
            ImageColor3 = Theme.Accent
        }):Play()
    end

    local function updateSelectedUI()
        for _, r in ipairs(optRefs) do
            local isSel = (r.name == curVal)
            r.lbl.TextColor3 = isSel and Theme.Accent or Theme.TextGray
            r.lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
            r.lbl.Font = Enum.Font.GothamBold
            r.check.Visible = isSel
        end
    end

    for oIdx, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = ""
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = oIdx
        optBtn.ZIndex = 61
        optBtn.Parent = popup

        local optLbl = Instance.new("TextLabel")
        optLbl.RichText = true
        optLbl.Size = UDim2.new(1, -26, 1, 0)
        optLbl.Position = UDim2.new(0, 8, 0, 0)
        optLbl.BackgroundTransparency = 1
        optLbl.Text = opt
        optLbl.TextSize = 14
        optLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
        optLbl.Font = Enum.Font.GothamBold
        optLbl.TextXAlignment = Enum.TextXAlignment.Left
        optLbl.ZIndex = 62
        optLbl.Parent = optBtn

        local checkMark = createLucideIcon(optBtn, "check", 14, Theme.Accent)
        checkMark.Position = UDim2.new(1, -20, 0.5, -7)
        checkMark.ZIndex = 62

        table.insert(optRefs, { name = opt, lbl = optLbl, check = checkMark })

        trackConn(optBtn.MouseButton1Click:Connect(function()
            curVal = opt
            selLbl.Text = opt
            updateSelectedUI()
            closeDropdown()
            if callback then pcall(callback, opt) end
        end))
    end

    updateSelectedUI()

    trackConn(box.MouseEnter:Connect(function()
        TweenService:Create(selLbl, TweenInfo.new(0.12), { TextColor3 = Theme.Accent }):Play()
        TweenService:Create(arrowIcon, TweenInfo.new(0.12), { ImageColor3 = Theme.Accent }):Play()
    end))
    trackConn(box.MouseLeave:Connect(function()
        if not isOpen then
            TweenService:Create(selLbl, TweenInfo.new(0.12), { TextColor3 = Theme.TextWhite }):Play()
            TweenService:Create(arrowIcon, TweenInfo.new(0.12), { ImageColor3 = Theme.TextGray }):Play()
        end
    end))

    trackConn(box.MouseButton1Click:Connect(function()
        if isOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end))

    -- Закрытие при клике мимо селектора
    trackConn(UserInputService.InputBegan:Connect(function(input)
        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = input.Position
            local bp = box.AbsolutePosition
            local bs = box.AbsoluteSize
            local pp = popup.AbsolutePosition
            local ps = popup.AbsoluteSize
            local inBox = (mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y)
            local inPopup = (mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y)
            if not inBox and not inPopup then
                closeDropdown()
            end
        end
    end))

    trackConn(box:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if isOpen then syncPos() end
    end))
    trackConn(MainWindow:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if isOpen then syncPos() end
    end))
    task.defer(syncPos)

    local function setDropdown(val)
        curVal = val
        selLbl.Text = val
        updateSelectedUI()
        if callback then pcall(callback, val) end
    end

    local function refreshDropdown(newOpts, newDefault)
        -- Очистка старых кнопок в попапе
        for _, ch in ipairs(popup:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        optRefs = {}
        options = newOpts or {}
        targetH = #options * 32 + 8
        curVal = newDefault or options[1] or ""
        selLbl.Text = curVal

        for oIdx, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 30)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.LayoutOrder = oIdx
            optBtn.ZIndex = 251
            optBtn.Parent = popup

            local optLbl = Instance.new("TextLabel")
            optLbl.RichText = true
            optLbl.Size = UDim2.new(1, -26, 1, 0)
            optLbl.Position = UDim2.new(0, 8, 0, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.Text = opt
            optLbl.TextSize = 14
            optLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
            optLbl.Font = Enum.Font.GothamBold
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.ZIndex = 252
            optLbl.Parent = optBtn

            local checkMark = createLucideIcon(optBtn, "check", 14, Theme.Accent)
            checkMark.Position = UDim2.new(1, -20, 0.5, -7)
            checkMark.ZIndex = 252

            table.insert(optRefs, { name = opt, lbl = optLbl, check = checkMark })

            trackConn(optBtn.MouseButton1Click:Connect(function()
                curVal = opt
                selLbl.Text = opt
                updateSelectedUI()
                closeDropdown()
                if callback then pcall(callback, opt) end
            end))
        end
        updateSelectedUI()
    end

    if flag then
        Library.Registry[flag] = {
            Type = "Dropdown",
            Get = function() return curVal end,
            Set = setDropdown,
            Refresh = refreshDropdown
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setDropdown, Refresh = refreshDropdown, Get = function() return curVal end }
end


local function addInput(section, labelText, defaultVal, placeholder, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.45, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Size = UDim2.new(0, 144, 0, 28)
    box.Position = UDim2.new(1, -14, 0.5, 0)
    box.BackgroundColor3 = Theme.DropdownBg
    box.BackgroundTransparency = 0.4
    box.Text = defaultVal or ""
    box.PlaceholderText = placeholder or "type here..."
    box.PlaceholderColor3 = Theme.TextGray
    box.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextColor3 = Theme.TextWhite
    box.ClearTextOnFocus = false
    box.ClipsDescendants = true
    box.Parent = row
    addCorner(box, 6)
    local stroke = addStroke(box, Theme.StrokeInner, 1, 0)

    trackConn(box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Accent }):Play()
    end))
    trackConn(box.FocusLost:Connect(function(enterPressed)
        TweenService:Create(box, TweenInfo.new(0.15), { BackgroundTransparency = 0.4 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.StrokeInner }):Play()
        if callback then pcall(callback, box.Text) end
    end))

    local function setInput(val)
        box.Text = tostring(val or "")
        if callback then pcall(callback, box.Text) end
    end

    if flag then
        Library.Registry[flag] = {
            Type = "Input",
            Get = function() return box.Text end,
            Set = setInput
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setInput, Get = function() return box.Text end, Box = box }
end

-- ============ KEYBIND ============
local function addKeybind(section, labelText, defaultKey, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local curKey = (typeof(defaultKey) == "EnumItem") and defaultKey or Enum.KeyCode[defaultKey or "None"]

    local keyBtn = Instance.new("TextButton")
    keyBtn.AnchorPoint = Vector2.new(1, 0.5)
    keyBtn.Size = UDim2.new(0, 90, 0, 26)
    keyBtn.Position = UDim2.new(1, -14, 0.5, 0)
    keyBtn.BackgroundColor3 = Theme.DropdownBg
    keyBtn.BackgroundTransparency = 0.4
    keyBtn.Text = curKey and curKey.Name or "None"
    keyBtn.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 13
    keyBtn.TextColor3 = Theme.TextValues
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = row
    addCorner(keyBtn, 6)
    local keyStroke = addStroke(keyBtn, Theme.StrokeInner, 1, 0)

    local listening = false
    trackConn(keyBtn.MouseButton1Click:Connect(function()
        listening = true
        Library._KeybindListening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = Theme.Accent
        TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Theme.Accent }):Play()
    end))

    trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                Library._KeybindListening = false
                keyBtn.Text = curKey and curKey.Name or "None"
                keyBtn.TextColor3 = Theme.TextValues
                TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Theme.StrokeInner }):Play()
                return
            end
            curKey = input.KeyCode
            listening = false
            Library._KeybindListening = false
            keyBtn.Text = curKey.Name
            keyBtn.TextColor3 = Theme.TextValues
            TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Theme.StrokeInner }):Play()
            if callback then pcall(callback, curKey) end
        end
    end))

    local function setKeybind(val)
        if typeof(val) == "EnumItem" then
            curKey = val
        elseif type(val) == "string" and Enum.KeyCode[val] then
            curKey = Enum.KeyCode[val]
        end
        keyBtn.Text = curKey and curKey.Name or "None"
        if callback then pcall(callback, curKey) end
    end

    if flag then
        Library.Registry[flag] = {
            Type = "Keybind",
            Get = function() return curKey end,
            Set = setKeybind
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setKeybind, Get = function() return curKey end }
end

-- ============ COLOR PICKER ============
local function addColorPicker(section, labelText, defaultColor, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.7, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local h, s, v = defaultColor and defaultColor:ToHSV() or 0, 0.7, 1
    if defaultColor then
        h, s, v = defaultColor:ToHSV()
    end

    local swatch = Instance.new("TextButton")
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Size = UDim2.new(0, 24, 0, 24)
    swatch.Position = UDim2.new(1, -14, 0.5, 0)
    swatch.BackgroundColor3 = defaultColor or Color3.fromHSV(h, s, v)
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = row
    addCorner(swatch, 6)
    addStroke(swatch, Theme.StrokeInner, 1, 0)

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 172, 0, 148)
    popup.BackgroundColor3 = Theme.PopupBg
    popup.Visible = false
    popup.ZIndex = 250
    popup.Parent = OverlayLayer
    addCorner(popup, 8)
    addStroke(popup, Theme.StrokeOuter, 1, 0.3)

    local svBox = Instance.new("Frame")
    svBox.Position = UDim2.new(0, 12, 0, 12)
    svBox.Size = UDim2.new(1, -24, 0, 84)
    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svBox.ZIndex = 251
    svBox.Parent = popup
    addCorner(svBox, 6)

    local gradWhite = Instance.new("UIGradient")
    gradWhite.Rotation = 0
    gradWhite.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    gradWhite.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradWhite.Parent = svBox

    local gradBlack = Instance.new("UIGradient")
    gradBlack.Rotation = 90
    gradBlack.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
    gradBlack.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    gradBlack.Parent = svBox

    local svThumb = Instance.new("Frame")
    svThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    svThumb.Size = UDim2.new(0, 10, 0, 10)
    svThumb.Position = UDim2.new(s, 0, 1 - v, 0)
    svThumb.BackgroundColor3 = Color3.new(1, 1, 1)
    svThumb.ZIndex = 253
    svThumb.BorderSizePixel = 0
    svThumb.Parent = svBox
    addCorner(svThumb, 5)
    addStroke(svThumb, Color3.new(0, 0, 0), 1, 0.4)

    local hueBox = Instance.new("Frame")
    hueBox.Position = UDim2.new(0, 12, 0, 108)
    hueBox.Size = UDim2.new(1, -24, 0, 12)
    hueBox.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBox.ZIndex = 251
    hueBox.Parent = popup
    addCorner(hueBox, 6)

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })
    hueGrad.Parent = hueBox

    local hueThumb = Instance.new("Frame")
    hueThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    hueThumb.Size = UDim2.new(0, 8, 0, 16)
    hueThumb.Position = UDim2.new(h, 0, 0.5, 0)
    hueThumb.BackgroundColor3 = Color3.new(1, 1, 1)
    hueThumb.ZIndex = 253
    hueThumb.BorderSizePixel = 0
    hueThumb.Parent = hueBox
    addCorner(hueThumb, 4)
    addStroke(hueThumb, Color3.new(0, 0, 0), 1, 0.4)

    local function fire()
        local col = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = col
        if callback then pcall(callback, col) end
    end

    local function syncHue()
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        hueThumb.Position = UDim2.new(h, 0, 0.5, 0)
    end

    local draggingSV = false
    local draggingHue = false

    local function updateSV(input)
        local inPos = Vector2.new(input.Position.X, input.Position.Y)
        local rel = (inPos - svBox.AbsolutePosition) / svBox.AbsoluteSize
        s = math.clamp(rel.X, 0, 1)
        v = 1 - math.clamp(rel.Y, 0, 1)
        svThumb.Position = UDim2.new(s, 0, 1 - v, 0)
        fire()
    end

    local function updateHue(input)
        local inPos = Vector2.new(input.Position.X, input.Position.Y)
        local rel = (inPos - hueBox.AbsolutePosition) / hueBox.AbsoluteSize
        h = math.clamp(rel.X, 0, 0.999)
        syncHue()
        fire()
    end

    trackConn(svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV = true
            updateSV(input)
        end
    end))
    trackConn(hueBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
            updateHue(input)
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if draggingSV then updateSV(input) end
            if draggingHue then updateHue(input) end
        end
    end))
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV = false
            draggingHue = false
        end
    end))

    local isOpen = false

    local function syncPos()
        local bp = swatch.AbsolutePosition
        local bs = swatch.AbsoluteSize
        local mp = MainWindow.AbsolutePosition
        popup.Position = UDim2.new(0, (bp.X - mp.X) + bs.X - 172, 0, (bp.Y - mp.Y) + bs.Y + 4)
    end

    local function closePicker()
        if not isOpen then return end
        isOpen = false
        if activePopup == popup then
            activePopup = nil
            activePopupClose = nil
        end
        popup.Visible = false
    end

    local function openPicker()
        if isOpen then return end
        if activePopup and activePopup ~= popup then
            if activePopupClose then activePopupClose() else activePopup.Visible = false end
        end
        isOpen = true
        activePopup = popup
        activePopupClose = closePicker
        syncPos()
        popup.Visible = true
    end

    trackConn(swatch.MouseButton1Click:Connect(function()
        if isOpen then closePicker() else openPicker() end
    end))

    trackConn(UserInputService.InputBegan:Connect(function(input)
        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = input.Position
            local pp = popup.AbsolutePosition
            local ps = popup.AbsoluteSize
            local sp = swatch.AbsolutePosition
            local ss = swatch.AbsoluteSize
            local inPopup = (mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y)
            local inSwatch = (mp.X >= sp.X and mp.X <= sp.X + ss.X and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y)
            if not inPopup and not inSwatch then
                closePicker()
            end
        end
    end))

    trackConn(swatch:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if isOpen then syncPos() end
    end))

    local function setColor(col)
        if typeof(col) ~= "Color3" then return end
        h, s, v = col:ToHSV()
        if h ~= h then h = 0 end
        syncHue()
        svThumb.Position = UDim2.new(s, 0, 1 - v, 0)
        swatch.BackgroundColor3 = col
    end

    if flag then
        Library.Registry[flag] = {
            Type = "ColorPicker",
            Get = function() return Color3.fromHSV(h, s, v) end,
            Set = setColor
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setColor, Get = function() return Color3.fromHSV(h, s, v) end }
end

-- ============ MULTI DROPDOWN ============
local function addMultiDropdown(section, labelText, options, selectedList, isLast, callback, flag)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.45, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextButton")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Size = UDim2.new(0, 144, 0, 28)
    box.Position = UDim2.new(1, -14, 0.5, 0)
    box.BackgroundColor3 = Theme.DropdownBg
    box.BackgroundTransparency = 1
    box.Text = ""
    box.AutoButtonColor = false
    box.Parent = row
    addCorner(box, 6)
    addStroke(box, Theme.StrokeInner, 1, 0)

    local selLbl = Instance.new("TextLabel")
    selLbl.RichText = true
    selLbl.AnchorPoint = Vector2.new(0, 0.5)
    selLbl.Size = UDim2.new(1, -26, 0, 20)
    selLbl.Position = UDim2.new(0, 8, 0.5, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.TextSize = 13
    selLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    selLbl.Font = Enum.Font.GothamBold
    selLbl.TextColor3 = Theme.TextWhite
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd
    selLbl.Parent = box

    local arrowIcon = createLucideIcon(box, "chevron-down", 14, Theme.TextGray)
    arrowIcon.AnchorPoint = Vector2.new(1, 0.5)
    arrowIcon.Position = UDim2.new(1, -10, 0.5, 0)

    local selected = {}
    local selectedOrder = {}
    local optRefs = {}

    local function summary()
        if #selectedOrder == 0 then return "-" end
        return table.concat(selectedOrder, ", ")
    end

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 144, 0, #options * 30 + 8)
    popup.BackgroundColor3 = Theme.PopupBg
    popup.Visible = false
    popup.ZIndex = 250
    popup.Parent = OverlayLayer
    addCorner(popup, 6)
    addStroke(popup, Theme.StrokeOuter, 1, 0.3)

    local pLayout = Instance.new("UIListLayout")
    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pLayout.Padding = UDim.new(0, 2)
    pLayout.Parent = popup

    local pPad = Instance.new("UIPadding")
    pPad.PaddingTop = UDim.new(0, 4)
    pPad.PaddingBottom = UDim.new(0, 4)
    pPad.PaddingLeft = UDim.new(0, 4)
    pPad.PaddingRight = UDim.new(0, 4)
    pPad.Parent = popup

    local function setSelected(list, silent)
        selected = {}
        selectedOrder = {}
        local seen = {}
        if type(list) == "table" then
            for _, name in ipairs(list) do
                if table.find(options, name) and not seen[name] then
                    seen[name] = true
                    selected[name] = true
                    table.insert(selectedOrder, name)
                end
            end
        end
        for _, r in ipairs(optRefs) do
            local isSel = selected[r.name] == true
            r.lbl.TextColor3 = isSel and Theme.Accent or Theme.TextGray
            r.check.Visible = isSel
        end
        selLbl.Text = summary()
        if not silent and callback then pcall(callback, selectedOrder) end
    end

    for oIdx, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = ""
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = oIdx
        optBtn.ZIndex = 251
        optBtn.Parent = popup

        local optLbl = Instance.new("TextLabel")
        optLbl.RichText = true
        optLbl.Size = UDim2.new(1, -26, 1, 0)
        optLbl.Position = UDim2.new(0, 8, 0, 0)
        optLbl.BackgroundTransparency = 1
        optLbl.Text = opt
        optLbl.TextSize = 14
        optLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
        optLbl.Font = Enum.Font.GothamBold
        optLbl.TextXAlignment = Enum.TextXAlignment.Left
        optLbl.ZIndex = 252
        optLbl.Parent = optBtn

        local checkMark = createLucideIcon(optBtn, "check", 14, Theme.Accent)
        checkMark.Position = UDim2.new(1, -20, 0.5, -7)
        checkMark.ZIndex = 252

        table.insert(optRefs, { name = opt, lbl = optLbl, check = checkMark })

        trackConn(optBtn.MouseButton1Click:Connect(function()
            local newList = {}
            if selected[opt] then
                selected[opt] = nil
                for _, n in ipairs(selectedOrder) do
                    if n ~= opt then table.insert(newList, n) end
                end
            else
                selected[opt] = true
                newList = table.clone(selectedOrder)
                table.insert(newList, opt)
            end
            setSelected(newList)
        end))
    end

    setSelected(selectedList or {}, true)

    local targetH = #options * 30 + 8
    local isOpen = false

    local function syncPos()
        local bp = box.AbsolutePosition
        local bs = box.AbsoluteSize
        local mp = MainWindow.AbsolutePosition
        popup.Position = UDim2.new(0, bp.X - mp.X, 0, (bp.Y - mp.Y) + bs.Y + 4)
    end

    local function closeMulti()
        if not isOpen then return end
        isOpen = false
        if activePopup == popup then
            activePopup = nil
            activePopupClose = nil
        end
        TweenService:Create(arrowIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = 0,
            ImageColor3 = Theme.TextGray
        }):Play()
        popup.Visible = false
    end

    local function openMulti()
        if isOpen then return end
        if activePopup and activePopup ~= popup then
            if activePopupClose then activePopupClose() else activePopup.Visible = false end
        end
        isOpen = true
        activePopup = popup
        activePopupClose = closeMulti
        syncPos()
        popup.Visible = true
        TweenService:Create(arrowIcon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 180,
            ImageColor3 = Theme.Accent
        }):Play()
    end

    trackConn(box.MouseButton1Click:Connect(function()
        if isOpen then closeMulti() else openMulti() end
    end))

    trackConn(UserInputService.InputBegan:Connect(function(input)
        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = input.Position
            local bp = box.AbsolutePosition
            local bs = box.AbsoluteSize
            local pp = popup.AbsolutePosition
            local ps = popup.AbsoluteSize
            local inBox = (mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y)
            local inPopup = (mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y)
            if not inBox and not inPopup then
                closeMulti()
            end
        end
    end))

    trackConn(box:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if isOpen then syncPos() end
    end))
    trackConn(MainWindow:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if isOpen then syncPos() end
    end))

    local function setMulti(list)
        setSelected(list, false)
    end

    local function refreshMulti(newOpts, newSelected)
        for _, ch in ipairs(popup:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        optRefs = {}
        options = newOpts or {}
        targetH = #options * 30 + 8
        popup.Size = UDim2.new(0, 144, 0, targetH)

        for oIdx, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 30)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.LayoutOrder = oIdx
            optBtn.ZIndex = 251
            optBtn.Parent = popup

            local optLbl = Instance.new("TextLabel")
            optLbl.RichText = true
            optLbl.Size = UDim2.new(1, -26, 1, 0)
            optLbl.Position = UDim2.new(0, 8, 0, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.Text = opt
            optLbl.TextSize = 14
            optLbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
            optLbl.Font = Enum.Font.GothamBold
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.ZIndex = 252
            optLbl.Parent = optBtn

            local checkMark = createLucideIcon(optBtn, "check", 14, Theme.Accent)
            checkMark.Position = UDim2.new(1, -20, 0.5, -7)
            checkMark.ZIndex = 252

            table.insert(optRefs, { name = opt, lbl = optLbl, check = checkMark })

            trackConn(optBtn.MouseButton1Click:Connect(function()
                local newList = {}
                if selected[opt] then
                    selected[opt] = nil
                    for _, n in ipairs(selectedOrder) do
                        if n ~= opt then table.insert(newList, n) end
                    end
                else
                    selected[opt] = true
                    newList = table.clone(selectedOrder)
                    table.insert(newList, opt)
                end
                setSelected(newList)
            end))
        end
        setSelected(newSelected or selectedOrder, true)
    end

    if flag then
        Library.Registry[flag] = {
            Type = "MultiDropdown",
            Get = function() return table.clone(selectedOrder) end,
            Set = setMulti,
            Refresh = refreshMulti
        }
    end

    if not isLast then
        addBottomLine(row)
    end
    return { Set = setMulti, Refresh = refreshMulti, Get = function() return table.clone(selectedOrder) end }
end

local function addButton(section, labelText, buttonText, iconName, isLast, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = section

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(0.7, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    -- Всегда компактная иконка фингерпринта без рамок и боксов
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Size = UDim2.new(0, 24, 0, 24)
    btn.Position = UDim2.new(1, -14, 0.5, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    local iconToUse = (iconName and iconName ~= "") and iconName or "fingerprint"
    local btnIcon = createLucideIcon(btn, iconToUse, 18, Theme.TextGray)
    btnIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    btnIcon.Position = UDim2.new(0.5, 0, 0.5, 0)

    trackConn(btn.MouseEnter:Connect(function()
        TweenService:Create(btnIcon, TweenInfo.new(0.12), { ImageColor3 = Theme.Accent }):Play()
    end))
    trackConn(btn.MouseLeave:Connect(function()
        TweenService:Create(btnIcon, TweenInfo.new(0.12), { ImageColor3 = Theme.TextGray }):Play()
    end))
    trackConn(btn.MouseButton1Click:Connect(function()
        btnIcon.Size = UDim2.new(0, 15, 0, 15)
        task.delay(0.08, function()
            btnIcon.Size = UDim2.new(0, 18, 0, 18)
        end)
        if callback then pcall(callback) end
    end))

    if not isLast then
        addBottomLine(row)
    end
end

--------------------------------------------------------------------------------
-- МОДУЛЬНОЕ API БИБЛИОТЕКИ (CS2 NEVERLOSE STYLE)
--------------------------------------------------------------------------------
local TabMeta = {}
TabMeta.__index = TabMeta

local SectionCardMeta = {}
SectionCardMeta.__index = SectionCardMeta

Library.ScreenGui = ScreenGui
Library.MainWindow = MainWindow
Library.TabPages = TabPages
Library.ConfigsTab = nil
Library.ShowConfigs = true
Library.ConfigFolder = "configs"
Library.AutoLoadFile = "configs/autoload.txt"
Library.Unload = Cleanup

local function parseArgs(arg1, arg2)
    local flag, cfg
    if type(arg1) == "string" and type(arg2) == "table" then
        flag = arg1
        cfg = arg2
    elseif type(arg1) == "table" then
        cfg = arg1
        flag = cfg.Flag or cfg.flag or cfg.Name or cfg.Text
    else
        cfg = arg2 or {}
        flag = tostring(arg1 or "Item")
    end
    local name = cfg.Name or cfg.Text or flag
    return flag, name, cfg
end

function SectionCardMeta:AddToggle(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local default = (cfg.Default ~= nil) and cfg.Default or false
    local isLast = cfg.IsLast or false
    local callback = cfg.Callback or function() end

    local item = addToggle(self.Container, label, default, isLast, callback, flag)
    local tObj = {
        Value = default,
        Type = "Toggle",
        Callback = callback
    }
    function tObj:SetValue(v)
        self.Value = v
        if item and item.Set then item.Set(v) end
    end
    function tObj:OnChanged(fn)
        local oldCb = self.Callback
        self.Callback = function(val)
            pcall(oldCb, val)
            pcall(fn, val)
        end
    end
    local selfSec = self
    function tObj:AddColorPicker(cpArg1, cpArg2)
        return selfSec:AddColorPicker(cpArg1, cpArg2)
    end
    function tObj:AddKeyPicker(kpArg1, kpArg2)
        return selfSec:AddKeybind(kpArg1, kpArg2)
    end

    if getgenv().Toggles then getgenv().Toggles[flag] = tObj end
    return tObj
end

function SectionCardMeta:AddSlider(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local min = cfg.Min or 0
    local max = cfg.Max or 100
    local default = cfg.Default or min
    local suffix = cfg.Suffix or ""
    local decimals = cfg.Decimals or cfg.Rounding or 0
    local isLast = cfg.IsLast or false
    local callback = cfg.Callback or function() end

    local item = addSlider(self.Container, label, min, max, default, suffix, decimals, isLast, callback, flag)
    local sObj = {
        Value = default,
        Type = "Slider",
        Callback = callback
    }
    function sObj:SetValue(v)
        self.Value = v
        if item and item.Set then item.Set(v) end
    end
    function sObj:OnChanged(fn)
        local oldCb = self.Callback
        self.Callback = function(val)
            pcall(oldCb, val)
            pcall(fn, val)
        end
    end

    if getgenv().Options then getgenv().Options[flag] = sObj end
    return sObj
end

function SectionCardMeta:AddInput(config)
    local label = config.Name or config.label or "Input"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "config name..."
    local isLast = config.IsLast or false
    local callback = config.Callback or function() end
    local flag = config.Flag or config.flag or label
    return addInput(self.Container, label, default, placeholder, isLast, callback, flag)
end

function SectionCardMeta:AddKeybind(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local defaultKey = cfg.Default or cfg.Key or Enum.KeyCode.None
    local isLast = cfg.IsLast or false
    local callback = cfg.Callback or function() end

    local item = addKeybind(self.Container, label, defaultKey, isLast, callback, flag)
    local kObj = {
        Value = defaultKey,
        Type = "Keybind",
        Callback = callback
    }
    function kObj:SetValue(k)
        self.Value = k
        if item and item.Set then item.Set(k) end
    end
    function kObj:OnClick(fn)
        self.Callback = fn
    end

    if getgenv().Options then getgenv().Options[flag] = kObj end
    return kObj
end

SectionCardMeta.AddKeyPicker = SectionCardMeta.AddKeybind

function SectionCardMeta:AddLabel(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local selfSec = self
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = self.Container

    local lbl = Instance.new("TextLabel")
    lbl.RichText = true
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Size = UDim2.new(1, -28, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(cfg.Text or label or "")
    lbl.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = Theme.TextGray
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local lObj = { Text = lbl.Text }
    function lObj:SetText(t)
        self.Text = tostring(t)
        lbl.Text = tostring(t)
    end
    function lObj:AddColorPicker(cpArg1, cpArg2)
        local cpFlag, cpLabel, cpCfg = parseArgs(cpArg1, cpArg2)
        cpCfg.Text = cpCfg.Text or label
        return selfSec:AddColorPicker(cpFlag, cpCfg)
    end
    function lObj:AddKeyPicker(kpArg1, kpArg2)
        local kpFlag, kpLabel, kpCfg = parseArgs(kpArg1, kpArg2)
        kpCfg.Text = kpCfg.Text or label
        return selfSec:AddKeybind(kpFlag, kpCfg)
    end

    if getgenv().Options then getgenv().Options[flag] = lObj end
    return lObj
end

function SectionCardMeta:AddDivider()
    local divRow = Instance.new("Frame")
    divRow.Size = UDim2.new(1, 0, 0, 10)
    divRow.BackgroundTransparency = 1
    divRow.LayoutOrder = nextOrder()
    divRow.Parent = self.Container

    local line = Instance.new("Frame")
    line.Position = UDim2.new(0, 14, 0.5, 0)
    line.Size = UDim2.new(1, -28, 0, 1)
    line.BackgroundColor3 = Theme.Divider
    line.BackgroundTransparency = 0.05
    line.BorderSizePixel = 0
    line.Parent = divRow

    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.9),
        NumberSequenceKeypoint.new(0.08, 0.15),
        NumberSequenceKeypoint.new(0.5, 0.0),
        NumberSequenceKeypoint.new(0.92, 0.15),
        NumberSequenceKeypoint.new(1.0, 0.9),
    })
    grad.Parent = line
    return divRow
end

function SectionCardMeta:AddColorPicker(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local defaultColor = cfg.Default or cfg.Color or Color3.fromRGB(255, 255, 255)
    local isLast = cfg.IsLast or false
    local callback = cfg.Callback or function() end

    local item = addColorPicker(self.Container, label, defaultColor, isLast, callback, flag)
    local cObj = {
        Value = defaultColor,
        Type = "ColorPicker",
        Callback = callback
    }
    function cObj:SetValue(col)
        self.Value = col
        if item and item.Set then item.Set(col) end
    end
    function cObj:OnChanged(fn)
        local oldCb = self.Callback
        self.Callback = function(val)
            pcall(oldCb, val)
            pcall(fn, val)
        end
    end

    if getgenv().Options then getgenv().Options[flag] = cObj end
    return cObj
end

function SectionCardMeta:AddMultiDropdown(config)
    local label = config.Name or config.label or "Multi"
    local options = config.Options or {}
    local defaultList = config.Default or {}
    local isLast = config.IsLast or false
    local callback = config.Callback or function() end
    local flag = config.Flag or config.flag or label
    return addMultiDropdown(self.Container, label, options, defaultList, isLast, callback, flag)
end

function SectionCardMeta:AddButton(config)
    local label = config.Name or config.label or "Action"
    local icon = config.Icon or config.icon or "fingerprint"
    local isLast = config.IsLast or false
    local callback = config.Callback or function() end
    return addButton(self.Container, label, "", icon, isLast, callback)
end

function SectionCardMeta:AddDropdown(arg1, arg2)
    local flag, label, cfg = parseArgs(arg1, arg2)
    local options = cfg.Options or cfg.Values or {}
    local multi = cfg.Multi or false
    local isLast = cfg.IsLast or false
    local callback = cfg.Callback or function() end

    local dObj = {
        Type = multi and "MultiDropdown" or "Dropdown",
        Values = options,
        Callback = callback
    }

    local item
    if multi then
        local def = type(cfg.Default) == "table" and cfg.Default or (cfg.Default and { cfg.Default } or {})
        dObj.Value = def
        item = addMultiDropdown(self.Container, label, options, def, isLast, function(l)
            dObj.Value = l
            pcall(callback, l)
        end, flag)
    else
        local def = type(cfg.Default) == "string" and cfg.Default or (options[1] or "")
        dObj.Value = def
        item = addDropdown(self.Container, label, options, def, cfg.HasGear or false, cfg.Open or false, isLast, function(v)
            dObj.Value = v
            pcall(callback, v)
        end, flag)
    end

    function dObj:SetValue(v)
        self.Value = v
        if item and item.Set then item.Set(v) end
    end
    function dObj:SetValues(newVals)
        self.Values = newVals
        if item and item.Refresh then item.Refresh(newVals, self.Value) end
    end
    function dObj:OnChanged(fn)
        local oldCb = self.Callback
        self.Callback = function(val)
            pcall(oldCb, val)
            pcall(fn, val)
        end
    end

    if getgenv().Options then getgenv().Options[flag] = dObj end
    return dObj
end

function TabMeta:CreateSection(columnSide, title)
    local targetCol = (columnSide == "right" or columnSide == 2) and self.Right or self.Left
    local container = createSectionCard(targetCol, title)
    return setmetatable({ Container = container, Column = targetCol }, SectionCardMeta)
end

-- НАСТОЯЩИЙ ПОЛНОФУНКЦИОНАЛЬНЫЙ КОНФИГ-МЕНЕДЖЕР
local HttpService = game:GetService("HttpService")

-- Резервное хранилище на случай отсутствия файлового API эксплойта
getgenv()._SavedConfigs = getgenv()._SavedConfigs or {}

local function hasFileSystem()
    return (type(writefile) == "function" and type(readfile) == "function")
end

local function ensureFolder()
    if hasFileSystem() and type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder(Library.ConfigFolder) then
            pcall(makefolder, Library.ConfigFolder)
        end
    end
end

function Library:GetConfigList()
    ensureFolder()
    local list = { "default" }
    local seen = { ["default"] = true }

    if hasFileSystem() and type(listfiles) == "function" then
        local ok, files = pcall(listfiles, Library.ConfigFolder)
        if ok and type(files) == "table" then
            for _, f in ipairs(files) do
                local clean = tostring(f):gsub("\\", "/")
                local name = clean:match("([^/]+)%.json$")
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(list, name)
                end
            end
        end
    end

    for name in pairs(getgenv()._SavedConfigs) do
        if not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end

    return list
end

function Library:SaveConfig(name)
    name = (name and name ~= "") and name or "default"
    ensureFolder()
    local data = {}
    local ignoredFlags = {
        ["active preset"] = true,
        ["config name"] = true,
        ["set as autoload"] = true
    }
    for flag, item in pairs(Library.Registry) do
        if item.Get and not ignoredFlags[flag] then
            data[flag] = item.Get()
        end
    end
    local json = HttpService:JSONEncode(data)
    getgenv()._SavedConfigs[name] = json

    if hasFileSystem() then
        local path = Library.ConfigFolder .. "/" .. name .. ".json"
        pcall(writefile, path, json)
    end
    return json
end

function Library:LoadConfig(name)
    name = (name and name ~= "") and name or "default"
    ensureFolder()
    local content = nil

    if hasFileSystem() and type(isfile) == "function" then
        local path = Library.ConfigFolder .. "/" .. name .. ".json"
        if isfile(path) then
            local ok, res = pcall(readfile, path)
            if ok and res and res ~= "" then
                content = res
            end
        end
    end

    if not content then
        content = getgenv()._SavedConfigs[name]
    end

    if not content then return false end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not ok or type(data) ~= "table" then return false end

    for flag, val in pairs(data) do
        local item = Library.Registry[flag]
        if item and item.Set then
            pcall(item.Set, val)
        end
    end
    return true
end

function Library:SetAutoLoad(name)
    ensureFolder()
    local cfg = tostring(name or "default")
    getgenv()._AutoLoadPreset = cfg
    if hasFileSystem() then
        pcall(writefile, Library.AutoLoadFile, cfg)
    end
end

function Library:CheckAutoLoad()
    ensureFolder()
    local name = nil
    if hasFileSystem() and type(isfile) == "function" and isfile(Library.AutoLoadFile) then
        local ok, res = pcall(readfile, Library.AutoLoadFile)
        if ok and res and res ~= "" then
            name = res:match("^%s*(.-)%s*$")
        end
    end
    if not name then
        name = getgenv()._AutoLoadPreset
    end
    if name and name ~= "" then
        Library:LoadConfig(name)
        return name
    end
    return nil
end

function Library:SetConfigsVisible(visible)
    Library.ShowConfigs = visible
    if ConfigsBtn then
        ConfigsBtn.Visible = visible
    end
end

function Library:SetConfigFolder(folderName)
    if folderName and folderName ~= "" then
        Library.ConfigFolder = folderName
        Library.AutoLoadFile = folderName .. "/autoload.txt"
        ensureFolder()
    end
end


function Library:GetTab(tabId)
    local page = TabPages[tabId] or createTabPage(tabId)
    return setmetatable({ TabId = tabId, Scroll = page.Scroll, Left = page.Left, Right = page.Right }, TabMeta)
end

-- Инициализируем страницы под все зарегистрированные вкладки
for _, item in ipairs(navConfig) do
    createTabPage(item.id)
end

-- Дефолтно активируем первую вкладку через switchTab
task.defer(function()
    switchTab("rage")
end)


-- 5. СЕКЦИИ ДЛЯ СЕКРЕТНОЙ ВКЛАДКИ SETTINGS (ОТКРЫВАЕТСЯ СТРЕЛОЧКОЙ У ПРОФИЛЯ)
local SettingsTab = Library:GetTab("settings")

local MenuSec = SettingsTab:CreateSection("left", "MENU SETTINGS")
MenuSec:AddToggle({ Name = "watermark", Default = true })
MenuSec:AddToggle({
    Name = "glass blur",
    Default = true,
    Callback = function(state)
        for _, part in ipairs(GlassParts) do
            part.Transparency = state and 0.98 or 1
        end
    end
})
MenuSec:AddSlider({ Name = "menu scale", Min = 80, Max = 120, Default = 100, Suffix = "%" })
MenuSec:AddButton({
    Name = "unload menu",
    Icon = "fingerprint",
    IsLast = true,
    Callback = function()
        Cleanup()
    end
})

local CreditsSec = SettingsTab:CreateSection("right", "CREDITS")
CreditsSec:AddToggle({ Name = "cs2 design reproduction", Default = true })
CreditsSec:AddToggle({ Name = "developed by sn3yt", Default = true })
CreditsSec:AddSlider({ Name = "version", Min = 1, Max = 10, Default = 2, Suffix = ".0", IsLast = true })

-- 6. СЕКЦИИ ДЛЯ ВКЛАДКИ CONFIGS (РАБОЧИЙ МЕНЕДЖЕР С ФАЙЛАМИ И АВТОЛОАДОМ)
createTabPage("configs")
local ConfigsTab = Library:GetTab("configs")
Library.ConfigsTab = ConfigsTab

local currentCfgName = "default"
local cfgDropdown = nil

local ConfigListSec = ConfigsTab:CreateSection("left", "PRESETS & STORAGE")
local nameInput = ConfigListSec:AddInput({
    Name = "config name",
    Default = "",
    Placeholder = "my-config...",
    Callback = function(val)
        if val and val:gsub("%s+", "") ~= "" then
            currentCfgName = val:gsub("%s+", "")
        end
    end
})
cfgDropdown = ConfigListSec:AddDropdown({
    Name = "active preset",
    Options = Library:GetConfigList(),
    Default = "default",
    Callback = function(selected)
        currentCfgName = selected
        if nameInput and nameInput.Set then
            nameInput.Set(selected)
        end
    end
})
ConfigListSec:AddButton({
    Name = "save config",
    Callback = function()
        local target = (nameInput and nameInput.Get() ~= "") and nameInput.Get() or currentCfgName
        target = target:gsub("%s+", "")
        if target == "" then target = "default" end
        Library:SaveConfig(target)
        currentCfgName = target
        if cfgDropdown and cfgDropdown.Refresh then
            cfgDropdown.Refresh(Library:GetConfigList(), currentCfgName)
        end
    end
})
ConfigListSec:AddButton({
    Name = "load config",
    Callback = function()
        Library:LoadConfig(currentCfgName)
        if cfgDropdown and cfgDropdown.Set then
            cfgDropdown.Set(currentCfgName)
        end
        if nameInput and nameInput.Set then
            nameInput.Set(currentCfgName)
        end
    end
})
ConfigListSec:AddButton({
    Name = "refresh files",
    IsLast = true,
    Callback = function()
        if cfgDropdown and cfgDropdown.Refresh then
            cfgDropdown.Refresh(Library:GetConfigList(), currentCfgName)
        end
    end
})

local ConfigShareSec = ConfigsTab:CreateSection("right", "AUTOMATION & SHARE")
ConfigShareSec:AddButton({
    Name = "set as autoload",
    Callback = function()
        local target = (nameInput and nameInput.Get() ~= "") and nameInput.Get() or currentCfgName
        target = target:gsub("%s+", "")
        if target == "" then target = "default" end
        Library:SetAutoLoad(target)
        print("Set " .. target .. " as autoload!")
    end
})
ConfigShareSec:AddButton({
    Name = "export to clipboard",
    Callback = function()
        local raw = Library:SaveConfig(currentCfgName)
        if setclipboard then setclipboard(raw) end
    end
})
ConfigShareSec:AddButton({
    Name = "import from clipboard",
    IsLast = true,
    Callback = function()
        if getclipboard then
            local clip = getclipboard()
            if clip and clip ~= "" then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, clip)
                if ok and type(data) == "table" then
                    for flag, val in pairs(data) do
                        if Library.Registry[flag] and Library.Registry[flag].Set then
                            pcall(Library.Registry[flag].Set, val)
                        end
                    end
                end
            end
        end
    end
})

-- Проверка и применение автолоада при запуске
task.defer(function()
    local loadedName = Library:CheckAutoLoad()
    if loadedName and loadedName ~= "" then
        currentCfgName = loadedName
        if cfgDropdown and cfgDropdown.Set then
            cfgDropdown.Set(loadedName)
        end
        if nameInput and nameInput.Set then
            nameInput.Set(loadedName)
        end
    end
end)

getgenv().BestUI = Library
return Library
