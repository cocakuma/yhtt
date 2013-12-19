local network = require('network')
local client = require('client')
local controls = require('controls')
local gClients = {}

function sendaiinput(client)
	local pkg = beginpack()
		pkg = pack(pkg, controls.Shoot.Id, 1)

	pkg = pack(pkg, 'cid', client.id)
	pkg = pack(pkg, 'usr', 'AI')

	pkg = endpack(pkg)
	send(client.client, pkg, 'input')
end

function love.load()
	for i=1,32 do
		gClients[i] = {}
		gClients[i].id = 0
		gClients[i].client = startclient(getip(), getport())
	end
end

function love.update( dt)
	for i,v in pairs(gClients) do
		sendaiinput(v)
		updateclient(v.client)
		local message = nextmessage(v.client, 'ID')
		if message then
			v.id = message
		end
		clearmessages(v.client)
	end
end