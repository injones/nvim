return {
	"nvimdev/dashboard-nvim",
	opts = {
		theme = "hyper",
		config = {
			week_header = {
				enable = true,
			},
			shortcut = {
				{ desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
				{
					icon = " ",
					icon_hl = "@variable",
					desc = "Files",
					group = "Label",
					action = "Telescope find_files",
					key = "f",
				},
				{
					-- desc = " Apps",
					desc = " Mason",
					group = "DiagnosticHint",
					-- action = "Telescope app",
					action = "Mason",
					key = "m",
				},
				{
					desc = " dotfiles",
					group = "Number",
					action = "Telescope find_files cwd=~/.config",
					key = "d",
				},
			},
			footer = {
				"",
				" Sharp tools make good work.",
			},
		},
	},
}
