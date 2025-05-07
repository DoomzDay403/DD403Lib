-- Simple script to demonstrate D00MLib usage with loadstring in an executor
local D00MLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/DoomzDay403/DD403Lib/refs/heads/main/lib.lua"))()
if not D00MLib then
    print("Failed to load D00MLib from URL")
    return
end
print("D00MLib loaded successfully")

-- Create a window
local window = D00MLib:MakeWindow({
    Name = "D00MLib Executor Demo"
})

-- Add a "Player" tab
local playerTab = window:AddTab({
    Name = "Player"
})

-- Add a section to the Player tab
local playerSection = playerTab:AddSection({
    Name = "Controls"
})

-- Add a button to the Player section
playerSection:AddButton({
    Name = "Super Jump",
    Callback = function()
        print("Super jump activated!")
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character.Humanoid.JumpPower = 100
        end
    end
})

-- Add a slider to the Player section
playerSection:AddSlider({
    Name = "Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        print("Speed set to: " .. value)
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character.Humanoid.WalkSpeed = value
        end
    end
})

-- Add a "Settings" tab
local settingsTab = window:AddTab({
    Name = "Settings"
})

-- Add a section to the Settings tab
local settingsSection = settingsTab:AddSection({
    Name = "Options"
})

-- Add a button to the Settings section
settingsSection:AddButton({
    Name = "Reset",
    Callback = function()
        print("Stats reset!")
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character.Humanoid.JumpPower = 50
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
})

-- Add a slider to the Settings section
settingsSection:AddSlider({
    Name = "Volume",
    Min = 0,
    Max = 10,
    Default = 5,
    Callback = function(value)
        print("Volume set to: " .. value)
    end
})
