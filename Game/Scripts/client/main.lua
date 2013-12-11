local network = require('../../../Game/Scripts/network')
local gClient = nil

function love.load()	
	gClient = startclient()
end

function love.update(dt)
	updateclient(gClient)
	send(gClient, 'Test!')
end

function love.draw()

end
