local server = require('server')
local socket = require('socket')

function love.load()
	server_load()
end

local tick_time = 1 / 30
local last_tick = socket.gettime()
local gDt = 0
function love.update()	
	while socket.gettime() - last_tick < tick_time do
		updateserver(gServer)
	end	
	local this_tick = socket.gettime()	
	gDt = this_tick - last_tick
	last_tick = this_tick
	server_update(tick_time)
end

function love.draw()
	local x = 500
	local y = 50
	local y_delta = 15
	love.graphics.print("Tick: "..tick_time, x, y)
	y = y + y_delta
	love.graphics.print("Dt: "..gDt, x, y)
	y = y + y_delta
end

