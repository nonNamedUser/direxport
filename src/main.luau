local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local cloneref = cloneref or function(obj)
    return obj
end

local clip = setclipboard or toclipboard

local function getService(name)
    return cloneref(game:GetService(name))
end

local function escapeXML(value)
    local s = tostring(value)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    s = s:gsub("'", "&apos;")
    return s
end

local function createProgressUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ExportProgressUI"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.Parent = cloneref(game:GetService("CoreGui"))

    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(6, 10, 18)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = sg

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 430, 0, 145)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.5, 35)
    card.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    card.BorderSizePixel = 0
    card.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(92, 170, 255)
    stroke.Transparency = 0.15
    stroke.Parent = card

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 35, 54)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 30))
    })
    grad.Rotation = 15
    grad.Parent = card

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Size = UDim2.new(1, -28, 0, 40)
    title.Text = "Exporting Game Data"
    title.TextColor3 = Color3.fromRGB(236, 243, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 19
    title.Parent = card

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 14, 0, 58)
    track.Size = UDim2.new(1, -28, 0, 16)
    track.BackgroundColor3 = Color3.fromRGB(31, 45, 68)
    track.BorderSizePixel = 0
    track.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
    bar.BorderSizePixel = 0
    bar.Parent = track

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 232, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(84, 138, 255))
    })
    barGrad.Parent = bar

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 14, 0, 90)
    status.Size = UDim2.new(1, -28, 0, 28)
    status.Text = "Initializing..."
    status.TextColor3 = Color3.fromRGB(162, 187, 218)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13
    status.Parent = card

    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()

    return sg, bar, status
end

local function createTokenUI(onSubmit)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ExportTokenUI"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000
    sg.Parent = cloneref(game:GetService("CoreGui"))

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 390, 0, 160)
    card.Position = UDim2.new(0.5, -195, 0.45, 32)
    card.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    card.BorderSizePixel = 0
    card.Parent = sg

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(92, 170, 255)
    stroke.Transparency = 0.15

    local grad = Instance.new("UIGradient", card)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 35, 54)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 30))
    })

    local title = Instance.new("TextLabel", card)
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Size = UDim2.new(1, -28, 0, 42)
    title.Text = "Upload Export To GitHub Gist"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(236, 243, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16

    local input = Instance.new("TextBox", card)
    input.Size = UDim2.new(1, -28, 0, 38)
    input.Position = UDim2.new(0, 14, 0, 58)
    input.BackgroundColor3 = Color3.fromRGB(28, 38, 58)
    input.BorderSizePixel = 0
    input.Text = ""
    input.PlaceholderText = "ghp_xxxxxxxxxxxxxxxxx"
    input.TextColor3 = Color3.fromRGB(234, 241, 255)
    input.PlaceholderColor3 = Color3.fromRGB(118, 140, 172)
    input.Font = Enum.Font.Code
    input.TextSize = 14
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)

    local status = Instance.new("TextLabel", card)
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 14, 0, 100)
    status.Size = UDim2.new(1, -190, 0, 48)
    status.Text = ""
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.TextWrapped = true
    status.TextColor3 = Color3.fromRGB(170, 192, 220)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12

    local button = Instance.new("TextButton", card)
    button.Size = UDim2.new(0, 160, 0, 34)
    button.Position = UDim2.new(1, -174, 1, -46)
    button.BackgroundColor3 = Color3.fromRGB(38, 145, 246)
    button.BorderSizePixel = 0
    button.Text = "Upload Gist"
    button.TextColor3 = Color3.fromRGB(246, 250, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

    local bGrad = Instance.new("UIGradient", button)
    bGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(61, 204, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 125, 255))
    })

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {Size = UDim2.new(0, 166, 0, 36)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {Size = UDim2.new(0, 160, 0, 34)}):Play()
    end)

    button.MouseButton1Click:Connect(function()
        local token = input.Text
        if token == "" then
            status.Text = "GitHub token is required."
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
            return
        end
        onSubmit(token, status, sg)
    end)

    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, -195, 0.45, 0)
    }):Play()

    return sg
end

local function fetchApiDump()
    local ok, version = pcall(function()
        return game:HttpGet("https://setup.rbxcdn.com/versionQTStudio")
    end)
    if not ok or not version then
        return nil
    end

    local okDump, dumpBody = pcall(function()
        return game:HttpGet("https://setup.rbxcdn.com/" .. version .. "-API-Dump.json")
    end)
    if not okDump or not dumpBody then
        return nil
    end

    local okJson, data = pcall(function()
        return HttpService:JSONDecode(dumpBody)
    end)
    if not okJson then
        return nil
    end
    return data
end

local apiData = fetchApiDump()
local classMap = {}
if apiData and apiData.Classes then
    for _, class in ipairs(apiData.Classes) do
        classMap[class.Name] = class
    end
end

local propertyCache = {}

local function getApiTypeName(member)
    local vt = member and member.ValueType
    if type(vt) == "table" then
        return vt.Name or vt.name or vt.Category or "string"
    end
    if type(vt) == "string" then
        return vt
    end
    return "string"
end

local function getFlattenedProperties(className)
    if propertyCache[className] then
        return propertyCache[className]
    end

    local props = {}
    local seen = {}
    local current = className

    while current and current ~= "<<<ROOT>>>" do
        local data = classMap[current]
        if not data then
            break
        end

        for _, member in ipairs(data.Members or {}) do
            if member.MemberType == "Property" then
                local tags = member.Tags or {}
                if not table.find(tags, "ReadOnly") and not table.find(tags, "Hidden") then
                    local lower = string.lower(member.Name)
                    if not seen[lower] then
                        seen[lower] = true
                        table.insert(props, {
                            name = member.Name,
                            apiType = getApiTypeName(member)
                        })
                    end
                end
            end
        end

        current = data.Superclass
    end

    propertyCache[className] = props
    return props
end

local function normalizeTypeTag(apiType, runtimeType)
    local map = {
        bool = "boolean",
        int = "number",
        int32 = "number",
        int64 = "number",
        float = "number",
        double = "number",
        coordinateframe = "CFrame",
        cframe = "CFrame",
        vector2 = "Vector2",
        vector3 = "Vector3",
        color3 = "Color3",
        udim = "UDim",
        udim2 = "UDim2",
        token = "EnumItem",
        enum = "EnumItem",
        object = "Instance",
        instance = "Instance",
        brickcolor = "BrickColor",
        string = "string"
    }

    if runtimeType and runtimeType ~= "string" then
        return runtimeType
    end

    local key = string.lower(tostring(apiType or "string"))
    return map[key] or tostring(apiType or runtimeType or "string")
end

local function formatValue(v)
    local t = typeof(v)
    if t == "CFrame" then
        return table.concat({v:GetComponents()}, ",")
    elseif t == "Vector3" or t == "Vector2" then
        return tostring(v)
    elseif t == "Color3" then
        return string.format("%d,%d,%d", math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
    elseif t == "UDim2" then
        return string.format("%s,%s,%s,%s", tostring(v.X.Scale), tostring(v.X.Offset), tostring(v.Y.Scale), tostring(v.Y.Offset))
    elseif t == "UDim" then
        return string.format("%s,%s", tostring(v.Scale), tostring(v.Offset))
    end
    return tostring(v)
end

local services = {
    getService("Workspace"),
    getService("ReplicatedStorage"),
    getService("ReplicatedFirst"),
    getService("Lighting"),
    getService("StarterGui"),
    getService("StarterPlayer")
}

local totalObjects = 0
for _, service in ipairs(services) do
    totalObjects += #service:GetDescendants() + 1
end

local ui, progressBar, statusLabel = createProgressUI()
local startTime = tick()

local output = {"<RobloxExport>\n"}
local count = 0

local function serialize(obj)
    count += 1

    if count % 150 == 0 then
        local progress = math.clamp(count / math.max(totalObjects, 1), 0, 1)
        progressBar.Size = UDim2.new(progress, 0, 1, 0)

        local elapsed = tick() - startTime
        local estimatedTotal = progress > 0 and (elapsed / progress) or 0
        local remaining = math.max(0, estimatedTotal - elapsed)
        statusLabel.Text = string.format("%d/%d objects | ETA %.1fs", count, totalObjects, remaining)
        task.wait()
    end

    table.insert(output, string.format('  <Item class="%s" name="%s">\n', escapeXML(obj.ClassName), escapeXML(obj.Name)))

    if obj:IsA("LuaSourceContainer") then
        local decompiler = decompile or (bit and bit.decompile)
        if decompiler then
            local ok, src = pcall(function()
                return decompiler(obj)
            end)
            if ok and src and src ~= "" then
                table.insert(output, string.format('    <P n="Source" t="string">%s</P>\n', escapeXML(src)))
            end
        end
    end

    local props = getFlattenedProperties(obj.ClassName)
    for _, prop in ipairs(props) do
        if prop.name ~= "Parent" and prop.name ~= "Source" then
            local ok, raw = pcall(function()
                return obj[prop.name]
            end)
            if ok and raw ~= nil then
                local typeTag = normalizeTypeTag(prop.apiType, typeof(raw))
                local val = formatValue(raw)
                table.insert(output, string.format('    <P n="%s" t="%s">%s</P>\n', escapeXML(prop.name), escapeXML(typeTag), escapeXML(val)))
            end
        end
    end

    for _, child in ipairs(obj:GetChildren()) do
        serialize(child)
    end

    table.insert(output, "  </Item>\n")
end

for _, service in ipairs(services) do
    table.insert(output, string.format('  <ServiceRoot name="%s">\n', escapeXML(service.Name)))
    serialize(service)
    table.insert(output, "  </ServiceRoot>\n")
end

table.insert(output, "</RobloxExport>")
local finalOutput = table.concat(output)

progressBar.Size = UDim2.new(1, 0, 1, 0)
statusLabel.Text = "Saving export payload..."

local storageScript = Instance.new("LocalScript")
storageScript.Name = "CORE_DUMP_DATA"
storageScript.Disabled = true

local writeOk = pcall(function()
    storageScript.Source = "--[[ XML DATA BELOW ]]\n" .. finalOutput
end)

if writeOk then
    storageScript.Parent = game:GetService("ReplicatedStorage")
    statusLabel.Text = "Saved to ReplicatedStorage/CORE_DUMP_DATA"
else
    local val = Instance.new("StringValue")
    val.Name = "CORE_DUMP_DATA_STRING"
    val.Value = finalOutput:sub(1, 199999)
    val.Parent = game:GetService("ReplicatedStorage")
    statusLabel.Text = "Source too large. Saved trimmed CORE_DUMP_DATA_STRING"
end

task.wait(0.35)
ui:Destroy()

local httpRequest = request or http_request or (http and http.request) or syn.request
if not httpRequest then
    return
end

createTokenUI(function(token, status, tokenGui)
    status.Text = "Uploading gist..."
    status.TextColor3 = Color3.fromRGB(165, 188, 215)

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

    if response and response.Success then
        local okData, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if okData and data and data.html_url then
            clip(data.html_url)
            status.Text = "Success. Gist link copied to clipboard."
            status.TextColor3 = Color3.fromRGB(130, 232, 170)
            task.wait(1.5)
            tokenGui:Destroy()
            return
        end
    end

    status.Text = "Upload failed. Check token/scopes."
    status.TextColor3 = Color3.fromRGB(255, 130, 130)
end)
