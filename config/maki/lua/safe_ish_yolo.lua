local destructive = {
	rm = true,
	rmdir = true,
	shred = true,
	unlink = true,
	truncate = true,
	dd = true,
	mkfs = true,
	fdisk = true,
	parted = true,
	wipefs = true,
	srm = true,
}

local wrappers = {
	sudo = true,
	doas = true,
	env = true,
	nohup = true,
	setsid = true,
}

local protected = {
	"/",
	"/etc",
	"/boot",
	"/dev",
	"/usr",
	"/var",
	"/bin",
	"/lib",
	"/sbin",
	"/root",
}

local protected_home = { ".ssh", ".gnupg", ".aws", ".kube" }

local git_damaging = {
	{ "reset", "--hard" },
	{ "clean", "-f" },
	{ "branch", "-D" },
	{ "stash", "clear" },
	{ "stash", "drop" },
}

local function shell_words(text)
	local words = {}
	local i = 1
	local n = #text
	while i <= n do
		while i <= n and text:sub(i, i):match("%s") do
			i = i + 1
		end
		if i > n then
			break
		end
		local quote = nil
		local start = i
		while i <= n do
			local c = text:sub(i, i)
			if quote then
				if c == quote then
					quote = nil
				end
			elseif c == "'" or c == '"' then
				quote = c
			elseif c:match("%s") then
				break
			end
			i = i + 1
		end
		if quote then
			return nil
		end
		words[#words + 1] = text:sub(start, i - 1):gsub("^['\"]", ""):gsub("['\"]$", "")
	end
	return words
end

local function segments(command)
	local parser, err = maki.treesitter.get_parser(command, "bash")
	if err or not parser then
		return nil
	end
	local trees = parser:parse()
	if not trees or not trees[1] then
		return nil
	end
	local root = trees[1]:root()
	if root:has_error() then
		return nil
	end
	local out = {}
	local start = 1
	local quote, escaped = nil, false
	local i = 1
	while i <= #command do
		local c = command:sub(i, i)
		if escaped then
			escaped = false
		elseif c == "\\" and quote ~= "'" then
			escaped = true
		elseif quote then
			if c == quote then
				quote = nil
			end
		elseif c == "'" or c == '"' then
			quote = c
		elseif c == ";" or c == "|" or c == "&" or c == "\n" then
			local part = command:sub(start, i - 1):match("^%s*(.-)%s*$")
			if part ~= "" then
				out[#out + 1] = part
			end
			if (c == "|" or c == "&") and command:sub(i + 1, i + 1) == c then
				i = i + 1
			end
			start = i + 1
		end
		i = i + 1
	end
	local tail = command:sub(start):match("^%s*(.-)%s*$")
	if tail ~= "" then
		out[#out + 1] = tail
	end
	return out
end

local function verb_of(text)
	local words = shell_words(text)
	if not words then
		return nil
	end
	local i = 1
	while i <= #words do
		local word = words[i]
		if wrappers[word] then
			i = i + 1
		elseif word:sub(1, 1) == "-" then
			i = i + 1
		else
			return word
		end
	end
	return nil
end

local function destructive_verb(verb)
	if destructive[verb] then
		return verb
	end
	for name in pairs(destructive) do
		if verb:sub(1, #name + 1) == name .. "." then
			return name
		end
	end
	return nil
end

local function tokens(command)
	local out = {}
	for token in command:gmatch("%S+") do
		out[#out + 1] = token:gsub("^['\"]", ""):gsub("['\"]$", "")
	end
	return out
end

local function target_path(token)
	if token:match("^if=") then
		return nil
	end
	return token:match("=([^=]*)$") or token
end

local function normalize_path(path)
	local absolute = path:sub(1, 1) == "/"
	local parts = {}
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			if #parts > 0 and parts[#parts] ~= ".." then
				table.remove(parts)
			elseif not absolute then
				parts[#parts + 1] = part
			end
		elseif part ~= "." and part ~= "" then
			parts[#parts + 1] = part
		end
	end
	local result = (absolute and "/" or "") .. table.concat(parts, "/")
	if result == "" then
		return absolute and "/" or "."
	end
	return result
end

local function expand_path(path, home, cwd)
	path = path:gsub("%${HOME}", home):gsub("%$HOME", home)
	if path == "~" then
		path = home
	elseif path:sub(1, 2) == "~/" then
		path = home .. path:sub(2)
	end
	if path:sub(1, 1) ~= "/" then
		path = cwd .. "/" .. path
	end
	return normalize_path(path)
end

local function is_at_or_below(path, base)
	return path == base or base == "/" or path:sub(1, #base + 1) == base .. "/"
end

local function protected_target(token, home, cwd)
	local path = target_path(token)
	if not path or not (path:find("/", 1, true) or path:sub(1, 1) == "~" or path:find("$HOME", 1, true)) then
		return nil
	end
	local resolved = expand_path(path, home, cwd)
	for _, base in ipairs(protected) do
		if is_at_or_below(resolved, base) then
			return base
		end
	end
	for _, dir in ipairs(protected_home) do
		local base = normalize_path(home .. "/" .. dir)
		if is_at_or_below(resolved, base) then
			return "~/" .. dir
		end
	end
	return nil
end

local function delete_targets(command, verb)
	local out = {}
	local words = tokens(command)
	local seen = false
	for _, word in ipairs(words) do
		if seen then
			if word:sub(1, 1) ~= "-" then
				out[#out + 1] = word
			end
		elseif word == verb or word:match("^" .. verb:gsub("[%p]", "%%%0") .. "%.") then
			seen = true
		end
	end
	return out
end

local function is_blind(target)
	return target == nil or target == "" or target:find("[*?]") ~= nil
		or target == "." or target == ".." or target == "./" or target == "../"
end

local function damaging_git(command_segments)
	for _, segment in ipairs(command_segments) do
		local words = shell_words(segment)
		if words and words[1] == "git" then
			for _, rule in ipairs(git_damaging) do
				for i = 2, #words do
					if words[i] == rule[1] then
						for j = i + 1, #words do
							if words[j] == rule[2] or words[j]:sub(1, #rule[2]) == rule[2] then
								return rule[1] .. " " .. rule[2]
							end
						end
					end
				end
			end
		end
	end
	return nil
end

local function check(command)
	local command_segments = segments(command)
	if not command_segments then
		return nil
	end
	local home = maki.uv.os_homedir() or "/"
	local cwd = maki.uv.cwd() or home
	local destructive_name
	for _, segment in ipairs(command_segments) do
		destructive_name = destructive_verb(verb_of(segment) or "")
		if destructive_name then
			break
		end
	end
	if destructive_name then
		for _, token in ipairs(tokens(command)) do
			local hit = protected_target(token, home, cwd)
			if hit then
				return ("refused: `%s` targets %s. Run it outside the agent if it is really wanted."):format(destructive_name, hit)
			end
		end
	end
	local git = damaging_git(command_segments)
	if git then
		return ("refused: `git %s` discards work with no undo. Run it outside the agent if it is really wanted."):format(git)
	end
	if destructive_name then
		for _, segment in ipairs(command_segments) do
			if destructive_verb(verb_of(segment) or "") then
				local named = delete_targets(segment, destructive_name)
				local blind = #named == 0
				for _, target in ipairs(named) do
					if is_blind(target) then
						blind = true
					end
				end
				if blind then
					return ("refused: `%s` names no single path, so it would take the working directory. Name the path."):format(destructive_name)
				end
			end
		end
	end
	return nil
end

maki.api.set_slot("tool.bash.input", function(prev, input, ctx)
	if type(input) == "table" and type(input.command) == "string" then
		local reason = check(input.command)
		if reason then
			return nil, reason
		end
	end
	return prev(input, ctx)
end)
