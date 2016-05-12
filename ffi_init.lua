local ffi = require("ffi")
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