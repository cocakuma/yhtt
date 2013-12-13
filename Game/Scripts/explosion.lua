require("util/vector2")
require("util/class")

class("Explosion")

local bullet = 
{
	size = 2,
	speed = 15,
	speed_var = 14,
	num = 10,
	lifetime = 1,
}

local ship =
{
	size = 4,
	speed = 20,
	speed_var = 19,
	num = 30,
	lifetime = 2,
}

function Explosion:init(data)
	self.ID = NextID()
	explosions[self.ID] = self

	self.pos = data.pos
	self.team = data.team
	
	if data.exp_type == 1 then
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

function Explosion:MakeExplosion(ship)

end

function Explosion:CreateParticle()
	local particle = {}
	local angle = math.random() * 2 * math.pi
	local dir = Vector2(math.cos(angle), math.sin(angle))
	particle.velocity = dir * (self.speed + ((math.random() * self.speed_var/2) - (math.random() * self.speed_var)))
	particle.pos = self.pos
	return particle
end

function Explosion:Update(dt)
	self.age = self.age + dt
	self.alpha = lerp(255, 0, self.age/self.lifetime)
	
	for k,v in pairs(self.particles) do
		v.pos = v.pos + (v.velocity * dt)
	end

	if self.age > self.lifetime then
		self:Destroy()
	end

end

function Explosion:Pack(pkg)
	pkg = pack(pkg, 'a', self.alpha)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 's', self.size)
	pkg = beginpacktable(pkg, 'p')
		for k,v in pairs(self.particles) do
			pkg = beginpacktable(pkg, k)
			pkg = pack(pkg, 'x', v.pos.x)
			pkg = pack(pkg, 'y', v.pos.y)		
			pkg = endpacktable(pkg)
		end	
	pkg = endpacktable(pkg)	
	return pkg
end	

function Explosion:Destroy()
	explosions[self.ID] = nil
end