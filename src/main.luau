-- yes this is made by gemini cause i was too lazy to make it

local HttpService = game:GetService("HttpService")
local cloneref = cloneref or function(obj) return obj end
local clip=setclipboard or toclipboard

local function GetService(service)
    return cloneref(game:GetService(service))
end

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
local function serialize(obj)
    local className = obj.ClassName
    output = output .. string.format('  <Item class="%s" name="%s">\n', className, HttpService:UrlEncode(obj.Name))
    local props = getFlattenedProperties(className)
    for _, prop in ipairs(props) do
        local success, val = pcall(function() return formatVal(obj, prop.name) end)
        if success and val ~= nil then
            output = output .. string.format('    <P n="%s" t="%s">%s</P>\n', prop.name, typeof(obj[prop.name]), HttpService:UrlEncode(val))
        end
    end
    for _, child in ipairs(obj:GetChildren()) do serialize(child) end
    output = output .. "  </Item>\n"
end

local services = {
    GetService("Workspace"),
    GetService("ReplicatedStorage"),
    GetService("ReplicatedFirst"),
    GetService("StarterGui"),
    GetService("StarterPlayer")
}

for _, service in ipairs(services) do serialize(service) end
output = output .. "</RobloxExport>"

clip(output)
