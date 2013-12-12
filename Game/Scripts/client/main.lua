require 'client'
require 'socket'

function love.load()
	client_load()
end

function love.update(dt)
	client_update(dt)
end

local last_tick = socket.gettime()
function love.draw()
	local tick_time = 1 / 30
	while socket.gettime() - last_tick < tick_time do	
		updateclient(gClient)		
	end
	last_tick = socket.gettime()
	client_draw()
end
