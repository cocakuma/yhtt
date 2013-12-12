local network = require('../../../Game/Scripts/network')

local gClients = {}

function defaultinput()
	local keys = { 'd', 'a', 'w', ' ', 'f' }
	local input = {}
	for i,k in pairs(keys) do
		input[k] = false
	end	
	return input
end

function sendinput(client)
	local input = defaultinput()
	local pkg = beginpack()

	for k,v in pairs(input) do		
		pkg = pack(pkg, k, 0)
	end
	pkg = endpack(pkg)
	send(client, pkg, 'input')
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