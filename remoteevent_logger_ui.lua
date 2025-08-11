-- RemoteEvent Logger Aman + Filter UI
local MAX_LOGS = 200
local logFile = "RemoteEvent_Log.txt"
local logs = {}
local minimized = false
local filterText = ""

local function timestamp()
    return os.date("[%H:%M:%S]")
end

local function saveLog(text)
    if writefile and appendfile then
        if not isfile(logFile) then
            writefile(logFile, "")
        end
        appendfile(logFile, text .. "\n")
    end
end

local function addLog(text)
    table.insert(logs, text)
    if #logs > MAX_LOGS then
        table.remove(logs, 1)
    end
    saveLog(text)
    if not minimized then
        logBox.Text = table.concat(logs, "\n")
    end
end

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 450, 0, 350)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "RemoteEvent Logger"
title.TextColor3 = Color3.new(1, 1, 1)

local filterBox = Instance.new("TextBox", frame)
filterBox.Size = UDim2.new(0.6, -10, 0, 25)
filterBox.Position = UDim2.new(0, 5, 0, 30)
filterBox.PlaceholderText = "Ketik nama event (kosong = semua)"
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local clearBtn = Instance.new("TextButton", frame)
clearBtn.Size = UDim2.new(0.2, -5, 0, 25)
clearBtn.Position = UDim2.new(0.6, 5, 0, 30)
clearBtn.Text = "Clear"
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
clearBtn.TextColor3 = Color3.new(1, 1, 1)

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0.2, -5, 0, 25)
minimizeBtn.Position = UDim2.new(0.8, 5, 0, 30)
minimizeBtn.Text = "Minimize"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)

logBox = Instance.new("TextBox", frame)
logBox.Size = UDim2.new(1, -10, 1, -65)
logBox.Position = UDim2.new(0, 5, 0, 60)
logBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
logBox.TextColor3 = Color3.new(1, 1, 1)
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.ClearTextOnFocus = false
logBox.MultiLine = true
logBox.TextWrapped = false
logBox.TextSize = 14

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = filterBox.Text
end)

clearBtn.MouseButton1Click:Connect(function()
    logs = {}
    logBox.Text = ""
end)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    logBox.Visible = not minimized
    filterBox.Visible = not minimized
    clearBtn.Visible = not minimized
end)

-- Hook RemoteEvent
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            if filterText == "" or string.find(string.lower(obj.Name), string.lower(filterText)) then
                local args = {...}
                local argStr = {}
                for i, v in ipairs(args) do
                    table.insert(argStr, tostring(v))
                end
                addLog(timestamp() .. " EVENT: " .. obj:GetFullName() .. " | Args: " .. table.concat(argStr, ", "))
            end
        end)
    end
end
