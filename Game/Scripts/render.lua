
Renderer = {}

Renderer.offset_x = 0
Renderer.offset_y = 0

Renderer.camera = {
	pos = {
		x = 0, 
		y = 0,
	},
	zoom = {
		default = 1,
		current = 1,
		max = 3,
		min = 0.1,
		increment = 0.6,
	},
	default_line_width = 2,
}

Fonts = {
    title = {
        file = "Fonts/PLASTICB.TTF",
        size = 70,
    },
    header = {
        file = "Fonts/PLASTICB.TTF",
        size = 42,
    },
	info = {
        file = "Fonts/coolvetica.ttf",
        size = 20,
	}
}


function Renderer:Load()
	self.default_line_width = love.graphics.getLineWidth()
	print("Default line width", self.default_line_width)

	for k,v in pairs(Fonts) do
    	v.font = love.graphics.newFont(v.file, v.size)
		print("Loaded font", k, v.file, v.size)
	end
end

function Renderer:Draw(worldcb, hudcb)

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

	hudcb()

end

function Renderer:getZoomedLineWidth(w)
	return math.max(w / self.camera.zoom.current, self.default_line_width)
end

function Renderer:getImageScale(w, h, desired_radius)
	local rad = TheSim:getDistance(0, 0, w, h) / 2
	return desired_radius / math.max(rad, 0.01)
end


-- screen coordinates
function Renderer:SetCameraPos(x, y)
	--print("Renderer:SetCameraPos", pos.x, pos.y)
	self.camera.pos.x = x
	self.camera.pos.y = y
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
