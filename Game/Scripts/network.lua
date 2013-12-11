local gMessageStart = ':>>\n' 
local gMessageEnd = '<<:\n' 

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
	client.messages = {}
	return client
end

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

function send(node, text)
	message = 
	{ 
		bytes_sent = 0,
		text = gMessageStart..text..gMessageEnd
	}
	table.insert(node.messages, message)
end