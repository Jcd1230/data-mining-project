require("ffi_init")

local ffi = require("ffi")

local int_t = ffi.new("int")
local term_t = ffi.new("struct term")

return function(lexicon, dictionary, count)
	local C = ffi.C	

	local f_dict = io.open("dict.b","rb") 
	local f_post = C.fopen("post.b","rb")
	local f_lex = C.fopen("lex.b","rb")

	if f_dict ~= nil and f_post ~= nil and f_lex ~= nil then
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
		
		count.paragraphs = paragraph_count[0]
		count.words = word_count[0]
		
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
			t.word = dict:sub(ptr+1, ptr+terms[i].length)
			
			for j = 0, terms[i].ndocs - 1 do
				table.insert(t.docs, postings[postings_ptr+j])
			end
			
			postings_ptr = postings_ptr + terms[i].ndocs
			
			table.insert(lexicon, t)
			dictionary[t.word] = t
		end
		
		return true
	end
	return false
end