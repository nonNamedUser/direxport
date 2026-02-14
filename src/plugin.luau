-- also made by gemini

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local function createNotification(titleText, descText, isError)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GeminiImporterUI"
    screenGui.DisplayOrder = 999
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 120)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Thickness = 2
    stroke.Color = isError and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(0, 120, 215)
    stroke.Transparency = 1

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextTransparency = 1

    local desc = Instance.new("TextLabel", mainFrame)
    desc.Size = UDim2.new(1, -20, 0, 40)
    desc.Position = UDim2.new(0, 10, 0, 35)
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.SourceSans
    desc.TextSize = 15
    desc.TextWrapped = true
    desc.TextTransparency = 1

    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0.5, -150, 0.5, -60),
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
    TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(desc, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

    return screenGui, mainFrame, stroke, title, desc
end

local toolbar = plugin:CreateToolbar("Gemini Tools")
local toggle = toolbar:CreateButton("Import Dump", "Scans for CORE_DUMP_DATA", "rbxassetid://4458901886")

toggle.Click:Connect(function()
    local dumpScript = game:GetService("ServerStorage"):FindFirstChild("CORE_DUMP_DATA")
    
    if not dumpScript then
        local ui, frame, stroke, t, d = createNotification("Not Found", "CORE_DUMP_DATA script was not found in ServerStorage.", true)
        
        task.delay(3, function()
            local info = TweenInfo.new(0.5, Enum.EasingStyle.Quart)
            TweenService:Create(frame, info, {BackgroundTransparency = 1, Position = UDim2.new(0.5, -150, 0.5, -80)}):Play()
            TweenService:Create(stroke, info, {Transparency = 1}):Play()
            TweenService:Create(t, info, {TextTransparency = 1}):Play()
            TweenService:Create(d, info, {TextTransparency = 1}):Play()
            task.wait(0.5)
            ui:Destroy()
        end)
        return 
    end

    local ui, frame, stroke, t, d = createNotification("Data Detected", "Ready to reconstruct game structure?", false)
    
    local convertBtn = Instance.new("TextButton", frame)
    convertBtn.Size = UDim2.new(0.8, 0, 0, 35)
    convertBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    convertBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    convertBtn.Text = "CONVERT"
    convertBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    convertBtn.Font = Enum.Font.SourceSansBold
    convertBtn.TextSize = 16
    convertBtn.AutoButtonColor = true
    convertBtn.TextTransparency = 1
    Instance.new("UICorner", convertBtn).CornerRadius = UDim.new(0, 6)
    
    TweenService:Create(convertBtn, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

    convertBtn.MouseButton1Click:Connect(function()
        local rawData = dumpScript.Source:match("%-%-%[%[ (.*) %]%]%]")
        if not rawData then return warn("Data format invalid!") end

        local stack = {workspace}
        for line in rawData:gmatch("[^\r\n]+") do
            local class, name = line:match('<Item class="(.-)" name="(.-)">')
            if class then
                local inst = Instance.new(class)
                inst.Name = HttpService:UrlDecode(name)
                inst.Parent = stack[#stack]
                table.insert(stack, inst)
            elseif line:find("<P") then
                local n, typeT, v = line:match('<P n="(.-)" t="(.-)">(.-)</P>')
                pcall(function()
                    local target = stack[#stack]
                    local dec = HttpService:UrlDecode(v)
                    if typeT == "CFrame" then
                        local c = {} for val in dec:gmatch("[-%d%.]+") do table.insert(c, tonumber(val)) end
                        target[n] = CFrame.new(unpack(c))
                    elseif typeT == "Vector3" then
                        local c = {} for val in dec:gmatch("[-%d%.]+") do table.insert(c, tonumber(val)) end
                        target[n] = Vector3.new(unpack(c))
                    elseif typeT == "boolean" then target[n] = (dec == "true")
                    elseif typeT == "number" then target[n] = tonumber(dec)
                    else target[n] = dec end
                end)
            elseif line:find("</Item>") then
                table.remove(stack)
            end
        end

        dumpScript:Destroy()
        ui:Destroy()
        print("Success: Game structure imported.")
    end)
end)
