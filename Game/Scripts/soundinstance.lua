local easing = require "util/easing"
local SoundInstance = class("SoundInstance")

function SoundInstance:init(def, source)
	self.def = def
	self.source = source
	self.timestart = love.timer.getTime()
end

function SoundInstance:__tostring()
	return "SOUND"
end


function SoundInstance:Update(dt)
	local base_volume = 1
	if self.def.fadeintime and (love.timer.getTime() - self.timestart) < self.def.fadeintime then
		local t = love.timer.getTime() - self.timestart
		base_volume = base_volume * math.min(1, easing.linear(t, 0, 1, self.def.fadeintime))
	end

	if self.stopping then
		self.t = self.t + dt
		base_volume = base_volume * math.max(0, easing.linear(self.t,1,-1,self.def.fadeouttime))

		if self.t >= self.def.fadeouttime then
			self.source:stop()
		end
	end

	local v = base_volume * self.def.mixnode.network_volume
	--print(self.def, v, self.def.mixnode.name)
	self.source:setVolume(v)
end


function SoundInstance:Stop()
	if self.def.fadeouttime then
		self.stopping = true
		self.t = 0
	else
		self.source:stop()
	end

end
