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

function math.clamp(num, min, max)
	num = math.max(min, num)
	num = math.min(max, num)
	return num
end

function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end