require("util/vector2")
require("util/class")
require("attachable")

class("Payload", Attachable)

function Payload:init(x, y)
	self._base.init(self, x, y, PAYLOAD_SIZE.rad, TUNING.PAYLOAD.MASS)

	self.ID = NextID()
	payloads[self.ID] = self
	
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

