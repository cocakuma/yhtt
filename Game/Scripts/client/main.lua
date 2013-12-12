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
		input[k] = down
	end
	local dmp = serpent.dump(input)
	send(gClient, serpent.dump(input), 'test')
end

function love.update(dt)
	sendinput(gClient)
	updateclient(gClient)
	--send(gClient, 'Test!')
end

function love.draw()

end