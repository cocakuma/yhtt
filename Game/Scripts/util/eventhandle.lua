class("EventHandle")

function EventHandle:init(source, event, fn, ...)
	self.source = source
	self.event = event
	self.fn = fn
	self.args = {...}
end

function EventHandle:Cancel()
	if self.source.listeners[self.event] then
		for k,v in ipairs(self.source.listeners[self.event]) do
			if v == self then
				table.remove(self.source.listeners[self.event], k)
				return
			end
		end
	end
end
