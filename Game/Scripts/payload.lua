require("util/vector2")
require("util/class")
require("attachable")

class("Payload", Attachable)

function Payload:init(x, y)
	self._base.init(self, x, y, PAYLOAD_SIZE.rad, TUNING.PAYLOAD.MASS)

	self.team = -1
end

function Payload:GetChildVelocities()
	local c_Vels = self._base.GetChildVelocities(self)
	for i=1,self.mass do
		table.insert(c_Vels, Vector2(0,0))
	end
	return c_Vels
end

function Payload:GetChildVelocities()
	local c_Thrusts = self._base.GetChildVelocities(self)
	for i=1,self.mass do
		table.insert(c_Thrusts, Vector2(0,0))
	end
	return c_Thrusts
end

function Payload:OnAttached(other)
	print(self._classname, other._classname)
	print(self.ID,"Setting payload team to", other.team)
	self.team = other.team
end

function Payload:OnDetached(other)
	print(self.ID,"resetting payload team to")
	self.team = -1
end

function Payload:Collide(other)
	local diff = self.position - other.position
	-- random offset fixes two ships in the exact same position
	diff.x = diff.x + math.random()*0.002-0.001
	diff.y = diff.y + math.random()*0.002-0.001

	local parent = self:GetTrueParent()
	parent.velocity = self.velocity + diff:GetNormalized() * 20

	local impactVel = self.velocity:Length()
	if other.velocity then impactVel = impactVel + other.velocity:Length() end
end

function Payload:Hit(bullet)
	local parent = self:GetTrueParent()
	parent.velocity = parent.velocity + bullet.velocity:GetNormalized() * 20	

	self.tryDetach = true
end
