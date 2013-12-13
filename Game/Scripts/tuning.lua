return 
{
	SHIP =
	{
		THRUST = 100,
		DRAG = -0.0065,
		TURNSPEED = 3,
		SHOOT_COOLDOWN = 0.1,
		ATTACH_COOLDOWN = .5,
		MIN_ATTACH_DISTANCE = 10,
		MAX_ATTACH_DISTANCE = 70,
		MAX_AMMO_CLIP = 10,
		RELOAD_SPEED = 1,
		RESPAWN_TIME = 3.0,
	},
	BULLET =
	{
		SPEED = 10,
		THRUSTFORCE = 150,
		RAND = 0.2,
	},
	PAYLOAD =
	{
		MASS = 30,
		DRAG = -0.66,
	},
	DAMAGE = 
	{
		SHIP_ON_SHIP = 0.001, -- damage per unit of speed
		BULLET_ON_SHIP = 1/3, -- damage per bullet
		SHIP_ON_ROCK = 0.01,  -- ship hitting obstacle
	},
	GAME = 
	{
		WARMUP_TIME = 10,
		VICTORY_TIME = 10,
		POINTS_TO_WIN = 2,
	},

}
