local network = require('../../../Game/Scripts/network')
local serpent = require('../../../Game/Scripts/util/serpent')
local gClient = nil

function love.load()	
	gClient = startclient()
end

function sendinput(client)
	local keys = { 'd', 'a', 'w', ' ', 'f' }
	input = {}
	for i,k in pairs(keys) do
		local down = love.keyboard.isDown(k)
		if down then
			print(k)
		end
		input[k] = down
	end
	send(gClient, serpent.dump(input))
end

function love.update(dt)
	sendinput(gClient)
	updateclient(gClient)
	--send(gClient, 'Test!')
end

function love.draw()

end