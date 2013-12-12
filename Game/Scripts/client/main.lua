require 'client'

function love.load()
	client_load()
end

function love.update(dt)
	client_update(dt)
end

function love.draw()
	client_draw()
end
