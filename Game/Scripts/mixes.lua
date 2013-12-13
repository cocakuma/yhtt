require "mix"

return
{
	normal = Mix{
		pushtime=0,
		vol=
		{
			['sfx.ingame']=1,
			['sfx.ui']=1,
			['music']=.3,
			['ambient']=1
		},
	},

	pause = Mix{
		pushtime=1,
		vol=
		{
			['sfx.ingame'] = 0,
			['sfx.ui'] = 1,
			['music'] = .2,
			['ambient'] = 0
		},
	}
}
