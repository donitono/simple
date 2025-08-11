--[[
RemoteSpy PRO ULTIMATE - Tab View + Auto Save TXT
By ChatGPT
Executor harus support: writefile, appendfile, setclipboard
]]

-- ==== SETTINGS ====
local FILE_TO_SERVER = "RemoteSpy_ToServer.txt"
local FILE_FROM_SERVER = "RemoteSpy_FromServer.txt"

-- ==== Utility Save ====
local function saveToFile(fileName, text)
    if writefile and appendfile then
        if not isfile(fileName) then
            writefile(fileName, text .. "\n")
        else
            appendfile(fileName, text .. "\n")
        end
    else
        warn("Executor tidak support writefile/appendfile")
    end
end

-- ==== Dump Table ====
local function dumpTable(t, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            table.insert(result, spacing .. tostring(k) .. " = {")
            local nested = dumpTable(v, indent + 1)
            for _, line in ipairs(nested) do
                table.insert(result, line)
            end
            table.insert(result, spacing .. "}")
        else
            table.insert(result, spacing .. tostring(k) .. " = " .. tostring(v))
        end
    end
    return result
end

-- ==== Format Args ====
local function formatArgs(args)
    local str = {}
    for _, v in ipairs(args) do
        if type(v) == "table" then
            table.insert(str, "{TABLE}")
            local dumped = dumpTable(v)
            for _, line in ipairs(dumped) do
                print("[TABLE ARG] " .. line)
            end
        elseif typeof(v) == "string" then
            table.insert(str, '"' .. v .. '"')
        else
            table.insert(str, tostring(v))
        end
    end
    return table.concat(str, ", ")
end

-- ==== GUI ====
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "RemoteSpyUltimate"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 550, 0, 400)
Frame.Position = UDim2.new(0.5, -275, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -60, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "RemoteSpy PRO ULTIMATE - Tab View + Auto Save"

local MinimizeBtn = Instance.new("TextButton", Frame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)

local TabToServer = Instance.new("TextButton", Frame)
TabToServer.Size = UDim2.new(0, 100, 0, 30)
TabToServer.Position = UDim2.new(0, 0, 0, 30)
TabToServer.Text = "To Server"
TabToServer.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
TabToServer.TextColor3 = Color3.fromRGB(255, 255, 255)

local TabFromServer = Instance.new("TextButton", Frame)
TabFromServer.Size = UDim2.new(0, 100, 0, 30)
TabFromServer.Position = UDim2.new(0, 100, 0, 30)
TabFromServer.Text = "From Server"
TabFromServer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TabFromServer.TextColor3 = Color3.fromRGB(255, 255, 255)

local SearchBox = Instance.new("TextBox", Frame)
SearchBox.Size = UDim2.new(0, 200, 0, 30)
SearchBox.Position = UDim2.new(1, -210, 0, 30)
SearchBox.PlaceholderText = "Search..."
SearchBox.Text = ""
SearchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)

local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, 0, 1, -60)
Scroll.Position = UDim2.new(0, 0, 0, 60)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.BackgroundTransparency = 1
local UIList = Instance.new("UIListLayout", Scroll)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Scroll.Visible = false
        TabToServer.Visible = false
        TabFromServer.Visible = false
        SearchBox.Visible = false
        Frame.Size = UDim2.new(0, 550, 0, 30)
        MinimizeBtn.Text = "+"
    else
        Scroll.Visible = true
        TabToServer.Visible = true
        TabFromServer.Visible = true
        SearchBox.Visible = true
        Frame.Size = UDim2.new(0, 550, 0, 400)
        MinimizeBtn.Text = "-"
    end
end)

-- ==== Tab System ====
local currentTab = "ToServer"
local logs = { ToServer = {}, FromServer = {} }

local function refreshLogs()
    Scroll:ClearAllChildren()
    UIList.Parent = Scroll
    local keyword = string.lower(SearchBox.Text)
    for _, logBtn in ipairs(logs[currentTab]) do
        if keyword == "" or string.find(string.lower(logBtn.Text), keyword, 1, true) then
            logBtn.Parent = Scroll
        end
    end
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end

TabToServer.MouseButton1Click:Connect(function()
    currentTab = "ToServer"
    TabToServer.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    TabFromServer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    refreshLogs()
end)

TabFromServer.MouseButton1Click:Connect(function()
    currentTab = "FromServer"
    TabFromServer.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    TabToServer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    refreshLogs()
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshLogs)

-- ==== Add Log Function ====
local function addLog(tabName, text, fileName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = text
    btn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(text)
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            btn.Text = text .. " [COPIED!]"
            task.wait(0.5)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.Text = text
        end
    end)
    table.insert(logs[tabName], btn)
    saveToFile(fileName, text)
    refreshLogs()
end

-- ==== Filter Remote ====
local function passesFilter(name)
    local blockList = { "Heartbeat", "Stepped", "RenderStepped" }
    for _, blocked in ipairs(blockList) do
        if string.find(name, blocked) then
            return false
        end
    end
    return true
end

-- ==== Hook Remote Events ====
local function hookRemoteEvent(remote)
    if passesFilter(remote.Name) then
        -- From Server
        remote.OnClientEvent:Connect(function(...)
            local line = "[FROM SERVER] " .. remote:GetFullName() .. " | Args: " .. formatArgs({...})
            addLog("FromServer", line, FILE_FROM_SERVER)
        end)
        -- To Server
        local oldFireServer = remote.FireServer
        remote.FireServer = function(self, ...)
            local line = "[TO SERVER] " .. self:GetFullName() .. " | Args: " .. formatArgs({...})
            addLog("ToServer", line, FILE_TO_SERVER)
            return oldFireServer(self, ...)
        end
    end
end

local function hookRemoteFunction(remote)
    if passesFilter(remote.Name) then
        -- From Server
        remote.OnClientInvoke = function(...)
            local line = "[FROM SERVER] " .. remote:GetFullName() .. " | Args: " .. formatArgs({...})
            addLog("FromServer", line, FILE_FROM_SERVER)
            return nil
        end
        -- To Server
        local oldInvokeServer = remote.InvokeServer
        remote.InvokeServer = function(self, ...)
            local line = "[TO SERVER] " .. self:GetFullName() .. " | Args: " .. formatArgs({...})
            addLog("ToServer", line, FILE_TO_SERVER)
            return oldInvokeServer(self, ...)
        end
    end
end

-- Hook existing remotes
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        hookRemoteEvent(obj)
    elseif obj:IsA("RemoteFunction") then
        hookRemoteFunction(obj)
    end
end

-- Hook new remotes
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        hookRemoteEvent(obj)
    elseif obj:IsA("RemoteFunction") then
        hookRemoteFunction(obj)
    end
end)

-- Init
addLog("ToServer", "✅ RemoteSpy PRO ULTIMATE Loaded (To Server)", FILE_TO_SERVER)
addLog("FromServer", "✅ RemoteSpy PRO ULTIMATE Loaded (From Server)", FILE_FROM_SERVER)
