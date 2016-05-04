local filter

-- Table of typos to be replaced.
-- One example below, common typos can be added as necessary.
local typos = {
	ther = "their"
}

local dictionary
local lexicon

-- Used for future filter functionality which utilizes 
-- the currently built dictionary
local set = function(d, l)
	dictionary = d
	lexicon = l
end

-- Filter function to be run on words that are constructed from 
-- series of seperated letters
filter = function (cap)
	
	if typos[cap] then return typos[cap] end
	
	-- Common words that are combined
	if cap == "the" then return "the" end
	if cap == "inthe" then return "in", "the" end
	if cap == "tothe" then return "to", "the" end
	if cap == "thatthe" then return "that", "the" end
	if cap == "withthe" then return "with", "the" end
	if cap == "ina" then return "in", "a" end
	if cap == "toa" then return "to", "a" end
	if cap == "thatthe" then return "that", "the" end --100

	-- Detect if the word ends in 'the' and split it.
	local s,e
	s,e = cap:find("the$")
	if s then
		--print(cap, cap:sub(1,s-1), cap:sub(s,-1))
		local t = {filter(cap:sub(1,s-1))}
		table.insert(t, "the")
		return unpack(t)
	end

	return cap
end

return {filter = filter, set = set}