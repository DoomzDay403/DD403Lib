-- D00MLib: A simple and intuitive Roblox UI library
local D00MLib = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Utility functions
local Utilities = {}

function Utilities:MakeDraggable(frame, parentFrame)
    local dragging, dragInput, dragStart, startPos

    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        -- Ensure the parent frame (window) moves with the title bar
        if parentFrame then
            parentFrame.Position = frame.Position
        end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)
end

function Utilities:ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
end

function Utilities:Tween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Simple theme
local Theme = {
    WindowColor = Color3.fromRGB(30, 30, 30),
    TitleBarColor = Color3.fromRGB(20, 20, 20),
    TabColor = Color3.fromRGB(40, 40, 40),
    SectionColor = Color3.fromRGB(35, 35, 35),
    ButtonColor = Color3.fromRGB(50, 50, 50),
    TextColor = Color3.fromRGB(255, 255, 255),
    AccentColor = Color3.fromRGB(70, 70, 70),
    Font = Enum.Font.SourceSans,
    FontBold = Enum.Font.SourceSansBold,
    TextSize = 14
}

-- Window component
local Window = {}

function Window.new(config)
    config = config or {}
    local self = {
        Name = config.Name or "D00MLib", -- Revert to original naming
        Instance = nil,
        TabContainer = nil,
        ContentContainer = nil,
        Tabs = {},
        ActiveTab = nil
    }

    -- Wait for LocalPlayer and PlayerGui to be fully loaded
    local player = Players.LocalPlayer
    if not player then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = Players.LocalPlayer
    end
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("D00MLib: PlayerGui not found")
        return nil
    end

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "D00MLibGui"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false

    -- Create main window frame
    self.Instance = Instance.new("Frame")
    self.Instance.Size = UDim2.new(0, 400, 0, 300)
    self.Instance.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.Instance.BackgroundColor3 = Theme.WindowColor
    self.Instance.BorderSizePixel = 0
    self.Instance.Parent = screenGui

    Utilities:ApplyCorner(self.Instance)

    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Theme.TitleBarColor
    titleBar.BorderSizePixel = 0
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Parent = self.Instance -- Ensure title bar is parented to the window

    Utilities:ApplyCorner(titleBar)

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = self.Name
    titleText.TextColor3 = Theme.TextColor
    titleText.TextSize = Theme.TextSize
    titleText.Font = Theme.FontBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Make window draggable with title bar tied to the window
    Utilities:MakeDraggable(titleBar, self.Instance)

    -- Create tab bar
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Size = UDim2.new(1, -10, 0, 30)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 35)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.Instance

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabContainer

    -- Create content area
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -10, 1, -70)
    self.ContentContainer.Position = UDim2.new(0, 5, 0, 70)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Parent = self.Instance

    -- Window API
    function self:CreateTab(tabConfig)
        local tab = D00MLib.Components.Tab.new(tabConfig, self)
        table.insert(self.Tabs, tab)
        if not self.ActiveTab then
            tab:Activate()
            self.ActiveTab = tab
        end
        return tab
    end

    return self
end

-- Tab component
local Tab = {}

function Tab.new(config, window)
    config = config or {}
    local self = {
        Name = config.Name or "Tab",
        Button = nil,
        Content = nil,
        Window = window,
        Sections = {}
    }

    -- Create tab button
    self.Button = Instance.new("TextButton")
    self.Button.Size = UDim2.new(0, 80, 1, 0)
    self.Button.BackgroundColor3 = Theme.TabColor
    self.Button.Text = self.Name
    self.Button.TextColor3 = Theme.TextColor
    self.Button.TextSize = Theme.TextSize
    self.Button.Font = Theme.Font
    self.Button.Parent = window.TabContainer

    Utilities:ApplyCorner(self.Button, 4)

    -- Create tab content frame
    self.Content = Instance.new("Frame")
    self.Content.Size = UDim2.new(1, 0, 1, 0)
    self.Content.BackgroundTransparency = 1
    self.Content.Visible = false
    self.Content.Parent = window.ContentContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.Content

    -- Tab activation
    function self:Activate()
        if window.ActiveTab then
            window.ActiveTab.Content.Visible = false
            Utilities:Tween(window.ActiveTab.Button, {BackgroundColor3 = Theme.TabColor}, 0.2)
        end
        self.Content.Visible = true
        window.ActiveTab = self
        Utilities:Tween(self.Button, {BackgroundColor3 = Theme.AccentColor}, 0.2)
    end

    -- Tab button click
    self.Button.MouseButton1Click:Connect(function()
        self:Activate()
    end)

    -- Tab API
    function self:CreateSection(sectionConfig)
        local section = D00MLib.Components.Section.new(sectionConfig, self.Content)
        table.insert(self.Sections, section)
        return section
    end

    return self
end

-- Section component
local Section = {}

function Section.new(config, parent)
    config = config or {}
    local self = {
        Name = config.Name or "Section",
        Instance = nil,
        Components = {}
    }

    -- Create section frame
    self.Instance = Instance.new("Frame")
    self.Instance.Size = UDim2.new(1, 0, 0, 0)
    self.Instance.BackgroundColor3 = Theme.SectionColor
    self.Instance.AutomaticSize = Enum.AutomaticSize.Y
    self.Instance.Parent = parent

    Utilities:ApplyCorner(self.Instance, 4)

    -- Section padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = self.Instance

    -- Section layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.Instance

    -- Section label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = self.Name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.Instance

    -- Section API
    function self:CreateButton(buttonConfig)
        local button = D00MLib.Components.Button.new(buttonConfig, self.Instance)
        table.insert(self.Components, button)
        return button
    end

    function self:CreateSlider(sliderConfig)
        local slider = D00MLib.Components.Slider.new(sliderConfig, self.Instance)
        table.insert(self.Components, slider)
        return slider
    end

    return self
end

-- Button component
local Button = {}

function Button.new(config, parent)
    config = config or {}
    local self = {
        Name = config.Name or "Button",
        Callback = config.Callback or function() end,
        Instance = nil
    }

    -- Create button
    self.Instance = Instance.new("TextButton")
    self.Instance.Size = UDim2.new(1, 0, 0, 30)
    self.Instance.BackgroundColor3 = Theme.ButtonColor
    self.Instance.Text = self.Name
    self.Instance.TextColor3 = Theme.TextColor
    self.Instance.TextSize = Theme.TextSize
    self.Instance.Font = Theme.Font
    self.Instance.Parent = parent

    Utilities:ApplyCorner(self.Instance, 4)

    -- Button interaction
    self.Instance.MouseButton1Click:Connect(function()
        self.Callback()
    end)

    -- Hover animation
    self.Instance.MouseEnter:Connect(function()
        Utilities:Tween(self.Instance, {BackgroundColor3 = Theme.AccentColor}, 0.2)
    end)

    self.Instance.MouseLeave:Connect(function()
        Utilities:Tween(self.Instance, {BackgroundColor3 = Theme.ButtonColor}, 0.2)
    end)

    return self
end

-- Slider component
local Slider = {}

function Slider.new(config, parent)
    config = config or {}
    local self = {
        Name = config.Name or "Slider",
        Min = config.Min or 0,
        Max = config.Max or 100,
        Default = config.Default or 50,
        Callback = config.Callback or function() end,
        Instance = nil,
        Value = config.Default
    }

    -- Validate slider range
    if self.Min >= self.Max then
        self.Min, self.Max = 0, 100
    end
    self.Value = math.clamp(self.Default, self.Min, self.Max)

    -- Create slider frame
    self.Instance = Instance.new("Frame")
    self.Instance.Size = UDim2.new(1, 0, 0, 50)
    self.Instance.BackgroundTransparency = 1
    self.Instance.Parent = parent

    -- Slider label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = self.Name .. ": " .. self.Value
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.Instance

    -- Slider bar
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -10, 0, 10)
    sliderBar.Position = UDim2.new(0, 5, 0, 30)
    sliderBar.BackgroundColor3 = Theme.ButtonColor
    sliderBar.Parent = self.Instance

    Utilities:ApplyCorner(sliderBar, 4)

    -- Slider fill
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.AccentColor
    sliderFill.Parent = sliderBar

    Utilities:ApplyCorner(sliderFill, 4)

    -- Slider interaction
    local dragging = false

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = input.Position.X
            local barPos = sliderBar.AbsolutePosition.X
            local barWidth = sliderBar.AbsoluteSize.X
            local relativeX = math.clamp((mouseX - barPos) / barWidth, 0, 1)
            self.Value = math.floor(self.Min + (self.Max - self.Min) * relativeX)
            sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            label.Text = self.Name .. ": " .. self.Value
            self.Callback(self.Value)
        end
    end)

    return self
end

-- Component registry
D00MLib.Components = {
    Tab = Tab,
    Section = Section,
    Button = Button,
    Slider = Slider
}

-- Main API
function D00MLib:CreateWindow(config)
    return Window.new(config)
end

return D00MLib
