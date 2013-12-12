require("util/vector2")
require("util/class")

class("Arena")

local thickness = 5

function Arena:init(width, height)
	self.ID = NextID()

	self.width = width
	self.height = height
end

function Arena:Draw()
	love.graphics.setColor(125,55,55,255)
	love.graphics.rectangle("fill", -thickness, -thickness, thickness, self.height + thickness*2)
	love.graphics.rectangle("fill", -thickness, -thickness, self.width + thickness*2, thickness)
	love.graphics.rectangle("fill", -thickness, self.height, self.width + thickness*2, thickness)
	love.graphics.rectangle("fill", self.width, -thickness, thickness, self.height + thickness*2)
end

function Arena:OOB( position )
	local ret = Vector2(0,0)
	local oob = false
	if position.x < 0 then
		ret.x = 0 - position.x
		oob = true
	elseif position.x > self.width then
		ret.x = self.width - position.x
		oob = true
	end
	if position.y < 0 then
		ret.y = 0 - position.y
		oob = true
	elseif position.y > self.height then
		ret.y = self.height - position.y
		oob = true
	end
	if oob then
		return ret
	else
		return nil
	end
end
