function defaultinput()
	local keys = { 'd', 'a', 'w', ' ', 'f' }
	local input = {}
	for i,k in pairs(keys) do
		input[k] = false
	end	
	return input
end