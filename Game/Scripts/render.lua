
local Renderer = {}

Renderer.camera = {
	pos = {
		x = 0, 
		y = 0,
	},
	zoom = {
		default = 1,
		current = 1,
		max = 1.5,
		min = 0.1,
		increment = 0.05,
	},
	default_line_width = 2,
}

Fonts = {
    big = {
        file = "fonts/BABYU___.TTF",
        size = 32,
    },
    small = {
        file = "fonts/BABYU___.TTF",
        size = 16,
    },
}

local EffectInfo = 
{
	EXPLOSION = 
	{
		anim = 
		{
			folder = "FX/explodeFX",
			fileprefix = "explosionFX_",
			frame_count = 16,
			fps = 12,
		},		
	},
	TELEPORT = 
	{
		anim = 
		{
			folder = "FX/teleportFX",
			fileprefix = "teleport_",
			frame_count = 6,
			fps = 12,
		},		
	},
}

local ShipInfo = 
{
	-- good
	BATTLESHIP = 
	{
		imagefile = "images/units/BarnBattleship.png",
		anim = 
		{
			folder = "units/idle_barn",
			fileprefix = "barn_",
			frame_count = 2,
			fps = 2,
		},		
	},
	SHEEP = 
	{
		imagefile = "images/units/SpaceSheep.png",
		anim = 
		{
			folder = "units/idle_sheep",
			fileprefix = "sheep_idle_",
			frame_count = 2,
			fps = 12,
		},
	},
	FIGHTER = 
	{
		imagefile = "images/units/SheepDog.png",
		anim = 
		{
			folder = "units/idle_sheepdog",
			fileprefix = "sheepdog_idle_",
			frame_count = 12,
			fps = 12,
		},
	},
	-- bad
	MOTHERSHIP = 
	{
		imagefile = "images/units/ChopMothership.png",
		anim = 
		{
			folder = "units/idle_chophouse",
			fileprefix = "chophouse_",
			frame_count = 2,
			fps = 2,
		},			
	},
	ENEMYFIGHTER = 
	{
		imagefile = "images/units/Wolf.png",
		anim = 
		{
			folder = "units/idle_wolf",
			fileprefix = "wolf_idle_",
			frame_count = 8,
			fps = 12,
		},
	},
	MISSILE = 
	{
		imagefile = "images/projectile.png",
		anim = 
		{
			folder = "shearer",
			fileprefix = "shearer_projectile_",
			frame_count = 2,
			fps = 12,
		},
	},	
}

local StarImages = {}

local FOW = nil

local NebulaImage = nil

function Renderer:Load()
	for k,v in pairs(ShipInfo) do
		v.image = love.graphics.newImage(v.imagefile)
		print("Loaded", k, v.imagefile, v.image)

		if v.anim then
			v.anim.frames = {}
			for i=1,v.anim.frame_count do
				local filename = string.format("images/%s/%s%04d.png", v.anim.folder, v.anim.fileprefix, i)
				local image = love.graphics.newImage(filename)
				print("LOADED", filename, image)
				if image then
					table.insert(v.anim.frames, image)
				end
			end
		end
	end

	for k,v in pairs(EffectInfo) do

		if v.anim then
			v.anim.frames = {}
			for i=1,v.anim.frame_count do
				local filename = string.format("images/%s/%s%04d.png", v.anim.folder, v.anim.fileprefix, i)
				local image = love.graphics.newImage(filename)
				print("LOADED", filename, image)
				if image then
					table.insert(v.anim.frames, image)
				end
			end
		end
	end	

	self.default_line_width = love.graphics.getLineWidth()
	print("Default line width", self.default_line_width)

	for k,v in pairs(Fonts) do
    	v.font = love.graphics.newFont(v.file, v.size)
		print("Loaded", k, v.file, v.size)
	end

	for i = 1,TheSim.star_images do
		local filename = string.format("images/BG/star%d.png", i)
		print("Loaded star", i, filename)
		StarImages[i] = love.graphics.newImage(filename)
	end

	NebulaImage = love.graphics.newImage("images/nebula.png")

	self:RecreateFOW()
end

function Renderer:Draw()

	love.graphics.setBackgroundColor( 0x10, 0x06, 0x2C)
	love.graphics.clear()

	self.offset_x = love.graphics.getWidth()/2
	self.offset_y = love.graphics.getHeight()/2

	love.graphics.push()
	love.graphics.translate(self.offset_x, self.offset_y)
	love.graphics.scale(self.camera.zoom.current)
	love.graphics.translate(-self.camera.pos.x, -self.camera.pos.y)
	love.graphics.setLineWidth(self:getZoomedLineWidth(self.default_line_width))
	-- now drawing in WORLD space

	self:GenerateFOW()

	for i,v in ipairs(TheSim.stars) do
		self:DrawStar(v)
	end	

	for i,v in ipairs(TheSim.Ships) do
		self:DrawShip(v,"ships")
	end


	for i,v in ipairs(TheSim.effects) do
		self:DrawEffects(v)
	end

	for i,v in ipairs(TheSim.nebulas) do
		self:DrawNebulas(v)
	end	

	-- love.graphics.setColor(0, 255, 0)
	-- love.graphics.circle("line", self.camera.pos.x, self.camera.pos.y, 20, 32)

	love.graphics.pop() 
	love.graphics.setLineWidth(self.default_line_width)
	-- now drawing in SCREEN space (FOW)

	self:DrawFOW()

	love.graphics.push()
	love.graphics.translate(self.offset_x, self.offset_y)
	love.graphics.scale(self.camera.zoom.current)
	love.graphics.translate(-self.camera.pos.x, -self.camera.pos.y)
	love.graphics.setLineWidth(self:getZoomedLineWidth(self.default_line_width))
	-- now drawing in WORLD space


	for i,v in ipairs(TheSim.Ships) do
		self:DrawShip(v,"hud")
	end


	-- draw the border of the world for reference
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("line", 0, 0, TheSim.world.width, TheSim.world.height)

	-- draw end zone

	love.graphics.setColor(0, 255, 0, 50)
	love.graphics.rectangle("fill", TheSim.world.width - TheSim.world.endzone, 0, TheSim.world.endzone, TheSim.world.height)

	self:DrawSelectBox()


	love.graphics.pop() 
	love.graphics.setLineWidth(self.default_line_width)
	-- now drawing in SCREEN space (HUD stuff)

	self:DrawHUD()

	-- local screencamerapos = self:WorldToScreen(self.camera.pos)
	-- love.graphics.setColor(0, 0, 255)
	-- love.graphics.circle("line", screencamerapos.x, screencamerapos.y, 10, 32)

	-- TEST TEST TEST
	-- if Input.select_anchor then
	-- 	local pt1 = Input.select_anchor
	-- 	local pt2 = Input.select_last

	-- 	love.graphics.setColor(0, 0, 255)
	-- 	love.graphics.rectangle("line", math.min(pt1.x, pt2.x), math.min(pt1.y, pt2.y), math.abs(pt1.x - pt2.x), math.abs(pt1.y - pt2.y))
	-- end
	-- TEST TEST TEST
end

function Renderer:getZoomedLineWidth(w)
	return math.max(w / self.camera.zoom.current, self.default_line_width)
end

function Renderer:getImageScale(w, h, desired_radius)
	local rad = TheSim:getDistance(0, 0, w, h) / 2
	return desired_radius / math.max(rad, 0.01)
end

function Renderer:RecreateFOW()
	FOW = nil
	FOW = love.graphics.newCanvas()
end

function Renderer:GenerateFOW()
	love.graphics.setCanvas(FOW)

	FOW:clear(0, 0, 0, 128)
	love.graphics.setBlendMode('subtractive')

	for i,ship in ipairs(TheSim.Ships) do
		if ship.side == "hero" then

			local info = ShipInfo[ship.type]

			local range = (not ship.inNebula and ship.traits.scannerRange) or ship.traits.radius

			range = math.max(range,TheSim.SIGHT_RANGE)
			if range then

				love.graphics.setColor(0, 0, 0, 255)
				love.graphics.circle("fill", ship.pos[1], ship.pos[2], range, 64)

				-- love.graphics.setColor(0, 0, 0, 255)
				-- love.graphics.circle("fill",ship.pos[1],  ship.pos[2], range * 0.6, 64)
			end

		end	
	end

	love.graphics.setCanvas()

    love.graphics.setBlendMode('alpha')
end

function Renderer:DrawFOW()
	love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(FOW)
end

local NEBULA_ROT_SPEED = math.pi / 60
local NEBULA_SCALE_FUDGE = 2

function Renderer:DrawNebulas(nebula)

	love.graphics.setColor(100, 100, 255, 50)	
	love.graphics.setLineWidth( self:getZoomedLineWidth(5) )
	love.graphics.circle("line", nebula.pos[1], nebula.pos[2], nebula.radius, 32)

	love.graphics.setColor(255, 255, 255, 128)

	local image = NebulaImage
	local rot = nebula.anim_time * NEBULA_ROT_SPEED
	
	local scale = self:getImageScale(image:getWidth(), image:getHeight(), nebula.radius) * NEBULA_SCALE_FUDGE
	love.graphics.draw(image, nebula.pos[1], nebula.pos[2], rot, scale, scale, image:getWidth()/2, image:getHeight()/2)
	love.graphics.draw(image, nebula.pos[1], nebula.pos[2], -rot, scale, scale, image:getWidth()/2, image:getHeight()/2)

end

function Renderer:DrawStar(star)
	local image = StarImages[star.imagenum]

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(image, star.pos[1], star.pos[2], nil, nil, nil, image:getWidth()/2, image:getHeight()/2)

end

function Renderer:DrawEffects(effect)
	if effect.type == "laser" then
		love.graphics.setColor(255, 50, 0,255*(effect.life/effect.lifeMAX))
		love.graphics.setLineWidth(effect.beam)
		love.graphics.line(effect.x0,effect.y0, effect.x1, effect.y1)		
	end

	if effect.type == "warp" then
		love.graphics.setColor(255, 255, 255,255)
		local info = EffectInfo.TELEPORT
		local frame = nil

		if info.anim then
			local timeframe = effect.anim_time * info.anim.fps
			local frame_num = math.floor(timeframe % info.anim.frame_count) + 1
			--print("ANIM", info.anim.frame_count, timeframe, frame_num, info.anim.frames[frame_num])						
			frame = info.anim.frames[frame_num]

			if frame_num == info.anim.frame_count then
				table.remove(TheSim.effects,TheSim:AnIndexOf(TheSim.effects,effect))
			end								
		end


		local scale = self:getImageScale(frame:getWidth(), frame:getHeight(), 300)
		love.graphics.draw(frame, effect.x0,effect.y0, nil, scale, scale, frame:getWidth()/2, frame:getHeight()/2)
			
	end	
	if effect.type == "explosion" then
		love.graphics.setColor(255, 255, 255,255)
		local info = EffectInfo.EXPLOSION
		local frame = nil

		if info.anim then
			local timeframe = effect.anim_time * info.anim.fps
			local frame_num = math.floor(timeframe % info.anim.frame_count) + 1
			--print("ANIM", info.anim.frame_count, timeframe, frame_num, info.anim.frames[frame_num])
			frame = info.anim.frames[frame_num]
			if frame_num == info.anim.frame_count then
				table.remove(TheSim.effects,TheSim:AnIndexOf(TheSim.effects,effect))
			end						
		end

		local scale = self:getImageScale(frame:getWidth(), frame:getHeight(), 200)
		love.graphics.draw(frame, effect.x0,effect.y0, nil, scale, scale, frame:getWidth()/2, frame:getHeight()/2)		

	end		
end


function Renderer:DrawShip(ship,pass)

		local draw = true 
		if ship.side == "villain" and ship.scanned == false then
			draw = false
		end

		if draw == true then
			if pass == "ships" then

				if ship.traits.repairzone == true then
					love.graphics.setColor(0, 255, 0,50)				
					love.graphics.circle("fill",ship.pos[1],  ship.pos[2], ship.traits.repairzonerange, 64)

					love.graphics.setColor(0, 255, 0,100)
					love.graphics.setFont(Fonts.big.font)
					love.graphics.printf("REPAIR ZONE", ship.pos[1]-250,  ship.pos[2] - ship.traits.repairzonerange - 40,500,"center" )
				end

				local info = ShipInfo[ship.type]

				love.graphics.setColor(255, 255, 255)
				if info then
					local rot = nil
					local mirror = 1
					if ship.traits.rotate then
						rot = ship.traits.rotate
					elseif ship.traits.spin then
						ship.traits.spin = ship.traits.spin + ship.traits.spinspeed
						rot = ship.traits.spin
					elseif ship.traits.mirrorable and ship.dest and ship.dest[1] and ship.dest[1][1] then
						if ship.dest[1][1] < ship.pos[1] then
							mirror = -1
						end
					end

					local frame = info.image

					if info.anim then
						local timeframe = ship.anim_time * info.anim.fps
						local frame_num = math.floor(timeframe % info.anim.frame_count) + 1
						--print("ANIM", info.anim.frame_count, timeframe, frame_num, info.anim.frames[frame_num])
						frame = info.anim.frames[frame_num]
					end

					local scale = self:getImageScale(frame:getWidth(), frame:getHeight(), ship.radius)
					love.graphics.draw(frame, ship.pos[1], ship.pos[2], rot, scale * mirror, scale, frame:getWidth()/2, frame:getHeight()/2)
				else
					love.graphics.setColor(255, 0, 0)
					love.graphics.circle("line", ship.pos[1], ship.pos[2], 20, 16)
				end

			end
			

			if pass == "hud" then

				if ship.side == "hero" and ship.selected then
					local selection_radius = ship.radius

					love.graphics.setColor(255, 255, 255)
					love.graphics.circle("line", ship.pos[1], ship.pos[2], ship.radius, 32)
				end
				if ship.side == "hero" and ship.scanned then
					local scanned_radius = ship.radius * 0.95
					love.graphics.setColor(255, 0, 0)
					love.graphics.circle("line", ship.pos[1], ship.pos[2], scanned_radius, 32)				
				end


				if ship.traits.scannerRange and not ship.inNebula and ship.traits.scannerRange > 200 then
					local r = 0
					local g = 0
					local b = 255
					if ship.side == "villain" then 
						r = 255
						g = 0
						b = 0
					end
					love.graphics.setColor(r, g, b,50)
					love.graphics.setLineWidth( self:getZoomedLineWidth(5) )
					love.graphics.circle("line", ship.pos[1], ship.pos[2], ship.traits.scannerRange, 64)
					love.graphics.setColor(r*.5, g*.5, b*.5,50)
					love.graphics.setLineWidth( self:getZoomedLineWidth(2) )
					love.graphics.circle("line",ship.pos[1],  ship.pos[2], ship.traits.scannerRange *0.6, 64)
				end

				if ship.side == "hero" and ship.dest and ship.dest[1] then
					local lastcoord = {ship.pos[1],  ship.pos[2]}
					for i,dest in pairs(ship.dest) do
						love.graphics.setColor(0, 0, 255, 100)
						love.graphics.setLineWidth( self:getZoomedLineWidth(2) )				
						love.graphics.line(lastcoord[1],lastcoord[2], ship.dest[i][1],ship.dest[i][2] )	
						lastcoord = {ship.dest[i][1],ship.dest[i][2]}
					end
				end



				-- RENDER HP
				for i=1,ship.hp,1 do

					if not ship.traits.inocuous then 
						local rad = 5

						love.graphics.setColor(0,255,0,255)
						if ship.hp < 2 then
							love.graphics.setColor(255,0,0,255)
						end
						
						love.graphics.setLineWidth( self:getZoomedLineWidth(1) )
						love.graphics.circle("fill",
							ship.pos[1]+ ( (i-1) * rad *2) - (ship.radius/2),  
							ship.pos[2] - (ship.radius/2)  - rad*2  , 
							rad , 64)
					end
				end

			end



		end	


end

function Renderer:DrawHUD()
	local topbar_h = 50
	local bottombar_h = 25

	love.graphics.setColor(128, 128, 255, 100)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), topbar_h)

	local stats = TheSim:GetStats()
	local str = string.format("Sheeps: %d     Sheared: %d     Saved: %d", stats.alive, stats.killed, stats.saved)

	love.graphics.setColor(255, 255, 255, 128)
	love.graphics.setFont(Fonts.big.font)
	love.graphics.print(str, 20, 1)



	love.graphics.setColor(128, 128, 255, 100)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottombar_h, love.graphics.getWidth(), love.graphics.getHeight())

	local tips = "Select: L-CLICK or DRAG     Move: R-CLICK      Pan: R-DRAG     Zoom: MOUSEWHEEL     Fullscreen: ALT-ENTER"

	love.graphics.setColor(255, 255, 255, 128)
	love.graphics.setFont(Fonts.small.font)
	love.graphics.print(tips, 20, love.graphics.getHeight() - bottombar_h + 1)
end

-- screen coordinates
function Renderer:SetCameraPos(pos)
	--print("Renderer:SetCameraPos", pos.x, pos.y)
	self.camera.pos.x = pos.x
	self.camera.pos.y = pos.y
end

function Renderer:GetCameraPos()
	local pos = {
		 x = self.camera.pos.x, 
		 y = self.camera.pos.y,
	}
	return pos
end

function Renderer:ScreenToWorld( pos )
	local newpos = 
	{
		x = ((pos.x - self.offset_x) / self.camera.zoom.current) + self.camera.pos.x,
		y = ((pos.y - self.offset_y) / self.camera.zoom.current) + self.camera.pos.y,
	}
	return newpos
end

function Renderer:WorldToScreen( pos )
	local newpos = 
	{
		x = ((pos.x - self.camera.pos.x) * self.camera.zoom.current) + self.offset_x,
		y = ((pos.y - self.camera.pos.y) * self.camera.zoom.current) + self.offset_y,
	}
	return newpos
end

function Renderer:DrawSelectBox()
	if Input.select_anchor then
		local pt1 = self:ScreenToWorld(Input.select_anchor)
		local pt2 = self:ScreenToWorld(Input.select_last)

		love.graphics.setColor(0, 255, 0)
		love.graphics.rectangle("line", math.min(pt1.x, pt2.x), math.min(pt1.y, pt2.y), math.abs(pt1.x - pt2.x), math.abs(pt1.y - pt2.y))
	end
end

function Renderer:ZoomIn()
	self.camera.zoom.current = math.min(self.camera.zoom.max, self.camera.zoom.current + self.camera.zoom.increment)
end

function Renderer:ZoomOut()
	self.camera.zoom.current = math.max(self.camera.zoom.min, self.camera.zoom.current - self.camera.zoom.increment)
end

return Renderer
