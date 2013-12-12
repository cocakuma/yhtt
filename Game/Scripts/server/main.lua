local network = require('../../../Game/Scripts/network')
local gServer = nil

function love.load()	
	gServer = startserver()
end

function receiveinput(client)
	for k,message in pairs(client.in_messages) do
		local fun, err = loadstring(message)		
		if err then 
			print(error)
			assert()
		end
		local input = fun()
		for k,v in pairs(input) do
			if v then
				print(k)
			end
		end
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
