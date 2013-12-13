require("util/strict")
require("constants")
require("util/util")
require("util/vector2")
require("util/mathutil")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
require("network")
require("input")
require("explosion")
require("gamestate")
require("soundsystem")
TUNING = require("tuning")

gClient = nil

local gRemoteWorldView = nil
local gRemoteView = nil
local gRemoteID = "0"

gRenderDt = 0
explosions = {}

local lastMouse = Vector2(0,0)

function sendinput(client)
	local input = defaultinput()
	local pkg = beginpack()
	for k,v in pairs(input) do
		if love.keyboard.isDown(k) then
			pkg = pack(pkg, k, 1)
		end
	end
	
	local mouse = Vector2(love.mouse.getX(), love.mouse.getY())
	if (lastMouse - mouse):Length() > 2.0 then
		pkg = pack(pkg, 'm_x', love.mouse.getX() - Renderer.offset_x)
		pkg = pack(pkg, 'm_y', love.mouse.getY() - Renderer.offset_y)
	end
	lastMouse = mouse

	if love.mouse.isDown("r") then
		pkg = pack(pkg, 'm_r', 1)
	end
	if love.mouse.isDown("l") then
		pkg = pack(pkg, 'm_l', 1)
	end

	pkg = pack(pkg, 'cid', gRemoteID)

	pkg = endpack(pkg)
	send(client, pkg, 'input')
end

gLocalSoundScale = 1.0
gRemoteSoundScale = 0.4

gQueuedFrames = 0
gClientState = 'ok'
gShipSounds = {}
function client_draw()
	local start_time = socket.gettime()

	local id_message = nextmessage(gClient, 'ID')
	if id_message then
		gRemoteID = id_message
	end
	
	updateclient(gClient)		

	local world_view_message = nextmessage(gClient, 'world_view')
	if world_view_message then
		gRemoteWorldView = unpack(1, world_view_message)
	end
	
	local message_count = messagecount(gClient, 'view')
	gQueuedFrames = message_count - 1
	if message_count == 0 then
		gClientState = 'ahead'
	elseif message_count > 4 then
		gClientState = 'behind'
	end

	if gClientState ~= 'ok' then
		print('Client State: '..gClientState )
	end

	local target_queue = 3
	if gClientState == 'ahead' then
		if message_count > target_queue - 1 then 
			gClientState = 'ok'
		end
	elseif gClientState == 'behind' then
		while message_count > target_queue do		
			nextmessage(gClient, 'view')
			message_count = messagecount(gClient, 'view')
		end
		gClientState = 'ok'
	end	

	if gClientState == 'ok' then
		local message = nextmessage(gClient, 'view')
		if message then
			gRemoteView = unpack(1, message)
			
			for k,ship in pairs(gRemoteView.ships) do
				local sound_scale = k == gRemoteID and gLocalSoundScale or gRemoteSoundScale
				if ship.se_sht then
					SOUNDS:PlaySound("sfx.ingame.ship.shoot", sound_scale)
				end
			end
		end
	end
	
	if gRemoteView and gRemoteWorldView then
		Renderer:Draw(function()	

			for k,ptcl in pairs(gRemoteView.ptcl) do
				local makeNew = true
				for k,v in pairs(explosions) do
					if v.parent == ptcl.p then
						makeNew = false
					end
				end
				if makeNew then
					local data = 
					{
						position = Vector2(ptcl.x, ptcl.y),
						team = ptcl.t,
						parent = ptcl.p,
						particle_type = ptcl.typ,
					}
					Explosion(data)
					if ptcl.typ == 1 then
						SOUNDS:PlaySound("sfx.ingame.explosions.ship", 1.0)
					else
						SOUNDS:PlaySound("sfx.ingame.explosions.missile", 1.0)
					end
				end
			end	

			local forcefield_scale = (math.sin(socket.gettime()*5) + 1) / 2
			local arena = gRemoteWorldView.arena
			love.graphics.setColor(155 + 100*forcefield_scale,0,0,255)
			local thickness = 5
			love.graphics.rectangle("fill", -thickness, -thickness, thickness, arena.h + thickness*2)
			love.graphics.rectangle("fill", -thickness, -thickness, arena.w + thickness*2, thickness)
			love.graphics.rectangle("fill", -thickness, arena.h, arena.w + thickness*2, thickness)
			love.graphics.rectangle("fill", arena.w, -thickness, thickness, arena.h + thickness*2)

			for k,goal in pairs(gRemoteWorldView.goals) do
				if goal.t == 0 then
					love.graphics.setColor(5,55,15,255)
					love.graphics.rectangle("fill",
										goal.x-goal.w/2,
										goal.y-goal.h/2,
										goal.w,
										goal.h)
					love.graphics.setColor(55,255,155,255)
					love.graphics.rectangle("line",
										goal.x-goal.w/2,
										goal.y-goal.h/2,
										goal.w,
										goal.h)
				else
					love.graphics.setColor(15,5,55,255)
					love.graphics.rectangle("fill",
										goal.x-goal.w/2,
										goal.y-goal.h/2,
										goal.w,
										goal.h)
					love.graphics.setColor(155,55,255,255)
					love.graphics.rectangle("line",
										goal.x-goal.w/2,
										goal.y-goal.h/2,
										goal.w,
										goal.h)
				end
			end

			for k,payload in pairs(gRemoteView.plds) do

				love.graphics.setColor(0,0,100 + 155 * forcefield_scale,255)
				love.graphics.circle("fill", payload.x, payload.y, PAYLOAD_SIZE.rad, PAYLOAD_SIZE.segs )
				if payload.t == 0 then
					love.graphics.setColor(95,255,195,255)
				elseif payload.t == 1 then
					love.graphics.setColor(195,95,255,255)
				else
					love.graphics.setColor(255,255,255,255)
				end
				love.graphics.circle("fill", payload.x, payload.y, PAYLOAD_SIZE.rad - 3, PAYLOAD_SIZE.segs )				
				
				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for k,v in pairs(payload.l) do
					love.graphics.line(payload.x, payload.y, v.x, v.y)
				end
				love.graphics.setLineWidth(prevWidth)
			end

			for k,snd in pairs( gShipSounds ) do
				if not gRemoteView.ships[k] or not gRemoteView.ships[k].se_bst then
					snd:Stop()
					gShipSounds[k] = nil
				end 
			end
			for k,ship in pairs(gRemoteView.ships) do

				local sound_scale = k == gRemoteID and gLocalSoundScale or gRemoteSoundScale
				if ship.se_bst and not gShipSounds[k] then
					local snd = SOUNDS:PlaySound("sfx.ingame.ship.thrust", 0.3 )
					if snd then
						gShipSounds[k] = snd
					end
				end

				--team color
				if ship.t == 0 then
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end
				
				-- the ship
				DrawTriangle(10, 6, ship.x, ship.y, ship.a)

				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for k,v in pairs(ship.l) do
					love.graphics.line(ship.x, ship.y, v.x, v.y)
				end
				love.graphics.setLineWidth(prevWidth)

				-- shield
				if ship.h > 0 then
					love.graphics.setColor(ship.h*255,ship.h*255,255,255)
				else
					love.graphics.setColor(255,0,0,255)
				end

				if k == gRemoteID then
					love.graphics.setLineWidth(2)
				end
				love.graphics.circle("line", ship.x, ship.y, ship.r, 6)
				love.graphics.setLineWidth(prevWidth)
				
				-- thrusters
				if ship.it == 1 then -- TODO: detect whether or not a ship is thrusting!
					local flameLen = math.random()*0.8+0.2
					love.graphics.setColor(255,190,100,255)
					DrawTriangle(30*flameLen, 6, ship.x, ship.y, ship.a-math.pi, 15*flameLen+5, 0)
					love.graphics.setColor(255,255,255,255)
					DrawTriangle(20*flameLen, 4, ship.x, ship.y, ship.a-math.pi, 10*flameLen+5, 0)
				end

				if k == gRemoteID and not gSpectatorMode then
					Renderer:SetCameraPos(ship.x, ship.y)
				elseif gSpectatorMode then
					Renderer:SetCameraPos(arena.w / 2, arena.h/2)
				end
			end

			for k,bullet in pairs(gRemoteView.blts) do
				if bullet.t == 0 then
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end
				DrawRectangle(5,2,bullet.x, bullet.y, bullet.a)
				local flameLen = math.random()*0.7+0.2
				love.graphics.setColor(255,190,100,255)
				DrawTriangle(15*flameLen, 3, bullet.x, bullet.y, bullet.a-math.pi, 7.2*flameLen+5, 0)
				love.graphics.setColor(255,255,255,255)
				DrawTriangle(10*flameLen, 2, bullet.x, bullet.y, bullet.a-math.pi, 5*flameLen+5, 0)				
			end

			for k,expl in pairs(explosions) do
				if expl.team == 0 then
					love.graphics.setColor(55,255,155,expl.alpha)
				else
					love.graphics.setColor(155,55,255,expl.alpha)
				end

				for k,v in pairs(expl.particles) do
					love.graphics.rectangle("fill", v.position.x, v.position.y, expl.size, expl.size)
				end
			end

			
			for k,obstacle in pairs(gRemoteWorldView.obs) do
				love.graphics.setColor(155 + 100*forcefield_scale,0,0,255)
				love.graphics.circle("fill", obstacle.x, obstacle.y, obstacle.r)
			end

			for k,obstacle in pairs(gRemoteWorldView.obs) do
				love.graphics.setColor(155,155,155,255)
				love.graphics.circle("fill", obstacle.x, obstacle.y, obstacle.r-5)
			end			
		end,
		
		function()
			if gRemoteView.game then
				if gRemoteView.game.f == FLOW.WARMUP then
					love.graphics.setFont(Fonts.header.font)
					love.graphics.setColor(0,0,0,255)
					love.graphics.print("WARMUP MODE", Renderer.offset_x-150+1, Renderer.offset_y-90+1)
					love.graphics.setColor(255,255,255,255)
					love.graphics.print("WARMUP MODE", Renderer.offset_x-150, Renderer.offset_y-90)

					love.graphics.setColor(0,0,0,255)
					love.graphics.print(gRemoteView.game.t, Renderer.offset_x-40+1, Renderer.offset_y+40+1)
					love.graphics.setColor(255,255,255,255)
					love.graphics.print(gRemoteView.game.t, Renderer.offset_x-40, Renderer.offset_y+40)
				elseif gRemoteView.game.f == FLOW.WIN_0 then
					love.graphics.setFont(Fonts.title.font)
					love.graphics.setColor(0,0,0,255)
					love.graphics.print("TEAL WINS!!", Renderer.offset_x-200+1, Renderer.offset_y-90+1)
					love.graphics.setColor(55,255,155,255)
					love.graphics.print("TEAL WINS!!", Renderer.offset_x-200, Renderer.offset_y-90)
				elseif gRemoteView.game.f == FLOW.WIN_1 then
					love.graphics.setFont(Fonts.title.font)
					love.graphics.setColor(0,0,0,255)
					love.graphics.print("PURPLE WINS!!", Renderer.offset_x-250+1, Renderer.offset_y-90+1)
					love.graphics.setColor(155,55,255,255)
					love.graphics.print("PURPLE WINS!!", Renderer.offset_x-250, Renderer.offset_y-90)
				end

				local instructions = {
									"Instructions:",
									"W, LMB = Thrust",
									"Space, RMB = Shoot",
									"A,D,Mouse = Aim",
									"F = Attach!!",
									"L Shift = Boost!"
								}
				local instructionstring = table.concat(instructions,"          ")

				love.graphics.setFont(Fonts.info.font)
				love.graphics.setColor(0,0,0,255)
				love.graphics.print(instructionstring, 30+1, love.graphics.getHeight() - 30+1)
				love.graphics.setColor(255,255,255,255)
				love.graphics.print(instructionstring, 30, love.graphics.getHeight() - 30)

			end
			
		end)
	end

	gRenderDt = socket.gettime() - start_time

	
	local remote_frame_id = 0
	if gRemoteView then
		remote_frame_id = gRemoteView.frame_id
	end
end

function client_load()
	gClient = startclient(getip(), getport())
	Renderer:Load()	
	global("SOUNDS")
	SOUNDS = SoundSystem()
	SOUNDS.mixer:LoadDefs("mixes")
	SOUNDS:LoadBank( "mainbank" )
end

local playing_music = false
function client_update(dt)
	if not playing_music then
		SOUNDS:PlaySound("music.game", 0.3)
		playing_music = true
	end
	sendinput(gClient)
	updateclient(gClient)	
	for k,expl in pairs(explosions) do
		expl:Update(dt)
	end

	SOUNDS.mixer:SetMix("normal")
	SOUNDS:Update(dt)
	SOUNDS.mixer:Update(dt)
	--print("musicVol",SOUNDS.musicnode.network_volume)
end


gShowProfiling = false
gSpectatorMode = false
function love.keypressed(key)
	if key == 'f2' then
		gShowProfiling = not gShowProfiling
	end
	if key == 'f10' then
		gSpectatorMode = not gSpectatorMode
		if gSpectatorMode then
			Renderer:ZoomOut()
		else
			Renderer:ZoomIn()
		end
	end
end

