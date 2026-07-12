-- Runtime: enable treesitter for any filetype whose parser is present. c/lua/
-- vim/vimdoc/markdown*/query are compiled into neovim; the rest come from
-- :TSBuild below. Filetypes without a parser fall back to regex syntax.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      vim.treesitter.start()
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldlevel = 99
    end
  end,
})

-- :TSBuild — compile parsers into site/parser without any plugin or git clone.
-- Each grammar's parser.c is fetched as a GitHub tarball (curl) at a pinned
-- revision and compiled with cc. Queries are vendored in config/queries/ (see
-- the repo), so they are not touched here. Pins came once from nvim-treesitter's
-- parsers.lua; bump a revision here to update a parser. Requires: curl, tar, cc.
-- { lang, owner/repo, revision-or-tag, subdir? }
local GRAMMARS = {
  { "go", "tree-sitter/tree-sitter-go", "2346a3ab1bb3857b48b29d779a1ef9799a248cd7" },
  { "gomod", "camdencheek/tree-sitter-go-mod", "2e886870578eeba1927a2dc4bd2e2b3f598c5f9a" },
  { "gosum", "tree-sitter-grammars/tree-sitter-go-sum", "27816eb6b7315746ae9fcf711e4e1396dc1cf237" },
  { "gowork", "omertuc/tree-sitter-go-work", "949a8a470559543857a62102c84700d291fc984c" },
  { "yaml", "tree-sitter-grammars/tree-sitter-yaml", "4463985dfccc640f3d6991e3396a2047610cf5f8" },
  { "json", "tree-sitter/tree-sitter-json", "001c28d7a29832b06b0e831ec77845553c89b56d" },
  { "toml", "tree-sitter-grammars/tree-sitter-toml", "64b56832c2cffe41758f28e05c756a3a98d16f41" },
  { "bash", "tree-sitter/tree-sitter-bash", "a06c2e4415e9bc0346c6b86d401879ffb44058f7" },
  { "python", "tree-sitter/tree-sitter-python", "v0.25.0" },
  { "rust", "tree-sitter/tree-sitter-rust", "77a3747266f4d621d0757825e6b11edcbf991ca5" },
  { "dockerfile", "camdencheek/tree-sitter-dockerfile", "971acdd908568b4531b0ba28a445bf0bb720aba5" },
  { "hcl", "tree-sitter-grammars/tree-sitter-hcl", "64ad62785d442eb4d45df3a1764962dafd5bc98b" },
  { "terraform", "MichaHoffmann/tree-sitter-hcl", "64ad62785d442eb4d45df3a1764962dafd5bc98b", "dialects/terraform" },
  { "proto", "coder3101/tree-sitter-proto", "d65a18ce7c2242801f702770114ad08056c7f8c9" },
  { "helm", "ngalaiko/tree-sitter-go-template", "aa71f63de226c5592dfbfc1f29949522d7c95fac", "dialects/helm" },
}

local function run(cmd, cwd)
  local r = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if r.code ~= 0 then
    error(("%s failed: %s"):format(cmd[1], (r.stderr or r.stdout or ""):gsub("%s+$", "")))
  end
  return r.stdout
end

local function build()
  local parser_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser")
  local cxxlib = vim.uv.os_uname().sysname == "Darwin" and "-lc++" or "-lstdc++"
  vim.fn.mkdir(parser_dir, "p")
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")

  -- each grammar is isolated in pcall: one failure (404, tar, cc) is reported and
  -- skipped, not fatal to the rest, and the tmp dir is always cleaned up below.
  local failed = {}
  for _, g in ipairs(GRAMMARS) do
    local lang, repo, rev, subdir = g[1], g[2], g[3], g[4]
    vim.notify("==> " .. lang)
    local ok, err = pcall(function()
      local dir = vim.fs.joinpath(tmp, lang)
      vim.fn.mkdir(dir, "p")
      local tgz = dir .. ".tar.gz"
      run({ "curl", "-sfL", "-o", tgz, ("https://github.com/%s/archive/%s.tar.gz"):format(repo, rev) })
      run({ "tar", "xzf", tgz, "-C", dir, "--strip-components=1" })

      local src = vim.fs.joinpath(dir, subdir or "", "src")
      if vim.fn.filereadable(vim.fs.joinpath(src, "parser.c")) == 0 then
        -- ponytail: grammars without a committed parser.c need `tree-sitter
        -- generate` + the CLI. None in GRAMMARS today; add the step if one appears.
        error("no parser.c")
      end
      local args = { "cc", "-O2", "-fPIC", "-shared", "-I", src, vim.fs.joinpath(src, "parser.c") }
      if vim.fn.filereadable(vim.fs.joinpath(src, "scanner.c")) == 1 then
        table.insert(args, vim.fs.joinpath(src, "scanner.c"))
      end
      if vim.fn.filereadable(vim.fs.joinpath(src, "scanner.cc")) == 1 then
        table.insert(args, vim.fs.joinpath(src, "scanner.cc"))
        table.insert(args, cxxlib)
      end
      vim.list_extend(args, { "-o", vim.fs.joinpath(parser_dir, lang .. ".so") })
      run(args)
    end)
    if not ok then
      failed[#failed + 1] = lang
      vim.notify(("  %s failed: %s"):format(lang, err), vim.log.levels.WARN)
    end
  end

  vim.fn.delete(tmp, "rf")
  if #failed > 0 then
    vim.notify(("done with errors — failed: %s\nparsers: %s"):format(table.concat(failed, ", "), parser_dir),
      vim.log.levels.WARN)
  else
    vim.notify("done — parsers: " .. parser_dir)
  end
end

vim.api.nvim_create_user_command("TSBuild", build, { desc = "Build treesitter parsers + queries" })
