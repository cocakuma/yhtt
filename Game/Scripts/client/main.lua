local socket=require ("socket")
local settings = require("../../../settings")
local conn = nil

function love.load()
	print('Connecting to '..settings.server_ip..':'..settings.server_port)
	conn = assert(socket.connect(settings.server_ip, settings.server_port))
	print('Connected!')	
end

function love.update(dt)

end

function love.draw()

end
