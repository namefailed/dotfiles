return {
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      opts.section.header.val = {
        -- [[⠀⠀    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   ⠀⠀    ]],
        -- [[      ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣆⠀⢀⣀⣀⣤⣤⣤⣶⣦⣤⣤⣄⣀⣀⠀⢠⣾⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀         ]],
        -- [[      ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀         ]],
        -- [[      ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀          ]],
        -- [[       ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀          ]],
        -- [[      ⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⠟⠀⠀⠀⠀⠀⣀⣤⣤⣤⡀⠀⠀⠀⠀⠀⢀⣤⣤⣤⣄⡀⠀⠀⠀⠀⠘⣿⡿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀         ]],
        -- [[      ⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀⠀⠀⣠⣾⣿⣿⠛⣿⡇⠀⠀⠀⠀⠀⢸⣿⣿⠛⣿⣿⣦⠀⠀⠀⠀⠸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀          ]],
        -- [[      ⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁⠀⠀⠀⠀⣿⣿⣿⣿⣿⡟⢠⣶⣾⣿⣿⣷⣤⢹⣿⣿⣿⣿⣿⡇⠀⠀⣀⣤⣿⣷⣴⣶⣦⣀⡀⠀⠀⠀⠀         ]],
        -- [[      ⠀⠀⠀⠀ ⠀⠀⢀⣠⣤⣤⣤⣇⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⠀⠘⠻⣿⣿⣿⡿⠋⠀⢹⣿⣿⣿⣿⡇⠀⣿⣿⣿⡏⢹⣿⠉⣿⣿⣿⣷⠀⠀⠀         ]],
        -- [[      ⠀⠀⠀ ⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣶⣄⠀⠀⠹⣿⣿⠿⠋⠀⢤⣀⢀⣼⡄⠀⣠⠀⠈⠻⣿⣿⠟⠀⢸⣿⣇⣽⣿⠿⠿⠿⣿⣅⣽⣿⡇⠀⠀         ]],
        -- [[      ⠀⠀⠀⠀ ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣟⠁⠀⠀⠀⠈⣿⣿⣿⡇⠀⠀⠀        ]],
        -- [[⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛ ]],
        -- [[     ⠀⠀⠀⠀⠀⠀⠘⠛⠻⢿⣿⣿⣿⣿⣿⠟⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀         ]],
        -- [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   ]],
        [[                ███╗   ███╗ █████╗ ██╗  ██╗███████╗                 ]],
        [[                ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝                 ]],
        [[                ██╔████╔██║███████║█████╔╝ █████╗                   ]],
        [[                ██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝                   ]],
        [[                ██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗                 ]],
        [[                ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝                 ]],
        [[             ███████╗████████╗██╗   ██╗███████╗███████╗             ]],
        [[             ██╔════╝╚══██╔══╝██║   ██║██╔════╝██╔════╝             ]],
        [[             ███████╗   ██║   ██║   ██║█████╗  █████╗               ]],
        [[             ╚════██║   ██║   ██║   ██║██╔══╝  ██╔══╝               ]],
        [[             ███████║   ██║   ╚██████╔╝██║     ██║                  ]],
        [[             ╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝                  ]],
        [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   ]],
        [[  ▄██████▄      ▄██████▄      ▄██████▄      ▄██████▄      ▄██████▄  ]],
        [[▄█▀████▀███▄  ▄██ ████ ██▄  ▄██ ████ ██▄  ▄██ ████ ██▄  ▄███▀████▀█▄]],
        [[█▄▄███▄▄████  ████████████  ████████████  ████████████  ████▄▄███▄▄█]],
        [[████████████  ████████████  ████████████  ████████████  ████████████]],
        [[██▀██▀▀██▀██  ██▀██▀▀██▀██  ██▀██▀▀██▀██  ██▀██▀▀██▀██  ██▀██▀▀██▀██]],
        [[▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀  ▀   ▀]],
      }
      return opts
    end,
  },
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      opts.winbar = nil
      return opts
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      mappings = {
        ["H"] = "prev_source",
		    ["L"] = "next_source",
      },
    },
  },
  { "max397574/better-escape.nvim", enabled = false },
  { "rcarriga/nvim-notify",         enabled = false },
}
