--[[

    😛

    Script Name:      GAG Autobuy Seeds
    Author:           SuppliedOrange
    Version:          1.0.0
    GitHub:           https://github.com/SuppliedOrange/my-roblox-scripts/
    Date:             2025-06-02
    Description:      Automatically buys seeds in Grow a Garden.

    Disclaimer:
    This script is provided "as is", with no warranty or guarantee of safety.
    The author is not responsible for any bans or damages resulting from its use.
    Use at your own risk.

]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStreamEvent = game:GetService("ReplicatedStorage").GameEvents.DataStream

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player.Backpack

-- Configuration with default values
local config = {
    retryDelay = 0.2,
    isRunning = false,
    guiVisible = true
}

local LOG_ENTRY_LIMIT = 700
local SETTINGS_FILE = "gag_autobuy_seeds_settings.json"

-- All available fruit/vegetable items
local allFruitsAndVegetables = {
    "Daffodil", "Coconut", "Apple", "Pumpkin", "Pepper", "Cacao",
    "Orange Tulip", "Carrot", "Mango", "Tomato", "Blueberry", "Strawberry",
	"Beanstalk", "Mushroom", "Grape", "Dragon Fruit", "Cactus", "Bamboo", 
	"Watermelon", "Corn"
}

-- Selected items (all enabled by default)
local selectedItems = {}
for _, item in ipairs(allFruitsAndVegetables) do
    selectedItems[item] = true
end

-- Track current seed stocks
local currentStocks = {}
for _, item in ipairs(allFruitsAndVegetables) do
    currentStocks[item] = {Stock = 0, MaxStock = 0}
end

-- Load settings from file
local function loadSettings()
    local success, fileContent = pcall(function()
        return readfile(SETTINGS_FILE)
    end)

    if success and fileContent then
        local decodeSuccess, decodedJson = pcall(function()
            return HttpService:JSONDecode(fileContent)
        end)

        if decodeSuccess and type(decodedJson) == "table" then
            for key, value in pairs(decodedJson) do
                if key == "selectedItems" and type(value) == "table" then
                    local newSelectedItems = {}
                    for _, itemFullName in ipairs(allFruitsAndVegetables) do
                        newSelectedItems[itemFullName] = config.selectedItems[itemFullName]
                    end
                    for item, isSelected in pairs(value) do
                        if newSelectedItems[item] ~= nil then
                            newSelectedItems[item] = (isSelected == true)
                        end
                    end
                    config.selectedItems = newSelectedItems
                elseif config[key] ~= nil then
                    config[key] = value
                end
            end
            print("⚙️ Settings loaded from " .. SETTINGS_FILE)
        else
            print("❌ Error decoding settings JSON or not a table: " .. (decodeSuccess and "Invalid JSON format" or tostring(decodedJson)))
            print("⚠️ Using default settings.")
        end
    else
        print("⚠️ Could not read settings file: " .. SETTINGS_FILE .. ". Using default settings. Error: " .. tostring(fileContent))
    end
end

-- Save settings to file
local function saveSettings()
    local successEncode, jsonString = pcall(function()
        return HttpService:JSONEncode(config)
    end)

    if not successEncode then
        print("❌ Error encoding settings to JSON: " .. tostring(jsonString))
        return
    end

    local successWrite, writeError = pcall(function()
        writefile(SETTINGS_FILE, jsonString)
    end)

    if successWrite then
        print("💾 Settings saved to " .. SETTINGS_FILE)
    else
        print("❌ Error saving settings: " .. tostring(writeError))
    end
end

local BuyRemote = game.ReplicatedStorage.GameEvents.BuySeedStock

-- Utility Functions ( Not used anymore lol )
local function parseToolName(toolName)
    local seedName, quantity = string.match(toolName, "^(.+) Seed %[X(%d+)%]")
    if seedName and quantity then
        return seedName, tonumber(quantity), "seed"
    end
    return toolName, 1, "unknown"
end

-- Process seed stock updates from event
local function processSeedStock(stockTable)
    for foodName, info in pairs(stockTable) do
        if currentStocks[foodName] then
            currentStocks[foodName].Stock = info.Stock
            currentStocks[foodName].MaxStock = info.MaxStock
        end
    end
end

-- Attempt to buy an item (+ verified because it used to verify purchases, no actual verification)
local function verifiedTryBuy(item)
    if not currentStocks[item] or currentStocks[item].Stock <= 0 then
        return false, "No stock available"
    end
    
    local success, err = pcall(function()
        BuyRemote:FireServer(item)
    end)
    
    wait(config.retryDelay)
    return success, err
end

-- GUI Creation
local function createGUI()
    -- Main frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GAGAutoBuySeedsGUI"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    
    -- Floating toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "FloatingToggleButton"
    toggleButton.Parent = screenGui
    toggleButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    toggleButton.BorderSizePixel = 0
    toggleButton.AnchorPoint = Vector2.new(1, 1)
	toggleButton.Position = UDim2.new(1, -10, 1, -10)
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Text = "🌱"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true
    toggleButton.ZIndex = 1000
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 25)
    toggleCorner.Parent = toggleButton
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    mainFrame.Size = UDim2.new(0, 350, 0, 500)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = config.guiVisible
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = titleBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -60, 1, -5)
    titleLabel.Position = UDim2.new(0, 10, 0, 2)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Text = "🌱 Autobuy Seeds"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleBar
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Main content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Parent = mainFrame
    contentFrame.BackgroundTransparency = 1
    contentFrame.Position = UDim2.new(0, 10, 0, 40)
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    
    -- Control buttons frame
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Parent = contentFrame
    controlFrame.BackgroundTransparency = 1
    controlFrame.Size = UDim2.new(1, 0, 0, 50)
    
    -- Start/Stop button
    local startStopButton = Instance.new("TextButton")
    startStopButton.Name = "StartStopButton"
    startStopButton.Parent = controlFrame
    startStopButton.BackgroundColor3 = Color3.new(0.2, 0.7, 0.2)
    startStopButton.BorderSizePixel = 0
    startStopButton.Position = UDim2.new(0, 0, 0, 0)
    startStopButton.Size = UDim2.new(0.48, 0, 1, 0)
    startStopButton.Font = Enum.Font.SourceSansBold
    startStopButton.Text = "▶ START"
    startStopButton.TextColor3 = Color3.new(1, 1, 1)
    startStopButton.TextScaled = true
    
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 6)
    startCorner.Parent = startStopButton
    
    -- Settings button
    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.Parent = controlFrame
    settingsButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.7)
    settingsButton.BorderSizePixel = 0
    settingsButton.Position = UDim2.new(0.52, 0, 0, 0)
    settingsButton.Size = UDim2.new(0.48, 0, 1, 0)
    settingsButton.Font = Enum.Font.SourceSansBold
    settingsButton.Text = "⚙ SETTINGS"
    settingsButton.TextColor3 = Color3.new(1, 1, 1)
    settingsButton.TextScaled = true
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsButton
    
    -- Plant selection frame
    local plantFrame = Instance.new("Frame")
    plantFrame.Name = "PlantFrame"
    plantFrame.Parent = contentFrame
    plantFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    plantFrame.BorderSizePixel = 0
    plantFrame.Position = UDim2.new(0, 0, 0, 60)
    plantFrame.Size = UDim2.new(1, 0, 0, 180)
    
    local plantCorner = Instance.new("UICorner")
    plantCorner.CornerRadius = UDim.new(0, 6)
    plantCorner.Parent = plantFrame
    
    local plantTitle = Instance.new("TextLabel")
    plantTitle.Name = "PlantTitle"
    plantTitle.Parent = plantFrame
    plantTitle.BackgroundTransparency = 1
    plantTitle.Position = UDim2.new(0, 10, 0, 5)
    plantTitle.Size = UDim2.new(1, -20, 0, 20)
    plantTitle.Font = Enum.Font.SourceSansBold
    plantTitle.Text = "Select Plants to Buy:"
    plantTitle.TextColor3 = Color3.new(1, 1, 1)
    plantTitle.TextSize = 14
    plantTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Scrolling frame for plants
    local plantScrollFrame = Instance.new("ScrollingFrame")
    plantScrollFrame.Name = "PlantScrollFrame"
    plantScrollFrame.Parent = plantFrame
    plantScrollFrame.BackgroundTransparency = 1
    plantScrollFrame.Position = UDim2.new(0, 5, 0, 25)
    plantScrollFrame.Size = UDim2.new(1, -10, 1, -30)
    plantScrollFrame.BottomImage = ""
    plantScrollFrame.MidImage = ""
    plantScrollFrame.TopImage = ""
    plantScrollFrame.ScrollBarThickness = 5
    plantScrollFrame.ScrollBarImageColor3 = Color3.new(0.7, 0.7, 0.7)
    
    local plantLayout = Instance.new("UIListLayout")
    plantLayout.Parent = plantScrollFrame
    plantLayout.Padding = UDim.new(0, 2)
    plantLayout.SortOrder = Enum.SortOrder.Name
    
    -- Create plant checkboxes
    local plantCheckboxes = {}
    for _, plant in ipairs(allFruitsAndVegetables) do
        local checkFrame = Instance.new("Frame")
        checkFrame.Name = plant .. "Frame"
        checkFrame.Parent = plantScrollFrame
        checkFrame.BackgroundTransparency = 1
        checkFrame.Size = UDim2.new(1, -10, 0, 25)
        
        local checkbox = Instance.new("TextButton")
        checkbox.Name = plant .. "Checkbox"
        checkbox.Parent = checkFrame
        checkbox.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
        checkbox.BorderSizePixel = 0
        checkbox.Position = UDim2.new(0, 0, 0, 0)
        checkbox.Size = UDim2.new(0, 20, 0, 20)
        checkbox.Font = Enum.Font.SourceSansBold
        checkbox.Text = "✓"
        checkbox.TextColor3 = Color3.new(1, 1, 1)
        checkbox.TextScaled = true
        
        local checkCorner = Instance.new("UICorner")
        checkCorner.CornerRadius = UDim.new(0, 3)
        checkCorner.Parent = checkbox
        
        local plantLabel = Instance.new("TextLabel")
        plantLabel.Name = plant .. "Label"
        plantLabel.Parent = checkFrame
        plantLabel.BackgroundTransparency = 1
        plantLabel.Position = UDim2.new(0, 25, 0, 0)
        plantLabel.Size = UDim2.new(1, -25, 1, 0)
        plantLabel.Font = Enum.Font.SourceSans
        plantLabel.Text = plant
        plantLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        plantLabel.TextSize = 14
        plantLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        plantCheckboxes[plant] = checkbox
        
        -- Checkbox toggle functionality
        checkbox.MouseButton1Click:Connect(function()
            selectedItems[plant] = not selectedItems[plant]
            if selectedItems[plant] then
                checkbox.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
                checkbox.Text = "✓"
            else
                checkbox.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
                checkbox.Text = ""
            end
            saveSettings()
        end)
        
        -- Set initial state from saved settings
        if selectedItems[plant] then
            checkbox.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
            checkbox.Text = "✓"
        else
            checkbox.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
            checkbox.Text = ""
        end
    end
    
    -- Update canvas size
    plantScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #allFruitsAndVegetables * 27)
    
    -- Log frame
    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogFrame"
    logFrame.Parent = contentFrame
    logFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
    logFrame.BorderSizePixel = 0
    logFrame.Position = UDim2.new(0, 0, 0, 250)
    logFrame.Size = UDim2.new(1, 0, 1, -250)
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 6)
    logCorner.Parent = logFrame
    
    local logTitle = Instance.new("TextLabel")
    logTitle.Name = "LogTitle"
    logTitle.Parent = logFrame
    logTitle.BackgroundTransparency = 1
    logTitle.Position = UDim2.new(0, 10, 0, 5)
    logTitle.Size = UDim2.new(1, -20, 0, 20)
    logTitle.Font = Enum.Font.SourceSansBold
    logTitle.Text = "Activity Log:"
    logTitle.TextColor3 = Color3.new(1, 1, 1)
    logTitle.TextSize = 14
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local logScrollFrame = Instance.new("ScrollingFrame")
    logScrollFrame.Name = "LogScrollFrame"
    logScrollFrame.Parent = logFrame
    logScrollFrame.BackgroundTransparency = 1
    logScrollFrame.Position = UDim2.new(0, 5, 0, 25)
    logScrollFrame.Size = UDim2.new(1, -10, 1, -30)
    logScrollFrame.BottomImage = ""
    logScrollFrame.MidImage = ""
    logScrollFrame.TopImage = ""
    logScrollFrame.ScrollBarThickness = 5
    logScrollFrame.ScrollBarImageColor3 = Color3.new(0.7, 0.7, 0.7)
    logScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.Parent = logScrollFrame
    logLayout.Padding = UDim.new(0, 2)
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Settings frame (initially hidden)
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Parent = screenGui
    settingsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
    settingsFrame.Size = UDim2.new(0, 350, 0, 200)  -- Reduced height
    settingsFrame.Visible = false
    settingsFrame.Active = true
    
    local settingsFrameCorner = Instance.new("UICorner")
    settingsFrameCorner.CornerRadius = UDim.new(0, 8)
    settingsFrameCorner.Parent = settingsFrame
    
    -- Settings title bar
    local settingsTitleBar = Instance.new("Frame")
    settingsTitleBar.Name = "SettingsTitleBar"
    settingsTitleBar.Parent = settingsFrame
    settingsTitleBar.BackgroundColor3 = Color3.new(0.3, 0.3, 0.7)
    settingsTitleBar.BorderSizePixel = 0
    settingsTitleBar.Size = UDim2.new(1, 0, 0, 30)
    
    local settingsTitleCorner = Instance.new("UICorner")
    settingsTitleCorner.CornerRadius = UDim.new(0, 8)
    settingsTitleCorner.Parent = settingsTitleBar
    
    local settingsTitleLabel = Instance.new("TextLabel")
    settingsTitleLabel.Name = "SettingsTitleLabel"
    settingsTitleLabel.Parent = settingsTitleBar
    settingsTitleLabel.BackgroundTransparency = 1
    settingsTitleLabel.Size = UDim2.new(1, -40, 1, 0)
    settingsTitleLabel.Position = UDim2.new(0, 10, 0, 0)
    settingsTitleLabel.Font = Enum.Font.SourceSansBold
    settingsTitleLabel.Text = "⚙️ Settings"
    settingsTitleLabel.TextColor3 = Color3.new(1, 1, 1)
    settingsTitleLabel.TextScaled = true
    settingsTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Settings close button
    local settingsCloseButton = Instance.new("TextButton")
    settingsCloseButton.Name = "SettingsCloseButton"
    settingsCloseButton.Parent = settingsTitleBar
    settingsCloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    settingsCloseButton.BorderSizePixel = 0
    settingsCloseButton.Position = UDim2.new(1, -25, 0, 5)
    settingsCloseButton.Size = UDim2.new(0, 20, 0, 20)
    settingsCloseButton.Font = Enum.Font.SourceSansBold
    settingsCloseButton.Text = "×"
    settingsCloseButton.TextColor3 = Color3.new(1, 1, 1)
    settingsCloseButton.TextScaled = true
    
    local settingsCloseCorner = Instance.new("UICorner")
    settingsCloseCorner.CornerRadius = UDim.new(0, 4)
    settingsCloseCorner.Parent = settingsCloseButton
    
    -- Settings content
    local settingsContent = Instance.new("Frame")
    settingsContent.Name = "SettingsContent"
    settingsContent.Parent = settingsFrame
    settingsContent.BackgroundTransparency = 1
    settingsContent.Position = UDim2.new(0, 15, 0, 40)
    settingsContent.Size = UDim2.new(1, -30, 1, -80)
    
    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Parent = settingsContent
    settingsLayout.Padding = UDim.new(0, 15)
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Retry delay setting
    local retryDelayFrame = Instance.new("Frame")
    retryDelayFrame.Name = "RetryDelayFrame"
    retryDelayFrame.Parent = settingsContent
    retryDelayFrame.BackgroundTransparency = 1
    retryDelayFrame.Size = UDim2.new(1, 0, 0, 50)
    retryDelayFrame.LayoutOrder = 1
    
    local retryDelayLabel = Instance.new("TextLabel")
    retryDelayLabel.Name = "RetryDelayLabel"
    retryDelayLabel.Parent = retryDelayFrame
    retryDelayLabel.BackgroundTransparency = 1
    retryDelayLabel.Size = UDim2.new(1, 0, 0, 20)
    retryDelayLabel.Font = Enum.Font.SourceSansBold
    retryDelayLabel.Text = "Buy Delay (seconds):"
    retryDelayLabel.TextColor3 = Color3.new(1, 1, 1)
    retryDelayLabel.TextSize = 14
    retryDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local retryDelayBox = Instance.new("TextBox")
    retryDelayBox.Name = "RetryDelayBox"
    retryDelayBox.Parent = retryDelayFrame
    retryDelayBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    retryDelayBox.BorderSizePixel = 0
    retryDelayBox.Position = UDim2.new(0, 0, 0, 25)
    retryDelayBox.Size = UDim2.new(1, 0, 0, 25)
    retryDelayBox.Font = Enum.Font.SourceSans
    retryDelayBox.Text = tostring(config.retryDelay)
    retryDelayBox.TextColor3 = Color3.new(1, 1, 1)
    retryDelayBox.TextSize = 14
    retryDelayBox.PlaceholderText = "Enter seconds (e.g. 1)"
    
    local retryDelayCorner = Instance.new("UICorner")
    retryDelayCorner.CornerRadius = UDim.new(0, 4)
    retryDelayCorner.Parent = retryDelayBox
    
    -- Save button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Parent = settingsContent
    saveButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    saveButton.BorderSizePixel = 0
    saveButton.Size = UDim2.new(1, 0, 0, 35)
    saveButton.Font = Enum.Font.SourceSansBold
    saveButton.Text = "💾 Save Settings"
    saveButton.TextColor3 = Color3.new(1, 1, 1)
    saveButton.TextScaled = true
    saveButton.LayoutOrder = 2
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 6)
    saveCorner.Parent = saveButton
    
    -- Store references
    local gui = {
        screenGui = screenGui,
        toggleButton = toggleButton,
        mainFrame = mainFrame,
        startStopButton = startStopButton,
        settingsButton = settingsButton,
        logScrollFrame = logScrollFrame,
        logLayout = logLayout,
        settingsFrame = settingsFrame,
        settingsCloseButton = settingsCloseButton,
        plantCheckboxes = plantCheckboxes,
        closeButton = closeButton,
        retryDelayBox = retryDelayBox,
        saveButton = saveButton
    }
    
    return gui
end

-- Global reference for log updates
local gui
local logEntries = {}

function updateLog(message)

    if not gui then return end
    
    local timestamp = os.date("[%H:%M:%S] ")
    local fullMessage = timestamp .. message
    
    table.insert(logEntries, fullMessage)
    
    if #logEntries > LOG_ENTRY_LIMIT then
        table.remove(logEntries, 1)
    end
    
    for _, child in ipairs(gui.logScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local totalHeight = 0
    for i, entry in ipairs(logEntries) do
        local logEntry = Instance.new("TextLabel")
        logEntry.Name = "LogEntry" .. i
        logEntry.Parent = gui.logScrollFrame
        logEntry.BackgroundTransparency = 1
        logEntry.Size = UDim2.new(1, -10, 0, 16)
        logEntry.Font = Enum.Font.SourceSans
        logEntry.Text = entry
        logEntry.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        logEntry.TextSize = 12
        logEntry.TextXAlignment = Enum.TextXAlignment.Left
        logEntry.TextYAlignment = Enum.TextYAlignment.Top
        logEntry.TextWrapped = true
        logEntry.LayoutOrder = i
        
        totalHeight = totalHeight + 18
    end
    
    gui.logScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    wait()
    gui.logScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, totalHeight - gui.logScrollFrame.AbsoluteSize.Y))
end

-- Handle stock updates and buy items with retry logic
local function handleStockUpdate()

    if not config.isRunning then 
        updateLog("⏱ Stock got refreshed but autobuy is disabled, skipping...")
        return 
    end

    function tablelength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end
    
    -- Find items with available stock
    local itemsToBuy = {}
    local totalItemsAvailable = 0
    
    for item, stock in pairs(currentStocks) do
        if selectedItems[item] and stock.Stock > 0 then
            itemsToBuy[item] = stock.Stock
            totalItemsAvailable = totalItemsAvailable + stock.Stock
        end
    end
    
    if next(itemsToBuy) == nil then 
        updateLog("📦 No items available for purchase")
        return 
    end
    
    updateLog("📦 Stock update detected - " .. tablelength(itemsToBuy) .. " item types, " .. totalItemsAvailable .. " total items available")
    
    -- Process each item type
    for item, stockQuantity in pairs(itemsToBuy) do

        if not config.isRunning then 
            updateLog("⏹️ Purchase stopped - GAGAutobuySeeds disabled")
            break 
        end

        updateLog("🛒 Processing " .. item .. " (" .. stockQuantity .. " available)")
        
        local successfulPurchases = 0
        local totalAttempts = 0
        
        -- Try to buy each unit in stock
        for i = 1, stockQuantity do

            if not config.isRunning then 
                updateLog("⏹️ Purchase interrupted for " .. item .. " at " .. i .. "/" .. stockQuantity)
                break 
            end
            
            local purchased = false
            local lastError = nil
            
            -- Retry up to 3 times for each unit
            for attempt = 1, 3 do
                totalAttempts = totalAttempts + 1
                
                local success, err = verifiedTryBuy(item)
                
                if success then
                    purchased = true
                    successfulPurchases = successfulPurchases + 1
                    if attempt > 1 then
                        updateLog("✅ " .. item .. " purchased on attempt " .. attempt .. " (" .. successfulPurchases .. "/" .. stockQuantity .. ")")
                    end
                    break
                else
                    lastError = err
                    if attempt < 3 then
                        updateLog("🔄 Retry " .. attempt .. "/3 for " .. item .. " failed: " .. tostring(err))
                        wait(config.retryDelay)
                    end
                end
            end
            
            -- Log if all retries failed
            if not purchased then
                updateLog("❌ Failed to buy " .. item .. " after 3 attempts: " .. tostring(lastError))
            end
        end
        
        -- Summary for this item
        if successfulPurchases > 0 then
            local efficiency = math.floor((successfulPurchases / stockQuantity) * 100)
            updateLog("✅ " .. item .. " complete: " .. successfulPurchases .. "/" .. stockQuantity .. " purchased (" .. efficiency .. "% success)")
        else
            updateLog("❌ " .. item .. " failed: 0/" .. stockQuantity .. " purchased")
        end
        
        -- Small delay between different item types
        if next(itemsToBuy, item) ~= nil then -- Not the last item
            wait(config.retryDelay)
        end

    end
    
    updateLog("🏁 Stock purchase session completed")
end

-- Event listener for DataStreamEvent
local function setupDataStreamListener()
    DataStreamEvent.OnClientEvent:Connect(function(eventType, object, tbl)
        if eventType == "UpdateData" then
            for _, pair in ipairs(tbl) do
                local path = pair[1]
                local data = pair[2]
                
                if path == "ROOT/SeedStock/Stocks" and type(data) == "table" then
                    processSeedStock(data)
                    handleStockUpdate()
                end
            end
        end
    end)
end

-- Main initialization
local function main()
    loadSettings()
    gui = createGUI()
    
    if config.isRunning then
        gui.startStopButton.Text = "⏸ STOP"
        gui.startStopButton.BackgroundColor3 = Color3.new(0.7, 0.2, 0.2)
        gui.toggleButton.BackgroundColor3 = Color3.new(0.7, 0.4, 0.2)
    else
        gui.startStopButton.Text = "▶ START"
        gui.startStopButton.BackgroundColor3 = Color3.new(0.2, 0.7, 0.2)
        gui.toggleButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    end
    
    -- Setup event listener
    setupDataStreamListener()
    
    -- Button connections
    gui.toggleButton.MouseButton1Click:Connect(function()
        config.guiVisible = not config.guiVisible
        gui.mainFrame.Visible = config.guiVisible
        gui.settingsFrame.Visible = false
        saveSettings()
        
        if config.guiVisible then
            updateLog("👁️ GUI opened")
        else
            updateLog("👁️ GUI minimized (use floating button to reopen)")
        end
    end)
    
    gui.startStopButton.MouseButton1Click:Connect(function()
        config.isRunning = not config.isRunning
        saveSettings()
        
        if config.isRunning then
            gui.startStopButton.Text = "⏸ STOP"
            gui.startStopButton.BackgroundColor3 = Color3.new(0.7, 0.2, 0.2)
            gui.toggleButton.BackgroundColor3 = Color3.new(0.7, 0.4, 0.2)
            updateLog("🚀 Auto-purchasing enabled")
        else
            gui.startStopButton.Text = "▶ START"
            gui.startStopButton.BackgroundColor3 = Color3.new(0.2, 0.7, 0.2)
            gui.toggleButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
            updateLog("🛑 Auto-purchasing disabled")
        end
    end)
    
    gui.settingsButton.MouseButton1Click:Connect(function()
        gui.settingsFrame.Visible = not gui.settingsFrame.Visible
    end)
    
    gui.settingsCloseButton.MouseButton1Click:Connect(function()
        gui.settingsFrame.Visible = false
    end)
    
    gui.saveButton.MouseButton1Click:Connect(function()
        local retryDelayValue = tonumber(gui.retryDelayBox.Text)
        if retryDelayValue and retryDelayValue >= 0 then
            config.retryDelay = retryDelayValue
            updateLog("⚙️ Buy delay updated to " .. retryDelayValue .. " seconds")
        else
            gui.retryDelayBox.Text = tostring(config.retryDelay)
            updateLog("❌ Invalid buy delay value, reverted to " .. config.retryDelay)
        end
        
        gui.settingsFrame.Visible = false
        saveSettings()
        updateLog("💾 Settings saved")
    end)
    
    gui.closeButton.MouseButton1Click:Connect(function()
        config.isRunning = false
        config.guiVisible = false
        gui.mainFrame.Visible = false
        gui.settingsFrame.Visible = false
        saveSettings()
        updateLog("❌ GUI closed (use floating 🌱 button to reopen)")
    end)
    
    updateLog("🌱 GAG Autobuy Seeds initialized (Event-Based)")
    updateLog("Click START to enable auto-purchasing")
    updateLog("Listening for stock updates...")

    print("🌱 GAG Autobuy Seeds (Event-Based) loaded successfully!")
end

local success, err = pcall(main)
if not success then
    print("❌ Critical error: " .. tostring(err))
end
