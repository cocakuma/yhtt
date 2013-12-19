local network = require('network')
local client = require('client')
local controls = require('controls')
local socket = require 'socket'
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
	for i=1,16 do
		gClients[i] = {}
		gClients[i].id = 0
		gClients[i].client = startclient(getip(), getport())
	end
end

local last_tick = socket.gettime()
function love.update(dt)
	while socket.gettime() - last_tick < 1 / 30 do
		for i,v in pairs(gClients) do
			updateclient(v.client)
		end
	end 
	last_tick = socket.gettime()	
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