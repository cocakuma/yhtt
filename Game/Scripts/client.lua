require("util/strict")
require("constants")
require("util/util")
require("util/vector2")
require("util/mathutil")
require("ship")
require("payload")
require("obstacle")
require("render")
require("network")
require("explosion")
require("gamestate")
require("soundsystem")

local controls = require('controls')
TUNING = require("tuning")

gClient = nil

local gRemoteWorldView = nil
local gRemoteView = nil
local gRemoteID = "0"

gRenderDt = 0
gInputId = 0
explosions = {}
gTimeScale = 1

local lastMouse = Vector2(0,0)

function sendinput(client)
 	gInputId = gInputId % ( love.joystick.getNumJoysticks() + 1 )
	
	local pkg = beginpack()
	if gInputId == 0 then	
		for k,action in pairs(controls) do
			if action.KeyboardKey and love.keyboard.isDown(action.KeyboardKey) then
				pkg = pack(pkg, action.Id, 1)
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
	else
		local x, y, n = love.joystick.getAxes( gInputId )
		local dist = Vector2(x,y)
		if dist:Length() > 0.5 then
			pkg = pack(pkg, 'm_x', x)
			pkg = pack(pkg, 'm_y', y)
		end

		for k,action in pairs(controls) do
			if action.GamepadButton and love.keyboard.isDown(action.GamepadButton) then
				pkg = pack(pkg, action.Id, 1)
			end
		end	
	end

	pkg = pack(pkg, 'cid', gRemoteID)
	pkg = pack(pkg, 'usr', gUser)

	pkg = endpack(pkg)
	send(client, pkg, 'input')
end

function lerp_position(a,b,l)
	if not b then
		return a.x,a.y
	else
		return lerp(a.x, b.x, l),  lerp(a.y, b.y, l)
	end
end

gLocalSoundScale = 1.0
gRemoteSoundScale = 0.4

gWarmupSong = nil
gGameSong = nil
gPlayCountdown = true
gQueuedFrames = 0
gClientState = 'ok'
gShipSounds = {}
gClientTime = 0
gFrameQueue = {}
function client_draw(dt)	
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
	
	local frame_message = nextmessage(gClient, 'view')
	while frame_message do
		gFrameQueue[#gFrameQueue + 1] = unpack(1, frame_message)
		frame_message = nextmessage(gClient, 'view')
	end

	local target_queued_frames = 3
	local target_latency = gTickTime * target_queued_frames
	local queued_frame_count = #gFrameQueue

	if gClientState == 'ok' then
		gClientTime = gClientTime + dt * gTimeScale
		
		if queued_frame_count == 0 or not gRemoteView or gClientTime >= gFrameQueue[#gFrameQueue].time then
			print('Client ahead!')
			gClientState = 'ahead'			
		elseif gFrameQueue[1].time > gClientTime + target_latency then
			print('Client behind!')
			gClientState = 'behind'			
		end
	else 
		if gClientState == 'ahead' then
			if queued_frame_count >= target_queued_frames then
				gClientState = 'ok'
				gClientTime = gFrameQueue[1].time
			end
		elseif gClientState == 'behind' then
			gClientState = 'ok'
			gClientTime = gFrameQueue[#gFrameQueue - target_queued_frames].time
		end
	end

	if gClientState == 'ok' then		
		while gClientTime >= gFrameQueue[1].time do
			local new_frame = gFrameQueue[1]
			if gRemoteView and gRemoteView.game then
				if gRemoteView.game.s0 < new_frame.game.s0 then
					SOUNDS:PlaySound("sfx.ingame.score_point", 2.0)
				end
				if gRemoteView.game.s1 < new_frame.game.s1 then
					SOUNDS:PlaySound("sfx.ingame.score_point", 2.0)					
				end
				
				for k,ship in pairs(new_frame.ships) do
					local sound_scale = k == gRemoteID and gLocalSoundScale or gRemoteSoundScale
					if ship.se_sht then
						SOUNDS:PlaySound("sfx.ingame.ship.shoot", sound_scale * 0.35)
					end
					if ship.se_atch then
						SOUNDS:PlaySound("sfx.ingame.ship.attach", sound_scale)
					end
					if ship.se_dtch then
						SOUNDS:PlaySound("sfx.ingame.ship.release", sound_scale)
					end	
				end
			end							
			gRemoteView = new_frame
			gTimeScale = gRemoteView.time_scale
			table.remove(gFrameQueue, 1)
		end
	end
	
	if gRemoteView and gRemoteWorldView then
		local blend = ( gClientTime - gRemoteView.time ) / ( gFrameQueue[1].time - gRemoteView.time )
		for k,ship in pairs(gRemoteView.ships) do
			local ship_x, ship_y = lerp_position( ship, gFrameQueue[1].ships[k], blend)
			if k == gRemoteID and not gSpectatorMode then
				Renderer:SetCameraPos(ship_x,ship_y)
			elseif gSpectatorMode then
				Renderer:SetCameraPos(arena.w / 2, arena.h/2)
			end
		end

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
						SOUNDS:PlaySound("sfx.ingame.explosions.ship", 0.3)
					else
						SOUNDS:PlaySound("sfx.ingame.explosions.missile", 0.3)
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

				local payload_x, payload_y = lerp_position(payload, gFrameQueue[1].plds[k], blend)

				love.graphics.setColor(255*(1-forcefield_scale),255*(1-forcefield_scale),255*forcefield_scale,255)
				love.graphics.circle("fill", payload_x, payload_y, PAYLOAD_SIZE.rad, PAYLOAD_SIZE.segs )

				if payload.t == 0 then
					love.graphics.setColor(55,255,155,255)
				elseif payload.t == 1 then
					love.graphics.setColor(195,95,255,255)
				else
					love.graphics.setColor(255,255,255,255)
				end
				love.graphics.circle("fill", payload_x, payload_y, PAYLOAD_SIZE.rad - 3, PAYLOAD_SIZE.segs )				
				
				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for i,v in pairs(payload.l) do	
					local end_x, end_y = v.x, v.y
					if gFrameQueue[1].plds[k] then
						end_x, end_y = lerp_position(v, gFrameQueue[1].plds[k].l[i], blend)
					end				
					love.graphics.line(payload_x, payload_y, end_x, end_y)
				end

				if payload.h < TUNING.PAYLOAD.HEALTH then
					local maxRad = PAYLOAD_SIZE.rad - 3
					local rad = maxRad
					if payload.ht >= TUNING.PAYLOAD.PULSE_COOLDOWN then
						rad = lerp(maxRad, 0, payload.h/TUNING.PAYLOAD.HEALTH)
					end
					love.graphics.setColor(255,0,0,255)

					love.graphics.circle("fill", payload_x, payload_y, rad, PAYLOAD_SIZE.segs)
				end

				love.graphics.setLineWidth(prevWidth)
			end

			for k,snd in pairs( gShipSounds ) do				
				if not gRemoteView.ships[k] or ( not gRemoteView.ships[k].se_bst and gRemoteView.ships[k].it == 0 ) then

					snd:Stop()
					gShipSounds[k] = nil
				end 
			end
			for k,ship in pairs(gRemoteView.ships) do

				local ship_x, ship_y = lerp_position( ship, gFrameQueue[1].ships[k], blend)
				local sound_scale = k == gRemoteID and gLocalSoundScale or gRemoteSoundScale
				if ( ship.it == 1 or ship.se_bst ) then
					local sound_scale = 0.15 * sound_scale
					if ship.se_bst then
						sound_scale = sound_scale * 4
					end
					if gShipSounds[k] then 
						gShipSounds[k]:SetVolumeScale(sound_scale)
					elseif k == gRemoteID then
						local snd = SOUNDS:PlaySound("sfx.ingame.ship.thrust", sound_scale )
						if snd then
						 	gShipSounds[k] = snd
						end						
					end
				end

				if ship.se_bsk == 1 then

					love.graphics.setColor(255,0,0,125)
					local time = ship.bt
					local a1 = lerp(0, math.pi * 2, time/2)
					local a2 = lerp(0, -math.pi * 3, time)
					local a3 = lerp(0, math.pi * 2, time*2)
					local sizeX = 20
					local sizeY = 20
					DrawTriangle(sizeX, sizeY, ship_x, ship_y, a1, nil, nil, "line")
					DrawTriangle(sizeX, sizeY, ship_x, ship_y, a2, nil, nil, "line")
					DrawTriangle(sizeX, sizeY, ship_x, ship_y, a3, nil, nil, "line")

				end

				--team color
				if ship.t == 0 then
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end

				-- the ship
				DrawTriangle(10, 6, ship_x, ship_y, ship.a)

				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for k,v in pairs(ship.l) do
					love.graphics.line(ship_x, ship_y, v.x, v.y)
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
				love.graphics.circle("line", ship_x, ship_y, ship.r, 6)
				love.graphics.setLineWidth(prevWidth)
				
				-- thrusters
				if ship.it == 1 then
					local flameLen = math.random()*0.8+0.2
					if ship.se_bst then
						flameLen  = flameLen * 2
						love.graphics.setColor(55,90,255,255)
						DrawTriangle(30*flameLen, 6, ship_x, ship_y, ship.a-math.pi, 15*flameLen+5, 0)
					else
						love.graphics.setColor(255,90,10,255)
						DrawTriangle(30*flameLen, 6, ship_x, ship_y, ship.a-math.pi, 15*flameLen+5, 0)

					end
					love.graphics.setColor(255,255,255,255)
					DrawTriangle(20*flameLen, 4, ship_x, ship_y, ship.a-math.pi, 10*flameLen+5, 0)
				end

				if ship.se_sld == 1 then
					if ship.t == 0 then
						love.graphics.setColor(55,255,155,100)
					else
						love.graphics.setColor(155,55,255,100)
					end
					love.graphics.circle("fill", ship_x, ship_y, ship.r + 3)
				end
			end

			for k,bullet in pairs(gRemoteView.blts) do
				local bullet_x, bullet_y = lerp_position(bullet, gRemoteView.blts[k], blend)
				if bullet.t == 0 then
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end
				DrawRectangle(5,2,bullet.x, bullet.y, bullet.a)
				local flameLen = math.random()*0.7+0.2
				love.graphics.setColor(255,190,100,255)
				DrawTriangle(15*flameLen, 3, bullet_x, bullet_y, bullet.a-math.pi, 7.2*flameLen+5, 0)
				love.graphics.setColor(255,255,255,255)
				DrawTriangle(10*flameLen, 2, bullet_x, bullet_y, bullet.a-math.pi, 5*flameLen+5, 0)	

				if bullet.tx then
					print("Draw Line")
					if bullet.t == 0 then
						love.graphics.setColor(55,255,155,255)
					else
						love.graphics.setColor(155,55,255,255)
					end
					love.graphics.line(bullet_x, bullet_y, bullet.tx, bullet.ty)
				end

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

				gFps = gRemoteView.fps
				gTickTime = 1 / gFps

				for k,ship in pairs(gRemoteView.ships) do
					if k == gRemoteID then	--PERSONAL SHIP HUD. AMMO/ BOOSTS
						--This is your ship, get info from it
						local maxAlpha = 180
						local yOffset = Renderer.offset_y + (Renderer.offset_y - 50)
						local xOffset = Renderer.offset_x
						local ammo_Width = 8
						local ammo_Height = 20
						xOffset = xOffset - (ammo_Width * TUNING.SHIP.MAX_AMMO_CLIP) + (ammo_Width*.5)

						local prevWidth = love.graphics.getLineWidth()
						love.graphics.setLineWidth(1)			

						for i= 1, TUNING.SHIP.MAX_AMMO_CLIP do
							love.graphics.setColor(255,255,255,255)
							love.graphics.rectangle("line", xOffset, yOffset, ammo_Width, ammo_Height)

							if i <= ship.ammo then
								if ship.t == 0 then
									love.graphics.setColor(55,255,155,maxAlpha)
								else
									love.graphics.setColor(155,55,255,maxAlpha)
								end
								love.graphics.rectangle("fill", xOffset, yOffset, ammo_Width, ammo_Height)
							end

							if i == ship.ammo + 1 then
								local a = lerp(maxAlpha, 0, ship.rl/TUNING.SHIP.RELOAD_SPEED)
								if ship.t == 0 then
									love.graphics.setColor(55,255,155,a)
								else
									love.graphics.setColor(155,55,255,a)
								end
								love.graphics.rectangle("fill", xOffset, yOffset, ammo_Width, ammo_Height)
							end
							xOffset = xOffset + (ammo_Width * 2)
						end

						local yOffset = Renderer.offset_y + (Renderer.offset_y - 75)
						local xOffset = Renderer.offset_x
						local boost_Rad = 10
						xOffset = xOffset - (boost_Rad * TUNING.SHIP.POWER_POINTS)
						for i = 1, TUNING.SHIP.POWER_POINTS do
							love.graphics.setColor(255,255,255,255)
							love.graphics.circle("line", xOffset, yOffset, boost_Rad)

							if i <= ship.b then
								local a = maxAlpha
								if i == ship.b and ship.pwr then
									a = lerp(0, maxAlpha, ship.bt/TUNING.SHIP.POWER_DURATION)
								end
								if ship.t == 0 then
									love.graphics.setColor(55,255,155,a)
								else
									love.graphics.setColor(155,55,255,a)
								end
								love.graphics.circle("fill", xOffset, yOffset, boost_Rad)
							end

							xOffset = xOffset + (boost_Rad * 3)
						end

						love.graphics.setLineWidth(prevWidth)
					end					

				end

				if gRemoteView.game.f == FLOW.WARMUP then
					if gGameSong then 
						gGameSong:Stop()
						gGameSong = nil
					end
					if not gWarmupSong then
						gWarmupSong = SOUNDS:PlaySound("music.warmup", 0.5)
					end

					love.graphics.setFont(Fonts.header.font)
					love.graphics.setColor(0,0,0,255)
					love.graphics.print("WARMUP MODE", Renderer.offset_x-150+1, Renderer.offset_y-90+1)
					love.graphics.setColor(255,255,255,255)
					love.graphics.print("WARMUP MODE", Renderer.offset_x-150, Renderer.offset_y-90)

					love.graphics.setColor(0,0,0,255)
					love.graphics.print(gRemoteView.game.t, Renderer.offset_x-40+1, Renderer.offset_y+40+1)
					love.graphics.setColor(255,255,255,255)
					love.graphics.print(gRemoteView.game.t, Renderer.offset_x-40, Renderer.offset_y+40)
					if gRemoteView.game.t > 1.2 then 
						gPlayCountdown = true
					elseif gPlayCountdown then
						gPlayCountdown = false
						SOUNDS:PlaySound("sfx.ingame.countdown", 1.0)
					end
				else
					if gWarmupSong then
						gWarmupSong:Stop()
						gWarmupSong = nil
					end		
					if not gGameSong then 
						gGameSong = SOUNDS:PlaySound("music.game", 0.5)
					end			

					for i=1,gRemoteView.game.st do
						love.graphics.setColor(0,0,0,255)
						love.graphics.circle("fill", Renderer.offset_x - i * 40, 40, 17, 6)
						love.graphics.circle("fill", Renderer.offset_x + i * 40, 40, 17, 6)

						local mode0 = "line"
						if gRemoteView.game.s0 >= i then
							mode0 = "fill"
						end
						love.graphics.setColor(55,255,155,255)
						love.graphics.circle(mode0, Renderer.offset_x - i * 40, 40, 15, 6)

						local mode1 = "line"
						if gRemoteView.game.s1 >= i then
							mode1 = "fill"
						end
						love.graphics.setColor(155,55,255,255)
						love.graphics.circle(mode1, Renderer.offset_x + i * 40, 40, 15, 6)
					end

					if gRemoteView.game.f == FLOW.WIN_0 then
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
				end

				local controls = require('controls')
				local instructions = {} 
				local control_type = 'KeyboardKey'
				local control_names = require('keyboard')
				if gInputId > 0 then
					control_type = 'GamepadButton'
					control_names = require('gamepad')
				end
				for k,action in pairs(controls) do
					local control = action[control_type]
					if control then 
						table.insert(instructions, action.Instruction..'='..control_names[control])
					end
				end
				local instructionstring = table.concat(instructions,"          ")

				local xPos = 250
				love.graphics.setFont(Fonts.info.font)
				love.graphics.setColor(0,0,0,255)
				love.graphics.print(instructionstring, xPos+1, love.graphics.getHeight() - 30+1)
				love.graphics.setColor(255,255,255,255)
				love.graphics.print(instructionstring, xPos, love.graphics.getHeight() - 30)

				for i,log in pairs(gRemoteView.kills) do
					local names = {}
					for n1,n2 in string.gmatch(log.usr, "(%w+)|(%w+)") do
						names[1] = n1
						names[2] = n2
					end
					local s = string.format("%s was killed by %s", names[2], names[1])

					love.graphics.setFont(Fonts.info.font)
					love.graphics.setColor(0,0,0,255)
					love.graphics.print(s, 30+1, love.graphics.getHeight() -60+1 - 30*i)
					if names[1] == gUser or names[2] == gUser then
						love.graphics.setColor(255,255,55,255)
					elseif names[2] == "Obstacle" then
						love.graphics.setColor(115,115,115,255)
					elseif names[2] == "Arena" then
						love.graphics.setColor(135,115,115,255)
					elseif names[2] == "Payload" then
						love.graphics.setColor(115,115,135,255)
					else
						love.graphics.setColor(155,155,55,255)
					end
					love.graphics.print(s, 30, love.graphics.getHeight() -60 - 30*i)

				end

			end
			
		end)
	end

	gRenderDt = socket.gettime() - start_time

	
	local remote_frame_id = 0
	if gRemoteView then
		remote_frame_id = gRemoteView.frame_id
	end
end

gUser = 'TriKiller'
function client_load()
	gClient = startclient(getip(), getport())
	Renderer:Load()	
	global("SOUNDS")
	SOUNDS = SoundSystem()
	SOUNDS.mixer:LoadDefs("mixes")
	SOUNDS:LoadBank( "mainbank" )

	for k,v in pairs(arg) do
		if string.len(v) > 5 then
			if string.sub(v, 1, 5 ) == 'user=' then
				gUser = string.sub(v,6)
			end
		end
	end
end


function client_update(dt)
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
	elseif key == 'f10' then
		gSpectatorMode = not gSpectatorMode
		if gSpectatorMode then
			Renderer:ZoomOut()
		else
			Renderer:ZoomIn()
		end
	elseif key == 'f3' then
		gInputId = gInputId + 1
	end
end

