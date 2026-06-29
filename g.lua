while task.wait()  do
	local rng = Random.new()
	local randomPosition = Vector3.new(
		rng:NextNumber(-100000, 100000),
		99
		rng:NextNumber(-100000, 100000)
	)

	local z=Instance.new("Part", workspace)
	z.Position=randomPosition
end
