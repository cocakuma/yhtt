local Mixer = class("Mixer")

function  Mixer:init( rootnode )
	self.mixstack = {}
	self.t = 0
	self.mixes = {}
	self.rootnode = rootnode
	self.snapshot = nil
	self.target = nil
	self.currentmix = nil
end

function Mixer:Snapshot()
	self.snapshot = {}
	self.rootnode:CollectSnapshot(self.snapshot)
end

function Mixer:LoadDefs(file)
	local mixes = require(file)
	for k,v in pairs(mixes) do
		self.mixes[k] = v
		for kk,vv in pairs(v.targets) do
		
			local node = self.rootnode
			for w in kk:gmatch("[%w]+") do
				if node.children[w] then
					node = node.children[w]
				else
					node = node:AddChild(MixNode(w))
				end
			end
			v.target_nodes[k] = node
		end
	end
end

function Mixer:Update(dt)
	if self.snapshot then
		local total_t = self.mixstack[#self.mixstack].pushtime
	end

	if self.currentmix then
		self.currentmix:Apply()
	end

end

function Mixer:PopMix()
	self:Snapshot()
	self.t = 0	
end

function Mixer:SetMix(name)
	self:Snapshot()
	local mix = self.mixes[name]
	self.mixstack = {mix}
end

function Mixer:PushMix(name)
	self:Snapshot()
	local mix = self.mixes[name]
	table.insert(self.mixstack, mix)
	self.t = 0
end
