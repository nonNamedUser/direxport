-- yes this is made by gemini cause i was too lazy to make it

local HttpService = game:GetService("HttpService")
local cloneref = cloneref or function(obj) return obj end
local clip = setclipboard or toclipboard

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
    
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 300, 0, 100)
    main.Position = UDim2.new(0.5, -150, 0.5, -50)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    main.BorderSizePixel = 0
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "Exporting Game Data..."
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    
    local barBackground = Instance.new("Frame", main)
    barBackground.Size = UDim2.new(0.8, 0, 0, 10)
    barBackground.Position = UDim2.new(0.1, 0, 0.5, 0)
    barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBackground.BorderSizePixel = 0
    
    local bar = Instance.new("Frame", barBackground)
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    bar.BorderSizePixel = 0
    
    local status = Instance.new("TextLabel", main)
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0.7, 0)
    status.Text = "Initializing..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    
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
    local current = className
    
    while current and current ~= "<<<ROOT>>>" do
        local data = classMap[current]
        if data then
            for _, member in ipairs(data.Members) do
                if member.MemberType == "Property" then
                    local tags = member.Tags or {}
                    if not (table.find(tags, "ReadOnly") or table.find(tags, "Hidden")) then
                        table.insert(props, {name = member.Name, type = member.ValueType.Name})
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
    
    -- UI & Performance: Yield every 200 objects to prevent Delta from freezing
    if count % 200 == 0 then 
        if statusLabel then
            statusLabel.Text = "Processing: " .. count .. " objects..."
        end
        task.wait() 
    end

    local className = obj.ClassName
    table.insert(outputChunks, string.format('  <Item class="%s" name="%s">\n', escapeXML(className), escapeXML(obj.Name)))

    -- 1. Special Handling for Scripts (LocalScripts & Modules)
    if obj:IsA("LuaSourceContainer") then
        -- Use the executor's decompiler if available
        local decompiler = decompile or (bit and bit.decompile) or (hookmetamethod and decompile)
        local success, source = pcall(function() 
            return decompiler(obj) 
        end)
        
        if success and source then
            table.insert(outputChunks, string.format('    <P n="Source" t="string">%s</P>\n', escapeXML(source)))
        end
    end

    -- 2. Standard Property Serialization
    local props = getProps(className)
    for _, prop in ipairs(props) do
        -- Skip Parent (handled by nesting) and Source (handled above)
        if prop.n == "Parent" or prop.n == "Source" then continue end
        
        local success, val = pcall(function() return formatVal(obj, prop.n) end)
        if success and val ~= nil then
            table.insert(outputChunks, string.format('    <P n="%s" t="%s">%s</P>\n', escapeXML(prop.n), escapeXML(typeof(obj[prop.n])), escapeXML(val)))
        end
    end

    -- 3. Recursion: Process children
    for _, child in ipairs(obj:GetChildren()) do 
        serialize(child) 
    end

    -- 4. Close the Item tag
    table.insert(outputChunks, "  </Item>\n")
end

-- Start serialization on specific services to avoid core game crash
for _, service in ipairs(services) do
    serialize(service)
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
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 300, 0, 120)
frame.Position = UDim2.new(0.5, -150, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 0, 40)
label.Text = "Paste GitHub Token to Upload Gist:"
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1

local textBox = Instance.new("TextBox", frame)
textBox.Size = UDim2.new(0.9, 0, 0, 30)
textBox.Position = UDim2.new(0.05, 0, 0.4, 0)
textBox.PlaceholderText = "ghp_xxxxxxxxxxxx"
textBox.Text = ""

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0.4, 0, 0, 30)
btn.Position = UDim2.new(0.3, 0, 0.75, 0)
btn.Text = "Upload Gist"
btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)

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
        setclipboard(data.html_url)
        label.Text = "Success! Link copied."
        task.wait(2)
        sg:Destroy()
    else
        label.Text = "Error: " .. response.StatusCode
        warn(response.Body)
    end
end)
