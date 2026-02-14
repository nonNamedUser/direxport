-- structureDump
local clip=setclipboard or toclipboard

local cloneref=cloneref or blankfunction

local function GetService(service)
    return cloneref(game:GetService(service))
end

local services = {
    GetService("Workspace"),
    GetService("ReplicatedStorage"),
    GetService("ReplicatedFirst"),
    GetService("StarterPlayer")
}

local output = "-- [[ Project Structure Dump ]] --\n\n"
local function dumpInstance(ins, indent)
    local prefix = string.rep("  ", indent)
    output = output .. prefix .. " -> " .. ins.Name .. " (" .. ins.ClassName .. ")\n"
    
    for _, child in ipairs(ins:GetChildren()) do
        task.spawn(dumpInstance child, indent + 1)
    end
end

for _, service in ipairs(services) do
    output = output .. "[" .. service.Name .. "]\n"
    for _, child in ipairs(service:GetChildren()) do
        task.spawn(dumpInstancechild, 1)
    end
    output = output .. "\n"
end

clip(output)
