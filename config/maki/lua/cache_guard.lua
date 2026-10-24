-- /cache — живая телеметрия prompt-кэша: hit% по ходам, алерты на промахи,
-- отметки о компакции. Считается по usage из autocmd TurnEnd, без чтения файлов.
--
--   после хода: молча копит статистику
--   промах:     one-line notice, если hit% провалился относительно прошлого хода
--   /cache:     история последних ходов текущей сессии

local GAP = "  "
local BAR_W = 8
local FRACS = { "", "▏", "▎", "▍", "▌", "▋", "▊", "▉" }

-- порог «шумного» хода: на коротком промпте hit% скачет случайно
local COLD_MIN_PROMPT = 4000
-- промах: hit% ниже этой доли при достаточном объёме промпта
local COLD_HIT = 0.5
-- резкое падение относительно предыдущего хода (иначе это просто новый кэш)
local DROP = 0.35

local history = {} -- session_id -> { turns = {...}, cold = 0, avg = 0 }
local order = {} -- session_id в порядке первого хода

local function fmt_money(v)
	return string.format("$%.2f", v or 0)
end

local function fmt_tokens(n)
	n = n or 0
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fk", n / 1e3)
	end
	return tostring(n)
end

local function fit(s, w)
	s = tostring(s or "")
	if maki.ui.display_width(s) <= w then
		return s
	end
	if w <= 1 then
		return "…"
	end
	return maki.ui.truncate_text(s, w - 1).head .. "…"
end

local function wpad(s, w, align)
	s = fit(s, w)
	local pad = math.max(0, w - maki.ui.display_width(s))
	if align == "right" then
		return string.rep(" ", pad) .. s
	end
	return s .. string.rep(" ", pad)
end

local function bar(hit)
	local filled = math.max(0, math.min(BAR_W, hit * BAR_W))
	local full = math.floor(filled)
	local frac = math.floor((filled - full) * 8 + 0.5)
	if frac >= 8 then
		full, frac = full + 1, 0
	end
	full = math.min(full, BAR_W)
	local head = string.rep("█", full) .. (full < BAR_W and FRACS[frac + 1] or "")
	local used = full + (frac > 0 and full < BAR_W and 1 or 0)
	return head .. string.rep(" ", math.max(0, BAR_W - used))
end

local function pct(hit)
	return math.floor(hit * 100 + 0.5) .. "%"
end

local function now()
	local ok, t = pcall(function()
		return os.time()
	end)
	return ok and t or 0
end

local function spans_width(spans)
	local w = 0
	for _, s in ipairs(spans) do
		w = w + maki.ui.display_width(type(s) == "table" and s[1] or s)
	end
	return w
end

local function entry_for(session)
	local h = history[session]
	if not h then
		h = { turns = {}, cold = 0 }
		history[session] = h
		order[#order + 1] = session
	end
	return h
end

-- ---------- реакция на события ----------

maki.api.create_autocmd("TurnEnd", {
	callback = function(ev)
		local d = ev.data or {}
		local u = d.usage or {}
		local input = u.input_tokens or 0
		local cr = u.cache_read_input_tokens or 0
		local cc = u.cache_creation_input_tokens or 0
		local output = u.output_tokens or 0
		local prompt = input + cr + cc
		if prompt <= 0 then
			return
		end

		local session = d.session_id or "?"
		local h = entry_for(session)
		local prev = h.turns[#h.turns]
		local hit = cr / prompt

		local cold = false
		if
			prev
			and d.reason ~= "cancelled"
			and prompt >= COLD_MIN_PROMPT
			and hit < COLD_HIT
			and (prev.hit - hit) >= DROP
		then
			cold = true
			h.cold = h.cold + 1
		end

		h.turns[#h.turns + 1] = {
			hit = hit,
			prompt = prompt,
			input = input,
			cr = cr,
			output = output,
			cost = d.cost or 0,
			cold = cold,
			reason = d.reason,
			ts = now(),
		}
		if #h.turns > 2000 then
			table.remove(h.turns, 1)
		end

		if cold then
			maki.notify(
				string.format(
					"cache dropped to %s (was %s) on %s prompt — context rewritten?",
					pct(hit),
					pct(prev.hit),
					fmt_tokens(prompt)
				),
				"warn"
			)
		end
	end,
})

maki.api.create_autocmd("AutoCompacting", {
	callback = function()
		maki.notify("compacting context — prompt cache will reset", "info")
	end,
})

maki.api.create_autocmd("CompactionDone", {
	callback = function(ev)
		local d = ev.data or {}
		maki.notify(
			string.format(
				"compaction done (%s → %s) — prompt cache starts over",
				fmt_tokens(d.context_size_before),
				fmt_tokens(d.context_size_after)
			),
			"warn"
		)
	end,
})

-- ---------- команда ----------

local function current()
	local id = maki.session.current()
	if id and history[id] then
		return id
	end
	for i = #order, 1, -1 do
		if history[order[i]] then
			return order[i]
		end
	end
	return nil
end

local function add_rows(lines, id, accent)
	local h = history[id]
	local n = #h.turns
	local from = math.max(1, n - 9)
	local total_cost, total_hit, total_prompt = 0, 0, 0
	for _, t in ipairs(h.turns) do
		total_cost = total_cost + t.cost
		total_prompt = total_prompt + t.prompt
		total_hit = total_hit + t.hit * t.prompt
	end
	local avg = total_prompt > 0 and (total_hit / total_prompt) or 0

	lines[#lines + 1] = {
		{ fmt_money(total_cost), { fg = accent, bold = true } },
		{
			" · " .. n .. " turns · " .. pct(avg) .. " cached · " .. h.cold .. " cold",
			"dim",
		},
	}
	lines[#lines + 1] = ""

	local hdr = {
		{ GAP .. wpad("TURN", 4, "right"), "dim" },
		{ GAP .. wpad("PROMPT", 8, "right"), "dim" },
		{ GAP .. wpad("HIT", BAR_W + 5, "left"), "dim" },
		{ GAP .. wpad("COST", 8, "right"), "dim" },
		{ GAP .. wpad("OUT", 7, "right"), "dim" },
	}
	lines[#lines + 1] = hdr
	lines[#lines + 1] = { { string.rep("─", spans_width(hdr)), "dim" } }

	for i = from, n do
		local t = h.turns[i]
		lines[#lines + 1] = {
			{ GAP .. wpad(tostring(i), 4, "right"), "dim" },
			{ GAP .. wpad(fmt_tokens(t.prompt), 8, "right"), "dim" },
			{ GAP .. bar(t.hit) .. " " .. wpad(pct(t.hit), 4, "right"), t.cold and { fg = "red" } or "dim" },
			{ GAP .. wpad(fmt_money(t.cost), 8, "right"), "dim" },
			{ GAP .. wpad(fmt_tokens(t.output), 7, "right"), "dim" },
		}
	end
end

maki.api.register_command({
	name = "/cache",
	description = "Prompt-cache hit history for this session",
	handler = function()
		local accent = maki.ui.theme_color("accent") or "3"
		local id = current()
		local lines = {}

		if not id then
			maki.ui.flash("cache: no turns recorded in this process yet")
			return
		end
		add_rows(lines, id, accent)

		local buf = maki.ui.buf()
		buf:set_lines(lines)
		local cols = maki.ui.terminal_size().cols
		local content_w = 0
		for _, line in ipairs(buf:get_lines()) do
			local w = 0
			if type(line) == "table" then
				for _, span in ipairs(line) do
					w = w + maki.ui.display_width(type(span) == "table" and span[1] or span)
				end
			else
				w = maki.ui.display_width(line)
			end
			content_w = math.max(content_w, w)
		end

		local win = maki.ui.open_win(buf, {
			title = "Cache",
			width = math.min(content_w + 4, cols - 2),
			height = math.min(#lines + 2, 20),
			border = "rounded",
			footer = { { "q", "close" } },
		})
		while true do
			local ev = win:recv()
			if not ev or ev.type == "close" then
				break
			end
			if ev.type == "key" and (ev.key == "q" or ev.key == "<Esc>") then
				break
			end
		end
		win:close()
	end,
})
