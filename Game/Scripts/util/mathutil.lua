function distsq(v1, v2)
	local distsq = (v2.x - v1.x)^2 + (v2.y - v1.y)^2
	return distsq
end

function sumVelocities(tbl)
	local vel = Vector2(0,0)

	for k,v in pairs(tbl) do
		vel = vel + v
	end

	return vel
end

function sumThrusts(tbl)
	local t = Vector2(0,0)

	for k,v in pairs(tbl) do
		t = t + v
	end

	return t
end

function lerp (a, b, t)
        return a + (b - a) * t
end