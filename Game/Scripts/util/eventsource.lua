require "eventhandle"

class("EventSource")

function EventSource:init()
	self.listeners = {}
end

function EventSource:ListenForEvent(event, fn, ...)
	local handle = EventHandle(self, event, fn, ...)

	if not self.listeners[event] then
		self.listeners[event] = {}
	end

	table.insert(self.listeners[event], handle)
end

function EventSource:PostEvent(event, ...)
	if self.listeners[event] then
		for k,v in ipairs(self.listeners[event]) do
			if v.fn( unpack(v.args), ...) then
				return true-- 'twas consumed!
			end
		end
	end
end

