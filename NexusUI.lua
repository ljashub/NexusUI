--[[
    NexusUI Library v2.0
    A modern and feature-rich Roblox UI Library
    Inspired by Rayfield Interface Suite
    Created: December 2025
]]

local NexusUI = {}
NexusUI.__index = NexusUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Variables
local screenGui
local mainFrame
local dragToggle = false
local dragSpeed = 0.25
local dragStart = nil
local startPos = nil
local SaveManager = {}
local Notifications = {}
local ActiveKeybinds = {}

-- Utility Functions
local function MakeDraggable(frame)
    local dragToggle = false
    local dragInput
    local dragStart
    local startPos
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
    end
    
    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            updateInput(input)
        end
    end)
end

local function CreateRipple(button, x, y)
    spawn(function()
        local ripple = Instance.new("ImageLabel")
        ripple.Name = "Ripple"
        ripple.Parent = button
        ripple.BackgroundTransparency = 1
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.new(0, x - 25, 0, y - 25)
        ripple.Size = UDim2.new(0, 50, 0, 50)
        ripple.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
        ripple.ImageTransparency = 0.5
        ripple.ZIndex = button.ZIndex + 1
        
        local goal = {Size = UDim2.new(0, 200, 0, 200), ImageTransparency = 1}
        local tween = TweenService:Create(ripple, TweenInfo.new(0.5), goal)
        tween:Play()
        
        tween.Completed:Connect(function()
            ripple:Destroy()
        end)
    end)
end

-- Notification System
function NexusUI:Notify(config)
    config = config or {}
    config.Title = config.Title or "Notification"
    config.Content = config.Content or "This is a notification"
    config.Duration = config.Duration or 5
    config.Image = config.Image or nil
    config.Actions = config.Actions or {}
    
    spawn(function()
        local notifFrame = Instance.new("Frame")
        notifFrame.Name = "Notification"
        notifFrame.Parent = screenGui or game:GetService("CoreGui"):FindFirstChild("NexusUI")
        notifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        notifFrame.BorderSizePixel = 0
        notifFrame.Position = UDim2.new(1, 10, 1, -80)
        notifFrame.Size = UDim2.new(0, 300, 0, 80)
        notifFrame.ClipsDescendants = true
        notifFrame.ZIndex = 1000
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 10)
        notifCorner.Parent = notifFrame
        
        local notifStroke = Instance.new("UIStroke")
        notifStroke.Color = Color3.fromRGB(100, 100, 255)
        notifStroke.Thickness = 1
        notifStroke.Parent = notifFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = notifFrame
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 15, 0, 10)
        titleLabel.Size = UDim2.new(1, -30, 0, 20)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = config.Title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 1001
        
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Parent = notifFrame
        contentLabel.BackgroundTransparency = 1
        contentLabel.Position = UDim2.new(0, 15, 0, 35)
        contentLabel.Size = UDim2.new(1, -30, 0, 35)
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.Text = config.Content
        contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        contentLabel.TextSize = 12
        contentLabel.TextWrapped = true
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.ZIndex = 1001
        
        -- Slide in animation
        notifFrame:TweenPosition(UDim2.new(1, -310, 1, -80), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
        
        wait(config.Duration)
        
        -- Slide out animation
        notifFrame:TweenPosition(UDim2.new(1, 10, 1, -80), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.5, true)
        wait(0.5)
        notifFrame:Destroy()
    end)
end

-- Save Manager
function SaveManager:SetFolder(folderName)
    self.Folder = folderName
    if not isfolder(folderName) then
        makefolder(folderName)
    end
end

function SaveManager:SetFile(fileName)
    self.FileName = fileName
end

function SaveManager:Save(data)
    if not self.Folder or not self.FileName then return end
    local json = HttpService:JSONEncode(data)
    writefile(self.Folder .. "/" .. self.FileName, json)
end

function SaveManager:Load()
    if not self.Folder or not self.FileName then return {} end
    if isfile(self.Folder .. "/" .. self.FileName) then
        local json = readfile(self.Folder .. "/" .. self.FileName)
        return HttpService:JSONDecode(json)
    end
    return {}
end

-- Main Window Creation
function NexusUI:CreateWindow(config)
    config = config or {}
    config.Name = config.Name or "NexusUI"
    config.LoadingTitle = config.LoadingTitle or "Loading..."
    config.LoadingSubtitle = config.LoadingSubtitle or "Please wait"
    config.ConfigurationSaving = config.ConfigurationSaving or {Enabled = false, FolderName = nil, FileName = "config.json"}
    config.Discord = config.Discord or {Enabled = false, Invite = "noinvite", RememberJoins = true}
    config.KeySystem = config.KeySystem or false
    config.KeySettings = config.KeySettings or {Title = "Key System", Subtitle = "Enter Key", Note = "", Key = {"Key123"}}
    
    local Window = {}
    
    -- Create ScreenGui
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NexusUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        if gethui then
            screenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        else
            screenGui.Parent = CoreGui
        end
    end
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.ClipsDescendants = true
    
    -- Corner
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    
    -- Drop Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = mainFrame
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = 0
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 10)
    titleBarCorner.Parent = titleBar
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = titleBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = config.Name
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleBar
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Position = UDim2.new(1, -30, 0.5, -10)
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Make draggable
    MakeDraggable(mainFrame)
    
    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = mainFrame
    tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    tabContainer.BorderSizePixel = 0
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.Size = UDim2.new(0, 150, 1, -60)
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabContainer
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.Parent = tabContainer
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    
    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Parent = mainFrame
    contentContainer.BackgroundTransparency = 1
    contentContainer.Position = UDim2.new(0, 170, 0, 50)
    contentContainer.Size = UDim2.new(1, -180, 1, -60)
    
    Window.Tabs = {}
    local currentTab = nil
    
    function Window:CreateTab(name, icon)
        local Tab = {}
        
        -- Tab Button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name
        tabButton.Parent = tabContainer
        tabButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        tabButton.BorderSizePixel = 0
        tabButton.Size = UDim2.new(1, -20, 0, 35)
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = icon and icon .. "  " .. name or name
        tabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
        tabButton.TextSize = 14
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.TextXOffset = 10
        
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 6)
        tabButtonCorner.Parent = tabButton
        
        -- Tab Content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = name .. "Content"
        tabContent.Parent = contentContainer
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
        tabContent.Visible = false
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Parent = tabContent
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 8)
        
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        local contentPadding = Instance.new("UIPadding")
        contentPadding.Parent = tabContent
        contentPadding.PaddingTop = UDim.new(0, 5)
        contentPadding.PaddingLeft = UDim.new(0, 5)
        contentPadding.PaddingRight = UDim.new(0, 5)
        
        -- Tab selection
        tabButton.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.Visible = false
            end
            
            for _, tab in pairs(tabContainer:GetChildren()) do
                if tab:IsA("TextButton") then
                    tab.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                    tab.TextColor3 = Color3.fromRGB(180, 180, 180)
                end
            end
            
            tabButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabContent.Visible = true
            currentTab = tabContent
        end)
        
        -- Auto-select first tab
        if not currentTab then
            tabButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabContent.Visible = true
            currentTab = tabContent
        end
        
        -- Tab Functions
        function Tab:CreateButton(config)
            config = config or {}
            config.Name = config.Name or "Button"
            config.Callback = config.Callback or function() end
            
            local button = Instance.new("TextButton")
            button.Name = config.Name
            button.Parent = tabContent
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, -10, 0, 40)
            button.Font = Enum.Font.Gotham
            button.Text = config.Name
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 14
            button.ClipsDescendants = true
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                local x = button.AbsolutePosition.X
                local y = button.AbsolutePosition.Y
                CreateRipple(button, x, y)
                pcall(config.Callback)
            end)
            
            button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
            end)
            
            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
            end)
            
            return button
        end
        
        function Tab:CreateToggle(config)
            config = config or {}
            config.Name = config.Name or "Toggle"
            config.CurrentValue = config.CurrentValue or false
            config.Flag = config.Flag or config.Name
            config.Callback = config.Callback or function() end
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = config.Name
            toggleFrame.Parent = tabContent
            toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Size = UDim2.new(1, -10, 0, 40)
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 6)
            toggleCorner.Parent = toggleFrame
            
            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.Parent = toggleFrame
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Position = UDim2.new(0, 10, 0, 0)
            toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
            toggleLabel.Font = Enum.Font.Gotham
            toggleLabel.Text = config.Name
            toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleLabel.TextSize = 14
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local toggleButton = Instance.new("TextButton")
            toggleButton.Name = "Toggle"
            toggleButton.Parent = toggleFrame
            toggleButton.BackgroundColor3 = config.CurrentValue and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(50, 50, 55)
            toggleButton.BorderSizePixel = 0
            toggleButton.Position = UDim2.new(1, -55, 0.5, -10)
            toggleButton.Size = UDim2.new(0, 45, 0, 20)
            toggleButton.Text = ""
            
            local toggleButtonCorner = Instance.new("UICorner")
            toggleButtonCorner.CornerRadius = UDim.new(1, 0)
            toggleButtonCorner.Parent = toggleButton
            
            local toggleCircle = Instance.new("Frame")
            toggleCircle.Name = "Circle"
            toggleCircle.Parent = toggleButton
            toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleCircle.BorderSizePixel = 0
            toggleCircle.Position = config.CurrentValue and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            toggleCircle.Size = UDim2.new(0, 16, 0, 16)
            
            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = toggleCircle
            
            local toggled = config.CurrentValue
            
            toggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                local buttonColor = toggled and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(50, 50, 55)
                local circlePos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = buttonColor}):Play()
                TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = circlePos}):Play()
                
                pcall(config.Callback, toggled)
            end)
            
            return toggleFrame
        end
        
        function Tab:CreateSlider(config)
            config = config or {}
            config.Name = config.Name or "Slider"
            config.Range = config.Range or {0, 100}
            config.Increment = config.Increment or 1
            config.CurrentValue = config.CurrentValue or config.Range[1]
            config.Flag = config.Flag or config.Name
            config.Callback = config.Callback or function() end
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = config.Name
            sliderFrame.Parent = tabContent
            sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Size = UDim2.new(1, -10, 0, 60)
            
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 6)
            sliderCorner.Parent = sliderFrame
            
            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.Parent = sliderFrame
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.Position = UDim2.new(0, 10, 0, 5)
            sliderLabel.Size = UDim2.new(0.7, 0, 0, 20)
            sliderLabel.Font = Enum.Font.Gotham
            sliderLabel.Text = config.Name
            sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            sliderLabel.TextSize = 14
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Parent = sliderFrame
            valueLabel.BackgroundTransparency = 1
            valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
            valueLabel.Size = UDim2.new(0.3, -10, 0, 20)
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.Text = tostring(config.CurrentValue)
            valueLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
            valueLabel.TextSize = 14
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local sliderBack = Instance.new("Frame")
            sliderBack.Parent = sliderFrame
            sliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            sliderBack.BorderSizePixel = 0
            sliderBack.Position = UDim2.new(0, 10, 0, 35)
            sliderBack.Size = UDim2.new(1, -20, 0, 15)
            
            local sliderBackCorner = Instance.new("UICorner")
            sliderBackCorner.CornerRadius = UDim.new(1, 0)
            sliderBackCorner.Parent = sliderBack
            
            local sliderFill = Instance.new("Frame")
            sliderFill.Parent = sliderBack
            sliderFill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            sliderFill.BorderSizePixel = 0
            sliderFill.Size = UDim2.new((config.CurrentValue - config.Range[1]) / (config.Range[2] - config.Range[1]), 0, 1, 0)
            
            local sliderFillCorner = Instance.new("UICorner")
            sliderFillCorner.CornerRadius = UDim.new(1, 0)
            sliderFillCorner.Parent = sliderFill
            
            local dragging = false
            
            local function updateSlider(input)
                local pos = (input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X
                pos = math.clamp(pos, 0, 1)
                
                local value = config.Range[1] + (config.Range[2] - config.Range[1]) * pos
                value = math.floor(value / config.Increment + 0.5) * config.Increment
                value = math.clamp(value, config.Range[1], config.Range[2])
                
                sliderFill.Size = UDim2.new(pos, 0, 1, 0)
                valueLabel.Text = tostring(value)
                
                pcall(config.Callback, value)
            end
            
            sliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            sliderBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)
            
            return sliderFrame
        end
        
        function Tab:CreateDropdown(config)
            config = config or {}
            config.Name = config.Name or "Dropdown"
            config.Options = config.Options or {}
            config.CurrentOption = config.CurrentOption or config.Options[1] or "None"
            config.Flag = config.Flag or config.Name
            config.Callback = config.Callback or function() end
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Name = config.Name
            dropdownFrame.Parent = tabContent
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.Size = UDim2.new(1, -10, 0, 40)
            dropdownFrame.ClipsDescendants = true
            
            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 6)
            dropdownCorner.Parent = dropdownFrame
            
            local dropdownButton = Instance.new("TextButton")
            dropdownButton.Parent = dropdownFrame
            dropdownButton.BackgroundTransparency = 1
            dropdownButton.Size = UDim2.new(1, 0, 0, 40)
            dropdownButton.Font = Enum.Font.Gotham
            dropdownButton.Text = ""
            dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdownButton.TextSize = 14
            
            local dropdownLabel = Instance.new("TextLabel")
            dropdownLabel.Parent = dropdownButton
            dropdownLabel.BackgroundTransparency = 1
            dropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            dropdownLabel.Size = UDim2.new(0.7, 0, 1, 0)
            dropdownLabel.Font = Enum.Font.Gotham
            dropdownLabel.Text = config.Name .. ": " .. config.CurrentOption
            dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdownLabel.TextSize = 14
            dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local dropdownIcon = Instance.new("TextLabel")
            dropdownIcon.Parent = dropdownButton
            dropdownIcon.BackgroundTransparency = 1
            dropdownIcon.Position = UDim2.new(1, -30, 0, 0)
            dropdownIcon.Size = UDim2.new(0, 20, 1, 0)
            dropdownIcon.Font = Enum.Font.GothamBold
            dropdownIcon.Text = "▼"
            dropdownIcon.TextColor3 = Color3.fromRGB(100, 100, 255)
            dropdownIcon.TextSize = 12
            
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Parent = dropdownFrame
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.Position = UDim2.new(0, 0, 0, 40)
            optionsFrame.Size = UDim2.new(1, 0, 0, 0)
            
            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.Parent = optionsFrame
            optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optionsLayout.Padding = UDim.new(0, 2)
            
            local expanded = false
            
            for _, option in ipairs(config.Options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Parent = optionsFrame
                optionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                optionButton.BorderSizePixel = 0
                optionButton.Size = UDim2.new(1, 0, 0, 30)
                optionButton.Font = Enum.Font.Gotham
                optionButton.Text = option
                optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                optionButton.TextSize = 13
                
                optionButton.MouseButton1Click:Connect(function()
                    config.CurrentOption = option
                    dropdownLabel.Text = config.Name .. ": " .. option
                    pcall(config.Callback, option)
                    
                    expanded = false
                    dropdownIcon.Text = "▼"
                    TweenService:Create(dropdownFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 40)}):Play()
                end)
                
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                end)
            end
            
            dropdownButton.MouseButton1Click:Connect(function()
                expanded = not expanded
                
                if expanded then
                    dropdownIcon.Text = "▲"
                    local targetHeight = 40 + (#config.Options * 32)
                    TweenService:Create(dropdownFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
                else
                    dropdownIcon.Text = "▼"
                    TweenService:Create(dropdownFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 40)}):Play()
                end
            end)
            
            return dropdownFrame
        end
        
        function Tab:CreateInput(config)
            config = config or {}
            config.Name = config.Name or "Input"
            config.PlaceholderText = config.PlaceholderText or "Enter text..."
            config.RemoveTextAfterFocusLost = config.RemoveTextAfterFocusLost or false
            config.Callback = config.Callback or function() end
            
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = config.Name
            inputFrame.Parent = tabContent
            inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            inputFrame.BorderSizePixel = 0
            inputFrame.Size = UDim2.new(1, -10, 0, 60)
            
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputFrame
            
            local inputLabel = Instance.new("TextLabel")
            inputLabel.Parent = inputFrame
            inputLabel.BackgroundTransparency = 1
            inputLabel.Position = UDim2.new(0, 10, 0, 5)
            inputLabel.Size = UDim2.new(1, -20, 0, 20)
            inputLabel.Font = Enum.Font.Gotham
            inputLabel.Text = config.Name
            inputLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            inputLabel.TextSize = 14
            inputLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local textBox = Instance.new("TextBox")
            textBox.Parent = inputFrame
            textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            textBox.BorderSizePixel = 0
            textBox.Position = UDim2.new(0, 10, 0, 30)
            textBox.Size = UDim2.new(1, -20, 0, 25)
            textBox.Font = Enum.Font.Gotham
            textBox.PlaceholderText = config.PlaceholderText
            textBox.Text = ""
            textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            textBox.TextSize = 13
            textBox.TextXAlignment = Enum.TextXAlignment.Left
            
            local textBoxCorner = Instance.new("UICorner")
            textBoxCorner.CornerRadius = UDim.new(0, 5)
            textBoxCorner.Parent = textBox
            
            local textBoxPadding = Instance.new("UIPadding")
            textBoxPadding.Parent = textBox
            textBoxPadding.PaddingLeft = UDim.new(0, 8)
            textBoxPadding.PaddingRight = UDim.new(0, 8)
            
            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    pcall(config.Callback, textBox.Text)
                    if config.RemoveTextAfterFocusLost then
                        textBox.Text = ""
                    end
                end
            end)
            
            return inputFrame
        end
        
        function Tab:CreateLabel(text)
            local label = Instance.new("TextLabel")
            label.Parent = tabContent
            label.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            label.BorderSizePixel = 0
            label.Size = UDim2.new(1, -10, 0, 35)
            label.Font = Enum.Font.Gotham
            label.Text = text
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 14
            label.TextWrapped = true
            
            local labelCorner = Instance.new("UICorner")
            labelCorner.CornerRadius = UDim.new(0, 6)
            labelCorner.Parent = label
            
            local labelPadding = Instance.new("UIPadding")
            labelPadding.Parent = label
            labelPadding.PaddingLeft = UDim.new(0, 10)
            labelPadding.PaddingRight = UDim.new(0, 10)
            
            function label:Set(newText)
                label.Text = newText
            end
            
            return label
        end
        
        function Tab:CreateParagraph(config)
            config = config or {}
            config.Title = config.Title or "Paragraph"
            config.Content = config.Content or "Content"
            
            local paragraphFrame = Instance.new("Frame")
            paragraphFrame.Name = config.Title
            paragraphFrame.Parent = tabContent
            paragraphFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            paragraphFrame.BorderSizePixel = 0
            paragraphFrame.Size = UDim2.new(1, -10, 0, 80)
            
            local paragraphCorner = Instance.new("UICorner")
            paragraphCorner.CornerRadius = UDim.new(0, 6)
            paragraphCorner.Parent = paragraphFrame
            
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = paragraphFrame
            titleLabel.BackgroundTransparency = 1
            titleLabel.Position = UDim2.new(0, 10, 0, 5)
            titleLabel.Size = UDim2.new(1, -20, 0, 25)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.Text = config.Title
            titleLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
            titleLabel.TextSize = 15
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextYAlignment = Enum.TextYAlignment.Top
            
            local contentLabel = Instance.new("TextLabel")
            contentLabel.Parent = paragraphFrame
            contentLabel.BackgroundTransparency = 1
            contentLabel.Position = UDim2.new(0, 10, 0, 30)
            contentLabel.Size = UDim2.new(1, -20, 1, -35)
            contentLabel.Font = Enum.Font.Gotham
            contentLabel.Text = config.Content
            contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentLabel.TextSize = 13
            contentLabel.TextWrapped = true
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextYAlignment = Enum.TextYAlignment.Top
            
            return paragraphFrame
        end
        
        function Tab:CreateSection(name)
            local sectionLabel = Instance.new("TextLabel")
            sectionLabel.Name = "Section"
            sectionLabel.Parent = tabContent
            sectionLabel.BackgroundTransparency = 1
            sectionLabel.Size = UDim2.new(1, -10, 0, 30)
            sectionLabel.Font = Enum.Font.GothamBold
            sectionLabel.Text = name
            sectionLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
            sectionLabel.TextSize = 16
            sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local sectionPadding = Instance.new("UIPadding")
            sectionPadding.Parent = sectionLabel
            sectionPadding.PaddingLeft = UDim.new(0, 5)
            
            local divider = Instance.new("Frame")
            divider.Parent = sectionLabel
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            divider.BorderSizePixel = 0
            divider.Position = UDim2.new(0, 0, 1, -2)
            divider.Size = UDim2.new(1, 0, 0, 2)
            
            local dividerCorner = Instance.new("UICorner")
            dividerCorner.CornerRadius = UDim.new(1, 0)
            dividerCorner.Parent = divider
            
            return sectionLabel
        end
        
        function Tab:CreateKeybind(config)
            config = config or {}
            config.Name = config.Name or "Keybind"
            config.CurrentKeybind = config.CurrentKeybind or "NONE"
            config.HoldToInteract = config.HoldToInteract or false
            config.Flag = config.Flag or config.Name
            config.Callback = config.Callback or function() end
            
            local keybindFrame = Instance.new("Frame")
            keybindFrame.Name = config.Name
            keybindFrame.Parent = tabContent
            keybindFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            keybindFrame.BorderSizePixel = 0
            keybindFrame.Size = UDim2.new(1, -10, 0, 40)
            
            local keybindCorner = Instance.new("UICorner")
            keybindCorner.CornerRadius = UDim.new(0, 6)
            keybindCorner.Parent = keybindFrame
            
            local keybindLabel = Instance.new("TextLabel")
            keybindLabel.Parent = keybindFrame
            keybindLabel.BackgroundTransparency = 1
            keybindLabel.Position = UDim2.new(0, 10, 0, 0)
            keybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
            keybindLabel.Font = Enum.Font.Gotham
            keybindLabel.Text = config.Name
            keybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            keybindLabel.TextSize = 14
            keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local keybindButton = Instance.new("TextButton")
            keybindButton.Parent = keybindFrame
            keybindButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            keybindButton.BorderSizePixel = 0
            keybindButton.Position = UDim2.new(1, -90, 0.5, -15)
            keybindButton.Size = UDim2.new(0, 80, 0, 30)
            keybindButton.Font = Enum.Font.GothamBold
            keybindButton.Text = config.CurrentKeybind
            keybindButton.TextColor3 = Color3.fromRGB(100, 100, 255)
            keybindButton.TextSize = 12
            
            local keybindButtonCorner = Instance.new("UICorner")
            keybindButtonCorner.CornerRadius = UDim.new(0, 6)
            keybindButtonCorner.Parent = keybindButton
            
            local listening = false
            local currentKey = config.CurrentKeybind
            
            keybindButton.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keybindButton.Text = "..."
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
                        local keyName = input.KeyCode.Name
                        currentKey = keyName
                        keybindButton.Text = keyName
                        listening = false
                        connection:Disconnect()
                        
                        ActiveKeybinds[keyName] = {
                            Callback = config.Callback,
                            HoldToInteract = config.HoldToInteract
                        }
                    end
                end)
            end)
            
            if currentKey ~= "NONE" then
                ActiveKeybinds[currentKey] = {
                    Callback = config.Callback,
                    HoldToInteract = config.HoldToInteract
                }
            end
            
            return keybindFrame
        end
        
        function Tab:CreateColorPicker(config)
            config = config or {}
            config.Name = config.Name or "Color Picker"
            config.Color = config.Color or Color3.fromRGB(255, 255, 255)
            config.Flag = config.Flag or config.Name
            config.Callback = config.Callback or function() end
            
            local colorFrame = Instance.new("Frame")
            colorFrame.Name = config.Name
            colorFrame.Parent = tabContent
            colorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            colorFrame.BorderSizePixel = 0
            colorFrame.Size = UDim2.new(1, -10, 0, 40)
            
            local colorCorner = Instance.new("UICorner")
            colorCorner.CornerRadius = UDim.new(0, 6)
            colorCorner.Parent = colorFrame
            
            local colorLabel = Instance.new("TextLabel")
            colorLabel.Parent = colorFrame
            colorLabel.BackgroundTransparency = 1
            colorLabel.Position = UDim2.new(0, 10, 0, 0)
            colorLabel.Size = UDim2.new(0.7, 0, 1, 0)
            colorLabel.Font = Enum.Font.Gotham
            colorLabel.Text = config.Name
            colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            colorLabel.TextSize = 14
            colorLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local colorDisplay = Instance.new("Frame")
            colorDisplay.Parent = colorFrame
            colorDisplay.BackgroundColor3 = config.Color
            colorDisplay.BorderSizePixel = 0
            colorDisplay.Position = UDim2.new(1, -45, 0.5, -12)
            colorDisplay.Size = UDim2.new(0, 35, 0, 24)
            
            local colorDisplayCorner = Instance.new("UICorner")
            colorDisplayCorner.CornerRadius = UDim.new(0, 6)
            colorDisplayCorner.Parent = colorDisplay
            
            local colorButton = Instance.new("TextButton")
            colorButton.Parent = colorDisplay
            colorButton.BackgroundTransparency = 1
            colorButton.Size = UDim2.new(1, 0, 1, 0)
            colorButton.Text = ""
            
            colorButton.MouseButton1Click:Connect(function()
                -- Simple color cycling for demonstration
                local r = math.random(0, 255)
                local g = math.random(0, 255)
                local b = math.random(0, 255)
                local newColor = Color3.fromRGB(r, g, b)
                colorDisplay.BackgroundColor3 = newColor
                pcall(config.Callback, newColor)
            end)
            
            return colorFrame
        end
        
        Table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    return Window
end

-- Keybind Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        if ActiveKeybinds[keyName] then
            local keybind = ActiveKeybinds[keyName]
            if not keybind.HoldToInteract then
                pcall(keybind.Callback)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        if ActiveKeybinds[keyName] then
            local keybind = ActiveKeybinds[keyName]
            if keybind.HoldToInteract then
                pcall(keybind.Callback)
            end
        end
    end
end)

return NexusUI
