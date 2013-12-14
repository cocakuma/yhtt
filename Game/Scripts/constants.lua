DEGREES = 180/math.pi

SHIP_VERTS = 
{
	x = {-5, -5, 5}, 
	y = {-3, 3, 0}
}
FLAME_VERTS = 
{
	x = {-5, -5, -25}, 
	y = {-3, 3, 0}
}

function DrawTriangle(w, h, x, y, rotation, offsetx, offsety, mode)
	local cosA = math.cos(rotation)
	local sinA = math.sin(rotation)
	offsetx = offsetx or 0
	offsety = offsety or 0
	local v = {{x=offsetx-w/2,y=offsety-h/2},
			   {x=offsetx-w/2,y=offsety+h/2},
			   {x=offsetx+w/2,y=offsety}}
	love.graphics.polygon( mode or "fill",
					x+(v[1].x*cosA)-(v[1].y*sinA),y+(v[1].x*sinA)+(v[1].y*cosA),
					x+(v[2].x*cosA)-(v[2].y*sinA),y+(v[2].x*sinA)+(v[2].y*cosA),
					x+(v[3].x*cosA)-(v[3].y*sinA),y+(v[3].x*sinA)+(v[3].y*cosA)
					)
end

function DrawRectangle(w, h, x, y, rotation, offsetx, offsety)
	local cosA = math.cos(rotation)
	local sinA = math.sin(rotation)
	offsetx = offsetx or 0
	offsety = offsety or 0
	local v = {{x = offsetx-w*0.5, y = offsety-h*0.5},
			   {x = offsetx+w*0.5, y = offsety-h*0.5 },
			   {x = offsetx+w*0.5, y = offsety+h*0.5},
			   {x = offsetx-w*0.5, y = offsety+h*0.5}}
	love.graphics.polygon( "fill",
					x+(v[1].x*cosA)-(v[1].y*sinA),y+(v[1].x*sinA)+(v[1].y*cosA),
					x+(v[2].x*cosA)-(v[2].y*sinA),y+(v[2].x*sinA)+(v[2].y*cosA),
					x+(v[3].x*cosA)-(v[3].y*sinA),y+(v[3].x*sinA)+(v[3].y*cosA),
					x+(v[4].x*cosA)-(v[4].y*sinA),y+(v[4].x*sinA)+(v[4].y*cosA)
					)
end


BULLET_SIZE =
{
	x = 3,
	y = 3,
}

PAYLOAD_SIZE =
{
	rad = 20,
	segs = 6,
}
