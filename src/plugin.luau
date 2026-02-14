-- also made by gemini

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local XML_ENTITIES = {
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&quot;"] = '"',
    ["&apos;"] = "'"
}

local ROOT_SERVICES = {
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
    StarterPlayer = game:GetService("StarterPlayer")
}

local function unescapeXML(value)
    local out = value
    out = out:gsub("&amp;", XML_ENTITIES["&amp;"])
    out = out:gsub("&lt;", XML_ENTITIES["&lt;"])
    out = out:gsub("&gt;", XML_ENTITIES["&gt;"])
    out = out:gsub("&quot;", XML_ENTITIES["&quot;"])
    out = out:gsub("&apos;", XML_ENTITIES["&apos;"])
    return out
end

local function parseCSVNumbers(dec)
    local nums = {}
    for val in dec:gmatch("[-%d%.eE]+") do
        table.insert(nums, tonumber(val))
    end
    return nums
end

local function getDumpBody(source)
    local marker = "--[[ XML DATA BELOW ]]"
    local startIdx = source:find(marker, 1, true)
    if not startIdx then
        return nil
    end
    local bodyStart = startIdx + #marker + 1
    if source:sub(bodyStart, bodyStart) == "\n" then
        bodyStart += 1
    end
    return source:sub(bodyStart)
end

local function createNotification(titleText, descText, isError)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GeminiImporterUI"
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui

    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 360, 0, 146)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 40)
    mainFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Thickness = 2
    stroke.Color = isError and Color3.fromRGB(255, 108, 108) or Color3.fromRGB(96, 170, 255)
    stroke.Transparency = 0.2

    local grad = Instance.new("UIGradient", mainFrame)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 31, 49)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 18, 29))
    })
    grad.Rotation = 18

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, -24, 0, 42)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(241, 246, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 19
    title.TextTransparency = 0

    local desc = Instance.new("TextLabel", mainFrame)
    desc.Size = UDim2.new(1, -24, 0, 52)
    desc.Position = UDim2.new(0, 12, 0, 46)
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(170, 192, 220)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.GothamMedium
    desc.TextSize = 14
    desc.TextWrapped = true
    desc.TextTransparency = 0

    TweenService:Create(mainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    TweenService:Create(dim, TweenInfo.new(0.35), {BackgroundTransparency = 0.46}):Play()

    return screenGui, mainFrame, stroke, title, desc
end

local toolbar = plugin:CreateToolbar("Gemini Tools")
local toggle = toolbar:CreateButton("Import Dump", "Scans for CORE_DUMP_DATA", "rbxassetid://4458901886")

toggle.Click:Connect(function()
    local serverStorage = game:GetService("ServerStorage")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local dumpScript = serverStorage:FindFirstChild("CORE_DUMP_DATA")
        or replicatedStorage:FindFirstChild("CORE_DUMP_DATA")
        or replicatedStorage:FindFirstChild("ExportedData_XML")
    
    if not dumpScript then
        local ui, frame, stroke, t, d = createNotification("Not Found", "CORE_DUMP_DATA script was not found in ServerStorage.", true)
        
        task.delay(3, function()
            local info = TweenInfo.new(0.5, Enum.EasingStyle.Quart)
            TweenService:Create(frame, info, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -20)}):Play()
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
    convertBtn.Size = UDim2.new(0, 172, 0, 36)
    convertBtn.Position = UDim2.new(0.5, -86, 0, 100)
    convertBtn.BackgroundColor3 = Color3.fromRGB(29, 140, 244)
    convertBtn.Text = "CONVERT"
    convertBtn.TextColor3 = Color3.fromRGB(244, 250, 255)
    convertBtn.Font = Enum.Font.GothamBold
    convertBtn.TextSize = 14
    convertBtn.AutoButtonColor = true
    convertBtn.TextTransparency = 0
    convertBtn.BorderSizePixel = 0
    Instance.new("UICorner", convertBtn).CornerRadius = UDim.new(0, 10)
    local cGrad = Instance.new("UIGradient", convertBtn)
    cGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(57, 198, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 120, 255))
    })
    convertBtn.MouseEnter:Connect(function()
        TweenService:Create(convertBtn, TweenInfo.new(0.12), {Size = UDim2.new(0, 178, 0, 38)}):Play()
    end)
    convertBtn.MouseLeave:Connect(function()
        TweenService:Create(convertBtn, TweenInfo.new(0.12), {Size = UDim2.new(0, 172, 0, 36)}):Play()
    end)

    convertBtn.MouseButton1Click:Connect(function()
        local sourceText = dumpScript:IsA("LuaSourceContainer") and dumpScript.Source or ""
        if sourceText == "" and dumpScript:IsA("StringValue") then
            sourceText = dumpScript.Value
        end
        local rawData = getDumpBody(sourceText) or sourceText
        if not rawData then return warn("Data format invalid!") end

        local stack = {}
        for line in rawData:gmatch("[^\r\n]+") do
            local serviceName = line:match('<ServiceRoot name="(.-)">')
            if serviceName then
                local service = ROOT_SERVICES[unescapeXML(serviceName)]
                if service then
                    table.insert(stack, service)
                end
            elseif line:find("</ServiceRoot>") then
                table.remove(stack)
            else
            local class, name = line:match('<Item class="(.-)" name="(.-)">')
            if class then
                name = unescapeXML(name)
                local parent = stack[#stack]

                if not parent and ROOT_SERVICES[class] and ROOT_SERVICES[class].Name == name then
                    table.insert(stack, ROOT_SERVICES[class])
                else
                    local ok, inst = pcall(Instance.new, class)
                    if ok and inst then
                        inst.Name = name
                        inst.Parent = parent
                        table.insert(stack, inst)
                    else
                        table.insert(stack, parent)
                    end
                end
            elseif line:find("<P") then
                local n, typeT, v = line:match('<P n="(.-)" t="(.-)">(.-)</P>')
                local target = stack[#stack]
                if n and typeT and v and target then
                    pcall(function()
                        local dec = unescapeXML(v)
                        n = unescapeXML(n)

                        if typeT == "CFrame" then
                            local c = parseCSVNumbers(dec)
                            if #c == 12 then
                                target[n] = CFrame.new(unpack(c))
                            end
                        elseif typeT == "Vector3" then
                            local c = parseCSVNumbers(dec)
                            if #c >= 3 then
                                target[n] = Vector3.new(c[1], c[2], c[3])
                            end
                        elseif typeT == "Color3" then
                            local c = parseCSVNumbers(dec)
                            if #c >= 3 then
                                target[n] = Color3.fromRGB(c[1], c[2], c[3])
                            end
                        elseif typeT == "UDim2" then
                            local c = parseCSVNumbers(dec)
                            if #c >= 4 then
                                target[n] = UDim2.new(c[1], c[2], c[3], c[4])
                            end
                        elseif typeT == "boolean" then
                            target[n] = (dec == "true")
                        elseif typeT == "number" then
                            local num = tonumber(dec)
                            if num ~= nil then
                                target[n] = num
                            end
                        elseif typeT == "nil" then
                            -- Skip nil properties.
                        elseif typeT == "Instance" then
                            -- Instance refs are resolved by hierarchy; skip direct assignment.
                        else
                            target[n] = dec
                        end
                    end)
                end
            elseif line:find("</Item>") then
                table.remove(stack)
            end
            end
        end

        dumpScript:Destroy()
        ui:Destroy()
        print("Success: Game structure imported.")
    end)
end)
