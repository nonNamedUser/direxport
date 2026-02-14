-- yes this is made by gemini cause i was too lazy to make it

local HttpService = game:GetService("HttpService")
local cloneref = cloneref or function(obj) return obj end
local clip = setclipboard or toclipboard

local function GetService(service)
    return cloneref(game:GetService(service))
end

-- UI Creation
local function createProgressUI(total)
    local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
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
        else break end
    end
    propertyCache[className] = props
    return props
end

local function formatVal(obj, pName)
    local v = obj[pName]
    local t = typeof(v)
    if t == "CFrame" then return table.concat({v:GetComponents()}, ",")
    elseif t == "Vector3" or t == "Vector2" then return tostring(v)
    elseif t == "Color3" then return v.R..","..v.G..","..v.B
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "UDim2" then return v.X.Scale..","..v.X.Offset..","..v.Y.Scale..","..v.Y.Offset
    end
    return tostring(v)
end

local output = "<RobloxExport>\n"
local count = 0
local totalObjects = 0

local services = {
    GetService("Workspace"),
    GetService("ReplicatedStorage"),
    GetService("ReplicatedFirst"),
    GetService("StarterGui"),
    GetService("StarterPlayer")
}

for _, s in ipairs(services) do
    totalObjects = totalObjects + #s:GetDescendants() + 1
end

local ui, progressBar, statusLabel = createProgressUI(totalObjects)
local startTime = tick()

local function serialize(obj)
    count = count + 1
    
    if count % 100 == 0 then
        local progress = count / totalObjects
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        
        local elapsed = tick() - startTime
        local estimatedTotal = elapsed / progress
        local remaining = math.max(0, estimatedTotal - elapsed)
        
        statusLabel.Text = string.format("%d/%d objects | ETA: %.1fs", count, totalObjects, remaining)
        task.wait(0.01) 
    end

    local className = obj.ClassName
    output = output .. string.format('  <Item class="%s" name="%s">\n', className, HttpService:UrlEncode(obj.Name))
    
    local props = getFlattenedProperties(className)
    for _, prop in ipairs(props) do
        local success, val = pcall(function() return formatVal(obj, prop.name) end)
        if success and val ~= nil then
            output = output .. string.format('    <P n="%s" t="%s">%s</P>\n', prop.name, typeof(obj[prop.name]), HttpService:UrlEncode(val))
        end
    end
    
    for _, child in ipairs(obj:GetChildren()) do 
        serialize(child) 
    end
    
    output = output .. "  </Item>\n"
end

serialize(game) -- You can serialize specific services or just the whole game

output = output .. "</RobloxExport>"
clip(output)


statusLabel.Text = "Export Finished! Cleaning up..."
task.wait(1)
ui:Destroy()
