local network = require('network')

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
	for i,client in pairs(gClients) do
		sendinput(client)
		updateclient(client)
		clearmessages(client)
	end	
end