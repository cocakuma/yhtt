require("util/strict")
require("constants")
require("util/util")
require("util/mathutil")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
require("network")
require("server")
require("client")
TUNING = require("tuning")


function load()
	server_load()	
	gClient = startclient(getip(), getport())

	Renderer:Load()
end

function update( dt)
	
	if paused then
		return
	end

	sendinput(gClient)
	updateserver(gServer)
	updateclient(gClient)	
	
	server_update(dt)	
end
