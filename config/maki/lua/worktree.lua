-- worktree: a worktree the agent itself makes with `git worktree add` in a bash
-- call is invisible to herdr, which knows only the ones it creates (`prefix+shift+g`,
-- herdr worktree create). After such a call, bin/herdr-worktree-open asks git for
-- the repo's linked worktrees and opens each not yet open as a workspace of its
-- own, labelled by branch. herdr answers already_open for the rest, so running it
-- again changes nothing.
--
-- The check runs only on a bash call whose command mentions both "worktree" and
-- "add": cheap to decide, and no work is done for the usual shell command.

local bin = maki.uv.os_getenv("HERDR_BIN_PATH")
local home = maki.uv.os_homedir()
if maki.uv.os_getenv("HERDR_ENV") ~= "1" or not bin or not home then
	return
end
local script = home .. "/dotfiles/bin/herdr-worktree-open"

local function command_of(input)
	if type(input) ~= "table" then
		return nil
	end
	return input.command or input.cmd
end

maki.api.create_autocmd("ToolDone", {
	callback = function(ev)
		local data = ev.data or {}
		if data.tool ~= "bash" or data.is_error then
			return
		end
		local cmd = command_of(data.input)
		if type(cmd) ~= "string" then
			maki.log.debug("worktree: the bash tool input has no command field, nothing checked")
			return
		end
		if not (cmd:find("worktree", 1, true) and cmd:find("add", 1, true)) then
			return
		end

		local opened = {}
		local ok, id = pcall(maki.fn.jobstart, { script, maki.uv.cwd() }, {
			scope = "plugin",
			stderr = false,
			on_stdout = function(_, line)
				if line and line ~= "" then
					opened[#opened + 1] = line
				end
			end,
			on_exit = function()
				if #opened == 0 then
					return
				end
				local names = {}
				for _, line in ipairs(opened) do
					names[#names + 1] = (line:match("^([^\t]*)"))
				end
				maki.notify("herdr: worktree opened as a workspace: " .. table.concat(names, ", "))
			end,
		})
		if not ok or not id then
			maki.log.warn("herdr: worktree check did not start")
		end
	end,
})
