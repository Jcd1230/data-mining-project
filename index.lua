local ffi = require("ffi")
local lpeg = require("lpeg")

local filter = require("filter").filter

local P,R,S,C,Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Ct

local stdio_h = io.open("stdio_ffi.h")
ffi.cdef(stdio_h:read("*a"))
stdio_h:close()

ffi.cdef[[
struct term {
	int freq;
	int post_ptr;
	int ndocs;
	int word_ptr;
	char length;
};
]]
local int_t = ffi.new("int")
local term_t = ffi.new("struct term")

local lexicon_from_disk = false


local n_paragraphs = 0
local n_total_words = 0

local dictionary = {} -- Unordered hash table of words
local lexicon = {} -- Ordered list of words (later sorted by frequency)


do
	local C = ffi.C	

	local f_dict = io.open("dict.b","rb") 
	local f_post = C.fopen("post.b","rb")
	local f_lex = C.fopen("lex.b","rb")

	if f_dict ~= nil and f_post ~= nil and f_lex ~= nil then
		lexicon_from_disk = true
		print("Loading lexicon from disk...")
			
		local dict = f_dict:read("*a")
		
		local lex_size = ffi.new("int[1]")
		local post_size = ffi.new("int[1]")
		local paragraph_count = ffi.new("int[1]")
		local word_count = ffi.new("int[1]")
		
		C.fread(lex_size, ffi.sizeof(int_t), 1, f_lex)
		
		C.fread(paragraph_count, ffi.sizeof(int_t), 1, f_post)
		C.fread(word_count, ffi.sizeof(int_t), 1, f_post)
		C.fread(post_size, ffi.sizeof(int_t), 1, f_post)
		
		n_paragraphs = paragraph_count[0]
		n_total_words = word_count[0]
		
		print("Post & lex size: ", post_size[0], lex_size[0])
		local terms = ffi.new("struct term[?]", lex_size[0])
		local postings = ffi.new("int[?]", post_size[0])
		
		C.fread(terms, ffi.sizeof(term_t), lex_size[0], f_lex)
		C.fread(postings, ffi.sizeof(int_t), post_size[0], f_post)
		
		C.fclose(f_lex)
		C.fclose(f_post)
		
		local postings_ptr = 0
		for i = 0,lex_size[0]-1 do
			local t = {
				freq = terms[i].freq,
				docs = {}
			}
			local ptr = terms[i].word_ptr
			t.word = dict:sub(ptr, ptr+terms[i].length)
			
			for j = 0, terms[i].ndocs - 1 do
				table.insert(t.docs, postings[postings_ptr+j])
			end
			
			postings_ptr = postings_ptr + terms[i].ndocs
			
			table.insert(lexicon, t)
		end
	end
end

if lexicon_from_disk then 
	
	
else --Construct lexicon menually
	-- Load the file
	local file = io.open("caesar-polo-esau.txt")
	local contents = file:read("*a")
	file:close()

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

	-- Performs some normalization (specifically case insensitivity, and removes
	-- single letter words besides 'a')
	-- More normalization techniques like stemming could be added later here.
	local function normalize(word)
		if #word == 1 and word ~= "a" then return nil end
		return word:lower()
	end

	while pos do
		for i,word in ipairs(matches) do
			word = normalize(word)
			if word then
				n_total_words = n_total_words + 1
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
		n_paragraphs = n_paragraphs + 1
		pid, matches, pos = patt:match(contents, pos)
	end

	-- Sort the lexicon by frequency
	table.sort(lexicon, function(a,b) return a.freq > b.freq end)
end


print("Number of paragraphs: "..n_paragraphs)
print("Most common words: (word, total occurrences, documents)")
for i = 1,20 do 
	print(i.."th\t",
		lexicon[i].word.."\t", 
		lexicon[i].freq.."\t", 
		#lexicon[i].docs)
end
print("100th\t", 
	lexicon[100].word.."\t", lexicon[100].freq.."\t", #lexicon[100].docs)
print("500th\t", 
	lexicon[500].word.."\t", lexicon[500].freq.."", #lexicon[500].docs)
print("1000th\t", 
	lexicon[1000].word.."\t", lexicon[1000].freq.."\t", #lexicon[1000].docs)

print("Total words: "..n_total_words)
print("Unique words: "..#lexicon)

-- Find # of words in only 1 doc
local unique_doc_words = 0
for i,v in ipairs(lexicon) do
	if #v.docs == 1 then
		unique_doc_words = unique_doc_words + 1
	end
end

print(("Words in only 1 document:\n\t%s =\t%.2f%% of unique words")
	:format(unique_doc_words, 100*unique_doc_words/#lexicon))
print(("\t\t\t%.2f%% of all words"):format(100*unique_doc_words/n_total_words))


if not lexicon_from_disk then
	print("Writing dictionary and postings list")

	local C = ffi.C	

	local f_dict = C.fopen("dict.b","wb") 
	local f_post = C.fopen("post.b","wb")
	local f_lex = C.fopen("lex.b","wb")


	local lex_size = ffi.new("int", #lexicon)
	local terms = ffi.new("struct term[?]", lex_size)
	local dict_size = 0
	local postings_size = 0
	local dict = {}
	local postings = {}
	for i,v in ipairs(lexicon) do
		terms[i-1].freq = v.freq
		terms[i-1].post_ptr = postings_size
		terms[i-1].ndocs = #v.docs
		terms[i-1].word_ptr = dict_size
		terms[i-1].length = #v.word
		table.insert(dict, v.word)
		for i,v in ipairs(v.docs) do
			table.insert(postings, v)
		end
	end
		
	print("writing docs...")
	local postings_c = ffi.new("int[?]", #postings, postings)
	local dict_c = table.concat(dict)
	
	C.fwrite(dict_c, #dict_c, 1, f_dict)
	
	C.fwrite(ffi.new("int[1]", {n_paragraphs}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(ffi.new("int[1]", {n_total_words}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(ffi.new("int[1]", {#postings}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(postings_c, ffi.sizeof(int_t), #postings, f_post)
	
	C.fwrite(ffi.new("int[1]", {lex_size}), ffi.sizeof(int_t), 1, f_lex)
	C.fwrite(terms, ffi.sizeof(term_t), lex_size , f_lex)
			
		
	
	C.fclose(f_dict)
	C.fclose(f_post)
	C.fclose(f_lex)
	
end