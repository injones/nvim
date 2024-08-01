return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"Issafalcon/neotest-dotnet",
	},
	opts = {
		adapters = {
			["neotest-dotnet"] = {
				-- Here we can set options for neotest-dotnet
			},
		},
	},
}
