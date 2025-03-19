return {
	"folke/zen-mode.nvim",
	config = function()
		Plugins = {
			-- disable some global vim options (vim.o...)
			-- comment the lines to not apply the options
			options = {
				enabled = true,
			},
			-- twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
			-- gitsigns = { enabled = false }, -- disables git signs
			tmux = { enabled = false }, -- disables the tmux statusline
			todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
			-- this will change the font size on alacritty when in zen mode
			-- requires  Alacritty Version 0.10.0 or higher
			-- uses `alacritty msg` subcommand to change font size
			alacritty = {
				enabled = false,
				font = "16", -- font size
			},
		}
		vim.keymap.set("n", "<leader>z", function()
			require("zen-mode").toggle({
				window = {
					width = 120,
					backdrop = 0.75,
				},
				plugins = Plugins,
			})
		end)
	end,
}
