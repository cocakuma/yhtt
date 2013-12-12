local network = require('../../../Game/Scripts/network')
local gServer = nil

function love.load()	
	gServer = startserver()
end

function receiveinput(client)
	local message = nextmessage(client)
	while message do
		local fun, err = loadstring(message)		
		if err then 
			print(error)
			assert()
		end
		local input = fun()
		message = nextmessage(client)
	end	
end

function love.update(dt)
	updateserver(gServer)
	for i,client in pairs(gServer.clients) do
		receiveinput(client)
		--send(client, 'WTF!')
	end
end

function love.draw()

end
