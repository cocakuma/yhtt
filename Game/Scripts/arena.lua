require("util/vector2")
require("util/class")

class("Arena")

function Arena:init(width, height)
	self.ID = NextID()

	self.width = width
	self.height = height
end

function Arena:Pack(pkg)
	pkg = pack(pkg, 'h', self.height)
	pkg = pack(pkg, 'w', self.width)	
	return pkg
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
