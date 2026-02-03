local function pack_update()
  print("Updating plugins...")
  vim.pack.update()
  print("Plugins updated!")
end

local function pack_clean(opts)
  local unused = {}
  for _, plugin in ipairs(vim.pack.get()) do
    if not plugin.active then
      table.insert(unused, plugin.spec.name)
    end
  end

  if #unused == 0 then
    vim.notify("No unused plugins.", vim.log.levels.INFO)
    return
  end

  if opts.bang then
    vim.pack.del(unused)
    vim.notify("Removed " .. #unused .. " plugin(s): " .. table.concat(unused, ", "), vim.log.levels.INFO)
  else
    vim.notify(
      "Unused plugins (" .. #unused .. "): " .. table.concat(unused, ", ") .. ". Run :PackClean! to remove.",
      vim.log.levels.INFO
    )
  end
end


local M = {}
M.setup = function()
  vim.api.nvim_create_user_command("PackUpdate", function() pack_update() end, {})
  vim.api.nvim_create_user_command("PackClean", function(opts) pack_clean(opts) end, { bang = true })
end

return M
