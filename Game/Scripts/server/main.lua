local server = require('server')
local game = require('game')

function love.load()
	server_load()

	while 1 do 
		server_update()
	end	
end
