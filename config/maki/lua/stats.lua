-- /stats — сводная статистика по сессиям, моделям и расходам.
-- Агрегирует данные из session-файлов в state dir (~/.maki/sessions).
-- Периоды считаются по дельтам кумулятивных meta-снапшотов (updated_at).

local GAP = "  "
local BAR_W = 10
local FRACS = { "", "▏", "▎", "▍", "▌", "▋", "▊", "▉" }

local PERIODS = {
	{ label = "All time", days = nil },
	{ label = "Last 7 days", days = 7 },
	{ label = "Last 30 days", days = 30 },
}

local ListPicker = require("maki.list_picker")

-- ---------- форматирование ----------

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

local function bar(v, maxv)
	local filled = 0
	if maxv and maxv > 0 then
		filled = math.max(0, math.min(BAR_W, (v / maxv) * BAR_W))
	end
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

local function short_path(p)
	if not p or p == "" then
		return "?"
	end
	local home = maki.uv.os_homedir()
	if home and #p >= #home and p:sub(1, #home) == home then
		p = "~" .. p:sub(#home + 1)
	end
	return p
end

-- gpt-6-sol / openai/gpt-6-sol -> gpt-6-sol
local function short_model(name)
	return (name:match("([^/]+)$")) or name
end

-- ---------- сбор данных ----------

local function collect()
	local sd = maki.env.state_dir() or maki.env.legacy_dir()
	if not sd then
		return nil, "state dir unavailable"
	end

	local hits, err = maki.fs.grep([["t"\s*:\s*"(header|meta)"]], {
		path = sd .. "/sessions",
		include = "*.jsonl",
		max_line_bytes = 20000,
		limit = 20000,
	})
	if not hits then
		return nil, err
	end

	local entries = {}
	for _, file in ipairs(hits) do
		local p = file.path
		if not p:find("/archive/", 1, true) and not p:find("/locks/", 1, true) then
			local entry = { path = p, header = nil, metas = {} }
			for _, g in ipairs(file.groups) do
				for _, line in ipairs(g.lines) do
					if line.is_match then
						local ok, obj = pcall(maki.json.decode, line.text)
						if ok and type(obj) == "table" then
							if obj.t == "header" then
								entry.header = obj
							elseif obj.t == "meta" then
								entry.metas[#entry.metas + 1] = obj
							end
						end
					end
				end
			end
			table.sort(entry.metas, function(a, b)
				return (a.updated_at or 0) < (b.updated_at or 0)
			end)
			if entry.header or #entry.metas > 0 then
				entries[#entries + 1] = entry
			end
		end
	end
	return entries
end

local function now_ts(entries)
	local ok, t = pcall(function()
		return os.time()
	end)
	if ok and type(t) == "number" then
		return t
	end
	local mx = 0
	for _, e in ipairs(entries) do
		for _, m in ipairs(e.metas) do
			mx = math.max(mx, m.updated_at or 0)
		end
	end
	return mx
end

local function num(v)
	return type(v) == "number" and v or 0
end

local function delta(a, b)
	local d = (num(a) - num(b))
	return d > 0 and d or 0
end

-- ---------- агрегация ----------

local function only_project(entries, project)
	if not project then
		return entries
	end
	local out = {}
	for _, e in ipairs(entries) do
		local cwd = (e.header or {}).cwd or "?"
		if cwd == project then
			out[#out + 1] = e
		end
	end
	return out
end

local COLD_VOLUME = 5000
local COLD_HIT = 0.5

local function aggregate(entries, days, ref_now)
	local cutoff = days and (ref_now - days * 86400) or nil
	local total = { sessions = 0, cost = 0, input = 0, output = 0, cc = 0, cr = 0, cold = 0 }
	local models, projects, topsessions, resets = {}, {}, {}, {}

	for _, e in ipairs(entries) do
		local hdr = e.header or {}
		local cwd = hdr.cwd or "?"
		local prev_tu = {}
		local prev_models = {}
		local sess_cost = 0
		local sess_in, sess_cc, sess_cr = 0, 0, 0
		local cold, cold_miss = 0, 0
		local has_prev = false
		local active = false

		for _, meta in ipairs(e.metas) do
			local ts = meta.updated_at or 0
			local tu = meta.token_usage or {}
			local ubm = meta.usage_by_model or {}

			if not cutoff or ts >= cutoff then
				active = true
				local d_in = delta(tu.input_tokens, prev_tu.input_tokens)
				local d_out = delta(tu.output_tokens, prev_tu.output_tokens)
				local d_cc = delta(tu.cache_creation_input_tokens, prev_tu.cache_creation_input_tokens)
				local d_cr = delta(tu.cache_read_input_tokens, prev_tu.cache_read_input_tokens)

				total.input = total.input + d_in
				total.output = total.output + d_out
				total.cc = total.cc + d_cc
				total.cr = total.cr + d_cr

				sess_in = sess_in + d_in
				sess_cc = sess_cc + d_cc
				sess_cr = sess_cr + d_cr

				-- «холодный» интервал: заметный объём промпта, но кэш не попал.
				-- Первую мету сессии пропускаем: у нового диалога кэша ещё нет.
				local volume = d_in + d_cc + d_cr
				if has_prev and volume >= COLD_VOLUME and d_cr < volume * COLD_HIT then
					cold = cold + 1
					cold_miss = cold_miss + d_in + d_cc
				end

				for name, m in pairs(ubm) do
					m = m or {}
					local pm = prev_models[name] or {}
					local dm_in = delta(m.input, pm.input)
					local dm_out = delta(m.output, pm.output)
					local dm_cc = delta(m.cache_creation, pm.cache_creation)
					local dm_cr = delta(m.cache_read, pm.cache_read)
					local dm_cost = delta(m.cost, pm.cost)

					if dm_in + dm_out + dm_cc + dm_cr + dm_cost > 0 then
						local key = short_model(name)
						local mod = models[key]
						if not mod then
							mod = { cost = 0, input = 0, output = 0, cc = 0, cr = 0, ids = {} }
							models[key] = mod
						end
						mod.cost = mod.cost + dm_cost
						mod.input = mod.input + dm_in
						mod.output = mod.output + dm_out
						mod.cc = mod.cc + dm_cc
						mod.cr = mod.cr + dm_cr
						if not mod.ids[e.path] then
							mod.ids[e.path] = true
							mod.sessions = (mod.sessions or 0) + 1
						end
						sess_cost = sess_cost + dm_cost
					end
				end
			end

			prev_tu = tu
			prev_models = ubm
			has_prev = true
		end

		if active then
			total.sessions = total.sessions + 1
			total.cost = total.cost + sess_cost

			if not projects[cwd] then
				projects[cwd] = { cost = 0, cr = 0, sessions = 0 }
			end
			projects[cwd].cost = projects[cwd].cost + sess_cost
			projects[cwd].sessions = projects[cwd].sessions + 1

			local last = e.metas[#e.metas]
			topsessions[#topsessions + 1] = {
				title = (last and last.title) or hdr.id or e.path,
				model = hdr.model or "?",
				cost = sess_cost,
			}
			-- сессия, где кэш вообще ни разу не сработал (провайдер не отдаёт
			-- cache_read), — это не сброс, а отсутствие кэша: не показываем
			local cached_any = sess_cr > 0
			if cached_any then
				total.cold = total.cold + cold
			end
			local volume = sess_in + sess_cc + sess_cr
			if cold > 0 and cached_any then
				resets[#resets + 1] = {
					title = (last and last.title) or hdr.id or e.path,
					cold = cold,
					hit = volume > 0 and (sess_cr / volume) or 0,
					miss = cold_miss,
				}
			end
		end
	end

	table.sort(topsessions, function(a, b)
		return a.cost > b.cost
	end)
	table.sort(resets, function(a, b)
		if a.cold ~= b.cold then
			return a.cold > b.cold
		end
		return a.miss > b.miss
	end)
	return total, models, projects, topsessions, resets
end

-- глобальные ширины колонок, чтобы не «прыгали» при смене периода
local function global_names(entries)
	local models, projects = {}, {}
	for _, e in ipairs(entries) do
		local hdr = e.header or {}
		projects[(short_path(hdr.cwd))] = true
		for _, meta in ipairs(e.metas) do
			for name in pairs(meta.usage_by_model or {}) do
				models[short_model(name)] = true
			end
		end
	end
	return models, projects
end

local function max_width(set, floor)
	local w = floor
	for name in pairs(set) do
		w = math.max(w, maki.ui.display_width(name))
	end
	return w
end

-- ---------- отрисовка ----------

local function tab_line(idx, accent)
	local spans = {}
	for i, p in ipairs(PERIODS) do
		if i > 1 then
			spans[#spans + 1] = { "  ·  ", "dim" }
		end
		if i == idx then
			spans[#spans + 1] = { p.label, { fg = accent, bold = true } }
		else
			spans[#spans + 1] = { p.label, "dim" }
		end
	end
	return spans
end

local function spans_width(spans)
	local w = 0
	for _, s in ipairs(spans) do
		w = w + maki.ui.display_width(type(s) == "table" and s[1] or s)
	end
	return w
end

-- lay: { share, cache, cache_rd, cache_wr, sess }
local function model_columns(nw, lay)
	local cols = {
		{ label = "COST", width = 8, align = "right", key = "cost", money = true },
		{ label = "INPUT", width = 8, align = "right", key = "input" },
	}
	if lay.cache_rd then
		cols[#cols + 1] = { label = "CACHE RD", width = 9, align = "right", key = "cr" }
	end
	if lay.cache_wr then
		cols[#cols + 1] = { label = "CACHE WR", width = 9, align = "right", key = "cc" }
	end
	cols[#cols + 1] = { label = "OUTPUT", width = 8, align = "right", key = "output" }
	if lay.sess then
		cols[#cols + 1] = { label = "SESS", width = 5, align = "right", key = "sessions" }
	end

	local spans = { { GAP .. wpad("MODEL", nw, "left"), "dim" } }
	if lay.share then
		spans[#spans + 1] = { GAP .. wpad("SHARE", BAR_W, "left"), "dim" }
	end
	for _, c in ipairs(cols) do
		spans[#spans + 1] = { GAP .. wpad(c.label, c.width, c.align), "dim" }
	end
	return spans, cols
end

local function add_models(lines, models, accent, nw, lay)
	local sorted = {}
	for name, m in pairs(models) do
		sorted[#sorted + 1] = {
			name = name,
			cost = m.cost,
			sessions = m.sessions or 0,
			input = m.input,
			output = m.output,
			cr = m.cr,
			cc = m.cc,
		}
	end
	if #sorted == 0 then
		lines[#lines + 1] = { { "No usage in this period", "dim" } }
		return
	end
	table.sort(sorted, function(a, b)
		return a.cost > b.cost
	end)
	local maxc = sorted[1].cost

	lines[#lines + 1] = { { "By model", { fg = accent, bold = true } } }
	local hdr, cols = model_columns(nw, lay)
	lines[#lines + 1] = hdr
	local width = spans_width(hdr)
	lines[#lines + 1] = { { string.rep("─", width), "dim" } }

	for _, m in ipairs(sorted) do
		local spans = { { GAP .. wpad(m.name, nw, "left"), nil } }
		if lay.share then
			spans[#spans + 1] = { GAP .. bar(m.cost, maxc), "dim" }
		end
		for _, c in ipairs(cols) do
			local v = m[c.key]
			local text = c.money and fmt_money(v) or (c.key == "sessions" and tostring(v) or fmt_tokens(v))
			spans[#spans + 1] = {
				GAP .. wpad(text, c.width, c.align),
				c.money and { fg = accent } or "dim",
			}
		end
		lines[#lines + 1] = spans
	end
	lines[#lines + 1] = ""
end

local function add_projects(lines, projects, accent, nw, lay)
	local sorted = {}
	for p, pr in pairs(projects) do
		sorted[#sorted + 1] = { path = short_path(p), cost = pr.cost, sessions = pr.sessions }
	end
	if #sorted == 0 then
		return
	end
	table.sort(sorted, function(a, b)
		return a.cost > b.cost
	end)
	local maxc = sorted[1].cost

	lines[#lines + 1] = { { "By project", { fg = accent, bold = true } } }
	local hdr = { { GAP .. wpad("PROJECT", nw, "left"), "dim" } }
	if lay.share then
		hdr[#hdr + 1] = { GAP .. wpad("SHARE", BAR_W, "left"), "dim" }
	end
	hdr[#hdr + 1] = { GAP .. wpad("COST", 8, "right"), "dim" }
	if lay.sess then
		hdr[#hdr + 1] = { GAP .. wpad("SESS", 5, "right"), "dim" }
	end
	lines[#lines + 1] = hdr
	lines[#lines + 1] = { { string.rep("─", spans_width(hdr)), "dim" } }
	for _, pr in ipairs(sorted) do
		local spans = { { GAP .. wpad(pr.path, nw, "left"), nil } }
		if lay.share then
			spans[#spans + 1] = { GAP .. bar(pr.cost, maxc), "dim" }
		end
		spans[#spans + 1] = { GAP .. wpad(fmt_money(pr.cost), 8, "right"), { fg = accent } }
		if lay.sess then
			spans[#spans + 1] = { GAP .. wpad(tostring(pr.sessions), 5, "right"), "dim" }
		end
		lines[#lines + 1] = spans
	end
	lines[#lines + 1] = ""
end

local function add_top(lines, topsessions, accent, cap)
	if #topsessions == 0 then
		return
	end
	local n = math.min(5, #topsessions)
	local title_w = 0
	for i = 1, n do
		title_w = math.max(title_w, maki.ui.display_width(topsessions[i].title))
	end
	title_w = math.min(title_w, cap + 10)

	lines[#lines + 1] = { { "Top sessions by cost", { fg = accent, bold = true } } }
	for i = 1, n do
		local s = topsessions[i]
		lines[#lines + 1] = {
			{ GAP .. wpad(tostring(i) .. ".", 3, "right") .. "  ", "dim" },
			{ wpad(s.title, title_w, "left"), nil },
			{ GAP .. wpad(fmt_money(s.cost), 8, "right"), { fg = accent } },
			{ GAP .. short_model(s.model), "dim" },
		}
	end
end

local function add_resets(lines, resets, accent, cap)
	if #resets == 0 then
		return
	end
	local n = math.min(5, #resets)
	local title_w = 0
	for i = 1, n do
		title_w = math.max(title_w, maki.ui.display_width(resets[i].title))
	end
	title_w = math.min(title_w, cap + 10)

	lines[#lines + 1] = { { "Cache resets", { fg = accent, bold = true } } }
	local hdr = {
		{ GAP .. wpad("SESSION", 7 + title_w, "left"), "dim" },
		{ GAP .. wpad("COLD", 5, "right"), "dim" },
		{ GAP .. wpad("HIT", 5, "right"), "dim" },
		{ GAP .. wpad("MISS", 9, "right"), "dim" },
	}
	lines[#lines + 1] = hdr
	lines[#lines + 1] = { { string.rep("─", spans_width(hdr)), "dim" } }
	for i = 1, n do
		local r = resets[i]
		lines[#lines + 1] = {
			{ GAP .. wpad(tostring(i) .. ".", 3, "right") .. "  ", "dim" },
			{ wpad(r.title, title_w, "left"), nil },
			{ GAP .. wpad(tostring(r.cold), 5, "right"), "dim" },
			{ GAP .. wpad(math.floor(r.hit * 100 + 0.5) .. "%", 5, "right"), "dim" },
			{ GAP .. wpad(fmt_tokens(r.miss), 9, "right"), { fg = accent } },
		}
	end
	lines[#lines + 1] = ""
end

-- ---------- команда ----------

maki.api.register_command({
	name = "/stats",
	description = "Show usage statistics: periods, models, cache, money",
	handler = function()
		local entries, err = collect()
		if not entries then
			maki.ui.flash("stats: " .. tostring(err))
			return
		end

		local accent = maki.ui.theme_color("accent") or "3"
		local cols = maki.ui.terminal_size().cols
		local ref_now = now_ts(entries)
		local model_set, project_set = global_names(entries)
		local model_w = max_width(model_set, 5)
		local project_w = max_width(project_set, 7)

		-- узкий терминал: убираем колонки по одной, сохраняя выравнивание
		local function layout_for(width)
			local lay = {
				share = width >= 96,
				cache_rd = width >= 84,
				cache_wr = width >= 108,
				sess = width >= 78,
			}
			local fixed = #GAP
			if lay.share then
				fixed = fixed + BAR_W + #GAP
			end
			fixed = fixed + (8 + #GAP) * 3 -- cost, input, output
			if lay.cache_rd then
				fixed = fixed + 9 + #GAP
			end
			if lay.cache_wr then
				fixed = fixed + 9 + #GAP
			end
			if lay.sess then
				fixed = fixed + 5 + #GAP
			end
			return lay, fixed
		end

		local lay, fixed = layout_for(cols)
		local cap = math.max(8, cols - fixed - 4)

		local all_total, _, all_projects = aggregate(entries, nil, ref_now)
		local project_list = {}
		for cwd, pr in pairs(all_projects) do
			project_list[#project_list + 1] = { cwd = cwd, cost = pr.cost, sessions = pr.sessions }
		end
		table.sort(project_list, function(a, b)
			return a.cost > b.cost
		end)
		local project = nil

		local function build(idx)
			local period = PERIODS[idx]
			local total, models, projects, topsessions, resets =
				aggregate(only_project(entries, project), period.days, ref_now)
			local lines = {}

			lines[#lines + 1] = tab_line(idx, accent)
			lines[#lines + 1] = {
				{ "Project: ", "dim" },
				{ project and short_path(project) or "All projects", { fg = accent } },
			}
			lines[#lines + 1] = ""

			local cached = 0
			if total.cr + total.input > 0 then
				cached = math.floor(total.cr / (total.cr + total.input) * 100 + 0.5)
			end
			lines[#lines + 1] = {
				{ fmt_money(total.cost), { fg = accent, bold = true } },
				{
					" · " .. total.sessions .. " sessions · " .. cached .. "% cached"
						.. (total.cold > 0 and (" · " .. total.cold .. " cold turns") or ""),
					"dim",
				},
			}
			lines[#lines + 1] = {
				{ "  " .. fmt_tokens(total.input) .. "↑ in · " .. fmt_tokens(total.output) .. "↓ out · "
					.. fmt_tokens(total.cr) .. " cache read · " .. fmt_tokens(total.cc) .. " cache write", "dim" },
			}
			lines[#lines + 1] = ""

			add_models(lines, models, accent, math.min(model_w, cap), lay)
			if not project then
				add_projects(lines, projects, accent, math.min(project_w, cap), lay)
			end
			add_resets(lines, resets, accent, cap)
			add_top(lines, topsessions, accent, cap)
			return lines
		end

		local idx = 1
		local buf = maki.ui.buf()
		buf:set_lines(build(idx))

		-- ширина окна по самой длинной строке
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
			title = "Stats",
			width = math.min(content_w + 4, cols - 2),
			height = "85%",
			border = "rounded",
			footer = { { "Tab", "period" }, { "p", "project" }, { "q", "close" } },
		})

		while true do
			local ev = win:recv()
			if not ev or ev.type == "close" then
				break
			end
			if ev.type == "key" then
				local k = ev.key
				if k == "q" or k == "<Esc>" then
					break
				elseif k == "<Tab>" or k == "<Right>" or k == "l" then
					idx = idx % #PERIODS + 1
					buf:set_lines(build(idx))
				elseif k == "<S-Tab>" or k == "<Left>" or k == "h" then
					idx = (idx - 2) % #PERIODS + 1
					buf:set_lines(build(idx))
				elseif k == "1" or k == "2" or k == "3" then
					idx = tonumber(k)
					buf:set_lines(build(idx))
				elseif k == "p" or k == "P" then
					local items = {
						{
							label = "All projects",
							detail = fmt_money(all_total.cost) .. " · " .. all_total.sessions .. " sess",
						},
					}
					for _, pr in ipairs(project_list) do
						items[#items + 1] = {
							label = short_path(pr.cwd),
							detail = fmt_money(pr.cost) .. " · " .. pr.sessions .. " sess",
						}
					end
					local cursor = 1
					if project then
						for i, pr in ipairs(project_list) do
							if pr.cwd == project then
								cursor = i + 1
								break
							end
						end
					end
					local res = ListPicker.open(items, {
						title = "Project",
						cursor = cursor,
						footer = { { "<CR>", "select" }, { "<Esc>", "cancel" } },
					})
					if res and res.type == "choice" then
						if res.index and res.index >= 2 and project_list[res.index - 1] then
							project = project_list[res.index - 1].cwd
						else
							project = nil
						end
						buf:set_lines(build(idx))
						win:set_config({
							title = project and ("Stats · " .. short_path(project)) or "Stats",
						})
					end
				end
			elseif ev.type == "resize" and ev.width then
				cols = ev.width
				lay, fixed = layout_for(cols)
				cap = math.max(8, cols - fixed - 4)
				buf:set_lines(build(idx))
			end
		end
		win:close()
	end,
})
