local network = require('../../../Game/Scripts/network')
local gServer = nil

function love.load()	
	gServer = startserver()
end

function love.update(dt)
	updateserver(gServer)
end

function love.draw()

end
