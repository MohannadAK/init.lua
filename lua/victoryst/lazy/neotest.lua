return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"fredrikaverpil/neotest-golang",
		"leoluz/nvim-dap-go",
	},
	config = function()
		-- Create a local variable to override the default go_test_args
		local neotest_golang = require("neotest-golang")

		require("neotest").setup({
			adapters = {
				neotest_golang({
					dap = { justMyCode = false },
					-- More explicit configuration to override default settings
					args = {
						"-v",
						"-count=1",
						-- No -race flag here
					},
					env = {
						CGO_ENABLED = "1", -- Enable CGO for tests
					},
					experimental = {
						test_table = true,
					},
					-- Explicitly override any default configuration that might include -race
					go_test_args = {
						"-v",
						"-count=1",
						-- No -race flag here
					},
				}),
			},
			-- Additional configuration to ensure no race detector is used
			running = {
				go = {
					args = {
						"-v",
						"-count=1",
						-- No -race flag
					},
				},
			},
		})

		vim.keymap.set("n", "<leader>tr", function()
			require("neotest").run.run({
				suite = false,
				testify = true,
				extra_args = { "-v", "-count=1" }, -- Explicitly set args for this command
			})
		end, { desc = "Debug: Running Nearest Test" })
		vim.keymap.set("n", "<leader>tv", function()
			require("neotest").summary.toggle()
		end, { desc = "Debug: Summary Toggle" })
		vim.keymap.set("n", "<leader>ts", function()
			require("neotest").run.run({
				suite = true,
				testify = true,
				extra_args = { "-v", "-count=1" }, -- Explicitly set args for this command
			})
		end, { desc = "Debug: Running Test Suite" })
		vim.keymap.set("n", "<leader>td", function()
			require("neotest").run.run({
				suite = false,
				testify = true,
				strategy = "dap",
				extra_args = { "-v", "-count=1" }, -- Explicitly set args for this command
			})
		end, { desc = "Debug: Debug Nearest Test" })
		vim.keymap.set("n", "<leader>to", function()
			require("neotest").output.open()
		end, { desc = "Debug: Open test output" })
		vim.keymap.set("n", "<leader>ta", function()
			require("neotest").run.run(vim.fn.getcwd(), {
				extra_args = { "-v", "-count=1" }, -- Explicitly set args for this command
			})
		end, { desc = "Debug: Run all tests" })
	end,
}
