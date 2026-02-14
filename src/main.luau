local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local cloneref = cloneref or function(obj)
    return obj
end

local clip = setclipboard or toclipboard

local SERVICES = {
    "Workspace",
    "ReplicatedStorage",
    "ReplicatedFirst",
    "Lighting",
    "StarterGui",
    "StarterPlayer"
}

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
    sg.Name = "ExporterUI"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.Parent = cloneref(game:GetService("CoreGui"))

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 430, 0, 146)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.5, 32)
    card.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    card.BorderSizePixel = 0
    card.Parent = sg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(90, 170, 255)
    stroke.Transparency = 0.15
    local grad = Instance.new("UIGradient", card)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 35, 54)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 30))
    })

    local title = Instance.new("TextLabel", card)
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Size = UDim2.new(1, -28, 0, 40)
    title.Text = "Exporting Game Data"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(236, 243, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 19

    local track = Instance.new("Frame", card)
    track.Position = UDim2.new(0, 14, 0, 60)
    track.Size = UDim2.new(1, -28, 0, 16)
    track.BackgroundColor3 = Color3.fromRGB(31, 45, 68)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame", track)
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local barGrad = Instance.new("UIGradient", bar)
    barGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 232, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(84, 138, 255))
    })

    local status = Instance.new("TextLabel", card)
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 14, 0, 92)
    status.Size = UDim2.new(1, -28, 0, 26)
    status.Text = "Initializing..."
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(162, 187, 218)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()

    return sg, bar, status
end

local function createTokenUI(onSubmit)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ExporterTokenUI"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000
    sg.Parent = cloneref(game:GetService("CoreGui"))

    local card = Instance.new("Frame", sg)
    card.Size = UDim2.new(0, 390, 0, 160)
    card.Position = UDim2.new(0.5, -195, 0.45, 30)
    card.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(90, 170, 255)
    stroke.Transparency = 0.15

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
    input.Text = ""
    input.PlaceholderText = "ghp_xxxxxxxxxxxxxxxxx"
    input.BackgroundColor3 = Color3.fromRGB(28, 38, 58)
    input.BorderSizePixel = 0
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

    button.MouseButton1Click:Connect(function()
        local token = input.Text
        if token == "" then
            status.Text = "GitHub token is required."
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
            return
        end
        onSubmit(token, status, sg)
    end)

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, -195, 0.45, 0)
    }):Play()
end

local function typeTagOf(v)
    local t = typeof(v)
    if t == "boolean" or t == "number" or t == "string" then
        return t
    end
    if t == "CFrame" or t == "Vector3" or t == "Vector2" or t == "Color3" or t == "UDim2" or t == "UDim" then
        return t
    end
    if t == "EnumItem" or t == "Instance" or t == "BrickColor" then
        return t
    end
    return "string"
end

local function formatValue(v, tag)
    if tag == "CFrame" then
        return table.concat({v:GetComponents()}, ",")
    end
    if tag == "Color3" then
        return string.format("%d,%d,%d", math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
    end
    if tag == "UDim2" then
        return string.format("%s,%s,%s,%s", tostring(v.X.Scale), tostring(v.X.Offset), tostring(v.Y.Scale), tostring(v.Y.Offset))
    end
    if tag == "UDim" then
        return string.format("%s,%s", tostring(v.Scale), tostring(v.Offset))
    end
    return tostring(v)
end

local function safeRead(obj, propName)
    local ok, value = pcall(function()
        return obj[propName]
    end)
    if ok then
        return true, value
    end
    return false, nil
end

local function fetchApiDump()
    local okV, version = pcall(function()
        return game:HttpGet("https://setup.rbxcdn.com/versionQTStudio")
    end)
    if not okV or not version then
        return nil
    end

    local okD, body = pcall(function()
        return game:HttpGet("https://setup.rbxcdn.com/" .. version .. "-API-Dump.json")
    end)
    if not okD or not body then
        return nil
    end

    local okJ, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if okJ then
        return data
    end
    return nil
end

local apiData = fetchApiDump()
local classMap = {}
if apiData and apiData.Classes then
    for _, class in ipairs(apiData.Classes) do
        classMap[class.Name] = class
    end
end

local propertyCache = {}

local function getMemberTypeName(member)
    local vt = member and member.ValueType
    if type(vt) == "table" then
        return vt.Name or "string"
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
        local classInfo = classMap[current]
        if not classInfo then
            break
        end

        for _, member in ipairs(classInfo.Members or {}) do
            if member.MemberType == "Property" then
                local tags = member.Tags or {}
                if not table.find(tags, "ReadOnly") and not table.find(tags, "Hidden") then
                    local key = string.lower(member.Name)
                    if not seen[key] then
                        seen[key] = true
                        props[#props + 1] = {
                            name = member.Name,
                            apiType = getMemberTypeName(member)
                        }
                    end
                end
            end
        end

        current = classInfo.Superclass
    end

    propertyCache[className] = props
    return props
end

local function collectObjectCount(rootServices)
    local total = 0
    for _, service in ipairs(rootServices) do
        total += 1 + #service:GetDescendants()
    end
    return total
end

local function exportXML()
    local roots = {}
    for _, name in ipairs(SERVICES) do
        roots[#roots + 1] = cloneref(game:GetService(name))
    end

    local total = collectObjectCount(roots)
    local ui, bar, status = createProgressUI()

    local chunks = {"<RobloxExport>\n"}
    local processed = 0
    local startTime = tick()

    local function appendProperties(obj)
        for _, prop in ipairs(getFlattenedProperties(obj.ClassName)) do
            if prop.name ~= "Parent" and prop.name ~= "Source" then
                local ok, raw = safeRead(obj, prop.name)
                if ok and raw ~= nil then
                    local tag = typeTagOf(raw)
                    if tag == "string" and prop.apiType then
                        local apiLower = string.lower(prop.apiType)
                        if apiLower == "bool" then tag = "boolean" end
                        if apiLower == "float" or apiLower == "double" or apiLower == "int" or apiLower == "int64" then tag = "number" end
                        if apiLower == "coordinateframe" then tag = "CFrame" end
                        if apiLower == "vector2" then tag = "Vector2" end
                        if apiLower == "vector3" then tag = "Vector3" end
                        if apiLower == "color3" then tag = "Color3" end
                        if apiLower == "udim2" then tag = "UDim2" end
                        if apiLower == "udim" then tag = "UDim" end
                        if apiLower == "token" or apiLower == "enum" then tag = "EnumItem" end
                        if apiLower == "object" or apiLower == "instance" then tag = "Instance" end
                        if apiLower == "brickcolor" then tag = "BrickColor" end
                    end
                    local val = formatValue(raw, tag)
                    chunks[#chunks + 1] = string.format('    <P n="%s" t="%s">%s</P>\n', escapeXML(prop.name), escapeXML(tag), escapeXML(val))
                end
            end
        end
    end

    local function visit(obj)
        processed += 1
        if processed % 120 == 0 then
            local progress = math.clamp(processed / math.max(1, total), 0, 1)
            bar.Size = UDim2.new(progress, 0, 1, 0)
            local elapsed = tick() - startTime
            local eta = progress > 0 and ((elapsed / progress) - elapsed) or 0
            status.Text = string.format("%d/%d objects | ETA %.1fs", processed, total, math.max(0, eta))
            task.wait()
        end

        chunks[#chunks + 1] = string.format('  <Item class="%s" name="%s">\n', escapeXML(obj.ClassName), escapeXML(obj.Name))

        if obj:IsA("LuaSourceContainer") then
            local decompiler = decompile or (bit and bit.decompile)
            if decompiler then
                local ok, src = pcall(function()
                    return decompiler(obj)
                end)
                if ok and src and src ~= "" then
                    chunks[#chunks + 1] = string.format('    <P n="Source" t="string">%s</P>\n', escapeXML(src))
                end
            end
        end

        appendProperties(obj)

        for _, child in ipairs(obj:GetChildren()) do
            visit(child)
        end

        chunks[#chunks + 1] = "  </Item>\n"
    end

    for _, service in ipairs(roots) do
        chunks[#chunks + 1] = string.format('  <ServiceRoot name="%s">\n', escapeXML(service.Name))
        visit(service)
        chunks[#chunks + 1] = "  </ServiceRoot>\n"
    end

    chunks[#chunks + 1] = "</RobloxExport>"
    local xml = table.concat(chunks)

    bar.Size = UDim2.new(1, 0, 1, 0)
    status.Text = "Saving payload..."

    local rs = game:GetService("ReplicatedStorage")
    local old = rs:FindFirstChild("CORE_DUMP_DATA")
    if old then old:Destroy() end
    local oldStr = rs:FindFirstChild("CORE_DUMP_DATA_STRING")
    if oldStr then oldStr:Destroy() end
    local oldChunks = rs:FindFirstChild("CORE_DUMP_CHUNKS")
    if oldChunks then oldChunks:Destroy() end

    local dump = Instance.new("LocalScript")
    dump.Name = "CORE_DUMP_DATA"
    dump.Disabled = true

    local okWrite = pcall(function()
        dump.Source = "--[[ XML DATA BELOW ]]\n" .. xml
    end)

    if okWrite then
        dump.Parent = rs
        task.wait(0.1)
        local verifyOk = pcall(function()
            return #dump.Source >= #("--[[ XML DATA BELOW ]]\n")
        end)
        if verifyOk then
            status.Text = "Saved to ReplicatedStorage/CORE_DUMP_DATA"
        else
            okWrite = false
            dump:Destroy()
        end
    end

    if not okWrite then
        local folder = Instance.new("Folder")
        folder.Name = "CORE_DUMP_CHUNKS"
        folder.Parent = rs

        local chunkSize = 180000
        local totalChunks = math.ceil(#xml / chunkSize)
        folder:SetAttribute("TotalChunks", totalChunks)

        for i = 1, totalChunks do
            local sv = Instance.new("StringValue")
            sv.Name = string.format("Chunk_%04d", i)
            local startIdx = ((i - 1) * chunkSize) + 1
            sv.Value = xml:sub(startIdx, startIdx + chunkSize - 1)
            sv.Parent = folder
        end

        status.Text = string.format("Saved in %d chunks (CORE_DUMP_CHUNKS).", totalChunks)
    end

    task.wait(0.4)
    ui:Destroy()
    return xml
end

local finalOutput = exportXML()

local httpRequest = request or http_request or (http and http.request) or syn.request
if httpRequest then
    createTokenUI(function(token, status, tokenGui)
        status.Text = "Uploading gist..."
        status.TextColor3 = Color3.fromRGB(165, 188, 215)

        local payload = HttpService:JSONEncode({
            description = "Roblox Game Export - " .. os.date(),
            public = false,
            files = {
                ["ExportedGame.xml"] = {content = finalOutput}
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
            local ok, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if ok and data and data.html_url then
                clip(data.html_url)
                status.Text = "Success. Link copied."
                status.TextColor3 = Color3.fromRGB(130, 232, 170)
                task.wait(1.4)
                tokenGui:Destroy()
                return
            end
        end

        status.Text = "Upload failed. Check token."
        status.TextColor3 = Color3.fromRGB(255, 130, 130)
    end)
end
