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

-- :TSBuild — install parsers + queries without the nvim-treesitter plugin.
-- It sparse-clones nvim-treesitter as a data source only (pinned url/revision/
-- location per grammar, plus the maintained queries), compiles each parser with
-- cc, and vendors queries into config/queries/. The plugin never loads at
-- runtime and is not kept on disk. Requires: git, cc.
local LANGS = {
  "go", "gomod", "gosum", "gowork", "yaml", "json", "toml", "bash",
  "python", "rust", "dockerfile", "hcl", "terraform", "proto", "helm",
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
  local query_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "queries")
  local cxxlib = vim.uv.os_uname().sysname == "Darwin" and "-lc++" or "-lstdc++"
  vim.fn.mkdir(parser_dir, "p")
  vim.fn.mkdir(query_dir, "p")

  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local nts = vim.fs.joinpath(tmp, "nts")

  vim.notify("cloning nvim-treesitter (data source)…")
  run({ "git", "clone", "-q", "--depth", "1", "--filter=blob:none", "--sparse",
    "https://github.com/nvim-treesitter/nvim-treesitter", nts })
  run({ "git", "-C", nts, "sparse-checkout", "set", "lua/nvim-treesitter", "runtime/queries" })

  vim.opt.runtimepath:append(nts)
  local P = require("nvim-treesitter.parsers")

  for _, lang in ipairs(LANGS) do
    local info = P[lang] and P[lang].install_info
    if not info then
      vim.notify("no install_info: " .. lang, vim.log.levels.WARN)
    else
      vim.notify("==> " .. lang)
      local dir = vim.fs.joinpath(tmp, lang)
      run({ "git", "clone", "-q", "--filter=blob:none", "--no-checkout", info.url, dir })
      run({ "git", "-C", dir, "checkout", "-q", info.revision or "HEAD" })

      local src = vim.fs.joinpath(dir, info.location or "", "src")
      if vim.fn.filereadable(vim.fs.joinpath(src, "parser.c")) == 0 then
        -- ponytail: grammars without a committed parser.c need `tree-sitter
        -- generate` + the CLI. None in LANGS today; add the step if one appears.
        vim.notify("  skip: no parser.c (" .. lang .. ")", vim.log.levels.WARN)
      else
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

        local srcq = vim.fs.joinpath(nts, "runtime", "queries", lang)
        if vim.fn.isdirectory(srcq) == 1 then
          vim.fn.delete(vim.fs.joinpath(query_dir, lang), "rf")
          run({ "cp", "-R", srcq, vim.fs.joinpath(query_dir, lang) })
        else
          vim.notify("  no queries: " .. lang, vim.log.levels.WARN)
        end
      end
    end
  end

  vim.fn.delete(tmp, "rf")
  vim.notify(("done — parsers: %s  queries: %s"):format(parser_dir, query_dir))
end

vim.api.nvim_create_user_command("TSBuild", build, { desc = "Build treesitter parsers + queries" })
