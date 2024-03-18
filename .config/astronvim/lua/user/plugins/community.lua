return {
  "AstroNvim/astrocommunity",
  -- Colorscheme
  { import = "astrocommunity.colorscheme.catppuccin" },
  -- Bars and Lines
  -- { import = "astrocommunity.bars-and-lines.heirline-vscode-winbar" },
  -- { import = "astrocommunity.bars-and-lines.heirline-mode-text-statusline" },
  -- { import = "astrocommunity.bars-and-lines.scope-nvim" },
  -- Scrolling
  -- { import = "astrocommunity.scrolling.satellite-nvim" },
  -- Editing Support
  { import = "astrocommunity.editing-support.todo-comments-nvim" },
  -- Motion
  { import = "astrocommunity.motion.mini-move" },
  -- Terminal
  { import = "astrocommunity.terminal-integration.flatten-nvim" },
  -- -- Project
  { import = "astrocommunity.project.project-nvim" },
  -- Note Taking
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  {
    "obsidian.nvim",
    event = "VimEnter",
    config = function()
      require("obsidian").setup({
        dir = "~/Documents/notes/obsidian/vault",
      })
    end,
  },
  { import = "astrocommunity.note-taking.neorg" },
  {
      "nvim-neorg/neorg",
      build = ":Neorg sync-parsers",
      lazy = false,
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("neorg").setup {
          load = {
            ["core.defaults"] = {},
            ["core.concealer"] = {},
            ["core.dirman"] = {
              config = {
                workspaces = {
                  notes = "~/notes/neorg",
                },
              },
            },
          },
        }
      end,
    },
  -- AI
  { import = "astrocommunity.completion.copilot-lua-cmp" },
  {
    "copilot.lua",
    config = function()
      require("copilot").setup({
        copilot_node_command = "/home/grey/.local/node/bin/node"
      })
    end,
  },
}
