local coroutine = require('coroutine')
local client = nil

function runclient()
	local settings = require("../../../settings")
	local socket=require ("socket")
	print('Connecting to '..settings.server_ip..':'..settings.server_port)
	local conn = assert(socket.connect(settings.server_ip, settings.server_port))
	print('Connected!')	
	while 1 do
		coroutine.yield()
	end
end

function love.load()	
	client = coroutine.create(runclient)
end

function love.update(dt)
	coroutine.resume(client)
end

function love.draw()

end
