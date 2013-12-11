local gClient = nil

function updateclientinternal()	
	local coroutine = require('coroutine')
	while 1 do
		coroutine.yield()
	end	
end

function updateclient(client)
	coroutine.resume(client.co)
end

function startclient()
	local client = {}
	local settings = require("../../../settings")
	local socket=require ("socket")
	print('Connecting to '..settings.server_ip..':'..settings.server_port)
	local conn = assert(socket.connect(settings.server_ip, settings.server_port))
	print('Connected!')		
	client.conn = conn
	client.co = coroutine.create(function() updateclientinternal(client) end)
	return client
end

function love.load()	
	gClient = startclient()
end

function love.update(dt)
	updateclient(gClient)
end

function love.draw()

end
