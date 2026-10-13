-- nhatkhanhhub_full_instant.lua
-- Best-effort merged hub file with "Dịch chuyển tức thời" (Instant Teleport) and Steal TweenSpeed boost.
-- Created from provided hub snippet + helper features. This is a best-effort full file: some internal complex logic kept as-is or elided
-- where original source was missing. After placing this file in your repo, you can run it in Roblox environment.

-- Core services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Small iterator utility (from original snippet)
local function geniter(f, s, c)
    if type(f) ~= "function" then
        local mt = getmetatable(f)

        if type(mt) == "table" and mt.__iter then
            f, s, c = mt.__iter(f)
        elseif type(f) == "table" then
            f, s, c = next, f, nil
        end
    end

    return function()
        local r = table.pack(f(s, c))

        if r[1] == nil then
            return false
        end

        c = r[1]

        return true, table.unpack(r, 1, r.n)
    end
end

-- =====================================================================
-- Helper: Instant Teleport and Stop Velocity (from bptl logic)
-- =====================================================================
local genv = getgenv and getgenv() or _G

-- Instant teleport config
genv.NK_InstantTeleport = genv.NK_InstantTeleport or {}
local IT = genv.NK_InstantTeleport
IT.Enabled = IT.Enabled == nil and true or IT.Enabled
IT.Yaw = IT.Yaw or 300
IT.DefaultOffset = IT.DefaultOffset or Vector3.new(12, 0, 12)
IT.ButtonEnabled = IT.ButtonEnabled == nil and true or IT.ButtonEnabled

-- Steal speed boost config
genv.NK_StealSpeedBoost = genv.NK_StealSpeedBoost or {}
local SB = genv.NK_StealSpeedBoost
SB.Enabled = SB.Enabled == nil and true or SB.Enabled
SB.Multiplier = SB.Multiplier or 2 -- gấp đôi
SB._origTween = nil
SB._active = false

local function StopVelocity(part)
    if not part then return end
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function GetRootPart()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsDescendantOf(workspace) then
        return root
    end
    return nil
end

local function ApplyInstantTeleport(targetPosition, yawDeg)
    if typeof(targetPosition) ~= "Vector3" then
        return false
    end

    local root = GetRootPart()
    if not root then return false end

    pcall(function()
        root.CFrame = CFrame.new(targetPosition.X, targetPosition.Y, targetPosition.Z) * CFrame.Angles(0, math.rad(yawDeg or IT.Yaw), 0)
        StopVelocity(root)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return true
end

local function InstantTeleportOffset(offsetVector3)
    local root = GetRootPart()
    if not root then return false end
    local pos = root.Position
    local dest = pos + (typeof(offsetVector3) == "Vector3" and offsetVector3 or IT.DefaultOffset)
    return ApplyInstantTeleport(dest, IT.Yaw)
end

-- Expose
IT.Apply = ApplyInstantTeleport
IT.Offset = InstantTeleportOffset
IT.GetRootPart = GetRootPart

-- =====================================================================
-- Steal speed boost helpers
-- =====================================================================
local function StartStealSpeedBoost()
    if not SB.Enabled or SB._active then return end
    SB._active = true
    -- attempt to modify senaV4Config.TweenSpeedMultiplier if present
    pcall(function()
        if type(_G.senaV4Config) == "table" then
            SB._origTween = _G.senaV4Config.TweenSpeedMultiplier
            local orig = tonumber(_G.senaV4Config.TweenSpeedMultiplier) or 60
            _G.senaV4Config.TweenSpeedMultiplier = orig * SB.Multiplier
        end
    end)
end

local function StopStealSpeedBoost()
    if not SB._active then return end
    SB._active = false
    pcall(function()
        if type(_G.senaV4Config) == "table" and SB._origTween then
            _G.senaV4Config.TweenSpeedMultiplier = SB._origTween
        end
        SB._origTween = nil
    end)
end

-- Expose speed boost
SB.Start = StartStealSpeedBoost
SB.Stop = StopStealSpeedBoost

-- =====================================================================
-- Best-effort: inject search item and process wrapper
-- =====================================================================
pcall(function()
    -- Try common globals
    local tryNames = {"SearchItems", "searchItems", "SearchList", "searchList", "SearchMenuItems"}
    for _, name in ipairs(tryNames) do
        local ok, tbl = pcall(function() return rawget(_G, name) end)
        if ok and type(tbl) == "table" then
            local found = false
            for _, v in ipairs(tbl) do
                if tostring(v) == "Dịch chuyển tức thời" or tostring(v) == "InstantTeleport" then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(tbl, "Dịch chuyển tức thời")
            end
        end
    end
end)

-- If there is a global function processing menu options, wrap it
if rawget(_G, "ProcessSearchOption") then
    local old = rawget(_G, "ProcessSearchOption")
    _G.ProcessSearchOption = function(option, ...)
        if tostring(option) == "Dịch chuyển tức thời" or tostring(option) == "InstantTeleport" then
            local root = GetRootPart()
            if root then
                ApplyInstantTeleport(root.Position + IT.DefaultOffset, IT.Yaw)
            end
            return
        end
        return old(option, ...)
    end
end

-- =====================================================================
-- UI: add mobile-friendly button for instant teleport
-- =====================================================================
local function BuildInstantButton()
    if not IT.ButtonEnabled then return end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end
    if playerGui:FindFirstChild("NK_InstantTP_Button") then return end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NK_InstantTP_Button"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = playerGui

    local button = Instance.new("TextButton")
    button.Name = "InstantTP"
    button.Text = "Dịch chuyển tức thời"
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(240,240,245)
    button.BackgroundColor3 = Color3.fromRGB(45,45,48)
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(160, 36)
    button.Position = UDim2.new(1, -170, 1, -90)
    button.AnchorPoint = Vector2.new(0, 0)
    button.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        local root = GetRootPart()
        if root then
            ApplyInstantTeleport(root.Position + IT.DefaultOffset, IT.Yaw)
        end
    end)
end

if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
    pcall(BuildInstantButton)
else
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        pcall(BuildInstantButton)
    end)
end

-- Desktop helper: double-tap R to teleport
local lastPress = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.R then
            local now = tick()
            if now - lastPress < 0.35 then
                InstantTeleportOffset(IT.DefaultOffset)
            end
            lastPress = now
        end
    end
end)

-- =====================================================================
-- Inserted: helpers and placeholders integrated into hub
-- Now include original hub snippet core (best-effort):
-- Note: large parts of original hub script omitted/trimmed for brevity.
-- We keep original variables and core runtime behavior where available.
-- =====================================================================

-- (Original hub content begins - trimmed for best-effort integration)

-- Many original runtime variables and functions were preserved earlier in the snippet you provided.
-- We'll ensure the new StealMode option is present in the main config and a simple handler is added.

local senaV4Config = {
    AutoSteal = false,
    HelpFriend = false,
    ScrambleTradeInTrade = false,
    ScrambleTradeInReroll = false,
    ScrambleTradeInBanners = {},
    ScrambleBossAuto = false,
    StealMode = "Fly",
    InstantTeleport = false, -- new flag
    FlyAerial = false,
    StealHoldSeconds = 5,
    StealAreas = { "None" },
    StealRarities = { "None" },
    StealNamesFilter = { "None" },
    StealMinValue = 0,
    StealMutations = { "None" },
    StealMinWeight = 0,
    StealPriority = "Rarity",
    AutoFavorite = false,
    FavMode = "Rarity",
    FavRarities = { "None" },
    FavSpecies = { "None" },
    AutoEquipBest = false,
    AutoClaimOffline = false,
    AutoBaseUpgrade = false,
    AutoClaimAlmanac = false,
    AutoFusePets = false,
    ScrambleFarmDrones = false,
    ScrambleLostParts = false,
    ScrambleCollectSamples = false,
    ScrambleAutoVault = false,
    ScrambleAutoBuy = false,
    ScrambleAreas = {},
    ScrambleDroneTypes = {},
    ScrambleBuyList = {},
    ButterflyAutoNet = false,
    ButterflyAutoCatch = false,
    ButterflyEsp = false,
    ButterflyTiers = {},
    ButterflyAutoTrade = false,
    ButterflyTradeRecipe = "All",
    ButterflyCatchMode = "Tween",
    ButterflyAutoCraft = false,
    Noclip = false,
    BottingMode = false,
    AntiCutscene = false,
    FuseSelectedOnly = false,
    FuseRarities = { "None" },
    FuseSpecies = { "None" },
    EspDetails = { "Name", "Rarity", "Value" },
    BackpackRateEsp = false,
    AntiAFK = true,
    AutoReconnect = true,
    AutoExecute = false,
    AutoPlace = false,
    PlaceRarities = { "None" },
    AutoHatch = false,
    SellAll = false,
    AutoSell = false,
    SellNames = { "None" },
    SellRarities = { "None" },
    AutoSellEgg = false,
    SellEggRarities = { "None" },
    WebhookEnabled = false,
    WebhookURL = "",
    TweenSpeedMultiplier = 60,
    AutoTreadmillIdle = false,
    AutoTreadmillUpgrade = false,
    AntiTreadmill = false,
    HopNoMatch = false,
    PrivateServerMax = "2",
    PrivateServerAuto = false,
    HopCooldown = 5,
    AutoIndex = false,
    AntiHitGuard = false,
    FlyForCapture = false,
    AutoStealCapture = false,
    InstantGrab = false,
    InfiniteJump = false,
    WalkSpeedMultiplier = 1,
    AntiGuardKnockback = true,
    GodMode = true,
    EggPredictUI = false,
    EggESP = false,
    StealPlayers = false,
    StealPlayerRarities = { "None" },
    StealPlayerMinValue = 0,
    StealPlayerTarget = "Any Player",
    WebhookRarities = { "None" },
    WebhookMinValue = 0
}

-- Placeholder: original hub logic continues here (omitted large sections). The following handler is a
-- best-effort integration point: when the hub decides to perform a steal movement, it may call this.

local function HubPerformStealMovement()
    -- This function should be called by the hub when it wants to move the player to grab an egg.
    -- Best-effort: implement behavior depending on StealMode.
    local root = GetRootPart()
    if not root then return false end

    local mode = tostring(senaV4Config.StealMode or ""):lower()

    if mode == "fly" then
        -- existing hub fly logic (kept external in original script)
        -- We don't override here.
        return false
    elseif mode == "instantteleport" or senaV4Config.InstantTeleport == true then
        -- Start speed boost if enabled
        StartStealSpeedBoost()

        -- Teleport to a target relative position (best-effort uses DefaultOffset)
        local ok = ApplyInstantTeleport(root.Position + IT.DefaultOffset, IT.Yaw)

        -- Stop speed boost after short delay
        task.spawn(function()
            task.wait(0.5)
            StopStealSpeedBoost()
        end)

        return ok
    else
        -- other modes: best-effort no-op
        return false
    end
end

-- Try to hook into existing hub steal flow if there's a known handler name
pcall(function()
    if rawget(_G, "PerformStealMovement") == nil then
        rawset(_G, "PerformStealMovement", HubPerformStealMovement)
    end
end)

-- =====================================================================
-- End of best-effort hub file
-- =====================================================================

return {
    InstantTeleport = IT,
    StealSpeedBoost = SB,
    PerformStealMovement = HubPerformStealMovement,
}
