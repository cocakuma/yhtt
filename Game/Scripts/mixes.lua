require "mix"

return
{
	normal = Mix{
		pushtime=0,
		vol=
		{
			['sfx.game']=1,
			['sfx.ui']=1,
			['music']=1,
			['ambient']=1
		},
	},

	pause = Mix{
		pushtime=1,
		vol=
		{
			['sfx.game'] = 0,
			['sfx.ui'] = 1,
			['music'] = .5,
			['ambient'] = 0
		},
	}
}