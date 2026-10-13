-- NhatKhanhUI.lua
-- Standalone Roblox/Luau UI library for projects you own.
-- API-compatible starter for Window / AddTab / AddSection and common controls.
-- Branding: NhatKhanh Hub | Remake bởi NhatKhanh
-- No external HTTP library dependency.

local NhatKhanhUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local COLORS = {
    Background = Color3.fromRGB(22, 20, 29),
    Panel = Color3.fromRGB(31, 28, 40),
    Panel2 = Color3.fromRGB(40, 35, 51),
    Accent = Color3.fromRGB(226, 120, 255),
    Text = Color3.fromRGB(248, 242, 255),
    Muted = Color3.fromRGB(178, 166, 190),
    Stroke = Color3.fromRGB(77, 61, 91),
    Good = Color3.fromRGB(112, 231, 166),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function stroke(parent, color, thickness)
    make("UIStroke", {
        Color = color or COLORS.Stroke,
        Thickness = thickness or 1,
        Transparency = 0.15
    }, parent)
end

local function text(parent, value, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = size or 13,
        TextColor3 = color or COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 20)
    }, parent)
end

local function button(parent, label, height)
    local b = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = COLORS.Panel2,
        Size = UDim2.new(1, 0, 0, height or 34),
        Text = tostring(label or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = COLORS.Text
    }, parent)
    corner(b, 7)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.Stroke}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.Panel2}):Play()
    end)
    return b
end

local function addList(parent, padding)
    local list = make("UIListLayout", {
        Padding = UDim.new(0, padding or 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, parent)
    return list
end

local function draggable(handle, target)
    local dragging, startInput, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput.Position
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function makeControl(parent, title, description)
    local holder = make("Frame", {
        BackgroundColor3 = COLORS.Panel,
        Size = UDim2.new(1, 0, 0, description and 62 or 43),
        AutomaticSize = Enum.AutomaticSize.Y
    }, parent)
    corner(holder, 7)
    local pad = make("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)
    }, holder)
    local layout = addList(holder, 4)
    text(holder, title or "Tùy chọn", 13, COLORS.Text, true)
    if description and description ~= "" then
        text(holder, description, 11, COLORS.Muted, false)
    end
    return holder
end

local function addMethods(target, methods)
    for k, v in pairs(methods) do target[k] = v end
    return target
end

function NhatKhanhUI:Window(options)
    options = options or {}
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("NhatKhanhHubUI")
    if old then old:Destroy() end

    local gui = make("ScreenGui", {
        Name = "NhatKhanhHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, playerGui)

    local main = make("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(560, 420),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0
    }, gui)
    corner(main, 12)
    stroke(main, COLORS.Stroke, 1)

    local top = make("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0
    }, main)
    corner(top, 12)
    local title = text(top, options.Title or "NhatKhanh Hub", 17, COLORS.Text, true)
    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.new(1, -100, 0, 24)
    local footer = text(top, options.Footer or "Remake bởi NhatKhanh", 11, COLORS.Accent, false)
    footer.Position = UDim2.fromOffset(16, 34)
    footer.Size = UDim2.new(1, -100, 0, 17)
    local close = make("TextButton", {
        Name = "Close",
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = COLORS.Text,
        BackgroundColor3 = COLORS.Panel2,
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -46, 0, 14)
    }, top)
    corner(close, 8)
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)
    draggable(top, main)

    local sidebar = make("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(10, 72),
        Size = UDim2.new(0, 150, 1, -84),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new()
    }, main)
    corner(sidebar, 8)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7)
    }, sidebar)
    local tabLayout = addList(sidebar, 6)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebar.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 16)
    end)

    local content = make("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(170, 72),
        Size = UDim2.new(1, -180, 1, -84),
        BackgroundTransparency = 1
    }, main)

    local window = {Gui = gui, Main = main, Tabs = {}, _content = content, _sidebar = sidebar}
    function window:DestroyGui() gui:Destroy() end
    function window:Toggle() gui.Enabled = not gui.Enabled end
    function window:AddTab(tabOptions)
        tabOptions = type(tabOptions) == "table" and tabOptions or {Name = tostring(tabOptions)}
        local tabName = tabOptions.Name or "Tab"
        local tabButton = button(sidebar, (tabOptions.Icon and (tostring(tabOptions.Icon) .. "  ") or "") .. tabName, 34)
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        local tabPad = make("UIPadding", {PaddingLeft = UDim.new(0, 9)}, tabButton)
        local page = make("ScrollingFrame", {
            Name = "Page_" .. tabName,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            Visible = #self.Tabs == 0,
            CanvasSize = UDim2.new()
        }, content)
        make("UIPadding", {
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6)
        }, page)
        local pageLayout = addList(page, 10)
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 16)
        end)
        local tab = {Button = tabButton, Page = page}
        function tab:AddSection(name)
            local sectionFrame = make("Frame", {
                BackgroundColor3 = COLORS.Panel2,
                Size = UDim2.new(1, 0, 0, 48),
                AutomaticSize = Enum.AutomaticSize.Y
            }, page)
            corner(sectionFrame, 9)
            make("UIPadding", {
                PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)
            }, sectionFrame)
            local sectionLayout = addList(sectionFrame, 7)
            text(sectionFrame, name or "Mục", 14, COLORS.Accent, true)
            local section = {Frame = sectionFrame}
            function section:AddToggle(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Bật / Tắt", opts.Content)
                local state = opts.Default == true
                local toggle = button(row, state and "ĐANG BẬT  ✓" or "ĐANG TẮT  ○", 30)
                toggle.BackgroundColor3 = state and Color3.fromRGB(57, 93, 76) or COLORS.Panel2
                local api = {Value = state}
                function api:Set(v)
                    state = v == true
                    api.Value = state
                    toggle.Text = state and "ĐANG BẬT  ✓" or "ĐANG TẮT  ○"
                    toggle.BackgroundColor3 = state and Color3.fromRGB(57, 93, 76) or COLORS.Panel2
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, state) end
                end
                toggle.MouseButton1Click:Connect(function() api:Set(not state) end)
                if opts.Default == true and type(opts.Callback) == "function" then task.spawn(opts.Callback, true) end
                return api
            end
            function section:AddButton(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Nút", opts.Content)
                local b = button(row, opts.Title or "Chạy", 32)
                b.MouseButton1Click:Connect(function()
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback) end
                end)
                return {Button = b}
            end
            function section:AddDropdown(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Danh sách", opts.Content)
                local selected = opts.Default
                local choices = opts.Options or {}
                local index = 1
                for i, value in ipairs(choices) do if value == selected then index = i end end
                local b = button(row, tostring(selected or choices[1] or "Chọn"), 32)
                local api = {Value = selected}
                local function advance()
                    if #choices == 0 then return end
                    index = index % #choices + 1
                    selected = choices[index]
                    api.Value = selected
                    b.Text = tostring(selected)
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, selected) end
                end
                b.MouseButton1Click:Connect(advance)
                function api:Set(value)
                    for i, item in ipairs(choices) do
                        if item == value then index = i; selected = value; api.Value = value; b.Text = tostring(value); break end
                    end
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, selected) end
                end
                return api
            end
            function section:AddSlider(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Thanh điều chỉnh", opts.Content)
                local minV, maxV = tonumber(opts.Min) or 0, tonumber(opts.Max) or 100
                local value = math.clamp(tonumber(opts.Default) or minV, minV, maxV)
                local b = button(row, tostring(value), 30)
                local api = {Value = value}
                local direction = 1
                b.MouseButton1Click:Connect(function()
                    value = value + (maxV - minV) / 10 * direction
                    if value >= maxV then value = maxV; direction = -1 elseif value <= minV then value = minV; direction = 1 end
                    value = math.floor(value * 100) / 100
                    api.Value = value; b.Text = tostring(value)
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, value) end
                end)
                function api:Set(v)
                    value = math.clamp(tonumber(v) or minV, minV, maxV)
                    api.Value = value; b.Text = tostring(value)
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, value) end
                end
                return api
            end
            function section:AddInput(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Nhập nội dung", opts.Content)
                local box = make("TextBox", {
                    ClearTextOnFocus = false,
                    Text = tostring(opts.Default or ""),
                    PlaceholderText = tostring(opts.Placeholder or "Nhập..."),
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = COLORS.Text,
                    PlaceholderColor3 = COLORS.Muted,
                    BackgroundColor3 = COLORS.Background,
                    Size = UDim2.new(1, 0, 0, 32)
                }, row)
                corner(box, 6)
                box.FocusLost:Connect(function()
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, box.Text) end
                end)
                return {Input = box, Set = function(_, v) box.Text = tostring(v or "") end}
            end
            function section:AddParagraph(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Thông tin", opts.Content or opts.Text)
                return {Frame = row, SetContent = function(_, v) end}
            end
            function section:AddKeybind(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Phím tắt", opts.Content)
                local key = opts.Default or Enum.KeyCode.RightShift
                local b = button(row, tostring(key):gsub("Enum.KeyCode%.", ""), 30)
                local listening = false
                b.MouseButton1Click:Connect(function() listening = true; b.Text = "Nhấn phím..." end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening and not processed and input.KeyCode ~= Enum.KeyCode.Unknown then
                        key = input.KeyCode; listening = false
                        b.Text = tostring(key):gsub("Enum.KeyCode%.", "")
                        if type(opts.Callback) == "function" then task.spawn(opts.Callback, key) end
                    elseif not processed and input.KeyCode == key and type(opts.Callback) == "function" then
                        task.spawn(opts.Callback, key)
                    end
                end)
                return {Value = key}
            end
            function section:AddColorPicker(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Màu sắc", opts.Content)
                local b = button(row, "Đổi màu", 30)
                local colors = {Color3.fromRGB(226,120,255), Color3.fromRGB(100,190,255), Color3.fromRGB(112,231,166), Color3.fromRGB(255,190,100)}
                local idx = 1
                b.MouseButton1Click:Connect(function()
                    idx = idx % #colors + 1
                    b.BackgroundColor3 = colors[idx]
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback, colors[idx]) end
                end)
                return {Set = function(_, c) if typeof(c) == "Color3" then b.BackgroundColor3 = c end end}
            end
            function section:AddActionList(opts)
                opts = opts or {}
                local row = makeControl(sectionFrame, opts.Title or "Danh sách thao tác", opts.Content)
                local b = button(row, "Thực hiện", 30)
                b.MouseButton1Click:Connect(function()
                    if type(opts.Callback) == "function" then task.spawn(opts.Callback) end
                end)
                return {Button = b}
            end
            function section:AddSubSection(name) return tab:AddSection(name) end
            function section:AddForum(opts) return section:AddParagraph({Title = (opts and opts.Title) or "Thông tin", Content = (opts and opts.Content) or ""}) end
            return section
        end
        tabButton.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do t.Page.Visible = false end
            page.Visible = true
        end)
        table.insert(self.Tabs, tab)
        return tab
    end
    return window
end

return NhatKhanhUI
