-- yes this is made by gemini cause i was too lazy to make it

local HttpService = game:GetService("HttpService")
local cloneref = cloneref or function(obj) return obj end
local clip = setclipboard or toclipboard
local TweenService = game:GetService("TweenService")

local function GetService(service)
    return cloneref(game:GetService(service))
end

-- Proper XML Escaping
local function escapeXML(str)
    str = tostring(str)
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    str = string.gsub(str, '"', "&quot;")
    str = string.gsub(str, "'", "&apos;")
    return str
end

-- UI Creation
local function createProgressUI(total)
    local sg = Instance.new("ScreenGui", cloneref(game:GetService("CoreGui")))
    sg.Name = "ExportProgressUI"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999

    local dim = Instance.new("Frame", sg)
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 420, 0, 138)
    main.Position = UDim2.new(0.5, -210, 0.5, -69)
    main.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
    main.BackgroundTransparency = 0.08
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 40)

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 1.4
    stroke.Color = Color3.fromRGB(85, 160, 255)
    stroke.Transparency = 0.2

    local grad = Instance.new("UIGradient", main)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 28, 44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 17, 28))
    })
    grad.Rotation = 20

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, -28, 0, 42)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Text = "Exporting Game Data..."
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(237, 243, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 19

    local barBackground = Instance.new("Frame", main)
    barBackground.Size = UDim2.new(1, -28, 0, 16)
    barBackground.Position = UDim2.new(0, 14, 0, 58)
    barBackground.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    barBackground.BackgroundTransparency = 0.25
    barBackground.BorderSizePixel = 0
    Instance.new("UICorner", barBackground).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame", barBackground)
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(36, 182, 255)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local barGrad = Instance.new("UIGradient", bar)
    barGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(79, 221, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(77, 132, 255))
    })

    local status = Instance.new("TextLabel", main)
    status.Size = UDim2.new(1, -28, 0, 26)
    status.Position = UDim2.new(0, 14, 0, 90)
    status.Text = "Initializing..."
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(165, 188, 215)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13

    TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    TweenService:Create(dim, TweenInfo.new(0.35), {
        BackgroundTransparency = 0.46
    }):Play()

    return sg, bar, status
end

-- Fetching API Data
local studioVersion = game:HttpGet("https://setup.rbxcdn.com/versionQTStudio")
local apiDumpUrl = "https://setup.rbxcdn.com/" .. studioVersion .. "-API-Dump.json"
local apiData = HttpService:JSONDecode(game:HttpGet(apiDumpUrl))

local classMap = {}
for _, class in ipairs(apiData.Classes) do classMap[class.Name] = class end

local propertyCache = {}
local function getFlattenedProperties(className)
    if propertyCache[className] then return propertyCache[className] end
    local props = {}
    local seen = {}
    local current = className
    
    while current and current ~= "<<<ROOT>>>" do
        local data = classMap[current]
        if data then
            for _, member in ipairs(data.Members) do
                if member.MemberType == "Property" then
                    local tags = member.Tags or {}
                    if not (table.find(tags, "ReadOnly") or table.find(tags, "Hidden")) then
                        local key = string.lower(member.Name)
                        if not seen[key] then
                            seen[key] = true
                            table.insert(props, {name = member.Name, type = member.ValueType.Name})
                        end
                    end
                end
            end
            current = data.Superclass
        else 
            break 
        end
    end
    
    propertyCache[className] = props
    return props
end

local function formatVal(obj, pName)
    local v = obj[pName]
    local t = typeof(v)
    
    if t == "CFrame" then return table.concat({v:GetComponents()}, ",")
    elseif t == "Vector3" or t == "Vector2" then return tostring(v)
    elseif t == "Color3" then return math.round(v.R*255)..","..math.round(v.G*255)..","..math.round(v.B*255)
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "UDim2" then return v.X.Scale..","..v.X.Offset..","..v.Y.Scale..","..v.Y.Offset
    end
    
    return tostring(v)
end

-- Setup target services
local services = {
    GetService("Workspace"),
    GetService("ReplicatedStorage"),
    GetService("ReplicatedFirst"),
    GetService("Lighting"),
    GetService("StarterGui"),
    GetService("StarterPlayer")
}

local totalObjects = 0
for _, s in ipairs(services) do
    totalObjects = totalObjects + #s:GetDescendants() + 1
end

local ui, progressBar, statusLabel = createProgressUI(totalObjects)
local startTime = tick()

-- Use a table for massive performance gains when building strings
local outputChunks = {"<RobloxExport>\n"}
local count = 0

local function serialize(obj)
    count = count + 1
    
    -- 1. Yielding to prevent crashes and update UI
    if count % 150 == 0 then
        local progress = count / totalObjects
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        
        local elapsed = tick() - startTime
        local estimatedTotal = elapsed / progress
        local remaining = math.max(0, estimatedTotal - elapsed)
        
        statusLabel.Text = string.format("%d/%d objects | ETA: %.1fs", count, totalObjects, remaining)
        task.wait() 
    end

    local className = obj.ClassName
    table.insert(outputChunks, string.format('  <Item class="%s" name="%s">\n', escapeXML(className), escapeXML(obj.Name)))
    
    -- 2. Handle Script Sources (The "Actual Source" Fix)
    if obj:IsA("LuaSourceContainer") then
        -- Attempt to find the executor's decompiler
        local decompiler = decompile or (bit and bit.decompile)
        if decompiler then
            local success, source = pcall(function() return decompiler(obj) end)
            if success and source then
                table.insert(outputChunks, string.format('    <P n="Source" t="string">%s</P>\n', escapeXML(source)))
            end
        end
    end
    
    -- 3. Standard Property Serialization
    local props = getFlattenedProperties(className)
    for _, prop in ipairs(props) do
        -- Skip Parent (handled by nesting) and Source (handled above for scripts)
        if prop.name == "Parent" or prop.name == "Source" then continue end 
        
        local success, val = pcall(function() return formatVal(obj, prop.name) end)
        if success and val ~= nil then
            table.insert(outputChunks, string.format('    <P n="%s" t="%s">%s</P>\n', escapeXML(prop.name), escapeXML(typeof(val)), escapeXML(val)))
        end
    end
    
    -- 4. Recursive Children Processing
    for _, child in ipairs(obj:GetChildren()) do 
        serialize(child) 
    end
    
    -- 5. Close the Item tag (Crucial for the Importer's stack logic)
    table.insert(outputChunks, "  </Item>\n")
end

-- Start serialization on specific services to avoid core game crash
for _, service in ipairs(services) do
    table.insert(outputChunks, string.format('  <ServiceRoot name="%s">\n', escapeXML(service.Name)))
    serialize(service)
    table.insert(outputChunks, "  </ServiceRoot>\n")
end

table.insert(outputChunks, "</RobloxExport>")

-- Combine everything at the very end
local finalOutput = table.concat(outputChunks)
local httpRequest = request or http_request or (http and http.request) or syn.request

-- 1. Create the storage script
local storageScript = Instance.new("LocalScript")
storageScript.Name = "ExportedData_XML"
storageScript.Disabled = true -- Keep it disabled so it doesn't execute

-- 2. Set the Source
-- On Delta and other executors, you can write to .Source directly!
local success, err = pcall(function()
    storageScript.Source = "--[[ XML DATA BELOW ]]\n" .. finalOutput
end)

if success then
    storageScript.Parent = game:GetService("ReplicatedStorage")
    statusLabel.Text = "Data saved to LocalScript in ReplicatedStorage!"
else
    statusLabel.Text = "Source too big for script! Using StringValue fallback."
    -- Fallback: If the source is too huge, we use the StringValue method
    local val = Instance.new("StringValue")
    val.Name = "ExportedData_String"
    val.Value = string.sub(finalOutput, 1, 199999) -- Roblox limit
    val.Parent = game:GetService("ReplicatedStorage")
end

statusLabel.Text="Creating token GUI"

local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
sg.IgnoreGuiInset = true
sg.DisplayOrder = 1000
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 380, 0, 156)
frame.Position = UDim2.new(0.5, -190, 0.45, 40)
frame.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
frame.BackgroundTransparency = 0.07
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1.4
stroke.Color = Color3.fromRGB(88, 156, 255)
stroke.Transparency = 0.2
local fGrad = Instance.new("UIGradient", frame)
fGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 48)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 28))
})
TweenService:Create(frame, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
    Position = UDim2.new(0.5, -190, 0.45, 0)
}):Play()

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, -28, 0, 44)
label.Position = UDim2.new(0, 14, 0, 8)
label.Text = "Paste GitHub Token to Upload Gist:"
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextColor3 = Color3.fromRGB(240, 244, 255)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 16

local textBox = Instance.new("TextBox", frame)
textBox.Size = UDim2.new(1, -28, 0, 38)
textBox.Position = UDim2.new(0, 14, 0, 60)
textBox.PlaceholderText = "ghp_xxxxxxxxxxxx"
textBox.Text = ""
textBox.Font = Enum.Font.Code
textBox.TextSize = 14
textBox.TextColor3 = Color3.fromRGB(232, 240, 255)
textBox.PlaceholderColor3 = Color3.fromRGB(110, 130, 160)
textBox.BackgroundColor3 = Color3.fromRGB(27, 36, 54)
textBox.BorderSizePixel = 0
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 10)

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0, 160, 0, 34)
btn.Position = UDim2.new(0.5, -80, 0, 110)
btn.Text = "Upload Gist"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.fromRGB(245, 250, 255)
btn.BackgroundColor3 = Color3.fromRGB(29, 140, 244)
btn.BorderSizePixel = 0
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
local bGrad = Instance.new("UIGradient", btn)
bGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(57, 198, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 120, 255))
})
btn.MouseEnter:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 166, 0, 36)}):Play()
end)
btn.MouseLeave:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 160, 0, 34)}):Play()
end)

ui:Destroy()

btn.MouseButton1Click:Connect(function()
    local token = textBox.Text
    if token == "" then label.Text = "Token required!"; return end
    
    label.Text = "Uploading..."
    
    local payload = HttpService:JSONEncode({
        description = "Roblox Game Export - " .. os.date(),
        public = false,
        files = {
            ["ExportedGame.xml"] = {
                content = finalOutput
            }
        }
    })

    local response = httpRequest({
        Url = "https://api.github.com/gists",
        Method = "POST",
        Headers = {
            ["Authorization"] = "token " .. token,
            ["Content-Type"] = "application/json"
        },
        Body = payload
    })

    if response.Success then
        local data = HttpService:JSONDecode(response.Body)
        clip(data.html_url)
        label.Text = "Success! Link copied."
        task.wait(2)
        sg:Destroy()
    else
        label.Text = "Error: " .. response.StatusCode
        warn(response.Body)
    end
end)
