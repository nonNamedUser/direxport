local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local me=Players.LocalPlayer
 
local hiddenfling = false
local flingThread 

 
local function fling()
	local lp = Players.LocalPlayer
	local c, hrp, vel, movel = nil, nil, nil, 0.1
 
	while hiddenfling do
		RunService.Heartbeat:Wait()
		c = lp.Character
		hrp = c and c:FindFirstChild("HumanoidRootPart")
 
		if hrp then
			vel = hrp.Velocity
			hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
			RunService.RenderStepped:Wait()
			hrp.Velocity = vel
			RunService.Stepped:Wait()
			hrp.Velocity = vel + Vector3.new(0, movel, 0)
			movel = -movel
		end
	end
end

local whitelist={
    "snowboy12766",
    "cs26k",
    "haksibak",
    "jdheiudheu",
    "vvhor884",
    "asiadattinadodici",
}

local flingui=Instance.new("ScreenGui",Players.LocalPlayer.PlayerGui)
flingui.ResetOnSpawn=false

local button=Instance.new("TextButton",flingui)

button.Position=UDim2.new(0.5,0,0.5,0)
button.Size=UDim2.new(0.5,0,0.5,0)

button.AnchorPoint=Vector2.new(0.5,0.5)

local db=false

local cc="pos"
local name=""
local pos=Vector3.new(0,200,0)

task.spawn(function()
    while task.wait(0.1) do
        if cc == "p" then
            local p=Players:FindFirstChild(name)
            if p then
                me.Character.HumanoidRootPart.Position=p.Character.HumanoidRootPart.Position
            end
        else
            me.Character.HumanoidRootPart.Position=pos
        end
    end
end)

button.MouseButton1Click:Connect(function ()
    if db then return end
    db=true
    task.spawn(fling)
    for _, player in Players:GetPlayers() do
        if table.find(whitelist,string.lower(player.Name)) then continue end
        name=player.Name
        cc="p"
        task.wait(0.4)
    end
    cc="pos"
    db=false
end)
