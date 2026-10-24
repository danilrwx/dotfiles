-- herdr: maki's pane in herdr's sidebar. Maki in a herdr pane reports its own
-- state and the command that resumes the session, instead of leaving herdr to
-- read it off the screen: the states line up one to one, and herdr runs the
-- resume command after its server restarts, so the conversation comes back.
--
--   working      → working
--   needs_input  → blocked
--   idle         → idle
--
-- The interface is herdr's "Add Herdr support to your agent": report-agent, with
-- --seq that must only grow, and the resume command after --. Outside herdr
-- (HERDR_ENV unset) nothing here runs.

local bin = maki.uv.os_getenv("HERDR_BIN_PATH")
local pane = maki.uv.os_getenv("HERDR_PANE_ID")
if maki.uv.os_getenv("HERDR_ENV") ~= "1" or not bin or not pane then
	return
end

local STATES = {
	working = "working",
	needs_input = "blocked",
	idle = "idle",
}

local seq = 0
local sent -- the last state and session, so a repeat is not reported twice
local warned = false

-- herdr keeps the highest --seq it has seen and drops anything that does not beat
-- it, so a late report cannot overwrite a newer one: wall-clock seconds carry
-- across maki restarts, the counter orders reports inside one second
local function next_seq()
	seq = seq + 1
	return os.time() * 1000 + seq % 1000
end

-- fire and forget: a report must not hold up a turn, and a failed one is only
-- worth a single warning, herdr's own detection stays as the fallback
local function run(argv)
	local ok, id, err = pcall(maki.fn.jobstart, argv, { scope = "plugin", stdout = false, stderr = false })
	if (not ok or not id) and not warned then
		warned = true
		maki.log.warn("herdr: report failed: " .. tostring(ok and err or id))
	end
end

local function report(state, sid, message)
	local argv = { bin, "pane", "report-agent", pane, "--source", "maki", "--agent", "maki",
		"--state", state, "--seq", tostring(next_seq()), "--agent-session-id", sid }
	if message and message ~= "" then
		argv[#argv + 1] = "--message"
		argv[#argv + 1] = message:sub(1, 60)
	end
	-- the command herdr runs after a server restart, in the pane's directory
	argv[#argv + 1] = "--"
	argv[#argv + 1] = "maki"
	argv[#argv + 1] = "--resume"
	argv[#argv + 1] = sid
	run(argv)
end

local function current()
	return maki.session.current()
end

maki.api.create_autocmd("SessionStatusChanged", {
	callback = function(ev)
		local data = ev.data or {}
		local state = STATES[data.status]
		local sid = data.session_id or current()
		if not state or not sid then
			return
		end
		local key = state .. " " .. sid
		if key == sent then
			return
		end
		sent = key
		report(state, sid, state == "blocked" and data.title or nil)
	end,
})

-- another session in the same pane, or the last one closed: herdr has to resume
-- the session that is there now, so the resume command follows it, state untouched
maki.api.create_autocmd({ "SessionFocusChanged", "SessionReset", "SessionEnd" }, {
	callback = function()
		sent = nil
		local sid = current()
		if not sid then
			run({ bin, "pane", "release-agent", pane, "--source", "maki", "--agent", "maki",
				"--seq", tostring(next_seq()) })
			return
		end
		run({ bin, "pane", "report-agent-session", pane, "--source", "maki", "--agent", "maki",
			"--seq", tostring(next_seq()), "--agent-session-id", sid,
			"--", "maki", "--resume", sid })
	end,
})
