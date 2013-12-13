require "mixnode"

local Mix = class("Mix")

local function setnames(t,sounds,namesofar)
	for k,v in pairs(t) do
		local name = namesofar and namesofar .."." .. k or k
		if is_class(v, SoundDef) then
			v.name = name
			sounds[name] = v
		elseif type(v) == "table" then
			setnames(v, sounds, name)
		end
	end
end

function Mix:init(arg)
	self.targets = {}
	self.target_nodes = {}
	self.pushtime = arg.pushtime or 0
	for k,v in pairs(arg.vol) do
		self.targets[k] = v
	end
end
