local network = require('network')
local client = require('client')

local gClients = {}

function defaultinput(useMouse)
	local keys = { 'd', 'a', 'w', ' ', 'f' }
	if useMouse then
		keys = {' ', 'f'}
	end
	local input = {}
	for i,k in pairs(keys) do
		input[k] = false
	end	
	return input
end

function love.load()
	for i=1,32 do
		gClients[i] = startclient(getip(), getport())
	end
end

function love.update( dt)
	for i,v in pairs(gClients) do
		sendinput(v)
		updateclient(v)
		clearmessages(v)
	end	
end