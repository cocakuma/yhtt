return 
{
	SHIP =
	{
		THRUST = 100,
		BOOST_THRUST = 1000,
		DRAG = -0.0065,
		TURNSPEED = 3,
		ATTACH_COOLDOWN = .5,
		MIN_ATTACH_DISTANCE = 10,
		MAX_ATTACH_DISTANCE = 70,
		
		SHOOT_COOLDOWN = 0.1,
		MAX_AMMO_CLIP = 15,
		RELOAD_SPEED = .75,

		BERSERK_RELOAD_SPEED = 0.1,
		BERSERK_SHOOT_COOLDOWN = 0.05,

		RESPAWN_TIME = 3.0,
		POWER_POINTS = 5,
		POWER_DURATION = 3,
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
		HEALTH = 10,
		REGEN_RATE = 0.33,
		PULSE_COOLDOWN = 10, --Can't be dragged during this time!
		DETACH_FORCE = 500,
	},
	DAMAGE = 
	{
		SHIP_ON_SHIP = 0.001, -- damage per unit of speed
		BULLET_ON_SHIP = 1/8, -- damage per bullet
		SHIP_ON_ROCK = 0.01,  -- ship hitting obstacle
		BULLET_ON_PAYLOAD = 1,
		PAYLOAD_ON_ROCK = 0.01,
		PAYLOAD_ON_SHIP = 0.01,
	},
	GAME = 
	{
		WARMUP_TIME = 1,
		VICTORY_TIME = 10,
		POINTS_TO_WIN = 2,
	},

}
