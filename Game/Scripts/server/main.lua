local socket=require ("socket")
local settings = require("../../../settings")
local conn = nil
local clients = {}

function love.load()
	
	conn = assert(socket.bind(settings.server_ip, settings.server_port))
	local ip, port = conn:getsockname()
	print('Listening for connections at '..ip..':'..port..'.')
	while 1 do
		local client_conn = conn:accept()
		local client_ip, client_port = client_conn:getpeername()
		print('New connection '..client_ip..':'..client_port..'.')
		table.insert(clients, client_conn)
	end
end

function love.update(dt)

end

function love.draw()

end
