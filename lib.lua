-- D00MLib: A branded and feature-rich Roblox UI library
local D00MLib = {
    currentGui = nil,
    currentTab = nil,
    currentSection = nil,
    loadingAnimation = {
        type = "pulse",
        speed = 1,
        active = false,
        frame = nil
    }
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- Utility: Convert hex to Color3
function Internal:HexToColor(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16) or 0,
        tonumber(hex:sub(3, 4), 16) or 0,
        tonumber(hex:sub(5, 6), 16) or 0
    )
end

-- Utility: Make a frame draggable
function Internal:MakeDraggable(dragHandle, target)
    local dragging = false
    local dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, target.Position
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
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

-- Loading Animation Manager
function D00MLib:StartLoadingAnimation()
    if self.loadingAnimation.active then return end
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.new(0, 50, 0, 50)
    loadingFrame.Position = UDim2.new(0.5, -25, 0.5, -25)
    loadingFrame.BackgroundColor3 = Internal.Theme.AccentColor
    loadingFrame.Parent = game.Players.LocalPlayer.PlayerGui
    Internal:ApplyCorner(loadingFrame, 8)
    self.loadingAnimation.frame = loadingFrame
    self.loadingAnimation.active = true
    spawn(function()
        while self.loadingAnimation.active do
            if self.loadingAnimation.type == "pulse" then
                Internal:Tween(loadingFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.5 / self.loadingAnimation.speed)
                wait(0.5 / self.loadingAnimation.speed)
                Internal:Tween(loadingFrame, {Size = UDim2.new(0, 50, 0, 50)}, 0.5 / self.loadingAnimation.speed)
                wait(0.5 / self.loadingAnimation.speed)
            elseif self.loadingAnimation.type == "spin" then
                local rotation = 0
                while self.loadingAnimation.active do
                    rotation = (rotation + 10 * self.loadingAnimation.speed) % 360
                    loadingFrame.Rotation = rotation
                    wait(0.016)
                end
            elseif self.loadingAnimation.type == "fade" then
                Internal:Tween(loadingFrame, {BackgroundTransparency = 0.5}, 0.5 / self.loadingAnimation.speed)
                wait(0.5 / self.loadingAnimation.speed)
                Internal:Tween(loadingFrame, {BackgroundTransparency = 0}, 0.5 / self.loadingAnimation.speed)
                wait(0.5 / self.loadingAnimation.speed)
            end
        end
    end)
end

function D00MLib:StopLoadingAnimation()
    self.loadingAnimation.active = false
    if self.loadingAnimation.frame then
        self.loadingAnimation.frame:Destroy()
        self.loadingAnimation.frame = nil
    end
end

function D00MLib:SetLoadingAnimation(type, speed)
    self.loadingAnimation.type = type or "pulse"
    self.loadingAnimation.speed = math.max(0.1, speed or 1)
    return self
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
    self.BackgroundColor = Internal.Theme.WindowColor

    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "D00MLibGui"
    self.ScreenGui.Parent = playerGui
    self.ScreenGui.ResetOnSpawn = false

    -- Create main window frame
    self.WindowFrame = Instance.new("Frame")
    self.WindowFrame.Size = UDim2.new(0, 400, 0, 300)
    self.WindowFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.WindowFrame.BackgroundColor3 = self.BackgroundColor
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

    -- Title text with branding
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "D00MLib - " .. self.Name
    titleText.TextColor3 = Internal.Theme.TextColor
    titleText.TextSize = Internal.Theme.TextSize
    titleText.Font = Internal.Theme.FontBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = self.TitleBar

    -- Make draggable
    Internal:MakeDraggable(self.TitleBar, self.WindowFrame)

    -- Create tab scroll frame
    self.TabScrollFrame = Instance.new("ScrollingFrame")
    self.TabScrollFrame.Size = UDim2.new(1, -110, 0, 30) -- Adjusted for avatar
    self.TabScrollFrame.Position = UDim2.new(0, 105, 0, 35) -- Shifted right for avatar
    self.TabScrollFrame.BackgroundTransparency = 1
    self.TabScrollFrame.ScrollBarThickness = 4
    self.TabScrollFrame.ScrollBarImageColor3 = Internal.Theme.AccentColor
    self.TabScrollFrame.Parent = self.WindowFrame

    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Size = UDim2.new(0, 0, 1, 0)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.TabScrollFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabContainer

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabScrollFrame.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X, 0, 0)
    end)

    -- Create content scroll frame
    self.ContentScrollFrame = Instance.new("ScrollingFrame")
    self.ContentScrollFrame.Size = UDim2.new(1, -10, 1, -80)
    self.ContentScrollFrame.Position = UDim2.new(0, 5, 0, 70)
    self.ContentScrollFrame.BackgroundTransparency = 1
    self.ContentScrollFrame.ScrollBarThickness = 4
    self.ContentScrollFrame.ScrollBarImageColor3 = Internal.Theme.AccentColor
    self.ContentScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    self.ContentScrollFrame.Parent = self.WindowFrame

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, 0, 0, 0)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.ContentScrollFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = self.ContentArea

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
    end)

    -- Avatar viewport
    self.AvatarViewport = Instance.new("ViewportFrame")
    self.AvatarViewport.Size = UDim2.new(0, 50, 0, 50)
    self.AvatarViewport.Position = UDim2.new(0, 5, 1, -55)
    self.AvatarViewport.BackgroundTransparency = 1
    self.AvatarViewport.ZIndex = 2
    self.AvatarViewport.Parent = self.WindowFrame

    local camera = Instance.new("Camera")
    camera.Parent = self.AvatarViewport
    self.AvatarViewport.CurrentCamera = camera

    local player = Players.LocalPlayer
    if player.Character then
        local character = player.Character:Clone()
        character.Parent = self.AvatarViewport
        camera.CFrame = CFrame.new(character.Head.Position + Vector3.new(0, 0, 3), character.Head.Position)
        camera.FieldOfView = 20
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            local faceAnimation = Instance.new("Animation")
            faceAnimation.AnimationId = "rbxassetid://250628170"
            local animationTrack = humanoid:LoadAnimation(faceAnimation)
            animationTrack:Play()
        end
    else
        player.CharacterAdded:Connect(function(character)
            local clonedCharacter = character:Clone()
            clonedCharacter.Parent = self.AvatarViewport
            camera.CFrame = CFrame.new(clonedCharacter.Head.Position + Vector3.new(0, 0, 3), clonedCharacter.Head.Position)
            camera.FieldOfView = 20
            local humanoid = clonedCharacter:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                local faceAnimation = Instance.new("Animation")
                faceAnimation.AnimationId = "rbxassetid://250628170"
                local animationTrack = humanoid:LoadAnimation(faceAnimation)
                animationTrack:Play()
            end
        end)
    end

    -- Start loading animation
    D00MLib:StartLoadingAnimation()
    wait(2)
    D00MLib:StopLoadingAnimation()

    return self
end

function Window:AddTab(name)
    local tab = {
        Name = name or "Tab",
        Gui = D00MLib,
        Sections = {},
        Content = nil,
        Button = nil
    }

    function tab:Activate()
        if self.Gui.currentGui and self.Gui.currentGui.ActiveTab then
            self.Gui.currentGui.ActiveTab.Content.Visible = false
            Internal:Tween(self.Gui.currentGui.ActiveTab.Button, {BackgroundColor3 = Internal.Theme.TabColor}, 0.2)
        end
        self.Content.Visible = true
        self.Gui.currentGui.ActiveTab = self
        Internal:Tween(self.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
    end

    tab.Button = Instance.new("TextButton")
    tab.Button.Size = UDim2.new(0, 80, 1, 0)
    tab.Button.BackgroundColor3 = Internal.Theme.TabColor
    tab.Button.Text = "D00MLib - " .. tab.Name
    tab.Button.TextColor3 = Internal.Theme.TextColor
    tab.Button.TextSize = Internal.Theme.TextSize
    tab.Button.Font = Internal.Theme.Font
    tab.Button.Parent = self.TabContainer
    Internal:ApplyCorner(tab.Button, 4)

    tab.Content = Instance.new("Frame")
    tab.Content.Size = UDim2.new(1, 0, 1, 0)
    tab.Content.BackgroundTransparency = 1
    tab.Content.Visible = false
    tab.Content.Parent = self.ContentScrollFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = tab.Content

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)

    tab.Button.MouseButton1Click:Connect(function() tab:Activate() end)

    if not self.ActiveTab then tab:Activate() self.ActiveTab = tab end
    table.insert(self.Tabs, tab)
    self.currentTab = tab
    return D00MLib
end

function Window:AddSection(name)
    local section = {
        Name = name or "Section",
        Tab = self.currentTab,
        Frame = nil,
        Components = {}
    }

    section.Frame = Instance.new("Frame")
    section.Frame.Size = UDim2.new(1, 0, 0, 0)
    section.Frame.BackgroundColor3 = Internal.Theme.SectionColor
    section.Frame.AutomaticSize = Enum.AutomaticSize.Y
    section.Frame.Parent = self.currentTab.Content
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
    label.Text = "D00MLib - " .. section.Name
    label.TextColor3 = Internal.Theme.TextColor
    label.TextSize = Internal.Theme.TextSize
    label.Font = Internal.Theme.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.Frame

    table.insert(self.currentTab.Sections, section)
    self.currentSection = section

    return D00MLib
end

function Window:AddButton(name, callback)
    if not self.currentSection then
        warn("No section selected. Use D00MLib:AddSection() first.")
        return self
    end
    local button = {
        Name = name or "Button",
        Callback = callback or function() end
    }

    button.Button = Instance.new("TextButton")
    button.Button.Size = UDim2.new(1, 0, 0, 30)
    button.Button.BackgroundColor3 = Internal.Theme.ButtonColor
    button.Button.Text = "D00MLib - " .. button.Name
    button.Button.TextColor3 = Internal.Theme.TextColor
    button.Button.TextSize = Internal.Theme.TextSize
    button.Button.Font = Internal.Theme.Font
    button.Button.Parent = self.currentSection.Frame
    Internal:ApplyCorner(button.Button, 4)

    button.Button.MouseButton1Click:Connect(function() button.Callback() end)

    button.Button.MouseEnter:Connect(function()
        Internal:Tween(button.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
    end)

    button.Button.MouseLeave:Connect(function()
        Internal:Tween(button.Button, {BackgroundColor3 = Internal.Theme.ButtonColor}, 0.2)
    end)

    table.insert(self.currentSection.Components, button)
    return D00MLib
end

function Window:AddSlider(name, min, max, default, callback)
    if not self.currentSection then
        warn("No section selected. Use D00MLib:AddSection() first.")
        return self
    end
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
    slider.Frame.Parent = self.currentSection.Frame

    slider.Label = Instance.new("TextLabel")
    slider.Label.Size = UDim2.new(1, -10, 0, 20)
    slider.Label.Position = UDim2.new(0, 5, 0, 5)
    slider.Label.BackgroundTransparency = 1
    slider.Label.Text = "D00MLib - " .. slider.Name .. ": " .. slider.Value
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
            slider.Label.Text = "D00MLib - " .. slider.Name .. ": " .. slider.Value
            slider.Callback(slider.Value)
        end
    end)

    table.insert(self.currentSection.Components, slider)
    return D00MLib
end

-- D00MLib methods for simplified API
function D00MLib:MakeGui(options)
    self:StartLoadingAnimation()
    self.currentGui = Window.new(options)
    wait(2)
    self:StopLoadingAnimation()
    return self
end

function D00MLib:AddTab(name)
    if not self.currentGui then
        warn("D00MLib: No GUI created. Use D00MLib:MakeGui() first.")
        return self
    end
    return self.currentGui:AddTab(name)
end

function D00MLib:AddSection(name)
    if not self.currentGui or not self.currentGui.ActiveTab then
        warn("D00MLib: No active tab or GUI. Use D00MLib:MakeGui() and D00MLib:AddTab() first.")
        return self
    end
    return self.currentGui:AddSection(name)
end

function D00MLib:AddButton(name, callback)
    if not self.currentGui or not self.currentGui.currentSection then
        warn("D00MLib: No active section or GUI. Use D00MLib:MakeGui(), D00MLib:AddTab(), and D00MLib:AddSection() first.")
        return self
    end
    return self.currentGui:AddButton(name, callback)
end

function D00MLib:AddSlider(name, min, max, default, callback)
    if not self.currentGui or not self.currentGui.currentSection then
        warn("D00MLib: No active section or GUI. Use D00MLib:MakeGui(), D00MLib:AddTab(), and D00MLib:AddSection() first.")
        return self
    end
    return self.currentGui:AddSlider(name, min, max, default, callback)
end

function D00MLib:GuiBackground(hex)
    if self.currentGui then
        self.currentGui.BackgroundColor = Internal:HexToColor(hex)
        self.currentGui.WindowFrame.BackgroundColor3 = self.currentGui.BackgroundColor
    else
        warn("D00MLib: No GUI created. Use D00MLib:MakeGui() first.")
    end
    return self
end

function D00MLib:Notify(message, duration)
    if not self.currentGui then
        warn("D00MLib: No GUI created. Use D00MLib:MakeGui() first.")
        return self
    end
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 200, 0, 50)
    notification.Position = UDim2.new(0.5, -100, 0, -60)
    notification.BackgroundColor3 = Internal.Theme.AccentColor
    notification.BorderSizePixel = 0
    notification.Parent = self.currentGui.ScreenGui
    Internal:ApplyCorner(notification, 6)

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 1, -10)
    text.Position = UDim2.new(0, 5, 0, 5)
    text.BackgroundTransparency = 1
    text.Text = "D00MLib: " .. message
    text.TextColor3 = Internal.Theme.TextColor
    text.TextSize = Internal.Theme.TextSize
    text.Font = Internal.Theme.Font
    text.TextWrapped = true
    text.Parent = notification

    Internal:Tween(notification, {Position = UDim2.new(0.5, -100, 0, 10)}, 0.5)
    wait(duration or 2)
    Internal:Tween(notification, {Position = UDim2.new(0.5, -100, 0, -60)}, 0.5)
    wait(0.5)
    notification:Destroy()
    return self
end

return D00MLib
