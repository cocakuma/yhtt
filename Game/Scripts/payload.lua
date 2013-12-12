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

function Payload:OnAttached(other)
	print(self._classname, other._classname)
	print(self.ID,"Setting payload team to", other.team)
	self.team = other.team
end

function Payload:OnDetached(other)
	print(self.ID,"resetting payload team to")
	self.team = -1
end

