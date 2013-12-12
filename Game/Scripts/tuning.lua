return 
{
	SHIP =
	{
		THRUST = 100,
		DRAG = -0.01,
		TURNSPEED = 3,
		SHOOT_COOLDOWN = 0.1,
		ATTACH_COOLDOWN = .5,
		MIN_ATTACH_DISTANCE = 10,
		MAX_ATTACH_DISTANCE = 90,
		MAX_AMMO_CLIP = 10,
		RELOAD_SPEED = 0.66,
	},
	BULLET =
	{
		SPEED = 10,
		THRUSTFORCE = 150,
	},
	PAYLOAD =
	{
		MASS = 100,
		DRAG = -0.66,
	},
	DAMAGE = 
	{
		SHIP_ON_SHIP = 0.001, -- damage per unit of speed
		BULLET_ON_SHIP = 1/6, -- damage per bullet
		SHIP_ON_ROCK = 0.01,  -- ship hitting obstacle
	}
}
