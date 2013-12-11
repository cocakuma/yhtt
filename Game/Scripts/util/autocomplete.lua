local function AutoComplete(str)
	if str == "" then return {} end
	
	local str2 = string.match(str, "(.*)[:.].*")
	local ctx = str2
	
	if str2 then 
		local in_str_literal = false
		local fcall_depth = 0
		for i = #str2, 1, -1 do
		    local c = str:sub(i,i)

		    if c == "'" or c == '"' then
		    	in_str_literal = not in_str_literal
		    end

		    if c == ")" then fcall_depth = fcall_depth + 1 end
		    if c == "(" then 
		    	if fcall_depth == 0 then
		    		ctx = string.sub(str2, i+1, #str2)
		    		break
		    	end
		    	fcall_depth = fcall_depth - 1 
		    end

		    if not in_str_literal and fcall_depth == 0 and c == " " then
		    	ctx = string.sub(str2, i, #str2)
		    	break
		    end
		end
	end

	local partial = string.match(str, ".*[:.](%a*)")
	if not partial and not ctx then
		ctx = "_G"
		partial = string.match(str, "(%a*)$")
		if partial == "" then
			return {}
		end
	end

	local t = nil
	if ctx then 
		local fn = loadstring("return " .. ctx)
		
		local res, t = pcall(fn)
		if t and type(t) == "table" then
			local results = {}
			for k, v in pairs(t) do 
				if type(k) == "string" and string.find(k, "^"..partial) then
					table.insert(results,string.match(k, "^"..partial.."(.*)"))
				end
			end
			table.sort(results)
			return results
		end
	end

	return {}
end

return AutoComplete