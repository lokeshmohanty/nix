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

-- Create a new note after asking for its title.
vim.keymap.set("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", { desc = "new note" })

-- Open notes.
vim.keymap.set("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>")
vim.keymap.set("n", "<leader>zt", "<Cmd>ZkTags<CR>")
vim.keymap.set("n", "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>")
vim.keymap.set("v", "<leader>zf", ":'<,'>ZkMatch<CR>")
