require 'server'
require 'client'

function love.load()
	server_load()
	client_load()
end

function love.update(dt)
	client_update(dt)
	server_update(dt)
end

function love.draw()
	client_draw()
end

