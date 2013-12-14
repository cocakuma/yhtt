require("util/vector2")
require("util/class")
require("attachable")

class("Payload", Attachable)

function Payload:init(x, y)
	self._base.init(self, x, y, PAYLOAD_SIZE.rad, TUNING.PAYLOAD.MASS)

	self.team = -1
	self.killname = 'Payload'
end

function Payload:OnAttached(other)
	print(self._classname, other._classname)
	print(self.ID,"Setting payload team to", other.team)
	self.team = other.team
end

function Payload:OnDetached(other)
	print(self.ID,"resetting payload team to")
	self.team = -1
	for k,v in pairs(self.children) do
		self.team = v.child.team
		break
	end
end

function Payload:Collide(other)
	local diff = self.position - other.position
	-- random offset fixes two ships in the exact same position
	diff.x = diff.x + math.random()*0.002-0.001
	diff.y = diff.y + math.random()*0.002-0.001

	local parent = self:GetTrueParent()
	parent.velocity = self.velocity + (diff:GetNormalized() * 20)/self:GetMass()

	local impactVel = self.velocity:Length()
	if other.velocity then impactVel = impactVel + other.velocity:Length() end
end

function Payload:Hit(bullet)
	local parent = self:GetTrueParent()
	parent.velocity = parent.velocity + (bullet.velocity:GetNormalized() * 2)/self:GetMass()

	self:Detach()
end

function Payload:Destroy()
	self:Detach()
	bodies[self.ID] = nil
end



