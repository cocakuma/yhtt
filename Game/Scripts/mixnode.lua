local MixNode = class("MixNode")

function MixNode:init(name)
	self.name = name
	self.fullname = name
	self.children = {}
	self.volume = 1
	self.network_volume = 1
end

function MixNode:GetNetworkString(str, level)
	local root = str == nil
	level = level or 0
	str = str or {}

	table.insert(str, string.format("%s%s", string.rep("  ", level),tostring(self)))
	for k,v in pairs(self.children) do
		v:GetNetworkString(str, level + 1)
	end

	if root then
		return table.concat(str, "\n")
	end
 end

function MixNode:__tostring()
	return string.format("%s - %2.2f (%2.2f)", self.name, self.volume, self.network_volume)
end

function MixNode:CollectSnapshot(t)
	if self.volume ~= 1.0 then
		t[self.fullname] = self.volume
	end
	for k,v in pairs(self.children) do
		v:CollectSnapshot(t)
	end

end

function MixNode:SetFullName()
	if self.parent then	
		self.fullname = self.parent.fullname .. "." .. self.name
	else
		self.fullname = self.name
	end

	for k, v in pairs(self.children) do
		v:SetFullName()
	end

end


function MixNode:AddChild(child)
	self.children[child.name] = child
	child.parent = self
	child:SetFullName()
	return child
end

function MixNode:SetVol(v)
	self.volume = v
end

function MixNode:Update()
	self.network_volume = self.parent and (self.parent.network_volume * self.volume) or self.volume
	for k,v in pairs(self.children) do
		v:Update()
	end
end

