-- RemoteFunction Logger UI Aman (Tidak Error OnClientInvoke)
-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Scroll = Instance.new("ScrollingFrame")
local Template = Instance.new("TextLabel")

ScreenGui.Name = "RemoteFunctionLogger"
ScreenGui.Parent = game.CoreGui

Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui

Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "RemoteFunction Logger"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

Scroll.Size = UDim2.new(1, 0, 1, -30)
Scroll.Position = UDim2.new(0, 0, 0, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.BackgroundTransparency = 1
Scroll.Parent = Frame

Template.Size = UDim2.new(1, 0, 0, 20)
Template.BackgroundTransparency = 1
Template.TextColor3 = Color3.fromRGB(255, 255, 255)
Template.TextXAlignment = Enum.TextXAlignment.Left
Template.Text = ""
Template.Visible = false
Template.Parent = Scroll

-- Fungsi untuk tambah log ke UI
local function AddLog(text)
    local NewLabel = Template:Clone()
    NewLabel.Text = text
    NewLabel.Visible = true
    NewLabel.Parent = Scroll
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #Scroll:GetChildren() * 20)
end

-- Simpan log juga ke file (khusus exploit yang support writefile)
local function SaveLog(text)
    local filename = "RemoteFunction_Log.txt"
    if writefile and appendfile then
        if not isfile(filename) then
            writefile(filename, "")
        end
        appendfile(filename, text .. "\n")
    end
end

-- Hook metamethod untuk deteksi RemoteFunction
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "InvokeServer" then
        local args = {...}
        local msg = "[RF Invoke] " .. tostring(self) .. " | Args: " .. table.concat(args, ", ")
        AddLog(msg)
        SaveLog(msg)
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

AddLog("RemoteFunction Logger Started!")
SaveLog("RemoteFunction Logger Started!")
