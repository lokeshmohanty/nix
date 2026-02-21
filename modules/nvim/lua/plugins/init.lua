require("plugins.debug")
require("plugins.format")
require("plugins.lsp")
require("plugins.completion") -- Completion (blink, snippets, copilot)
require("plugins.general_ui")
require("plugins.gitsigns")
require("plugins.lint")
require("plugins.noice")

require("plugins.mini")
require("plugins.snacks")
require("plugins.lze")         -- lazy-loaded plugins

require("zk").setup({
  picker = "snacks_picker",
  lsp = {
    config = {
      name = "zk",
      cmd = { "zk", "lsp" },
      filetypes = { "markdown" },
    },
    auto_attach = { enabled = true, },
  },
})
