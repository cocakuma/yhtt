require("util/vector2")
require("util/class")

class("Explosion")

local bullet = 
{
	size = 3,
	speed = 150,
	speed_var = 104,
	num = 20,
	lifetime = .5,
}

local ship =
{
	size = 6,
	speed = 230,
	speed_var = 205,
	num = 30,
	lifetime = .52,
}

function Explosion:init(data)
	explosions[self] = self

	self.position = data.position
	self.team = data.team
	self.parent = data.parent
	if data.particle_type == 1 then
		data = ship	
	else
		data = bullet
	end

	self.num = data.num
	self.size = data.size
	self.lifetime = data.lifetime
	self.speed = data.speed
	self.speed_var = data.speed_var

	self.age = 0
	self.particles = {}

	for i = 1, self.num do
		local particle = self:CreateParticle()
		table.insert(self.particles, particle)
	end
end

function Explosion:CreateParticle()
	local particle = {}
	local angle = math.random() * 2 * math.pi
	local dir = Vector2(math.cos(angle), math.sin(angle))
	particle.velocity = dir * (self.speed + ((math.random() * self.speed_var/2) - (math.random() * self.speed_var)))
	particle.position = self.position
	return particle
end

function Explosion:Update(dt)
	self.age = self.age + dt
	self.alpha = lerp(255, 0, self.age/self.lifetime)
	
	for k,v in pairs(self.particles) do
		v.position = v.position + (v.velocity * dt)
	end

	if self.age > self.lifetime then
		self:Destroy()
	end

end

function Explosion:Destroy()
	explosions[self] = nil
end
