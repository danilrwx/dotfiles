-- golangci-lint auto-fix, after pi's: when a turn ends, run `golangci-lint
-- run --fix` over the Go files maki just touched, and report the result to the
-- session as a follow-up. Only fires when Go was actually edited, so a pure
-- reading turn stays quiet.

local touched = {}
local running = false

local function go_files()
	local out = {}
	for f in pairs(touched) do
		if f:match("%.go$") then
			out[#out + 1] = f
		end
	end
	return out
end

-- the git root that contains a file, so golangci-lint runs in the right module
local function repo_root(file)
	local dir = maki.fs.dirname(file)
	local files = maki.fs.glob("**/go.mod", { path = dir, limit = 200 })
	for _, g in ipairs(files or {}) do
		local root = maki.fs.dirname(g)
		if maki.fs.relpath(root, file) and not maki.fs.relpath(root, file):match("^%.%.") then
			return root
		end
	end
	return dir
end

maki.api.create_autocmd("ToolDone", {
	callback = function(ev)
		local tool = ev.data and ev.data.tool
		local input = ev.data and ev.data.input
		if not input then
			return
		end
		local path = input.path or (input.file and input.file.path)
		if path and (tool == "write" or tool == "edit" or tool == "multiedit"
			or tool == "edit_lines" or tool == "bash") then
			touched[path] = true
		end
	end,
})

maki.api.create_autocmd("TurnEnd", {
	callback = function()
		local files = go_files()
		if #files == 0 or running then
			return
		end
		running = true
		-- dedupe by repo root: one golangci-lint per module
		local roots, seen = {}, {}
		for _, f in ipairs(files) do
			local r = repo_root(f)
			if not seen[r] then
				seen[r] = true
				roots[#roots + 1] = r
			end
		end
		maki.async.run(function()
			local report = {}
			for _, root in ipairs(roots) do
				local id = maki.fn.jobstart(
					{ "sh", "-c", "golangci-lint run --fix --timeout 5m ./... 2>&1" },
					{ cwd = root, scope = "plugin" })
				if not id then
					report[#report + 1] = root .. ": could not start golangci-lint"
				else
					local out = maki.fn.jobwait(id, 300000)
					local text = (out and (out.stdout or "")) or ""
					if text:match("%S") then
						report[#report + 1] = root .. ":\n" .. text
					end
				end
			end
			touched = {}
			running = false
			if #report > 0 then
				local body = "[golangci-lint] auto-fix after the last turn:\n\n"
					.. table.concat(report, "\n\n")
				maki.session.notify(body, { wake = false })
				maki.log.info("golangci-lint: " .. #report .. " module(s) reported")
			end
		end)
	end,
})
