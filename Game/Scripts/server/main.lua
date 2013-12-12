local server = require('server')

function love.load()
	server_load()

	while 1 do 
		server_update()
	end	
end
