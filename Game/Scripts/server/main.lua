local server = require('server')

function love.load()
	server_load()
	while 1 do 
		local tick_time = 1 / 30
		local start_time = socket.gettime()
		server_update(tick_time)
		while socket.gettime() - start_time < tick_time do
		end
	end	
end
