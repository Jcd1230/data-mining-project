require("ffi_init")

local normalize = require("filter").normalize

local count = {
	paragraphs = 0,
	words = 0
}

local dictionary = {} -- Unordered hash table of words
local lexicon = {} -- Ordered list of words (later sorted by frequency)

local lexicon_from_disk = require("load")(lexicon, dictionary, count)

if not lexicon_from_disk then 
	require("parse")(lexicon, dictionary, count)
	require("save")(lexicon, dictionary, count)
end

print("Number of paragraphs (documents): "..count.paragraphs)

print("Total words: "..count.words)
print("Unique words: "..#lexicon)

local function print_postings(_word, post)
	word = normalize(_word)
	print("Word: ".._word, " Document Frequency: "..#dictionary[word].docs)
	if post then print("Postings: ", table.concat(dictionary[word].docs, ", ")) end
end

-- Find # of words in only 1 doc
local unique_doc_words = 0
for i,v in ipairs(lexicon) do
	if #v.docs == 1 then
		unique_doc_words = unique_doc_words + 1
	end
end

print(("Words in only 1 document:\n\t%s =\t%.2f%% of unique words")
	:format(unique_doc_words, 100*unique_doc_words/#lexicon))
print(("\t\t\t%.2f%% of all words"):format(100*unique_doc_words/count.words))

print_postings("Francisco", true)
print_postings("midway", true)
print_postings("paddy", true)
print_postings("Kremlin")
print_postings("KGB")
print_postings("Khrushchev")


