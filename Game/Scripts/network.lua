local gMessageStart = ':>>\n' 
local gMessageEnd = '<<:\n' 

function updateclientinternal(client)
	local coroutine = require('coroutine')
	while 1 do
		local message = client.messages[#client.messages]
		if message then
			message.sent = message.sent + client.conn:send(message.text)
			if message.sent == string.len(message.text) then
				print('SEND SUCCESSFUL!')
			else
				print('SEND IN PROGRESS!')
				coroutine.yield()
			end
		else
			coroutine.yield()
		end
	end	
end

function updateclient(client)
	v,e = coroutine.resume(client.co)
	if not v then
		print(e)
		assert()
	end
end

function startclient()
	local client = {}
	local settings = require("../../../settings")
	local socket=require ("socket")
	print('Connecting to '..settings.server_ip..':'..settings.server_port)
	local conn = assert(socket.connect(settings.server_ip, settings.server_port))
	conn:settimeout(0)
	print('Connected!')		
	client.conn = conn
	client.messages = {}
	client.co = coroutine.create(function() updateclientinternal(client) end)
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

function updateserver(server)
	v,e = coroutine.resume(server.co)
	if not v then
		print(e)
		assert()
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
		sent = 0,
		text = gMessageStart..text..gMessageEnd
	}
	node.messages[#node.messages+1] = message
end