-- Go environment configuration as a lazy.nvim plugin
return {
	"nvim-lua/plenary.nvim", -- Use an existing dependency since we don't need a new plugin
	config = function()
		-- Set global environment variables for Go development
		vim.env.CGO_ENABLED = "1"

		-- Create FileType autocmd for Go-specific settings
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "go",
			callback = function()
				-- Set environment variables for Go files
				vim.env.CGO_ENABLED = "1"

				-- You can add other Go-specific environment variables here if needed
				-- vim.env.GOPATH = "/path/to/your/gopath"
				-- vim.env.GOFLAGS = "-mod=vendor"
			end,
		})

		-- Optional: Add a command to toggle CGO_ENABLED
		vim.api.nvim_create_user_command("ToggleCGO", function()
			if vim.env.CGO_ENABLED == "1" then
				vim.env.CGO_ENABLED = "0"
				vim.notify("CGO_ENABLED set to 0", vim.log.levels.INFO)
			else
				vim.env.CGO_ENABLED = "1"
				vim.notify("CGO_ENABLED set to 1", vim.log.levels.INFO)
			end
		end, { desc = "Toggle CGO_ENABLED environment variable" })

		-- Let the user know the configuration is loaded
		vim.notify("Go environment configuration loaded: CGO_ENABLED=1", vim.log.levels.INFO)
	end,
	-- Load this plugin very early to ensure environment variables are set
	priority = 1000,
}
