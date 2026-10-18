local binary = "/home/danil/.local/bin/ast-grep"
local max_results = 100

local function project_root()
	local cwd = maki.uv.cwd()
	return maki.fs.root(cwd, { ".git", "go.work", "Cargo.toml", "package.json", "pyproject.toml" }) or cwd
end

local function safe_paths(paths)
	local root = project_root()
	local resolved = {}
	for _, path in ipairs(paths or { "." }) do
		if path:sub(1, 1) == "/" or path:match("^[A-Za-z]:") then
			return nil, "paths must be relative to the project root"
		end
		local full = maki.fs.normalize(maki.fs.joinpath(root, path))
		local relative = maki.fs.relpath(root, full)
		if not relative or relative == ".." or relative:match("^%.%./") then
			return nil, "path escapes the project root: " .. path
		end
		resolved[#resolved + 1] = relative == "." and root or full
	end
	return root, resolved
end

local function run(args, cwd)
	local id, err = maki.fn.jobstart(args, { cwd = cwd, scope = "task", tail = 1024 })
	if not id then
		return nil, err
	end
	local result, wait_err = maki.fn.jobwait(id, 30000)
	if not result then
		return nil, wait_err or "ast-grep timed out"
	end
	if result.exit_code ~= 0 and result.exit_code ~= 1 then
		return nil, result.stderr ~= "" and result.stderr or result.stdout
	end
	if result.truncated then
		return nil, "ast-grep output exceeded the capture limit"
	end
	return result.stdout, nil, result.exit_code
end

local function parse_matches(output)
	local ok, matches = pcall(maki.json.decode, output)
	if not ok or type(matches) ~= "table" then
		return nil, "could not parse ast-grep JSON output"
	end
	return matches
end

local function make_args(input, rewrite)
	local args = { binary, "run", "--pattern", input.pattern, "--lang", input.language, "--json=compact" }
	if rewrite then
		args[#args + 1] = "--rewrite"
		args[#args + 1] = input.rewrite
	end
	for _, glob in ipairs(input.globs or {}) do
		args[#args + 1] = "--globs"
		args[#args + 1] = glob
	end
	for _, path in ipairs(input._paths) do
		args[#args + 1] = path
	end
	return args
end

local function format_matches(matches, include_replacement)
	local lines = { "Matches: " .. #matches }
	local shown = math.min(#matches, max_results)
	for i = 1, shown do
		local m = matches[i]
		local start = m.range and m.range.start or {}
		local line = (m.file or "?") .. ":" .. tostring((start.line or 0) + 1) .. ":" .. tostring((start.column or 0) + 1)
		lines[#lines + 1] = line
		lines[#lines + 1] = "  " .. ((m.lines or m.text or ""):gsub("\n+$", ""))
		if include_replacement then
			lines[#lines + 1] = "  -> " .. tostring(m.replacement or "")
		end
	end
	if #matches > shown then
		lines[#lines + 1] = "Output limited to " .. max_results .. " matches."
	end
	return table.concat(lines, "\n")
end

local path_schema = {
	type = "array",
	items = { type = "string" },
	description = "Relative paths under the project root; defaults to the project root.",
}
local glob_schema = {
	type = "array",
	items = { type = "string" },
	description = "ast-grep glob filters.",
}

maki.api.register_tool({
	name = "ast_grep_search",
	kind = "search",
	permission = "run",
	description = "Search source code by ast-grep AST pattern and return matching locations and snippets. Use before rewriting to inspect what will match.",
	schema = {
		type = "object",
		properties = {
			pattern = { type = "string", description = "AST pattern; use $NAME for a single-node wildcard and $$$NAME for multiple nodes.", required = true },
			language = { type = "string", description = "Source language, such as rust, lua, go, python, javascript, or typescript.", required = true },
			paths = path_schema,
			globs = glob_schema,
		},
		required = { "pattern", "language" },
	},
	handler = function(input)
		if type(input.pattern) ~= "string" or input.pattern == "" or type(input.language) ~= "string" or input.language == "" then
			return { llm_output = "error: pattern and language are required", is_error = true }
		end
		local root, paths_or_err = safe_paths(input.paths)
		if not root then
			return { llm_output = "error: " .. paths_or_err, is_error = true }
		end
		input._paths = paths_or_err
		local output, err, code = run(make_args(input), root)
		if not output then
			return { llm_output = "error: " .. tostring(err), is_error = true }
		end
		local matches, parse_err = parse_matches(output)
		if not matches then
			return { llm_output = "error: " .. parse_err, is_error = true }
		end
		if code == 1 or #matches == 0 then
			return "No matches found."
		end
		return format_matches(matches, false)
	end,
})

maki.api.register_tool({
	name = "ast_grep_rewrite",
	kind = "execute",
	permission = "run",
	description = "Preview an ast-grep structural rewrite by default. Set apply=true to write all matching changes; always inspect the preview first.",
	schema = {
		type = "object",
		properties = {
			pattern = { type = "string", description = "AST pattern to match.", required = true },
			rewrite = { type = "string", description = "Replacement pattern using metavariables captured by pattern.", required = true },
			language = { type = "string", description = "Source language, such as rust, lua, go, python, javascript, or typescript.", required = true },
			paths = path_schema,
			globs = glob_schema,
			apply = { type = "boolean", description = "Must be true to apply changes; false or omitted only previews." },
		},
		required = { "pattern", "rewrite", "language" },
	},
	handler = function(input)
		if type(input.pattern) ~= "string" or input.pattern == "" or type(input.rewrite) ~= "string" or type(input.language) ~= "string" or input.language == "" then
			return { llm_output = "error: pattern, rewrite, and language are required", is_error = true }
		end
		local root, paths_or_err = safe_paths(input.paths)
		if not root then
			return { llm_output = "error: " .. paths_or_err, is_error = true }
		end
		input._paths = paths_or_err
		local output, err = run(make_args(input, input.rewrite), root)
		if not output then
			return { llm_output = "error: " .. tostring(err), is_error = true }
		end
		local matches, parse_err = parse_matches(output)
		if not matches then
			return { llm_output = "error: " .. parse_err, is_error = true }
		end
		if #matches == 0 then
			return "No matches found."
		end
		if input.apply ~= true then
			return "Preview only; no files changed.\n" .. format_matches(matches, true) .. "\nCall again with apply=true to apply this rewrite."
		end
		local args = { binary, "run", "--pattern", input.pattern, "--lang", input.language, "--rewrite", input.rewrite, "--update-all" }
		for _, glob in ipairs(input.globs or {}) do
			args[#args + 1] = "--globs"
			args[#args + 1] = glob
		end
		for _, path in ipairs(paths_or_err) do
			args[#args + 1] = path
		end
		local applied, apply_err = run(args, root)
		if not applied then
			return { llm_output = "error applying rewrite: " .. tostring(apply_err), is_error = true }
		end
		return "Applied rewrite to " .. #matches .. " match(es).\n" .. format_matches(matches, true)
	end,
})
