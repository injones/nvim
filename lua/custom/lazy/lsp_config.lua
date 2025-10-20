return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"stevearc/conform.nvim",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },
	},

	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			-- from nvim kickstart
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				-- NOTE: Remember that Lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				-- Jump to the definition of the word under your cursor.
				--  This is where a variable was first declared, or where a function is defined, etc.
				--  To jump back, press <C-t>.
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

				-- Find references for the word under your cursor.
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

				-- Jump to the type of the word under your cursor.
				--  Useful when you're not sure what type a variable is and you want to see
				--  the definition of its *type*, not where it was *defined*.
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

				-- Fuzzy find all the symbols in your current workspace.
				--  Similar to document symbols, except searches over your entire project.
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

				-- Rename the variable under your cursor.
				--  Most Language Servers support renaming across files, etc.
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header.
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
				---@param client vim.lsp.Client
				---@param method vim.lsp.protocol.Method
				---@param bufnr? integer some lsp support methods only in specific files
				---@return boolean
				local function client_supports_method(client, method, bufnr)
					if vim.fn.has("nvim-0.11") == 1 then
						return client:supports_method(method, bufnr)
					else
						return client.supports_method(method, { bufnr = bufnr })
					end
				end

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if
					client
					and client_supports_method(
						client,
						vim.lsp.protocol.Methods.textDocument_documentHighlight,
						event.buf
					)
				then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				-- The following code creates a keymap to toggle inlay hints in your
				-- code, if the language server you are using supports them
				--
				-- This may be unwanted, since they displace some of your code
				if
					client
					and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
				then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "[T]oggle Inlay [H]ints")
				end

				-- setup compiler config for omnisharp
				-- https://github.com/Hoffs/omnisharp-extended-lsp.nvim/issues/42#issuecomment-2480414792
				if client and client.name == "omnisharp" then
					map("gd", require("omnisharp_extended").lsp_definition, "[G]oto [D]efinition")
					map("gr", require("omnisharp_extended").lsp_references, "[G]oto [R]eferences")
					map("gI", require("omnisharp_extended").lsp_implementation, "[G]oto [I]mplementation")
					map("<leader>D", require("omnisharp_extended").lsp_type_definition, "Type [D]efinition")
				end
			end,
		})

		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")
		local luasnip = require("luasnip")
		luasnip.config.setup({})
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		local servers = {
			-- clangd = {},
			-- gopls = {},
			-- pyright = {},
			-- rust_analyzer = {},
			-- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
			--
			-- Some languages (like typescript) have entire language plugins that can be useful:
			--    https://github.com/pmizio/typescript-tools.nvim
			--
			-- But for many setups, the LSP (`ts_ls`) will work just fine
			-- ts_ls = {},
			--

			lua_ls = {
				-- cmd = { ... },
				-- filetypes = { ... },
				-- capabilities = {},
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
						-- diagnostics = { disable = { 'missing-fields' } },
					},
				},
			},

			omnisharp = {
				--cmd = { "dotnet", "/path/to/omni/OmniSharp.dll" },
				-- The following doesn't work for some reason
				handlers = {
					["textDocument/definition"] = function(...)
						return require("omnisharp_extended").handler(...)
					end,
				},
				keys = {
					{
						"gd",
						function()
							require("omnisharp_extended").telescope_lsp_definitions()
						end,
						noremap = true,
						desc = "Goto Definition",
					},
				},
				--
				enable_roslyn_analyzers = true,
				organize_imports_on_format = true,
				enable_import_completion = true,
				settings = {
					FormattingOptions = {
						-- Enables support for reading code style, naming convention and analyzer
						-- settings from .editorconfig.
						EnableEditorConfigSupport = true,
						-- Specifies whether 'using' directives should be grouped and sorted during
						-- document formatting.
						OrganizeImports = true,
					},
					MsBuild = {
						-- If true, MSBuild project system will only load projects for files that
						-- were opened in the editor. This setting is useful for big C# codebases
						-- and allows for faster initialization of code navigation features only
						-- for projects that are relevant to code that is being edited. With this
						-- setting enabled OmniSharp may load fewer projects and may thus display
						-- incomplete reference lists for symbols.
						LoadProjectsOnDemand = nil,
					},
					RoslynExtensionsOptions = {
						-- Enables support for roslyn analyzers, code fixes and rulesets.
						EnableAnalyzersSupport = true,
						-- Enables support for showing unimported types and unimported extension
						-- methods in completion lists. When committed, the appropriate using
						-- directive will be added at the top of the current file. This option can
						-- have a negative impact on initial completion responsiveness,
						-- particularly for the first few completion sessions after opening a
						-- solution.
						EnableImportCompletion = nil,
						-- Only run analyzers against open files when 'enableRoslynAnalyzers' is
						-- true
						AnalyzeOpenDocumentsOnly = nil,
					},
					Sdk = {
						-- Specifies whether to include preview versions of the .NET SDK when
						-- determining which version to use for project loading.
						IncludePrereleases = true,
					},
				},
			},

			clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
				},
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
				},
			},
		}

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format Lua code
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
		require("fidget").setup({})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {},
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for ts_ls)
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})

		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
				end,
			},
			completion = { completeopt = "menu,menuone,noinsert" },
			mapping = cmp.mapping.preset.insert({
				-- Select the [n]ext item
				["<C-n>"] = cmp.mapping.select_next_item(),
				-- Select the [p]revious item
				["<C-p>"] = cmp.mapping.select_prev_item(),

				-- Scroll the documentation window [b]ack / [f]orward
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),

				-- Accept ([y]es) the completion.
				--  This will auto-import if your LSP supports it.
				--  This will expand snippets if the LSP sent a snippet.
				["<C-y>"] = cmp.mapping.confirm({ select = true }),

				-- If you prefer more traditional completion keymaps,
				-- you can uncomment the following lines
				--['<CR>'] = cmp.mapping.confirm { select = true },
				--['<Tab>'] = cmp.mapping.select_next_item(),
				--['<S-Tab>'] = cmp.mapping.select_prev_item(),

				-- Manually trigger a completion from nvim-cmp.
				--  Generally you don't need this, because nvim-cmp will display
				--  completions whenever it has completion options available.
				["<C-Space>"] = cmp.mapping.complete({}),

				-- Think of <c-l> as moving to the right of your snippet expansion.
				--  So if you have a snippet that's like:
				--  function $name($args)
				--    $body
				--  end
				--
				-- <c-l> will move you to the right of each of the expansion locations.
				-- <c-h> is similar, except moving you backwards.
				["<C-l>"] = cmp.mapping(function()
					if luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					end
				end, { "i", "s" }),
				["<C-h>"] = cmp.mapping(function()
					if luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					end
				end, { "i", "s" }),

				-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
				--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
			}),
			sources = {
				{
					name = "lazydev",
					-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
					group_index = 0,
				},
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
				{ name = "nvim_lsp_signature_help" },
			},
		})

		vim.diagnostic.config({
			-- update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
	end,
}

--[[ ---@class LazyKeysBase
---@field desc? string
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field nowait? boolean
---@field ft? string|string[]

---@class LazyKeysSpec: LazyKeysBase
---@field [1] string lhs
---@field [2]? string|fun()|false rhs
---@field mode? string|string[]

---@class LazyKeys: LazyKeysBase
---@field lhs string lhs
---@field rhs? string|fun() rhs
---@field mode? string
---@field id string
---@field name string

---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], cond?:fun():boolean}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], cond?:fun():boolean}

return {
	{ "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },
	-- lspconfig
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason.nvim",
			{ "williamboman/mason-lspconfig.nvim", config = function() end },
		},
		opts = function()
			Diagnostic_icons = {
				Error = " ",
				Warn = " ",
				Hint = " ",
				Info = " ",
			}
			---@class PluginLspOpts
			local ret = {
				-- options for vim.diagnostic.config()
				---@type vim.diagnostic.Opts
				diagnostics = {
					underline = true,
					update_in_insert = false,
					virtual_text = {
						spacing = 4,
						source = "if_many",
						prefix = "●",
						-- this will set set the prefix to a function that returns the diagnostics icon based on the severity
						-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
						-- prefix = "icons",
					},
					severity_sort = true,
					signs = {
						text = {
							[vim.diagnostic.severity.ERROR] = Diagnostic_icons.Error,
							[vim.diagnostic.severity.WARN] = Diagnostic_icons.Warn,
							[vim.diagnostic.severity.HINT] = Diagnostic_icons.Hint,
							[vim.diagnostic.severity.INFO] = Diagnostic_icons.Info,
						},
					},
				},
				-- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
				-- Be aware that you also will need to properly configure your LSP server to
				-- provide the inlay hints.
				inlay_hints = {
					enabled = true,
					exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
				},
				-- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
				-- Be aware that you also will need to properly configure your LSP server to
				-- provide the code lenses.
				codelens = {
					enabled = false,
				},
				-- Enable lsp cursor word highlighting
				document_highlight = {
					enabled = true,
				},
				-- add any global capabilities here
				capabilities = {
					workspace = {
						fileOperations = {
							didRename = true,
							willRename = true,
						},
					},
				},
				-- options for vim.lsp.buf.format
				-- `bufnr` and `filter` is handled by the LazyVim formatter,
				-- but can be also overridden when specified
				format = {
					formatting_options = nil,
					timeout_ms = nil,
				},
				-- LSP Server Settings
				servers = {
					lua_ls = {
						-- mason = false, -- set to false if you don't want this server to be installed with mason
						-- Use this to add any additional keymaps
						-- for specific lsp servers
						-- ---@type LazyKeysSpec[]
						-- keys = {},
						settings = {
							Lua = {
								workspace = {
									checkThirdParty = false,
								},
								codeLens = {
									enable = true,
								},
								completion = {
									callSnippet = "Replace",
								},
								doc = {
									privateName = { "^_" },
								},
								hint = {
									enable = true,
									setType = false,
									paramType = true,
									paramName = "Disable",
									semicolon = "Disable",
									arrayIndex = "Disable",
								},
								diagnostics = {
									globals = { "vim" },
								},
							},
						},
					},
					omnisharp = {
						handlers = {
							["textDocument/definition"] = function(...)
								return require("omnisharp_extended").handler(...)
							end,
						},
						keys = {
							{
								"gd",
								function()
									require("omnisharp_extended").telescope_lsp_definitions()
								end,
								desc = "Goto Definition",
							},
						},
						enable_roslyn_analyzers = true,
						organize_imports_on_format = true,
						enable_import_completion = true,
                        settings = {
                            FormattingOptions = {
                                -- Enables support for reading code style, naming convention and analyzer
                                -- settings from .editorconfig.
                                EnableEditorConfigSupport = true,
                                -- Specifies whether 'using' directives should be grouped and sorted during
                                -- document formatting.
                                OrganizeImports = true,
                            },
                        }
					},
				},
				-- you can do any additional lsp server setup here
				-- return true if you don't want this server to be setup with lspconfig
				setup = {
					-- example to setup with typescript.nvim
					-- tsserver = function(_, opts)
					--   require("typescript").setup({ server = opts })
					--   return true
					-- end,
					-- Specify * to use this function as a fallback for any server
					-- ["*"] = function(server, opts) end,
				},
			}
			return ret
		end,
		---@param opts PluginLspOpts
		config = function(_, opts)
			-- setup autoformat
			-- LazyVim.format.register(LazyVim.lsp.formatter())

			-- setup keymaps
			local keymaps = {
				{ "<leader>cl", "<cmd>LspInfo<cr>", desc = "Lsp Info" },
				{ "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
				{ "gr", vim.lsp.buf.references, desc = "References", nowait = true },
				{ "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
				{ "gy", vim.lsp.buf.type_definition, desc = "Goto T[y]pe Definition" },
				{ "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
				{ "K", vim.lsp.buf.hover, desc = "Hover" },
				{ "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
				{ "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },
				{
					"<leader>ca",
					vim.lsp.buf.code_action,
					desc = "Code Action",
					mode = { "n", "v" },
					has = "codeAction",
				},
				{ "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
				{
					"<leader>cC",
					vim.lsp.codelens.refresh,
					desc = "Refresh & Display Codelens",
					mode = { "n" },
					has = "codeLens",
				},
				{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
			}

			local function get_clients(opts)
				local ret = {} ---@type vim.lsp.Client[]
				if vim.lsp.get_clients then
					ret = vim.lsp.get_clients(opts)
				else
					---@diagnostic disable-next-line: deprecated
					ret = vim.lsp.get_active_clients(opts)
					if opts and opts.method then
						---@param client vim.lsp.Client
						ret = vim.tbl_filter(function(client)
							return client.supports_method(opts.method, { bufnr = opts.bufnr })
						end, ret)
					end
				end
				return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
			end

			---@param method string|string[]
			local function has_method(buffer, method)
				if type(method) == "table" then
					for _, m in ipairs(method) do
						if has_method(buffer, m) then
							return true
						end
					end
					return false
				end
				method = method:find("/") and method or "textDocument/" .. method
				local clients = get_clients({ bufnr = buffer })
				for _, client in ipairs(clients) do
					if client.supports_method(method) then
						return true
					end
				end
				return false
			end

			local function resolve(buffer)
				local Keys = require("lazy.core.handler.keys")
				if not Keys.resolve then
					return {}
				end
				local spec = keymaps
				local plugin_opts = {}
				local plugin = require("lazy.core.config").spec.plugins["nvim-lspconfig"]
				local Plugin = require("lazy.core.plugin")
				plugin_opts = Plugin.values(plugin, "opts", false)
				local clients = get_clients({ bufnr = buffer })
				for _, client in ipairs(clients) do
					local maps = plugin_opts.servers[client.name] and opts.servers[client.name].keys or {}
					vim.list_extend(spec, maps)
				end
				return Keys.resolve(spec)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local buffer = args.data.buffer ---@type number
					if client then
						if client and (not buffer or client.name == buffer) then
							local Keys = require("lazy.core.handler.keys")
							local _keymaps = resolve(buffer) ---@type LazyKeysLsp[]
							for _, keys in pairs(_keymaps) do
								local has = not keys.has or has_method(buffer, keys.has)
								local cond = not (
									keys.cond == false or ((type(keys.cond) == "function") and not keys.cond())
								)

								if has and cond then
									local opt = Keys.opts(keys)
									opt.cond = nil
									opt.has = nil
									opt.silent = opts.silent ~= false
									opt.buffer = buffer
									vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opt)
								end
							end
						end
					end

					-- -- don't trigger on invalid buffers
					-- if not vim.api.nvim_buf_is_valid(buffer) then
					-- 	return
					-- end
					-- -- -- don't trigger on non-listed buffers
					-- if not vim.bo[buffer].buflisted then
					-- 	return
					-- end
					-- -- -- don't trigger on nofile buffers
					-- if vim.bo[buffer].buftype == "nofile" then
					-- 	return
					-- end
				end,
			})

			--LazyVim.lsp.on_attach(function(client, buffer)
			--require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
			--end)
			local register_capability = vim.lsp.handlers["client/registerCapability"]
			vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
				---@diagnostic disable-next-line: no-unknown
				local ret = register_capability(err, res, ctx)
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				if client then
					for buffer in pairs(client.attached_buffers) do
						vim.api.nvim_exec_autocmds("User", {
							pattern = "LspDynamicCapability",
							data = { client_id = client.id, buffer = buffer },
						})
					end
				end
				return ret
			end

			vim.api.nvim_create_autocmd("User", {
				pattern = "LspDynamicCapability",
				-- group = opts or nil,
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local buffer = args.data.buffer ---@type number
					if client then
						if client and (not buffer or client.name == buffer) then
							local Keys = require("lazy.core.handler.keys")
							local _keymaps = resolve(buffer) ---@type LazyKeysLsp[]
							for _, keys in pairs(_keymaps) do
								local has = not keys.has or has_method(buffer, keys.has)
								local cond = not (
									keys.cond == false or ((type(keys.cond) == "function") and not keys.cond())
								)

								if has and cond then
									local opt = Keys.opts(keys)
									opt.cond = nil
									opt.has = nil
									opt.silent = opts.silent ~= false
									opt.buffer = buffer
									vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opt)
								end
							end
						end
					end
					-- don't trigger on invalid buffers
					if not vim.api.nvim_buf_is_valid(buffer) then
						return
					end
					-- -- don't trigger on non-listed buffers
					if not vim.bo[buffer].buflisted then
						return
					end
					-- -- don't trigger on nofile buffers
					if vim.bo[buffer].buftype == "nofile" then
						return
					end
				end,
			})

			--LazyVim.lsp.setup()
			--LazyVim.lsp.on_dynamic_capability(require("lazyvim.plugins.lsp.keymaps").on_attach)

			--LazyVim.lsp.words.setup(opts.document_highlight)

			-- diagnostics signs
			if vim.fn.has("nvim-0.10.0") == 0 then
				if type(opts.diagnostics.signs) ~= "boolean" then
					for severity, icon in pairs(opts.diagnostics.signs.text) do
						local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
						name = "DiagnosticSign" .. name
						vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
					end
				end
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
					or function(diagnostic)
						local icons = Diagnostic_icons
						for d, icon in pairs(icons) do
							if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
								return icon
							end
						end
					end
			end

			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

			local servers = opts.servers
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				has_cmp and cmp_nvim_lsp.default_capabilities() or {},
				opts.capabilities or {}
			)

			local function setup(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, servers[server] or {})
				if server_opts.enabled == false then
					return
				end

				if opts.setup[server] then
					if opts.setup[server](server, server_opts) then
						return
					end
				elseif opts.setup["*"] then
					if opts.setup["*"](server, server_opts) then
						return
					end
				end
				require("lspconfig")[server].setup(server_opts)
			end

			-- get all the servers that are available through mason-lspconfig
			local have_mason, mlsp = pcall(require, "mason-lspconfig")
			local all_mslp_servers = {}
			if have_mason then
				all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
			end

			local ensure_installed = {} ---@type string[]
			for server, server_opts in pairs(servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					if server_opts.enabled ~= false then
						-- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
						if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
							setup(server)
						else
							ensure_installed[#ensure_installed + 1] = server
						end
					end
				end
			end

			if have_mason then
				mlsp.setup({
					ensure_installed = vim.tbl_deep_extend("force", ensure_installed, {}),
					handlers = { setup },
				})
			end
		end,
	},

	-- cmdline tools and lsp servers
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts_extend = { "ensure_installed" },
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"omnisharp",
				"csharpier",
				"netcoredbg",
			},
		},
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
} ]]
