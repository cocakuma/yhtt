
local SoundDef = class("SoundDef")

function SoundDef:init(args)
	--self.samples = args.samples

	self.sounddata = {}
	for k,v in pairs(args.samples) do
		if args.stream then
			table.insert(self.sounddata, love.sound.newDecoder(v))
		else
			table.insert(self.sounddata, love.sound.newSoundData(v))
		end
	end


	self.sample_picker = args.pick or "random"

	if self.sample_picker == "sequence" then
		self.idx = 1
	end

	self.pitch_model = args.pitch 
	self.pitch_min = args.pitch_min
	self.pitch_max = args.pitch_max

	self.volume_min = args.volume_min
	self.volume_max = args.volume_max

	self.looping = args.looping
	self.stream = args.stream
	self.maxplaybacks = args.maxplaybacks or 1
	self.fadeintime = args.fadeintime
	self.fadeouttime = args.fadeouttime
end

function SoundDef:PickSource()
	if self.sample_picker == "random" then
		return self.sounddata[math.random(#self.sounddata)]
	elseif self.sample_picker == "sequence" then
		local def = self.sounddata[self.idx]
		self.idx = self.idx + 1
		if self.idx > #self.sounddata then
			self.idx = 1
		end
		return def
	end
end

