-- RemoteSpy DELTA (VERSI LENGKAP)
-- By ChatGPT (adapted for Delta Android)
-- Features: namecall hook (FireServer/InvokeServer), OnClientEvent scan, table dump, GUI (drag/minimize/search), copy all

-- ======= Utilities =======
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function safeType(v)
    local ok, t = pcall(function() return typeof(v) end)
    if ok then return t end
    return type(v)
end

local function dumpTable(t, indent, visited)
    indent = indent or 0
    visited = visited or {}
    if type(t) ~= "table" then return {tostring(t)} end
    if visited[t] then return {"<recursive-table>"} end
    visited[t] = true
    local out = {}
    local pad = string.rep("  ", indent)
    for k,v in pairs(t) do
        local key = tostring(k)
        if type(v) == "table" then
            table.insert(out, pad .. key .. " = {")
            local nested = dumpTable(v, indent+1, visited)
            for _,line in ipairs(nested) do table.insert(out, line) end
            table.insert(out, pad .. "}")
        else
            local vt = safeType(v)
            local val = (vt == "string") and ('"'..v..'"') or tostring(v)
            table.insert(out, pad .. key .. " = " .. val)
        end
    end
    visited[t] = nil
    return out
end

local function formatArgs(args)
    local parts = {}
    for i,v in ipairs(args) do
        local vt = safeType(v)
        if vt == "table" then
            table.insert(parts, "{TABLE}")
            local dumped = dumpTable(v)
            for _,line in ipairs(dumped) do print("[TABLE ARG] " .. line) end
        elseif vt == "string" then
            table.insert(parts, '"'..v..'"')
        else
            table.insert(parts, tostring(v))
        end
    end
    return table.concat(parts, ", ")
end

-- ======= GUI =======
local screen = Instance.new("ScreenGui")
screen.Name = "DeltaRemoteSpy"
screen.ResetOnSpawn = false
screen.Parent = CoreGui

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 540, 0, 420)
frame.Position = UDim2.new(0.2,0,0.08,0)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.BorderSizePixel = 0

-- Title bar
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -80, 0, 34)
title.Position = UDim2.new(0,8,0,4)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Text = "RemoteSpy DELTA (Lengkap) - Click logs to copy"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local btnMin = Instance.new("TextButton", frame)
btnMin.Size = UDim2.new(0, 28, 0, 28)
btnMin.Position = UDim2.new(1, -36, 0, 4)
btnMin.Text = "-"
btnMin.BackgroundColor3 = Color3.fromRGB(65,65,65)
btnMin.TextColor3 = Color3.new(1,1,1)

local btnCopyAll = Instance.new("TextButton", frame)
btnCopyAll.Size = UDim2.new(0, 90, 0, 28)
btnCopyAll.Position = UDim2.new(1, -140, 0, 4)
btnCopyAll.Text = "Copy All"
btnCopyAll.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnCopyAll.TextColor3 = Color3.new(1,1,1)

-- Search box
local search = Instance.new("TextBox", frame)
search.Size = UDim2.new(0, 180, 0, 28)
search.Position = UDim2.new(1, -330, 0, 4)
search.PlaceholderText = "search..."
search.TextColor3 = Color3.new(1,1,1)
search.BackgroundColor3 = Color3.fromRGB(48,48,48)

-- Log area
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -16, 1, -54)
scroll.Position = UDim2.new(0,8,0,46)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6

local uiList = Instance.new("UIListLayout", scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,4)

-- Dragging (manual for better compatibility)
local dragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- minimize behavior
local minimized = false
btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        for _,v in ipairs(frame:GetChildren()) do
            if v ~= title and v ~= btnMin and v ~= btnCopyAll then
                v.Visible = false
            end
        end
        frame.Size = UDim2.new(0, 260, 0, 40)
        btnMin.Text = "+"
    else
        for _,v in ipairs(frame:GetChildren()) do v.Visible = true end
        frame.Size = UDim2.new(0, 540, 0, 420)
        btnMin.Text = "-"
    end
end)

-- ======= Logging backend =======
local logs = {} -- { {text=..., dir="To"|"From"} ... }
local uiButtons = {} -- keep references to UI elements

local function addLogEntry(txt, dir)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.fromRGB(1,1,1)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = txt
    btn.Parent = scroll

    btn.MouseButton1Click:Connect(function()
        if pcall(function() return setclipboard end) then
            pcall(function() setclipboard(txt) end)
            local old = btn.Text
            btn.Text = txt .. "  [COPIED]"
            task.wait(0.6)
            if btn then btn.Text = old end
        else
            -- fallback: print
            print("setclipboard not available on this executor")
        end
    end)

    table.insert(logs, {text = txt, dir = dir})
    table.insert(uiButtons, btn)
    scroll.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
end

local function refreshFilter()
    local k = string.lower(search.Text or "")
    for i,entry in ipairs(logs) do
        local btn = uiButtons[i]
        if k == "" or string.find(string.lower(entry.text), k, 1, true) then
            btn.Visible = true
        else
            btn.Visible = false
        end
    end
    scroll.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
end
search:GetPropertyChangedSignal("Text"):Connect(refreshFilter)

btnCopyAll.MouseButton1Click:Connect(function()
    local all = {}
    for _,e in ipairs(logs) do table.insert(all, e.text) end
    local combined = table.concat(all, "\n")
    if pcall(function() return setclipboard end) then
        pcall(function() setclipboard(combined) end)
        print("[RemoteSpy] Copied all logs to clipboard ("..#logs.." entries)")
    else
        print("[RemoteSpy] setclipboard not supported")
    end
end)

-- ======= Hook machinery (namecall) =======
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
local blockedNames = { "Heartbeat", "Stepped", "RenderStepped" }

local function passesFilter(name)
    if not name then return true end
    for _,b in ipairs(blockedNames) do
        if string.find(name, b) then return false end
    end
    return true
end

setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if (method == "FireServer" or method == "InvokeServer") and passesFilter(tostring(self)) then
        local txt = "[TO SERVER] " .. tostring(self:GetFullName and pcall(function() return self:GetFullName() end) and self:GetFullName() or tostring(self)) .. " | Args: " .. formatArgs(args)
        addLogEntry(txt, "ToServer")
        -- also print for detail
        print(txt)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ======= Hook existing Remotes (server -> client) =======
local function tryHookRemote(obj)
    if obj:IsA("RemoteEvent") then
        if passesFilter(obj.Name) then
            pcall(function()
                obj.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local txt = "[FROM SERVER] " .. (pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj)) .. " | Args: " .. formatArgs(args)
                    addLogEntry(txt, "FromServer")
                    print(txt)
                end)
            end)
        end
    elseif obj:IsA("RemoteFunction") then
        if passesFilter(obj.Name) then
            pcall(function()
                obj.OnClientInvoke = function(...)
                    local args = {...}
                    local txt = "[FROM SERVER INVOKE] " .. (pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj)) .. " | Args: " .. formatArgs(args)
                    addLogEntry(txt, "FromServer")
                    print(txt)
                    return nil
                end
            end)
        end
    end
end

-- Hook all current remotes
for _,v in ipairs(game:GetDescendants()) do
    pcall(function() tryHookRemote(v) end)
end

-- Auto-hook new ones
game.DescendantAdded:Connect(function(obj)
    pcall(function() tryHookRemote(obj) end)
end)

-- initial message
addLogEntry("✅ RemoteSpy DELTA (Lengkap) loaded — do actions to capture logs", "Info")
print("[RemoteSpy] Loaded. Listening for FireServer/InvokeServer and OnClientEvent.")

-- End of script
