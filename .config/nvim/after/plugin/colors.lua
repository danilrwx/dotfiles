require('noirbuddy').setup {
  colors = {
    background         = '#ffffff',
    primary            = '#20ac20',
    secondary          = '#777777',
    noir_0             = '#000000', -- `noir_0` is light for dark themes, and dark  for light themes
    noir_1             = '#0a0a0a',
    noir_2             = '#2a2a2a',
    noir_3             = '#4b4b4b',
    noir_4             = '#585858',
    noir_5             = '#6b6b6b',
    noir_6             = '#8c8c8c',
    noir_7             = '#acacac',
    noir_8             = '#cdcdcd',
    noir_9             = '#dedede', -- `noir_9` is dark  for dark themes, and light for light themes
    diagnostic_error   = '#ac2020',
    diagnostic_warning = '#acac20',
    diagnostic_info    = '#acacac',
    diagnostic_hint    = '#20ac20',
    diff_add           = '#20ac20',
    diff_change        = '#acac20',
    diff_delete        = '#ac2020',
  },
  styles = {
    italic = true,
    bold = true,
    underline = false,
    undercurl = true,
  },
}

local Color, colors, Group, groups, styles = require('colorbuddy').setup {}

Group.new('Pmenu', colors.noir_0, colors.noir_3)
Group.new('PmenuSel', colors.noir_0, colors.noir_7)
Group.new('PmenuSbar', colors.primary, colors.noir_7)
Group.new('PmenuThumb', colors.primary, colors.noir_7)

Group.new('WildMenu', colors.noir_7, colors.noir_7)

Group.new('MiniFilesNormal', colors.noir_2)
Group.new('MiniFilesBorder', colors.noid_9)

Group.new('@constant', colors.noir_2, nil, styles.bold)
Group.new('@method', colors.noir_0, nil, styles.bold)

vim.opt.termguicolors = true
