require "sounddef"
require "soundbank"

return SoundBank
{
	music =
	{
		warmup = SoundDef{
			samples={"Sound/thehardestspace.ogg"},
			looping = true,
			stream = true,
			fadeintime = 1,
			fadeouttime = 1,
			volume_min = 0.3,
			volume_max = 0.3,
		},

		game = SoundDef{
			samples={"Sound/beatsNbeats.ogg"},
			looping = true,
			stream = true,
			fadeintime = 1,
			fadeouttime = 1,
			volume_min = 0.3,
			volume_max = 0.3,
		},		
	},


	sfx=
	{	
		ui=
		{
			--click=SoundDef{
				--samples={
					--"data/sounds/menu_button.ogg",
				--},
				--maxplaybacks = 1,
			--},
		},
		ingame=
		{
			countdown=SoundDef{
				samples={
					"Sound/countdown.ogg",
				},
				maxplaybacks=1,
			},
			--win=SoundDef{
				--samples={
					--"data/sounds/win.ogg",
				--},
				--maxplaybacks=1,
			--},
			score_point=SoundDef{
				samples={
					"Sound/score_point.ogg"
				},
				maxplaybacks=2,
			},
			ship={
				attach=SoundDef{
					samples={
						"Sound/ship_attach.ogg"
					},
					maxplaybacks=10,
				},
				release=SoundDef{
					samples={
						"Sound/ship_release.ogg"
					},
					maxplaybacks=10,
				},
				thrust=SoundDef{
					samples={
						"Sound/ship_thrust.ogg"
					},
					maxplaybacks=60,
					looping=true,
					volume_min = .3,
					volume_max = .3,
				},
				shoot=SoundDef{
					samples={
						"Sound/missle_launch.ogg"
					},
					pick = "sequence",
					pitch_min = .75,
					pitch_max = 1.5,
					volume_min = .3,
					volume_max = .5,
					maxplaybacks = 60,
				},
			},
			explosions=
			{
				ship=SoundDef{
					samples={
						"Sound/ship_explo.ogg"
					},
					pick = "sequence",
					pitch_min = .75,
					pitch_max = 1.5,
					volume_min = .8,
					volume_max = 1.2,
					maxplaybacks = 8,
				},
				missile=SoundDef{
					samples={
						"Sound/missle_explo.ogg"
					},
					pick = "sequence",
					pitch_min = .75,
					pitch_max = 1.5,
					volume_min = .8,
					volume_max = 1.2,
					maxplaybacks = 20,
				},
			},
		}
	},
	
}
