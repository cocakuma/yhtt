local game = require('game')
local server = require('server')

function love.load()
	server_load()

	while 1 do 
		update_server()
	end	
end
