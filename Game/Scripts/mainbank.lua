require "sounddef"
require "soundbank"

return SoundBank
{
	music =
	{
		title= SoundDef{
			samples={"data/sounds/IronButterTank.ogg"},
			looping = true,
			stream = true,
			fadeintime = 1,
			fadeouttime = 1,
		},
				inGame= SoundDef{
			samples={"data/sounds/puriya_kalyan01_new.mp3"},
			looping = true,
			stream = true,
			fadeintime = 1,
			fadeouttime = 1,
		}
	},

	sfx=
	{	
		ui=
		{
			click=SoundDef{
				samples={
					"data/sounds/menu_button.ogg",
				},
				maxplaybacks = 1,
			},
		},
		ingame=
		{
			countdown=SoundDef{
				samples={
					"data/sounds/Beep_Race_StartCountdown1.ogg",
				},
				maxplaybacks=1,
			},
			win=SoundDef{
				samples={
					"data/sounds/win.ogg",
				},
				maxplaybacks=1,
			},
			chain_scatter=SoundDef{
				samples={
					"data/sounds/chain_scatter.ogg",
				},
				maxplaybacks=10,
			},
			dash=SoundDef{
				samples={
					"data/sounds/dash.ogg",
				},
				maxplaybacks=10,
			},
			flower_dropoff=SoundDef{
				samples={
					"data/sounds/flower_dropoff.ogg",
				},
				maxplaybacks=10,
			},
			flower_lost=SoundDef{
				samples={
					"data/sounds/flower_lost.ogg",
				},
				maxplaybacks=10,
			},
			flower_pickup=SoundDef{
				samples={
					"data/sounds/flower_pickup.ogg",
				},
				volume_min = .4,
				volume_max = .6,
				pitch_min = .9,
				pitch_max = 1.1,
				maxplaybacks=10,
			},
			freeze_impact=SoundDef{
				samples={
					"data/sounds/freeze_impact.ogg",
				},
				maxplaybacks=10,
			},
			freeze_shot=SoundDef{
				samples={
					"data/sounds/freeze_shot.ogg",
				},
				maxplaybacks=10,
			},
			radius_blast=SoundDef{
				samples={
					"data/sounds/radius_blast.ogg",
				},
				maxplaybacks=10,
			},
			bounce=SoundDef{
				samples={
					"data/sounds/bounce.ogg",
				},
				maxplaybacks=20,
			},
			freeze_bounce=SoundDef{
				samples={
					"data/sounds/freeze_bounce.ogg",
				},
				maxplaybacks=20,
			},

			explosions=
			{
				small=SoundDef{
					samples={
						"data/sounds/bomb-02.ogg",
						"data/sounds/bomb-03.ogg"
					},
					pick = "sequence",
					pitch_min = .75,
					pitch_max = 1.5,
					volume_min = .8,
					volume_max = 1.2,
					maxplaybacks = 2,
				}

			},
			tank=
			{
				turret_rotate=SoundDef{
					samples={},
					loop = true,
				}
			}
		}
	},
}