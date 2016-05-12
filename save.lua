require("ffi_init")

local ffi = require("ffi")

local int_t = ffi.new("int")
local term_t = ffi.new("struct term")

return function(lexicon, dictionary, count)
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
		dict_size = dict_size + #v.word
		terms[i-1].length = #v.word
		table.insert(dict, v.word)
		for i,v in ipairs(v.docs) do
			table.insert(postings, v)
		end
	end
		
	local postings_c = ffi.new("int[?]", #postings, postings)
	local dict_c = table.concat(dict)
	
	C.fwrite(dict_c, #dict_c, 1, f_dict)
	
	C.fwrite(ffi.new("int[1]", {count.paragraphs}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(ffi.new("int[1]", {count.words}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(ffi.new("int[1]", {#postings}), ffi.sizeof(int_t), 1, f_post)
	C.fwrite(postings_c, ffi.sizeof(int_t), #postings, f_post)
	
	C.fwrite(ffi.new("int[1]", {lex_size}), ffi.sizeof(int_t), 1, f_lex)
	C.fwrite(terms, ffi.sizeof(term_t), lex_size , f_lex)
	
	C.fclose(f_dict)
	C.fclose(f_post)
	C.fclose(f_lex)
end