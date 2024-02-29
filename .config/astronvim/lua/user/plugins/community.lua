return {
  "AstroNvim/astrocommunity",
  -- Colorscheme
  { import = "astrocommunity.colorscheme.nord-nvim" },
  { import = "astrocommunity.colorscheme.nordic-nvim" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  -- Bars and Lines
  { import = "astrocommunity.bars-and-lines.heirline-vscode-winbar" },
  { import = "astrocommunity.bars-and-lines.heirline-mode-text-statusline" },
  { import = "astrocommunity.bars-and-lines.scope-nvim" },
  -- Scrolling
  { import = "astrocommunity.scrolling.satellite-nvim" },
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
  -- { import = "astrocommunity.note-taking.neorg" },
  -- {
  --     "nvim-neorg/neorg",
  --     build = ":Neorg sync-parsers",
  --     lazy = false,
  --     dependencies = { "nvim-lua/plenary.nvim" },
  --     config = function()
  --       require("neorg").setup {
  --         load = {
  --           ["core.defaults"] = {},
  --           ["core.concealer"] = {},
  --           ["core.dirman"] = {
  --             config = {
  --               workspaces = {
  --                 notes = "~/notes",
  --               },
  --             },
  --           },
  --         },
  --       }
  --     end,
  --   },
  -- AI
  { import = "astrocommunity.completion.copilot-lua" },
  {
    "copilot.lua",
    opts = {
      panel = {
        auto_refresh = true,
        keymap = {
          accept = "<C-l>",
          jump_next = "<C-j>",
          jump_prev = "<C-k>",
          dismiss = "<C-h>",
        },
        layout = {
          position = "right",
        },
      },
      suggestion = {
        keymap = {
          accept = "<C-l>",
          accept_word = false,
          accept_line = false,
          next = "<C-j>",
          prev = "<C-k>",
          dismiss = "<C-h>",
        },
      },
    },
  },
}
