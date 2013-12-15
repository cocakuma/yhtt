local gActionId = 0
local function NextActionId()
	gActionId = gActionId + 1
	return tostring(gActionId)
end

return 
{
	Thrust = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'w',
		GamepadButton 	= 	'1',
		Instruction 	= 	'Thrust'
	},

	Shield = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'q',
		GamepadButton 	= 	'2',
		Instruction 	= 	'Shield'
	},

	Berserk = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'e',
		GamepadButton 	= 	'4',
		Instruction 	= 	'Berzerk'
	},	

	TurnLeft = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'd',
		Instruction 	= 	'Turn Left'
	},		

	TurnRight = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'a',
		Instruction 	= 	'Turn Right'
	},	

	Boost = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'lshift',
		GamepadButton 	= 	'6',
		Instruction 	= 	'Turn Right'
	},

	Attach = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	'f',
		GamepadButton 	= 	'5',
		Instruction 	= 	'Attach/Detach'
	},	

	Shoot = 
	{
		Id 				= 	NextActionId(),
		KeyboardKey 	= 	' ',
		GamepadButton 	= 	'3',
		Instruction 	= 	'Shoot'
	},		
}
