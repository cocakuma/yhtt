local network = require('../../../Game/Scripts/network')

local gServer = nil

function updateserverinternal(server)
	local coroutine = require('coroutine')
	while 1 do
		local client_conn = server.conn:accept()
		if client_conn then
			local client_ip, client_port = client_conn:getpeername()
			print('New connection '..client_ip..':'..client_port..'.')
			table.insert(server.clients, client_conn)
		end
		coroutine.yield()
	end
end

function startserver()
	local coroutine = require('coroutine')
	local server = {}
	local settings = require('../../../settings')
	local socket=require ('socket')
	local conn = assert(socket.bind(settings.server_ip, settings.server_port))
	local ip, port = conn:getsockname()
	print('Listening for connections at '..ip..':'..port..'.')
	conn:settimeout(0)
	server.conn = conn
	server.clients = {}	
	server.co = coroutine.create(function() updateserverinternal(server) end)
	return server
end


function updateserver(server)
	coroutine.resume(server.co)
end

function love.load()	
	gServer = startserver()
end

function love.update(dt)
	updateserver(gServer)
end

function love.draw()

end
