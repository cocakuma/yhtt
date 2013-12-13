local network = require('network')
local client = require('client')

local gClients = {}

function sendaiinput(client)
	local input = defaultinput()

	local pkg = beginpack()
	pkg = pack(pkg, ' ', 1)

	pkg = pack(pkg, 'cid', 2)

	pkg = endpack(pkg)
	send(client, pkg, 'input')
end

function love.load()
	for i=1,32 do
		gClients[i] = startclient(getip(), getport())
	end
end

function love.update( dt)
	for i,v in pairs(gClients) do
		sendaiinput(v)
		updateclient(v)
		clearmessages(v)
	end	
end