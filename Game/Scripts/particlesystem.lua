require("util/vector2")
require("util/class")

class("ParticleSystem")

function ParticleSystem:init(parent)
	self.ID = NextID()
	particlesystems[self.ID] = self

	self.position = parent.position
	self.team = parent.team
	self.particle_type = parent.particle_type
	self.parent = parent.ID

	self.age = 0
	self.lifetime = 10
end

function ParticleSystem:Update(dt)
	self.age = self.age + 1
	if self.age > self.lifetime then
		self:Destroy()
	end
end

function ParticleSystem:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 'p', self.parent)
	pkg = pack(pkg, 'typ', self.particle_type)
	return pkg
end	

function ParticleSystem:Destroy()
	particlesystems[self.ID] = nil
end