require "sounddef"
require "mixnode"

local SoundBank = class("SoundBank")

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

function SoundBank:init(defs)
	self.sounds = {}
	self.defs = defs
	setnames(defs, self.sounds)
end
