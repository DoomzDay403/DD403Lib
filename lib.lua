-- D00MLib: A simple and reliable Roblox UI library
local D00MLib = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Internal utilities
local Internal = {}

-- Theme configuration
Internal.Theme = {
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

-- Utility: Make a frame draggable
function Internal:MakeDraggable(dragHandle, target)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            target.Position = newPosition
        end
    end)
end

-- Utility: Apply rounded corners
function Internal:ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
end

-- Utility: Tween animation
function Internal:Tween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Utility: Wait for PlayerGui with retries
function Internal:WaitForPlayerGui()
    local maxRetries, retryDelay = 5, 1
    for i = 1, maxRetries do
        local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
        if player then
            local playerGui = player:WaitForChild("PlayerGui", 10)
            if playerGui then return playerGui end
        end
        if i < maxRetries then wait(retryDelay) end
    end
    warn("D00MLib: Failed to find PlayerGui after retries")
    return nil
end

-- Utility: Clean up existing GUI
function Internal:CleanupGui(playerGui)
    local existingGui = playerGui:FindFirstChild("D00MLibGui")
    if existingGui then existingGui:Destroy() end
end

-- Window class
local Window = {}
Window.__index = Window

function Window.new(options)
    options = options or {}
    local self = setmetatable({}, Window)

    -- Ensure PlayerGui is ready
    local playerGui = Internal:WaitForPlayerGui()
    if not playerGui then return nil end

    -- Clean up existing GUI
    Internal:CleanupGui(playerGui)

    self.Name = options.Name or "D00MLib"
    self.Tabs = {}
    self.ActiveTab = nil

    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "D00MLibGui"
    self.ScreenGui.Parent = playerGui
    self.ScreenGui.ResetOnSpawn = false

    -- Create main window frame
    self.WindowFrame = Instance.new("Frame")
    self.WindowFrame.Size = UDim2.new(0, 400, 0, 300)
    self.WindowFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.WindowFrame.BackgroundColor3 = Internal.Theme.WindowColor
    self.WindowFrame.BorderSizePixel = 0
    self.WindowFrame.Parent = self.ScreenGui
    Internal:ApplyCorner(self.WindowFrame)

    -- Create title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    self.TitleBar.BackgroundColor3 = Internal.Theme.TitleBarColor
    self.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    self.TitleBar.Parent = self.WindowFrame
    Internal:ApplyCorner(self.TitleBar)

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = self.Name
    titleText.TextColor3 = Internal.Theme.TextColor
    titleText.TextSize = Internal.Theme.TextSize
    titleText.Font = Internal.Theme.FontBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = self.TitleBar

    -- Make draggable
    Internal:MakeDraggable(self.TitleBar, self.WindowFrame)

    -- Create tab bar
    self.TabBar = Instance.new("Frame")
    self.TabBar.Size = UDim2.new(1, -10, 0, 30)
    self.TabBar.Position = UDim2.new(0, 5, 0, 35)
    self.TabBar.BackgroundTransparency = 1
    self.TabBar.Parent = self.WindowFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabBar

    -- Create content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -10, 1, -70)
    self.ContentArea.Position = UDim2.new(0, 5, 0, 70)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.WindowFrame

    return self
end

function Window:AddTab(name)
    local tab = {
        Name = name or "Tab",
        Gui = self,
        Sections = {},
        Content = nil,
        Button = nil
    }

    function tab:Activate()
        if self.Gui.ActiveTab then
            self.Gui.ActiveTab.Content.Visible = false
            Internal:Tween(self.Gui.ActiveTab.Button, {BackgroundColor3 = Internal.Theme.TabColor}, 0.2)
        end
        self.Content.Visible = true
        self.Gui.ActiveTab = self
        Internal:Tween(self.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
    end

    tab.Button = Instance.new("TextButton")
    tab.Button.Size = UDim2.new(0, 80, 1, 0)
    tab.Button.BackgroundColor3 = Internal.Theme.TabColor
    tab.Button.Text = tab.Name
    tab.Button.TextColor3 = Internal.Theme.TextColor
    tab.Button.TextSize = Internal.Theme.TextSize
    tab.Button.Font = Internal.Theme.Font
    tab.Button.Parent = self.TabBar
    Internal:ApplyCorner(tab.Button, 4)

    tab.Content = Instance.new("Frame")
    tab.Content.Size = UDim2.new(1, 0, 1, 0)
    tab.Content.BackgroundTransparency = 1
    tab.Content.Visible = false
    tab.Content.Parent = self.ContentArea

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = tab.Content

    tab.Button.MouseButton1Click:Connect(function() tab:Activate() end)

    if not self.ActiveTab then tab:Activate() self.ActiveTab = tab end
    table.insert(self.Tabs, tab)

    function tab:AddSection(name)
        local section = {
            Name = name or "Section",
            Tab = tab,
            Frame = nil,
            Components = {}
        }

        section.Frame = Instance.new("Frame")
        section.Frame.Size = UDim2.new(1, 0, 0, 0)
        section.Frame.BackgroundColor3 = Internal.Theme.SectionColor
        section.Frame.AutomaticSize = Enum.AutomaticSize.Y
        section.Frame.Parent = tab.Content
        Internal:ApplyCorner(section.Frame, 4)

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 5)
        padding.PaddingLeft = UDim.new(0, 5)
        padding.PaddingRight = UDim.new(0, 5)
        padding.Parent = section.Frame

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 5)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = section.Frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = section.Name
        label.TextColor3 = Internal.Theme.TextColor
        label.TextSize = Internal.Theme.TextSize
        label.Font = Internal.Theme.FontBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = section.Frame

        table.insert(tab.Sections, section)

        function section:AddButton(name, callback)
            local button = {
                Name = name or "Button",
                Callback = callback or function() end
            }

            button.Button = Instance.new("TextButton")
            button.Button.Size = UDim2.new(1, 0, 0, 30)
            button.Button.BackgroundColor3 = Internal.Theme.ButtonColor
            button.Button.Text = button.Name
            button.Button.TextColor3 = Internal.Theme.TextColor
            button.Button.TextSize = Internal.Theme.TextSize
            button.Button.Font = Internal.Theme.Font
            button.Button.Parent = section.Frame
            Internal:ApplyCorner(button.Button, 4)

            button.Button.MouseButton1Click:Connect(function() button.Callback() end)

            button.Button.MouseEnter:Connect(function()
                Internal:Tween(button.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
            end)

            button.Button.MouseLeave:Connect(function()
                Internal:Tween(button.Button, {BackgroundColor3 = Internal.Theme.ButtonColor}, 0.2)
            end)

            table.insert(section.Components, button)
            return section
        end

        function section:AddSlider(name, min, max, default, callback)
            local slider = {
                Name = name or "Slider",
                Min = min or 0,
                Max = max or 100,
                Default = default or 50,
                Callback = callback or function() end,
                Value = default or 50
            }

            if slider.Min >= slider.Max then slider.Min, slider.Max = 0, 100 end
            slider.Value = math.clamp(slider.Default, slider.Min, slider.Max)

            slider.Frame = Instance.new("Frame")
            slider.Frame.Size = UDim2.new(1, 0, 0, 50)
            slider.Frame.BackgroundTransparency = 1
            slider.Frame.Parent = section.Frame

            slider.Label = Instance.new("TextLabel")
            slider.Label.Size = UDim2.new(1, -10, 0, 20)
            slider.Label.Position = UDim2.new(0, 5, 0, 5)
            slider.Label.BackgroundTransparency = 1
            slider.Label.Text = slider.Name .. ": " .. slider.Value
            slider.Label.TextColor3 = Internal.Theme.TextColor
            slider.Label.TextSize = Internal.Theme.TextSize
            slider.Label.Font = Internal.Theme.Font
            slider.Label.TextXAlignment = Enum.TextXAlignment.Left
            slider.Label.Parent = slider.Frame

            slider.Bar = Instance.new("Frame")
            slider.Bar.Size = UDim2.new(1, -10, 0, 10)
            slider.Bar.Position = UDim2.new(0, 5, 0, 30)
            slider.Bar.BackgroundColor3 = Internal.Theme.ButtonColor
            slider.Bar.Parent = slider.Frame
            Internal:ApplyCorner(slider.Bar, 4)

            slider.Fill = Instance.new("Frame")
            slider.Fill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
            slider.Fill.BackgroundColor3 = Internal.Theme.AccentColor
            slider.Fill.Parent = slider.Bar
            Internal:ApplyCorner(slider.Fill, 4)

            local dragging = false

            slider.Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)

            slider.Bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mouseX = input.Position.X
                    local barPos = slider.Bar.AbsolutePosition.X
                    local barWidth = slider.Bar.AbsoluteSize.X
                    local relativeX = math.clamp((mouseX - barPos) / barWidth, 0, 1)
                    slider.Value = math.floor(slider.Min + (slider.Max - slider.Min) * relativeX)
                    slider.Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                    slider.Label.Text = slider.Name .. ": " .. slider.Value
                    slider.Callback(slider.Value)
                end
            end)

            table.insert(section.Components, slider)
            return section
        end

        return section
    end

    return tab
end

-- Public API
function D00MLib:MakeGui(options)
    return Window.new(options)
end

return D00MLib
