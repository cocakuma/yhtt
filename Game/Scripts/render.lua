
Renderer = {}

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
	self.default_line_width = love.graphics.getLineWidth()
	print("Default line width", self.default_line_width)

	--for k,v in pairs(Fonts) do
        --v.font = love.graphics.newFont(v.file, v.size)
		--print("Loaded", k, v.file, v.size)
	--end
end

function Renderer:Draw(worldcb)

	love.graphics.setBackgroundColor( 10, 0, 0)
	love.graphics.clear()

	self.offset_x = love.graphics.getWidth()/2
	self.offset_y = love.graphics.getHeight()/2

	love.graphics.push()
	love.graphics.translate(self.offset_x, self.offset_y)
	love.graphics.scale(self.camera.zoom.current)
	love.graphics.translate(-self.camera.pos.x, -self.camera.pos.y)
	love.graphics.setLineWidth(self:getZoomedLineWidth(self.default_line_width))
	-- now drawing in WORLD space
	

	worldcb()

	love.graphics.pop()
	love.graphics.setLineWidth(self.default_line_width)
	-- now drawing in SCREEN space (HUD stuff)

	--self:DrawHUD()

end

function Renderer:getZoomedLineWidth(w)
	return math.max(w / self.camera.zoom.current, self.default_line_width)
end

function Renderer:getImageScale(w, h, desired_radius)
	local rad = TheSim:getDistance(0, 0, w, h) / 2
	return desired_radius / math.max(rad, 0.01)
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
