-- /handoff, after pi's: distil the current session into a short brief and start a
-- fresh session from it, so a long thread keeps moving without dragging its whole
-- history. A throwaway subagent writes the brief from the transcript, so the main
-- model is not spent on it. With no argument it hands off the last state as-is;
-- with a goal it steers the new session.
--
--   /handoff                     brief the current work, new session
--   /handoff доделай тесты         brief + a goal for the new session

local BRIEF_SYSTEM = [[
You write handoff briefs. From the conversation given, reply with ONLY the brief,
no preamble, in this shape:

## Goal
The original task in one or two lines.

## Done
What was already accomplished (files changed, decisions made, what works).

## Next
The concrete next steps to finish the job.

## Context
Anything the new session must know: paths, constraints, open questions, gotchas.

Keep it under ~30 lines. Be concrete and factual; do not plan new work.
]]

local function transcript_text(session)
	local msgs, err = maki.session.messages({ session = session, last = 60 })
	if not msgs then
		return nil, err
	end
	local parts = {}
	for _, m in ipairs(msgs) do
		if type(m.content) == "table" then
			for _, b in ipairs(m.content) do
				if b.type == "text" and b.text and b.text:match("%S") then
					parts[#parts + 1] = (m.role == "user" and "[user] " or "[assistant] ") .. b.text
				elseif b.type == "tool_use" then
					parts[#parts + 1] = "[tool] " .. tostring(b.name)
						.. (b.input and b.input.path and (" " .. b.input.path) or "")
				end
			end
		end
	end
	local text = table.concat(parts, "\n")
	if #text > 16000 then
		text = text:sub(-16000)
	end
	return text
end

local function brief(session, goal)
	local text, terr = transcript_text(session)
	if not text or not text:match("%S") then
		return nil, terr or "nothing to hand off yet"
	end
	-- a subagent with no tools: it only reads the transcript and writes the brief
	local sub, serr = maki.agent.session({
		session = session,
		name = "handoff-brief",
		system = BRIEF_SYSTEM,
	})
	if not sub then
		return nil, serr
	end
	local prompt = text
	if goal and goal:match("%S") then
		prompt = prompt .. "\n\nThe new session will be asked to: " .. goal
			.. " Reflect that in the Next section."
	end
	local res, perr = sub:prompt(prompt)
	sub:close()
	if perr then
		return nil, perr
	end
	local brief = res and res.text
	return brief and brief:match("^%s*(.-)%s*$") or nil, nil
end

maki.api.register_command({
	name = "/handoff",
	description = "Brief the current session and continue in a fresh one (args = the goal)",
	nargs = "*",
	handler = function(opts)
		local goal = opts.args
		local session = maki.session.current()
		if not session then
			maki.ui.flash("handoff: no focused session")
			return
		end
		maki.ui.flash("handoff: writing brief…")
		local b, err = brief(session, goal)
		if not b then
			maki.ui.flash("handoff: " .. tostring(err))
			return
		end
		local parent = maki.session.read({ session = session })
		local parent_label = parent and parent.title or "session"
		local id, nerr = maki.session.new({
			focus = true,
			prompt = "Continue from this handoff brief:\n\nParent Maki session: " .. session
				.. " (" .. parent_label .. ")\n\n" .. b,
		})
		if not id then
			maki.ui.flash("handoff: " .. tostring(nerr))
			return
		end
		maki.session.set_title({ id = id, title = "handoff from " .. session:sub(1, 8) .. ": " .. (goal:match("%S") and goal or "continued") })
		maki.ui.flash("handoff: new session ready")
	end,
})
