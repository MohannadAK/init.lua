local root_files = {
	"go.mod",
	".git",
	".luarc.json",
	".luarc.jsonc",
	".luacheckrc",
	".stylua.toml",
	"stylua.toml",
	"selene.toml",
	"selene.yml",
	"sln", -- Added for C# projects
	"csproj",
}

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", lazy = false },
		"williamboman/mason-lspconfig.nvim",
		"stevearc/conform.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

	config = function()
		-- Debug mason.nvim
		local ok, mason = pcall(require, "mason")
		if not ok then
			vim.notify("Failed to load mason.nvim", vim.log.levels.ERROR)
			return
		end

		-- Setup conform.nvim
		require("conform").setup({
			formatters_by_ft = {
				go = { "gofmt", "goimports" },
				lua = { "stylua" },
				cs = { "csharpier" }, -- Formatter for C#
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		-- Setup nvim-cmp
		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		require("fidget").setup({})
		mason.setup({
			ui = { border = "rounded" },
		})
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "rust_analyzer", "gopls", "omnisharp" }, -- Added omnisharp
			automatic_installation = true,
			handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
						root_dir = require("lspconfig.util").root_pattern(unpack(root_files)),
						on_init = function(client)
							vim.notify("LSP initialized: " .. server_name, vim.log.levels.INFO)
						end,
					})
				end,

				["gopls"] = function()
					require("lspconfig").gopls.setup({
						capabilities = capabilities,
						root_dir = require("lspconfig.util").root_pattern("go.mod", ".git"),
						settings = {
							gopls = {
								analyses = { unusedparams = true, shadow = true },
								staticcheck = true,
								gofumpt = true,
								hints = {
									assignVariableTypes = true,
									compositeLiteralFields = true,
									constantValues = true,
									functionTypeParameters = true,
									parameterNames = true,
									rangeVariableTypes = true,
								},
							},
						},
						on_init = function(client)
							vim.notify(
								"gopls initialized for " .. (client.workspace_folders[1].name or "unknown"),
								vim.log.levels.INFO
							)
						end,
						on_attach = function(client, bufnr)
							vim.notify("gopls attached to buffer " .. bufnr, vim.log.levels.INFO)
							vim.diagnostic.config({
								virtual_text = { prefix = "●" },
								signs = true,
								float = {
									focusable = false,
									style = "minimal",
									border = "rounded",
									source = "always",
									header = "",
									prefix = "",
								},
							}, bufnr)
						end,
					})
				end,

				["lua_ls"] = function()
					require("lspconfig").lua_ls.setup({
						capabilities = capabilities,
						root_dir = require("lspconfig.util").root_pattern(unpack(root_files)),
						settings = {
							Lua = {
								format = { enable = false }, -- Use conform.nvim
								diagnostics = { globals = { "vim" } },
							},
						},
					})
				end,

				["zls"] = function()
					require("lspconfig").zls.setup({
						capabilities = capabilities,
						root_dir = require("lspconfig.util").root_pattern(".git", "build.zig", "zls.json"),
						settings = {
							zls = {
								enable_inlay_hints = true,
								enable_snippets = true,
								warn_style = true,
							},
						},
					})
					vim.g.zig_fmt_parse_errors = 0
					vim.g.zig_fmt_autosave = 0
				end,

				["omnisharp"] = function()
					require("lspconfig").omnisharp.setup({
						capabilities = capabilities,
						root_dir = require("lspconfig.util").root_pattern("*.sln", "*.csproj", ".git"),
						cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
						settings = {
							omnisharp = {
								useModernNet = true, -- Use .NET 6+ if available
								enableRoslynAnalyzers = true,
								enableImportCompletion = true,
								organizeImportsOnFormat = true,
							},
						},
						on_init = function(client)
							vim.notify(
								"omnisharp initialized for " .. (client.workspace_folders[1].name or "unknown"),
								vim.log.levels.INFO
							)
						end,
						on_attach = function(client, bufnr)
							vim.notify("omnisharp attached to buffer " .. bufnr, vim.log.levels.INFO)
							vim.diagnostic.config({
								virtual_text = { prefix = "●" },
								signs = true,
								float = {
									focusable = false,
									style = "minimal",
									border = "rounded",
									source = "always",
									header = "",
									prefix = "",
								},
							}, bufnr)
						end,
					})
				end,
			},
		})

		local cmp_select = { behavior = cmp.SelectBehavior.Select }
		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
				["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
				["<C-y>"] = cmp.mapping.confirm({ select = true }),

				-- Add Enter key to confirm selection
				["<CR>"] = cmp.mapping.confirm({ select = true }),

				-- Add Tab and Shift-Tab to navigate items (optional, but common)
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end, { "i", "s" }),

				["<C-Space>"] = cmp.mapping.complete(),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp", priority = 1000 },
				{ name = "luasnip", priority = 750 },
				{ name = "buffer", priority = 500 },
				{ name = "copilot", group_index = 2, priority = 100 },
			}),
		})

		-- Global diagnostic configuration
		vim.diagnostic.config({
			virtual_text = { prefix = "●" },
			signs = true,
			update_in_insert = false,
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
