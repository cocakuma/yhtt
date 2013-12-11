local gMessageStart = ':>>\n' 
local gMessageEnd = '<<:\n' 

function send(node, text)
	message = 
	{ 
		bytes_sent = 0,
		text = gMessageStart..text..gMessageEnd
	}
	table.insert(node.messages, message)
end