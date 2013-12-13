local server = require('server')
local socket = require('socket')

function love.load()
	server_load()
end

local tick_time = 1 / 30
local last_tick = socket.gettime()
local gDt = 0
local gUpdate = 0
function love.update()	
	while socket.gettime() - last_tick < tick_time do
		updateserver(gServer)
	end	
	local this_tick = socket.gettime()	
	gDt = this_tick - last_tick
	last_tick = this_tick
	local sim_start = this_tick
	server_update(tick_time)
	gUpdate = socket.gettime() - sim_start
end

function love.draw()
	local x = 500
	local y = 50
	local y_delta = 20
	love.graphics.print("Tick: "..round3(tick_time), x, y)
	y = y + y_delta
	love.graphics.print("Dt: "..round3(gDt), x, y)
	y = y + y_delta
	love.graphics.print("Update: "..round3(gUpdate), x, y)
	y = y + y_delta	
	love.graphics.print("Package: "..round3(gPackageDT), x, y)
	y = y + y_delta		
end

