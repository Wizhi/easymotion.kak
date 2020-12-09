#!/usr/bin/env lua

if os.getenv("kak_opt_easymotion_chars") then
	kak_easymotion_chars = os.getenv("kak_opt_easymotion_chars")
else
	kak_easymotion_chars = "abcdefghijklmnopqrstuvwxyz"
end

-- Calculate `count` value for Kakoune from the two-char long input.
local function getCount(jumper)
	local counter = string.find(kak_easymotion_chars, string.sub(jumper, 1, 1) ) * #kak_easymotion_chars + string.find(kak_easymotion_chars, string.sub(jumper, 2, 2) ) - (#kak_easymotion_chars+1)
	return counter
end

if #arg == 1 then
	-- We are in getCount mode
	print( getCount(tostring(arg[1])) )
	os.exit(true)
end

if #arg < 5 then
	print("Wrong argument number, exitting. Expected 5 or 6, got:", #arg)
	for key, value in ipairs(arg) do
		print(key, value)
	end
	os.exit(false)
end

if os.getenv("kak_opt_extra_word_chars") then
	kak_extra_word_chars = os.getenv("kak_opt_extra_word_chars"):gsub(' ', '')
else
	kak_extra_word_chars = ""
end
word_partition_pattern = '([%P' .. kak_extra_word_chars .. ']*)([^%P' .. kak_extra_word_chars  .. ']+)([%P' .. kak_extra_word_chars .. ']*)'


kak_timestamp = tonumber(arg[1])
kak_line      = tonumber(arg[2])
kak_column    = tonumber(arg[3])
kak_mode      = tostring(arg[4])
direction     = tonumber(arg[5])
if kak_mode == "streak" then
	kak_pattern   = tostring(arg[6])
end

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

-- String partitioning function, creates words from lines
local function partition(str)
	local word_skip
	local T = {}
	for word, space in string.gmatch( str, '(%S*)(%s*)' ) do
		-- words separated by space
		for pre, punc, post in string.gmatch ( word, word_partition_pattern ) do
			-- a word with %p or kak_extra_word_chars charachter
			word_skip = true
			if #pre ~= 0 then table.insert(T, pre) end
			if #punc ~= 0 then table.insert(T, punc) end
			if #post ~= 0 then table.insert(T, post) end
		end
		if not word_skip then
			table.insert(T, word..space)
		else
			--replace last element with element..space
			local element = T[#T]
			table.remove(T)
			table.insert(T, element..space)
		end
		word_skip = false
	end
	return T
end

local function markLines()
	for k, v in ipairs(lines) do
		if #v ~= 0 and k ~= 1 then
			-- ignore first line and empty lines
			local keys = getKeys(k-1)
			-- Using +0 shifts the whole line right so it remains readable
			table.insert( ranges, string.format( '%s.1+0|{Information}%s', kak_line+(direction*k)-direction, keys) )
		end
	end
end

local function markWords(mode)
	local count = 1
	local first_line = true
	local first_word = true -- do not highlight matches in first word
	for _,line in ipairs(lines) do
		if direction == -1 then
			if not first_line then
				-- in backward mode first line starts at cursor position
				kak_column = string.len(line)
			elseif kak_column > string.len(line) then
				-- started on trailing \n
				kak_column = kak_column + direction
				first_word = false
			end
		end
		-- just reorder the words instead of reversing them:
		-- 1) this way utf8.len() will work
		-- 2) no need to reverse highlighting too
		line_words = partition(line)
		local loop_start = 1
		local loop_end = #line_words
		if direction == -1 then
			loop_start = #line_words
			loop_end = 1
		end
		for i=loop_start, loop_end, direction do
			word = line_words[i]
			if first_word and utf8.len(word) == 1 then
				-- we are on first/last char of the word, so `b` and `w` will jump
				-- to the next word immediatelly instead of selecting remaining part
				count = count - 1
			end
			if mode == "streak" then
				if word:find(kak_pattern, 1, true) ~= fail then
					if direction == 1 then
						table.insert( ranges, string.format( '%s.%s+%d|{Information}%s', kak_line, kak_column, utf8.len(kak_pattern), kak_pattern ) )
					else
						--print(word, kak_line, kak_column-#word+1, #word)
						table.insert( ranges, string.format( '%s.%s+%d|{Information}%s', kak_line, kak_column-string.len(word)+1, utf8.len(kak_pattern), kak_pattern ) )
					end
				end
			else
				if not first_word and utf8.len(word) > 3 then
					-- Do not higlight first word and short words (which messes up the buffer)
					if direction == 1 then
						table.insert( ranges, string.format( '%s.%s+2|{Information}%s', kak_line, kak_column, getKeys(count) ) )
					else
						table.insert( ranges, string.format( '%s.%s+2|{Information}%s', kak_line, kak_column-string.len(word)+1, getKeys(count) ) )
					end
				end
			end
			if #word ~= 0 then
				-- do not count `\n` as word
				count = count + 1
				first_word = false
				kak_column = kak_column + direction * string.len(word)
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
	markWords("easy")
elseif kak_mode == "streak" then
	markWords("streak")
else
	print("Wrong kak_mode. Expected 'lines',  'words' or 'streak'.")
	os.exit(false)
end

if #ranges > 0 then
	command = "set-option buffer easymotion_ranges " .. kak_timestamp .. " " .. table.concat(ranges, ' ')
else
	command = "set-option buffer easymotion_ranges"
end

if kak_mode == "streak" and #ranges == 1 then
	-- replace the line below with the following once this fix is released
	-- https://github.com/mawww/kakoune/commit/586f79c30de2185a18f5f769e625184dd10fa40f
	-- command = command .. "; execute-keys <ret>; set-option buffer easymotion_ranges"
	command = command .. "; hook -once -group easymotion global PromptIdle .* %{ execute-keys <ret> }; set-option buffer easymotion_ranges"
end

print(command)
