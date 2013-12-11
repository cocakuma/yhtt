local network = require('../../../Game/Scripts/network')
local gServer = nil

function love.load()	
	gServer = startserver()
end

function love.update(dt)
	updateserver(gServer)
	for i,client in pairs(gServer.clients) do
		--send(client, 'WTF!')
	end
end

function love.draw()

end
