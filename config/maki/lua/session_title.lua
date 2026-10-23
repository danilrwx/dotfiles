local sessions = {}
local ListPicker = require("maki.list_picker")

local function add_link(state, url, label)
	if state.links and not state.link_seen[url] then
		state.link_seen[url] = true
		state.links[#state.links + 1] = { label = label, url = url }
	end
end

local function card_id(value)
	local text = tostring(value or "")
	if text:match("^%d+$") then
		return text
	end
end

local function add_mr(state, repo, number)
	repo = repo:gsub("virtualization", "v12n")
		:gsub("kubevirt", "kv")
		:gsub("containerized%-data%-importer", "cdi")
		:gsub("architecture%-decision%-records", "adr")
		:gsub("deckhouse", "dh")
	local key = repo .. "-" .. number
	if not state.seen[key] then
		state.seen[key] = true
		state.mrs[#state.mrs + 1] = key
	end
	return key
end

local function scan_text(state, text)
	for scheme, host, raw_path in text:gmatch("(https?)://([%w%.%-]+)(/[^%s<>\"']*)") do
		local path = raw_path:gsub("[%)%]%},;%.!`]+$", "")
		local url = scheme .. "://" .. host .. path
		if host:match("%.kaiten%.ru$") or host:match("%.kaiten%.io$") then
			local card = path:match("^/([0-9]+)%f[%D]")
				or path:match("^/space/%d+/boards%?[^%s]*card=(%d+)")
				or path:match("^/cards/(%d+)%f[%D]")
			state.card = state.card or card
			if card then
				add_link(state, url, "Kaiten " .. card)
			end
		end
		local repo, number = path:match("/([^/]+)/%-/merge_requests/(%d+)%f[%D]")
		if repo then
			local key = add_mr(state, repo, number)
			add_link(state, url, key:gsub("%-(%d+)$", " !%1"))
		end
	end
end

local function scan_input(state, name, input)
	if type(input) ~= "table" then
		return
	end
	if name == "kaiten" or name:match("[_.]kaiten$") then
		state.card = state.card or card_id(input.card_id)
	end
	if type(input.tool_calls) == "table" then
		for _, call in ipairs(input.tool_calls) do
			if type(call) == "table" then
				scan_input(state, call.tool or "", call.parameters)
			end
		end
	end
end

local function scan_result(state, content)
	if type(content) == "string" then
		scan_text(state, content)
	elseif type(content) == "table" then
		for _, block in ipairs(content) do
			if type(block) == "table" and block.type == "text" and type(block.text) == "string" then
				scan_text(state, block.text)
			end
		end
	end
end

local function title_for(state)
	local parts = {}
	if state.card then
		parts[#parts + 1] = "ktn-" .. state.card
	end
	for _, mr in ipairs(state.mrs) do
		parts[#parts + 1] = mr
	end
	return table.concat(parts, "-")
end

local function restore(title)
	local state = { mrs = {}, seen = {} }
	local normalized = title:gsub("^kaiten%-", "ktn-")
	state.card = normalized:match("^ktn%-(%d+)$") or normalized:match("^ktn%-(%d+)%-")
	local rest = state.card and normalized:gsub("^ktn%-%d+%-?", "") or normalized
	while rest ~= "" do
		local repo, number, remaining = rest:match("^(.-)%-MR(%d+)(.*)$")
		if not repo then
			repo, number, remaining = rest:match("^(.-)%-(%d+)(.*)$")
		end
		if not repo or repo == "" or (remaining ~= "" and remaining:sub(1, 1) ~= "-") then
			break
		end
		add_mr(state, repo, number)
		rest = remaining:sub(2)
	end
	return state
end

local function scan_messages(state, messages)
	for _, message in ipairs(messages) do
		if message.kind == "turn" and not message.hidden then
			for _, block in ipairs(message.content or {}) do
				if block.type == "text" and type(block.text) == "string" then
					scan_text(state, block.text)
				elseif block.type == "tool_use" then
					scan_input(state, block.name or "", block.input)
				elseif block.type == "tool_result" and not block.is_error then
					scan_result(state, block.content)
				end
			end
		end
	end
end

local function open_links()
	local messages, err = maki.session.messages()
	if not messages then
		maki.ui.flash("links: " .. tostring(err))
		return
	end
	local state = { mrs = {}, seen = {}, links = {}, link_seen = {} }
	scan_messages(state, messages)
	if #state.links == 0 then
		maki.ui.flash("links: no Kaiten cards or MRs in this session")
		return
	end
	local choice = ListPicker.open(state.links, { title = "Session links" })
	if not choice or choice.type ~= "choice" or not choice.item then
		return
	end
	local platform_job, platform_err = maki.fn.jobstart({ "uname", "-s" })
	if not platform_job then
		maki.ui.flash("links: " .. tostring(platform_err))
		return
	end
	local platform, wait_err = maki.fn.jobwait(platform_job)
	if not platform or platform.exit_code ~= 0 then
		maki.ui.flash("links: uname failed: " .. tostring(wait_err or (platform and platform.stderr)))
		return
	end
	local opener = platform.stdout:match("Darwin") and "open" or platform.stdout:match("Linux") and "xdg-open"
	if not opener or maki.fn.executable(opener) ~= 1 then
		maki.ui.flash("links: no supported URL opener (xdg-open/open)")
		return
	end
	local _, open_err = maki.fn.jobstart({ opener, choice.item.url }, { stdout = false, stderr = false })
	if open_err then
		maki.ui.flash("links: " .. open_err)
	end
end

maki.api.register_command({
	name = "/links",
	description = "Pick a Kaiten card or MR URL mentioned in this session",
	handler = open_links,
})

maki.keymap.set("n", "<C-k>", open_links, { desc = "Open session links" })

maki.api.create_autocmd("TurnEnd", {
	callback = function(ev)
		local id = ev.data and ev.data.session_id
		if not id then
			return
		end
		local snapshot = maki.session.read({ session = id })
		local current_title = snapshot and snapshot.title or ""
		local state = sessions[id] or restore(current_title)
		sessions[id] = state
		local messages, err = maki.session.messages({ session = id })
		if not messages then
			maki.log.warn("session_title: " .. tostring(err))
			return
		end
		scan_messages(state, messages)
		local title = title_for(state)
		if title ~= "" and title ~= current_title then
			local _, rename_err = maki.session.set_title({ id = id, title = title })
			if rename_err then
				maki.log.warn("session_title: " .. rename_err)
			end
		end
	end,
})

maki.api.create_autocmd("SessionEnd", {
	callback = function(ev)
		local id = ev.data and ev.data.session_id
		if id then
			sessions[id] = nil
		end
	end,
})
