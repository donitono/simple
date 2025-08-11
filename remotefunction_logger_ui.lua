-- RemoteFunction Logger + UI
local logFile = "remotefunction_log.txt"

local function writeLog(text)
    writefile(logFile, (isfile(logFile) and readfile(logFile) or "") .. text .. "\n")
end

local function formatArgs(args)
    local output = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "string" then
            table.insert(output, '"' .. v .. '"')
        elseif t == "table" then
            table.insert(output, "table: " .. tostring(v))
        else
            table.insert(output, tostring(v))
        end
    end
    return table.concat(output, ", ")
end

-- Hook RemoteFunction
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteFunction") then
        local oldInvoke = obj.OnClientInvoke
        obj.OnClientInvoke = function(...)
            local logText = "[FUNCTION] " .. obj:GetFullName() .. " | Args: " .. formatArgs({...})
            print(logText)
            writeLog(logText)
            if oldInvoke then
                return oldInvoke(...)
            end
        end
    end
end

-- UI
local screenGui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(0.35, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "RemoteFunction Logger"
title.TextColor3 = Color3.new(1, 1, 1)

local logBox = Instance.new("TextBox", frame)
logBox.Size = UDim2.new(1, -10, 1, -35)
logBox.Position = UDim2.new(0, 5, 0, 30)
logBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
logBox.TextColor3 = Color3.new(1, 1, 1)
logBox.TextXAlignment, logBox.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
logBox.ClearTextOnFocus = false
logBox.MultiLine = true
logBox.TextWrapped = false
logBox.TextSize = 14
logBox.Text = "Menunggu function..."

task.spawn(function()
    while true do
        if isfile(logFile) then
            logBox.Text = readfile(logFile)
        end
        task.wait(1)
    end
end)

print("[RemoteFunction Logger] Aktif. Log disimpan di:", logFile)
