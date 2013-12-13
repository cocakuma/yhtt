require("util/vector2")
require("util/class")
require("bullet")

require("attachable")

class("Ship", Attachable)



function Ship:init(x, y, angle, team, ID)
	self.ID = ID -- in reset the game overrides this ID
	self._base.init(self, x, y, 8, 1)

	self.angle = angle --rads

	self.team = self.ID % 2

	self.particle_type = 1

	self.health = 1 -- 100% always
	
	self.thrustForce = TUNING.SHIP.THRUST
	self.drag = TUNING.SHIP.DRAG
	self.turnSpeed = TUNING.SHIP.TURNSPEED

	self.thrusting = false
	self.didThrust = false
	self.turnLeft = false
	self.turnRight = false

	self.numBoosts = 3
	self.tryBoost = false
	self.boosting = false
	
	self.boostDuration = 3
	self.boostDuration_timer = self.boostDuration

	self.mouse = nil
	
	self.maxAmmoClip = TUNING.SHIP.MAX_AMMO_CLIP
	self.minAmmoClip = 0
	self.currentAmmoClip = self.maxAmmoClip
	self.reloadSpeed = TUNING.SHIP.RELOAD_SPEED
	self.reload_timer = self.reloadSpeed
	self.shoot = false
	self.canShoot = true
	self.canShoot_timer = TUNING.SHIP.SHOOT_COOLDOWN
	self.shotoffset = Vector2(0, 4)

	self:Respawn()
end

function Ship:CanBoost()
	return not self.boosting and self.numBoosts > 0
end

function Ship:BoostTimer(dt)
	self.boostDuration_timer = self.boostDuration_timer - dt
	if self.boostDuration_timer <= 0 then
		self.boostDuration_timer = self.boostDuration
		self.boosting = false
	end
end

function Ship:StartBoost()
	if self:CanBoost() then
		self.boosting = true
		self.numBoosts = self.numBoosts - 1
	end
end

function Ship:ReloadClip(dt)
	self.reload_timer = self.reload_timer - dt
	if self.reload_timer <= 0 then
		self.currentAmmoClip = self.currentAmmoClip + 1
		self.reload_timer = self.reloadSpeed
	end
end

function Ship:ShootCooldown(dt)
	self.canShoot_timer = self.canShoot_timer - dt
	if self.canShoot_timer <= 0 then
		self.canShoot = true
		self.canShoot_timer = TUNING.SHIP.SHOOT_COOLDOWN
	end
end

function Ship:Shoot()
	self.canShoot = false
	local bullet = Bullet(self)
	self.currentAmmoClip = self.currentAmmoClip - 1
	self.shotoffset = self.shotoffset * -1
end

function Ship:HandleInput( )
	if not self.input then
		return
	end
	
	if self.input["d"] == 1 then
		self.turnLeft = true
	end
	if self.input["a"] == 1 then
		self.turnRight = true
	end
	if self.input["w"] == 1 then
		self.thrusting = true
	end
	if self.input[" "] == 1 then
		self.shoot = true
	end
	if self.input["f"] == 1 then
		if not self.parent and not next(self.children) then
			self.tryAttach = true
		else
			self.tryDetach = true
		end
	end

	if self.input["lshift"] == 1 then
		self.tryBoost = true
	end

	if self.input['m_x'] then
		self.mouse = Vector2(self.input['m_x'] or 0, self.input['m_y'] or 0)
	else
		self.mouse = nil
	end
	if self.input["m_l"] == 1 then
		self.thrusting = true
		self.didThrust = true
	end
	if self.input["m_r"] == 1 then
		self.shoot = true
	end
end

function Ship:Update(dt)

	if self.mouse ~= nil then
		self.angle = math.atan2(self.mouse.y, self.mouse.x)
	end

	if self.tryBoost then
		self:StartBoost()
	end

	if self.boosting then
		self:BoostTimer(dt)
		self.thrustForce = 1000
		self.thrusting = true
	else
		self.thrustForce = 100
	end

	if self.turnLeft then
		self.turnLeft = false
		self.angle = self.angle + self.turnSpeed * dt
	end
	if self.turnRight then
		self.turnRight = false
		self.angle = self.angle - self.turnSpeed * dt
	end
	if self.thrusting then
		self.didThrust = true
		self.thrusting = false
		local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
		local thrust = thrustVector * self.thrustForce
		self.thrust = thrust * dt
	else
		self.thrust = Vector2(0,0)
	end

	if not self.canShoot then
		self:ShootCooldown(dt)
	end

	if self.currentAmmoClip < self.maxAmmoClip then
		self:ReloadClip(dt)
	end

	if self.shoot and self.canShoot and self.currentAmmoClip > self.minAmmoClip then
		self:Shoot()
	end
	
	self.shoot = false
	self.tryBoost = false

	self._base.Update(self, dt)

end

function Ship:Pack(pkg)
	pkg = self._base.Pack(self, pkg)
	pkg = pack(pkg, 'a', self.angle)
	pkg = pack(pkg, 'h', self.health)
	pkg = pack(pkg, 'it', self.didThrust and 1 or 0) --"input: thrust"
	self.didThrust = false;
	return pkg
end

function Ship:Collide(other)
	local diff = self.position - other.position
	diff.x = diff.x + math.random()*0.002-0.001
	diff.y = diff.y + math.random()*0.002-0.001

	local parent = self:GetTrueParent()
	parent.velocity = self.velocity + diff:GetNormalized() * 20

	local impactVel = self.velocity:Length()
	if other.velocity then impactVel = impactVel + other.velocity:Length() end

	if other.obstacle then
		self:TakeDamage( impactVel * TUNING.DAMAGE.SHIP_ON_ROCK )
	else
		self:TakeDamage( impactVel * TUNING.DAMAGE.SHIP_ON_SHIP )
	end
end

function Ship:Hit(bullet)
	local parent = self:GetTrueParent()
	parent.velocity = parent.velocity + bullet.velocity:GetNormalized() * 20	
	self:TakeDamage( TUNING.DAMAGE.BULLET_ON_SHIP )
end

function Ship:TakeDamage(damage)
	self.health = math.max(0, self.health - damage)
	if self.health == 0 then
		self:Die()
	end
end

function Ship:Die()
	ParticleSystem(self)	
	self:Detach()
	bodies[self.ID] = nil
	to_respawn[self.ID] = {ship=self, remaining=TUNING.SHIP.RESPAWN_TIME}
end

function Ship:TryRespawn(dt)
	to_respawn[self.ID].remaining = to_respawn[self.ID].remaining - dt
	if to_respawn[self.ID].remaining <= 0 then
		self:Respawn()
	end
end

function Ship:Respawn()
	self.health = 1
	bodies[self.ID] = self
	to_respawn[self.ID] = nil

	if self.team == 0 then
		self.position.x = 40
	else
		self.position.x = arena.width - 40
	end
	self.position.y = math.random() * arena.height

	self.boosting = false
	self.numBoosts = 3

	self.velocity.x = 0
	self.velocity.y = 0
end
