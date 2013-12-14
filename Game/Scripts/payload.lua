require("util/vector2")
require("util/class")
require("attachable")

class("Payload", Attachable)

function Payload:init(x, y)
	self._base.init(self, x, y, PAYLOAD_SIZE.rad, TUNING.PAYLOAD.MASS)

	self.team = -1
	self.killname = 'Payload'

	self.health = TUNING.PAYLOAD.HEALTH
	self.maxHealth = self.health
	self.regenRate = TUNING.PAYLOAD.REGEN_RATE
	self.pulseCooldown = TUNING.PAYLOAD.PULSE_COOLDOWN
	self.pulseCooldown_timer = self.pulseCooldown
	self.pulseTriggered = false
end

function Payload:CanAttach()
	if self.pulseTriggered then
		return false
	end
	return self._base.CanAttach(self)
end

function Payload:Pack(pkg)
	pkg = self._base.Pack(self, pkg)
	pkg = pack(pkg, 'h', self.health)
	pkg = pack(pkg, 'ht', self.pulseCooldown_timer)
	return pkg
end

function Payload:OnAttached(other)
	print(self._classname, other._classname)
	print(self.ID,"Setting payload team to", other.team)
	self.team = other.team
end

function Payload:OnDetached(other)
	print(self.ID,"resetting payload team")
	self.team = -1
	for k,v in pairs(self.children) do
		self.team = v.child.team
		break
	end
end

function Payload:DoCooldown(dt)
	self.pulseCooldown_timer = self.pulseCooldown_timer - dt
	if self.pulseCooldown_timer <= 0 then
		self.pulseTriggered = false
		self.health = self.maxHealth
		self.pulseCooldown_timer = self.pulseCooldown
	end
end

function Payload:DoExplode()
	self.pulseTriggered = true
	self:ExplosiveDetach(TUNING.PAYLOAD.DETACH_FORCE)
end

function Payload:Update(dt)

	if self.health <= self.maxHealth and not self.pulseTriggered then
		self.health = lerp(self.health, self.maxHealth, dt * self.regenRate)
	end

	if self.pulseTriggered then
		self:DoCooldown(dt)
	end

	self._base.Update(self, dt)
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

	if other.obstacle then
		self:HealthDelta( impactVel * TUNING.DAMAGE.PAYLOAD_ON_ROCK, other )
	else
		self:HealthDelta( impactVel * TUNING.DAMAGE.PAYLOAD_ON_SHIP, other )
	end

end

function Payload:HealthDelta(d)
	self.health = self.health - d
	self.health = math.clamp(self.health, 0, self.maxHealth)
	if self.health <= 0 and not self.pulseTriggered then
		self:DoExplode()
	end
end

function Payload:Hit(bullet)
	local parent = self:GetTrueParent()
	parent.velocity = parent.velocity + (bullet.velocity:GetNormalized() * 2)/self:GetMass()
	self:HealthDelta(TUNING.DAMAGE.BULLET_ON_PAYLOAD)	
end

function Payload:Destroy()
	self:Detach()
	bodies[self.ID] = nil
end



