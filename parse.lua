local filterlib = require("filter")
local filter = filterlib.filter
local normalize = filterlib.normalize

local lpeg = require("lpeg")
local P,R,S,C,Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Ct


return function(lexicon, dictionary, count)
	-- Construct lexicon menually
	-- Load the file
	local file = io.open("caesar-polo-esau.txt")
	local contents = file:read("*a")
	file:close()
	
	require("filter").set(dictionary, lexicon)

	-- Construct PEG elements
	local alpha = R"az" + R"AZ" -- Single letter
	local num = R"09" -- Single digit

	-- Paragraph start and end tags
	local p_start = P"<P ID=" * ((num^1) / tonumber) * P">"
	local p_end = P"</P>"

	-- Single space & whitespace
	local space = P" "
	local ws = S" \t\n"

	-- A word as a series of separated letters, concatenated and filtered.
	local word = Ct((C(alpha) * space)^1) / table.concat / filter
	word = word + C(alpha^2) + C(alpha)

	-- Full pattern to match a paragraph
	local patt = ws^0 * p_start * Ct((word + P(1) - p_end)^0) * p_end * lpeg.Cp()

	-- First paragraph ID, words, and end position in the file of the paragraph.
	local pid, matches, pos = patt:match(contents)

	while pos do
		for i,word in ipairs(matches) do
			word = normalize(word)
			if word then
				count.words = count.words + 1
				-- Get or create the dictionary item for this word
				local isnew = dictionary[word] == nil
				local d = dictionary[word] or {freq = 0, docs = {}, word = word}
				d.freq = d.freq + 1 -- Increment the total frequency
				if (d.docs[#d.docs] ~= pid) then
					-- Add the current paragraph to the postings list for the word
					table.insert(d.docs, pid)
				end
				-- If this is the first occurence of the word, add it to the lexicon.
				if isnew then
					table.insert(lexicon, d)
					dictionary[word] = d
				end
			end
		end
		count.paragraphs = count.paragraphs + 1
		pid, matches, pos = patt:match(contents, pos)
	end

	-- Sort the lexicon by frequency
	table.sort(lexicon, function(a,b) return a.freq > b.freq end)
end