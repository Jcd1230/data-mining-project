local _M = {}

-- Table of very common typos to be replaced.
local typos = {
	ther = {"their"},
	th = {"the"},
	the = {"the"},
	inthe = {"in", "the"},
	tothe =  {"to", "the"},
	thatthe =  {"that", "the"},
	withthe = {"with", "the"},
	ina = {"in", "a"},
	toa = {"to", "a"},
	thatthe = {"that", "the"}
}

local dictionary
local lexicon

-- Used for future filter functionality which utilizes 
-- the currently built dictionary
_M.set = function(d, l)
	dictionary = d
	lexicon = l
end

-- Performs some normalization (specifically case insensitivity, and removes
-- single letter words besides 'a')
-- More normalization techniques like stemming could be added later here.
_M.normalize = function(word)
	if #word == 1 and word ~= "a" then return nil end
	return word:lower()
end

-- Filter function to be run on words that are constructed from 
-- series of seperated letters
_M.filter = function (cap)
	
	if typos[cap] then return table.unpack(typos[cap]) end

	-- Detect if the word can be split
	for i = #cap, 1, -1 do
		local a, b = _M.normalize(cap:sub(1,i)), _M.normalize(cap:sub(i+1,-1))
		if dictionary[a] and dictionary[b] then
			return a, b
		end
	end

	return cap
end

return _M