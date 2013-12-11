class("Heap")

function Heap:init(fn)
	self.fn = fn or function(a,b) return a > b end
	self.nodes = {}
end

function Heap:push(val)
	local idx = #self.nodes + 1
	self.nodes[idx] = val
	while true do
		local parent_idx = math.floor(idx / 2)
		if parent_idx > 0 and parent_idx ~= idx and not self.fn(self.nodes[parent_idx], self.nodes[idx]) then
			self.nodes[idx], self.nodes[parent_idx] = self.nodes[parent_idx], self.nodes[idx]
			idx = parent_idx
		else
			break
		end
	end
end

function Heap:size()
	return #self.nodes
end

function Heap:isempty()
	return #self.nodes == 0
end

function Heap:__tostring()

	local t = {}

	for k, v in ipairs(self.nodes) do
		table.insert(t, '\t'..tostring(v))
	end

	return table.concat(t,'\n')
end

function Heap:peek()
	return self.nodes[1]
end

function Heap:pop()
	if #self.nodes == 0 then
		return nil
	elseif #self.nodes == 1 then
		local ret = self.nodes[1]
		self.nodes[1] = nil
		return ret
	else
		local ret = self.nodes[1]
		self.nodes[1] = self.nodes[#self.nodes]
		self.nodes[#self.nodes] = nil
		local idx = 1
		while idx < #self.nodes do

			local val = self.nodes[idx]
			local left = idx*2 <= #self.nodes and self.nodes[idx*2]
			local right = idx*2+1 <= #self.nodes and self.nodes[idx*2+1]

			if left and not self.fn(val, left) and not (right and self.fn(right, left)) then
				self.nodes[idx], self.nodes[idx*2] = self.nodes[idx*2], self.nodes[idx]
				idx = idx*2
			elseif right and not self.fn(val, right) then
				self.nodes[idx], self.nodes[idx*2+1] = self.nodes[idx*2+1], self.nodes[idx]
				idx = idx*2+1
			else
				break
			end
		end
		return ret
	end
end
