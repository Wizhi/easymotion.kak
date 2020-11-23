#!/usr/bin/env lua

if os.getenv("kak_opt_easymotion_chars") then
	kak_easymotion_chars = os.getenv("kak_opt_easymotion_chars")
else
	kak_easymotion_chars = "abcdefghijklmnopqrstuvwxyz"
end

local function getCount(jumper)
	local counter = string.find(kak_easymotion_chars, string.sub(jumper, 1, 1) ) * #kak_easymotion_chars + string.find(kak_easymotion_chars, string.sub(jumper, 2, 2) ) - (#kak_easymotion_chars+1)
	return counter
end

if #arg == 1 then
	-- We are in getCount mode
	print( getCount(tostring(arg[1])) )
	os.exit(true)
end

if #arg ~= 5 then
	print("Wrong argument number, exitting. Expected 5, got:", #arg)
	for key, value in ipairs(arg) do
		print(key, value)
	end
	os.exit(false)
end

kak_timestamp = tonumber(arg[1])
kak_line      = tonumber(arg[2])
kak_column    = tonumber(arg[3])
kak_mode      = tostring(arg[4])
direction     = tonumber(arg[5])

-- Table for storing highlighting ranges
ranges = {}
-- Table for storing lines
lines = {}

-- Calculate highlighting characters from kak_easymotion_chars
local function getKeys(counter)
	local first = counter // #kak_easymotion_chars + 1
	local scnd = counter % #kak_easymotion_chars +1
	return string.sub(kak_easymotion_chars, first, first)..string.sub(kak_easymotion_chars, scnd, scnd)
end

local function partition(str)
	local word_skip
	local T = {}
	for word, space in string.gmatch( str, '(%S*)(%s*)' ) do
		-- a word without %p charachter
		for pre, punc, post in string.gmatch ( word, '(%P*)(%p)(%P*)' ) do
			-- a word with %p character
			word_skip = true
			if #pre ~= 0 then table.insert(T, pre) end
			if #punc ~= 0 then table.insert(T, punc) end
			if #post ~= 0 then table.insert(T, post) end
		end
		if not word_skip then table.insert(T, word..space) end
		word_skip = false
	end
	return T
end

local function markLines()
	for k, v in ipairs(lines) do
		if #v ~= 0 and k ~= 1 then
			local keys = getKeys(k-1)
			--print(k, keys, v)
			table.insert( ranges, string.format( '%s.1+0|{Information}%s', kak_line+(direction*k)-direction, keys) )
		end
	end
end

local function markWords()
	local count = 1
	local first_line = true -- in backward mode first line starts at cursor position
	local first_word = true -- do not highlight matches in current word
	for _,line in ipairs(lines) do
		if direction == -1 then
			line = string.reverse(line)
			if not first_line then
				kak_column = string.len(line)
			elseif kak_column > string.len(line) then -- XXX: remove?
				-- started on trailing \n
				kak_column = kak_column + direction
			end
		end
		for _,word in ipairs(partition(line)) do
			if not first_word and string.len(word) > 2 then
				--print( string.format("Replacing line %d column %d word: %s length: %d count: %d", kak_line, kak_column, word, #word, count) )
				table.insert( ranges, string.format( '%s.%s+2|{Information}%s', kak_line, kak_column, getKeys(count) ) )
			end
			if #word ~= 0 then
				count = count + 1
				first_word = false
				kak_column = kak_column + direction * utf8.len(word) -- XXX: backwards?
			end
		end
		kak_line = kak_line + direction
		kak_column = 1 -- new line, caret return
		first_line = false
	end
end

for line in io.lines() do
	if direction == -1 then
		table.insert(lines, 1, line)
	else
		table.insert(lines, line)
	end
end

if kak_mode == "lines" then
	markLines()
elseif kak_mode == "words" then
	markWords()
else
	print("Wrong kak_mode. Expected 'lines' or 'words'.")
	os.exit(false)
end

if #ranges > 0 then
	command = "set-option buffer easymotion_ranges " .. kak_timestamp .. " " .. table.concat(ranges, ' ')
else
	command = "set-option buffer easymotion_ranges"
end

print(command)
