---@class LazyKeysBase
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
}
