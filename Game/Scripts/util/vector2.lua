require("util/class")

class("Vector2")

function Vector2.init(x, y)
	return {["x"]=x, ["y"]=y}
end

function Vector2.__add( self, rhs )
    return Vector2( self.x + rhs.x, self.y + rhs.y)
end

function Vector2.__sub( self, rhs )
    return Vector2( self.x - rhs.x, self.y - rhs.y)
end

function Vector2.__mul( self, rhs )
    return Vector2( self.x * rhs, self.y * rhs)
end

function Vector2.__div( self, rhs )
    return Vector2( self.x / rhs, self.y / rhs)
end

function Vector2.__tostring( self )
    return string.format("(%2.2f, %2.2f)", self.x, self.y)
end

function Vector2.__eq( self, rhs )
    return self.x == rhs.x and self.y == rhs.y
end

function Vector2.DistSq( self,other)
    return (self.x - other.x)*(self.x - other.x) + (self.y - other.y)*(self.y - other.y)
end

function Vector2.Dist( self,other)
    return math.sqrt(self:DistSq(other))
end

function Vector2.LengthSq( self )
    return self.x*self.x + self.y*self.y
end

function Vector2.Length( self )
    return math.sqrt(self:LengthSq())
end

function Vector2.Normalize( self )
    local len = self:Length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
    end
    return self
end

function Vector2.GetNormalized( self )
    return self / self:Length()
end

function Vector2.Get( self )
    return self.x, self.y, self.z
end

function Vector2.IsVector2( self )
    return true
end

function Vector2.ToVector2( obj, y )
    if not obj then
        return
    end
    if obj.IsVector2 then  -- note: specifically not a function call! 
        return obj
    end
    if type(obj) == "table" then
        return Vector2(tonumber(obj[1]),tonumber(obj[2]))
    else
        return Vector2(tonumber(obj),tonumber(y))
    end
end

