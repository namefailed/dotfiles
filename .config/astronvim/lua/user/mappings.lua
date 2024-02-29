-- Key mappings for normal mode
return {
  n = {
    -- Disable default key mappings to avoid conflicts with custom ones
    ["<leader>C"] = false,
    ["<leader>c"] = false,
    ["<leader>o"] = false,
    ["<leader>h"] = false,
    ["<leader>w"] = false,
    ["<leader>Q"] = false,

    -- Move down half a page
    ["<C-d>"] = {
      "<C-d>zz",  -- Perform default move down half a page action and center cursor
      desc = "Move down half a page"
    },

    -- Move up half a page
    ["<C-u>"] = {
      "<C-u>zz",  -- Perform default move up half a page action and center cursor
      desc = "Move up half a page"
    },

    -- Save file
    ["<C-s>"] = {
      ":w!<cr>",
      desc = "Save File"
    },
    ["<leader>s"] = {
      ":w!<cr>",
      desc = "Save File"
    },

    -- Set current working directory
    ["<leader>."] = {
      "<cmd>cd %:p:h<cr>",  -- Change directory to the parent directory of the current file
      desc = "Set CWD"
    },

    -- Close buffer
    ["<C-q>"] = {
      -- Lua function to close buffer
      function()
        local bufs = vim.fn.getbufinfo { buflisted = true }  -- Get buffer information
        require("astronvim.utils.buffer").close(0)  -- Close current buffer
        if require("astronvim.utils").is_available "alpha-nvim" and not bufs[2] then
          require("alpha").start(true)  -- Start alpha-nvim if it's available and there's only one buffer left
        end
      end,
      desc = "Close buffer"
    },
    
    -- Close buffer (alternate binding)
    ["<leader>x"] = {
      function()
        local bufs = vim.fn.getbufinfo { buflisted = true }
        require("astronvim.utils.buffer").close(0)
        if require("astronvim.utils").is_available "alpha-nvim" and not bufs[2] then
          require("alpha").start(true)
        end
      end,
      desc = "Close buffer"
    },

    -- Pick buffer to close
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr)
            require("astronvim.utils.buffer").close(bufnr)
          end
        )
      end,
      desc = "Pick to close"
    },

    -- Next buffer
    L = {
      function()
        require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1)
      end,
      desc = "Next buffer"
    },

    -- Previous buffer
    H = {
      function()
        require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1))
      end,
      desc = "Previous buffer"
    },

    -- Toggle terminal
    ["<C-t>"] = {
      "<C-\\><C-n><cmd>ToggleTerm<cr>",
      desc = "Toggle terminal"
    },
  },

  -- Key mappings for visual mode
  v = {
    -- Paste from clipboard
    ["p"] = {
      '"_dP',  -- Delete selected text and paste from clipboard
      desc = "Paste from clipboard"
    },

    -- Execute selection in terminal
    ["<leader>te"] = {
      "<cmd>ToggleTermSendVisualSelection<cr>",
      desc = "Execute"
    },
  },

  -- Key mappings for terminal mode
  t = {
    -- Toggle terminal
    ["<C-t>"] = {
      "<C-\\><C-n><cmd>ToggleTerm<cr>",
      desc = "Toggle terminal"
    },

    -- Quit terminal
    ["<C-q>"] = {
      "<C-\\><C-n><cmd>ToggleTerm<cr>",
      desc = "Quit terminal"
    },
  },
}
