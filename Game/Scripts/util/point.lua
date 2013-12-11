class("Point")

function Point:init(x,y)
	self.x = self.x or x or 0
	self.y = self.y or y or 0
end

function Point:__add(pt)
	return Point:new(self.x + pt.x, self.y + pt.y)
end

function Point:__sub(pt)
	return Point:new(self.x - pt.x, self.y - pt.y)
end

function Point:__mul(num)
	return Point:new(self.x*num, self.y*num)
end

function Point:__div(num)
	return Point:new(self.x/num, self.y/num)
end

function Point:__unm(num)
	return Point:new(-self.x, -self.y)
end

function Point:__eq(pt)
	return self.x == pt.x and self.y == pt.y
end

function Point:__tostring()
	return string.format("(%2.2f, %2.2f)", self.x, self.y)
end

function Point:length()
	return math.sqrt(self.x*self.x + self.y*self.y)
end

function Point:lengthSq()
	return self.x*self.x + self.y*self.y
end

function Point:dist(pt)
	local dx = self.x - pt.x
	local dy = self.y - pt.y
	return math.sqrt(dx*dx + dy*dy)
end

function Point:Get()
	return self.x, self.y
end

function Point:distSq(pt)
	local dx = self.x - pt.x
	local dy = self.y - pt.y
	return dx*dx + dy*dy
end

function Point:dot(pt)
	return self.x*pt.x + self.y*pt.y
end

Point.Ones = Point(1,1)
Point.Zeros = Point(0,0)

