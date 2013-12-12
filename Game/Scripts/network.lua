local gMessageStart = ':>>'
local gMessageEnd = '<<:' 
local gMessageTypeDelim = '|' 

function sendmessages(node)
	local message = node.out_messages[#node.out_messages]
	if message then
		local sent, err, b = node.conn:send(message.text, message.sent + 1)
		if sent == nil then
			sent = b
			print(err)
		end
		message.sent = message.sent + sent
		if message.sent == string.len(message.text) then
			table.remove(node.out_messages, #node.out_messages)
			sendmessages(node)
		end
	end
end

function receivemessages(node)
	local a,b,text = node.conn:receive('*a')
	if text then
		node.receive_buffer = node.receive_buffer..text
		local end_delim = string.find( node.receive_buffer, gMessageEnd)
		while end_delim do
			local type_delim = string.find(node.receive_buffer, gMessageTypeDelim)
			local t = string.sub(node.receive_buffer, string.len(gMessageStart)+1, type_delim - 1)
			local message = string.sub(node.receive_buffer, type_delim + 1, end_delim - 1)
			local message_queue = node.in_messages[t]
			if message_queue == nil then
				node.in_messages[t] = {}
				message_queue = node.in_messages[t]
			end
			message_queue[#message_queue+1] = message
			node.receive_buffer = string.sub(node.receive_buffer, end_delim + string.len(gMessageEnd))
			end_delim = string.find( node.receive_buffer, gMessageEnd)
		end
	end
end

function updateclientinternal(client)
	local coroutine = require('coroutine')
	while 1 do
		sendmessages(client)
		receivemessages(client)
		coroutine.yield()
	end	
end

function updateclient(client)
	local v,e = coroutine.resume(client.co)
	if not v then
		print(e)
		assert()
	end
end

function createnode(conn)
	local node = {}
	node.in_messages = {}
	node.out_messages = {}
	node.receive_buffer = ""
	node.conn = conn
	return node
end

function startclient(ip, port)
	local client = {}
	local socket=require ("socket")
	print('Connecting to '..ip..':'..port)
	local conn = nil
	while nil == conn do
		conn = socket.connect(ip, port)
	end
	conn:settimeout(0)
	conn:setoption('keepalive', true)
	print('Connected!')		
	local client = createnode(conn)
	client.co = coroutine.create(function() updateclientinternal(client) end)	
	return client
end

function updateserverinternal(server)
	local coroutine = require('coroutine')
	while 1 do
		local client_conn = server.conn:accept()
		if client_conn then
			client_conn:settimeout(0)
			client_conn:setoption('keepalive', true)
			local client_ip, client_port = client_conn:getpeername()
			print('New connection '..client_ip..':'..client_port..'.')			
			table.insert(server.clients, createnode(client_conn))
		end

		for i,client in pairs(server.clients) do
			if client.error then
				print('Connection lost: '..client.error)
				server.clients[i] = nil
			end
			sendmessages(client)
			receivemessages(client)
		end

		coroutine.yield()
	end
end

function updateserver(server)
	local v,e = coroutine.resume(server.co)
	if not v then
		print(e)
		assert()
	end
end

function startserver(port)
	local coroutine = require('coroutine')
	local server = {}
	local socket=require ('socket')
	local conn = assert(socket.bind('*', port))
	local ip, port = conn:getsockname()
	print('Listening for connections at '..ip..':'..port..'.')
	conn:settimeout(0)
	server.conn = conn
	server.clients = {}	
	server.co = coroutine.create(function() updateserverinternal(server) end)
	return server
end

function send(node, text, type)
	local message = 
	{ 
		sent = 0,
		text = gMessageStart..type..gMessageTypeDelim..text..gMessageEnd
	}
	table.insert(node.out_messages, 1, message)	
end

function unpack(index, str)
	local t = {}
	local token_start = index + 1
	local key = ""	
	local i = index + 1
	while i <= #str do
		local s = str:sub(i,i)
		if s == '{' then
			t[key], i = unpack(i, str)
			token_start = i + 1
		elseif s == '=' then
			key=string.sub(str, token_start, i - 1)	
			token_start = i + 1
		elseif s == ',' then
			local val = tonumber(string.sub(str, token_start, i - 1))
			t[key] = val
			token_start = i + 1
		elseif s == '}' then
			return t, i + 1
		end
		i = i + 1
	end
	return t
end

function clearmessages(node)
	for k,v in pairs(node.in_messages) do
		node.in_messages[k] = {}
	end
end

function nextmessage(node, t)
	local message = nil
	local remaining = 0
	local message_queue = node.in_messages[t]	
	if message_queue then
		message = message_queue[1]
		if message then				
			table.remove(message_queue, 1)
			remaining = table.getn(message_queue)
		end
	end
	return message, remaining
end

function beginpack()
	return '{'
end

function endpack(package)
	return package..'},'
end

function beginpacktable(package, key)
	return package..tostring(key)..'={'
end

function endpacktable(package)
	return package..'},'
end

function pack(package, key, value)
	return package..tostring(key)..'='..tostring(value)..','
end

function getip()
	local ip = '127.0.0.1'
	for k,v in pairs(arg) do
		if string.len(v) > 3 and string.sub(v,1,3) == 'ip=' then
			ip = string.sub(v,4)
		end
	end
	return ip
end

function getport()
	return '7500'
end
