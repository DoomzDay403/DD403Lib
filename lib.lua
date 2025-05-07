-- D00MLib: A simple Roblox UI library with an intuitive API
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
function Internal:MakeDraggable(frame, parentFrame)
    local dragging, dragInput, dragStart, startPos

    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        parentFrame.Position = frame.Position -- Keep parent frame (window) in sync
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

-- Internal: Ensure PlayerGui is ready
function Internal:WaitForPlayerGui()
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
    return playerGui
end

-- Internal: Clean up existing GUI
function Internal:CleanupGui(playerGui)
    local existingGui = playerGui:FindFirstChild("D00MLibGui")
    if existingGui then
        existingGui:Destroy()
    end
end

-- GUI class
local GuiClass = {}
GuiClass.__index = GuiClass

function GuiClass.new(options)
    local self = setmetatable({}, GuiClass)
    options = options or {}

    -- Ensure PlayerGui is ready
    local playerGui = Internal:WaitForPlayerGui()
    if not playerGui then
        return nil
    end

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
    self.TitleBar.BorderSizePixel = 0
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

    -- Make window draggable
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

function GuiClass:AddTab(name)
    local tab = D00MLib.Classes.Tab.new(name, self)
    table.insert(self.Tabs, tab)
    if not self.ActiveTab then
        tab:Activate()
        self.ActiveTab = tab
    end
    return tab
end

-- Tab class
local TabClass = {}
TabClass.__index = TabClass

function TabClass.new(name, gui)
    local self = setmetatable({}, TabClass)
    self.Name = name or "Tab"
    self.Gui = gui
    self.Sections = {}

    -- Create tab button
    self.Button = Instance.new("TextButton")
    self.Button.Size = UDim2.new(0, 80, 1, 0)
    self.Button.BackgroundColor3 = Internal.Theme.TabColor
    self.Button.Text = self.Name
    self.Button.TextColor3 = Internal.Theme.TextColor
    self.Button.TextSize = Internal.Theme.TextSize
    self.Button.Font = Internal.Theme.Font
    self.Button.Parent = gui.TabBar

    Internal:ApplyCorner(self.Button, 4)

    -- Create tab content frame
    self.Content = Instance.new("Frame")
    self.Content.Size = UDim2.new(1, 0, 1, 0)
    self.Content.BackgroundTransparency = 1
    self.Content.Visible = false
    self.Content.Parent = gui.ContentArea

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.Content

    -- Tab button click
    self.Button.MouseButton1Click:Connect(function()
        self:Activate()
    end)

    return self
end

function TabClass:Activate()
    if self.Gui.ActiveTab then
        self.Gui.ActiveTab.Content.Visible = false
        Internal:Tween(self.Gui.ActiveTab.Button, {BackgroundColor3 = Internal.Theme.TabColor}, 0.2)
    end
    self.Content.Visible = true
    self.Gui.ActiveTab = self
    Internal:Tween(self.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
end

function TabClass:AddSection(name)
    local section = D00MLib.Classes.Section.new(name, self.Content)
    table.insert(self.Sections, section)
    return section
end

-- Section class
local SectionClass = {}
SectionClass.__index = SectionClass

function SectionClass.new(name, parent)
    local self = setmetatable({}, SectionClass)
    self.Name = name or "Section"
    self.Components = {}

    -- Create section frame
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(1, 0, 0, 0)
    self.Frame.BackgroundColor3 = Internal.Theme.SectionColor
    self.Frame.AutomaticSize = Enum.AutomaticSize.Y
    self.Frame.Parent = parent

    Internal:ApplyCorner(self.Frame, 4)

    -- Section padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = self.Frame

    -- Section layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.Frame

    -- Section label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = self.Name
    label.TextColor3 = Internal.Theme.TextColor
    label.TextSize = Internal.Theme.TextSize
    label.Font = Internal.Theme.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.Frame

    return self
end

function SectionClass:AddButton(name, callback)
    local button = D00MLib.Classes.Button.new(name, callback, self.Frame)
    table.insert(self.Components, button)
    return button
end

function SectionClass:AddSlider(name, min, max, default, callback)
    local slider = D00MLib.Classes.Slider.new(name, min, max, default, callback, self.Frame)
    table.insert(self.Components, slider)
    return slider
end

-- Button class
local ButtonClass = {}
ButtonClass.__index = ButtonClass

function ButtonClass.new(name, callback, parent)
    local self = setmetatable({}, ButtonClass)
    self.Name = name or "Button"
    self.Callback = callback or function() end

    -- Create button
    self.Button = Instance.new("TextButton")
    self.Button.Size = UDim2.new(1, 0, 0, 30)
    self.Button.BackgroundColor3 = Internal.Theme.ButtonColor
    self.Button.Text = self.Name
    self.Button.TextColor3 = Internal.Theme.TextColor
    self.Button.TextSize = Internal.Theme.TextSize
    self.Button.Font = Internal.Theme.Font
    self.Button.Parent = parent

    Internal:ApplyCorner(self.Button, 4)

    -- Button interaction
    self.Button.MouseButton1Click:Connect(function()
        self.Callback()
    end)

    -- Hover animation
    self.Button.MouseEnter:Connect(function()
        Internal:Tween(self.Button, {BackgroundColor3 = Internal.Theme.AccentColor}, 0.2)
    end)

    self.Button.MouseLeave:Connect(function()
        Internal:Tween(self.Button, {BackgroundColor3 = Internal.Theme.ButtonColor}, 0.2)
    end)

    return self
end

-- Slider class
local SliderClass = {}
SliderClass.__index = SliderClass

function SliderClass.new(name, min, max, default, callback, parent)
    local self = setmetatable({}, SliderClass)
    self.Name = name or "Slider"
    self.Min = min or 0
    self.Max = max or 100
    self.Default = default or 50
    self.Callback = callback or function() end
    self.Value = self.Default

    -- Validate slider range
    if self.Min >= self.Max then
        self.Min, self.Max = 0, 100
    end
    self.Value = math.clamp(self.Default, self.Min, self.Max)

    -- Create slider frame
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(1, 0, 0, 50)
    self.Frame.BackgroundTransparency = 1
    self.Frame.Parent = parent

    -- Slider label
    self.Label = Instance.new("TextLabel")
    self.Label.Size = UDim2.new(1, -10, 0, 20)
    self.Label.Position = UDim2.new(0, 5, 0, 5)
    self.Label.BackgroundTransparency = 1
    self.Label.Text = self.Name .. ": " .. self.Value
    self.Label.TextColor3 = Internal.Theme.TextColor
    self.Label.TextSize = Internal.Theme.TextSize
    self.Label.Font = Internal.Theme.Font
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Frame

    -- Slider bar
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -10, 0, 10)
    sliderBar.Position = UDim2.new(0, 5, 0, 30)
    sliderBar.BackgroundColor3 = Internal.Theme.ButtonColor
    sliderBar.Parent = self.Frame

    Internal:ApplyCorner(sliderBar, 4)

    -- Slider fill
    self.Fill = Instance.new("Frame")
    self.Fill.Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
    self.Fill.BackgroundColor3 = Internal.Theme.AccentColor
    self.Fill.Parent = sliderBar

    Internal:ApplyCorner(self.Fill, 4)

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
            self.Fill.Size = UDim2.new(relativeX, 0, 1, 0)
            self.Label.Text = self.Name .. ": " .. self.Value
            self.Callback(self.Value)
        end
    end)

    return self
end

-- Class registry
D00MLib.Classes = {
    Gui = GuiClass,
    Tab = TabClass,
    Section = SectionClass,
    Button = ButtonClass,
    Slider = SliderClass
}

-- Public API
function D00MLib:MakeGui(options)
    return self.Classes.Gui.new(options)
end

return D00MLib
