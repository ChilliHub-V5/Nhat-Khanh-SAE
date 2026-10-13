-- nhatkhanhhub_instant_teleport.lua
-- Helper cho "Dịch chuyển tức thời" (Instant Teleport) tích hợp với Nhat Khanh Hub.
-- File này là module độc lập: lưu vào repo và sau đó chèn/require hoặc loadstring trong hub chính.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local genv = getgenv and getgenv() or _G
genv.NK_InstantTeleport = genv.NK_InstantTeleport or {}
local cfg = genv.NK_InstantTeleport

-- cấu hình mặc định (có thể thay đổi ở runtime bằng getgenv().NK_InstantTeleport)
cfg.Enabled = cfg.Enabled == nil and true or cfg.Enabled
cfg.Yaw = cfg.Yaw or 300 -- góc quay mặc định (độ)
cfg.DefaultOffset = cfg.DefaultOffset or Vector3.new(12, 0, 12) -- dịch tương đối mặc định khi trigger
cfg.ButtonEnabled = cfg.ButtonEnabled == nil and true or cfg.ButtonEnabled

-- Safe root getter
local function GetRootPart()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsDescendantOf(workspace) then
        return root
    end
    return nil
end

-- Dừng vận tốc an toàn (từ bptl logic)
local function StopVelocity(part)
    if not part then return end
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

-- Đặt CFrame chính xác và dừng vận tốc
local function ApplyInstantTeleport(targetPosition, yawDeg)
    if typeof(targetPosition) ~= "Vector3" then
        return false
    end

    local root = GetRootPart()
    if not root then return false end

    pcall(function()
        root.CFrame = CFrame.new(targetPosition.X, targetPosition.Y, targetPosition.Z) * CFrame.Angles(0, math.rad(yawDeg or cfg.Yaw), 0)
        StopVelocity(root)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return true
end

-- Dịch tương đối so với vị trí hiện tại (tiện cho test)
local function InstantTeleportOffset(offsetVector3)
    local root = GetRootPart()
    if not root then return false end
    local pos = root.Position
    local dest = pos + (typeof(offsetVector3) == "Vector3" and offsetVector3 or cfg.DefaultOffset)
    return ApplyInstantTeleport(dest, cfg.Yaw)
end

-- Expose functions lên getgenv để hub gọi
genv.NK_InstantTeleport.Apply = ApplyInstantTeleport
genv.NK_InstantTeleport.Offset = InstantTeleportOffset
genv.NK_InstantTeleport.GetRootPart = GetRootPart
genv.NK_InstantTeleport.Config = cfg

-- Nếu hub có biến global senaV4Config, thêm key để chỗ xử lý StealMode có thể dùng
pcall(function()
    if _G and type(_G.senaV4Config) == "table" then
        local s = _G.senaV4Config
        if type(s.StealMode) == "string" then
            s.InstantTeleportMode = s.InstantTeleportMode or "InstantTeleport"
        end
    end
end)

-- Tạo nút UI đơn giản (dành cho mobile) để test instant teleport
local function BuildButton()
    if not cfg.ButtonEnabled then return end
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
        local success = InstantTeleportOffset(cfg.DefaultOffset)
        if not success then
            local base = Vector3.new(528.7, 70.57, -364.11)
            ApplyInstantTeleport(base, cfg.Yaw)
        end
    end)
end

if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
    pcall(BuildButton)
else
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        pcall(BuildButton)
    end)
end

-- Desktop helper: double-tap R để teleport (giúp test nhanh nếu đang dùng bàn phím)
local lastPress = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.R then
            local now = tick()
            if now - lastPress < 0.35 then
                InstantTeleportOffset(cfg.DefaultOffset)
            end
            lastPress = now
        end
    end
end)

-- Best-effort: thêm mục "Dịch chuyển tức thời" vào các SearchLists global nếu có
pcall(function()
    local tryNames = {"SearchItems", "searchItems", "SearchList", "searchList", "SearchMenuItems"}
    for _, name in ipairs(tryNames) do
        local ok, tbl = pcall(function() return rawget(_G, name) end)
        if ok and type(tbl) == "table" then
            local found = false
            for _, v in ipairs(tbl) do
                if type(v) == "string" and (v == "Dịch chuyển tức thời" or v == "InstantTeleport") then
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

return {
    Apply = ApplyInstantTeleport,
    Offset = InstantTeleportOffset,
    GetRootPart = GetRootPart,
    Config = cfg,
}
