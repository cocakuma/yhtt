local coroutine = require('coroutine')
local clients = {}
local server = nil

function runserver()
	local settings = require('../../../settings')
	local socket=require ('socket')
	local conn = assert(socket.bind(settings.server_ip, settings.server_port))
	local ip, port = conn:getsockname()
	print('Listening for connections at '..ip..':'..port..'.')
	conn:settimeout(0)
	while 1 do
		local client_conn = conn:accept()
		if cleint_conn then
			local client_ip, client_port = client_conn:getpeername()
			print('New connection '..client_ip..':'..client_port..'.')
			table.insert(clients, client_conn)
		else
			coroutine.yield()
		end
	end
end

function love.load()
	server = coroutine.create(runserver)
end

function love.update(dt)
	coroutine.resume(server)
end

function love.draw()

end
