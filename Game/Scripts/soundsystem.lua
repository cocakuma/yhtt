require "soundinstance"
require "mixnode"
require "mixer"

local SoundSystem = class("SoundSystem")

function SoundSystem:init()
	self.banks = {}
	self.sounds = {}

	self.instances = {}
	self.num_sounds = 0
	self.numbyname = {}
	self.bydef = {}

	self.mixtree = MixNode("root")
	self.sfxnode = self.mixtree:AddChild(MixNode("sfx"))
	self.ambientnode = self.mixtree:AddChild(MixNode("ambient"))
	self.musicnode = self.mixtree:AddChild(MixNode("music"))

	self.mixer = Mixer(self.mixtree)
end

function SoundSystem:SetAmbientVol(vol)
	self.ambientnode:SetVol(vol)
end

function SoundSystem:SetMusicVol(vol)
	self.musicvol:SetVol(vol)
end

function SoundSystem:SetSFXVol(vol)
	self.sfxnode:SetVol(vol)
end

local function addmixnodes(rootnode, defs)
	for k,v in pairs(defs) do
		if is_class(v, SoundDef) then
			v.mixnode = rootnode
		elseif type(v) == "table" then 
			if not rootnode.children[k] then
				rootnode:AddChild(MixNode(k))
			end
			addmixnodes(rootnode.children[k], v)
		end
	end
end

function SoundSystem:LoadBank(bankname)
	if not self.banks[bankname] then
		self.banks[bankname] = require("sounds/"..bankname)
		for k,v in pairs(self.banks[bankname].sounds) do
			self.sounds[v.name] = v
		end
	end

	addmixnodes(self.mixtree, self.banks[bankname].defs)
	return self.banks[bankname]
end

function SoundSystem:Update(dt)

	self.mixtree:Update()

	for k,v in pairs(self.instances) do
		k:Update(dt)

		if k.source:isStopped() then
			self.instances[k] = nil
			self.num_sounds = self.num_sounds - 1
			self.numbyname[k.def.name] = self.numbyname[k.def.name] - 1
			self.bydef[k.def.name][k] = nil
		end
	end

end

function SoundSystem:PlaySound(name)
	local def = self.sounds[name]
	
	if self.numbyname[def.name] and self.numbyname[def.name] >= def.maxplaybacks then
		if def.maxmode == "skip" then return end

		--steal the oldest playback
		local playing = self.bydef[def.name]
		local oldest = nil
		for k,v in pairs(playing) do
			if not oldest or oldest.starttime < k.starttime then
				k.source:stop()
				playing[k] = nil
			end
		end
	end

	if def then
		local source = love.audio.newSource(def:PickSource())
		source:setLooping(def.looping)
		if def.pitch_min and def.pitch_max then
			local pitch = def.pitch_min+math.random()*(def.pitch_max-def.pitch_min)
			source:setPitch(pitch)
		end

		if def.volume_min and self.volume_max then
			local volume = def.volume_min+math.random()*(def.volume_max-def.volume_min)
			source:setVolume(volume)
		end

		source:play()
		local instance = SoundInstance(def, source)
		self.numbyname[def.name] = self.numbyname[def.name] and self.numbyname[def.name] + 1 or 1
		self.bydef[def.name] = self.bydef[def.name] or {}
		self.bydef[def.name][instance] = true
		self.instances[instance] = true
		return instance
	else
		print("could not find sound def named" , name)
	end
end
