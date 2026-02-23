-- Only do this when not done yet for this buffer
vim.cmd([[
  if exists("b:did_ftplugin")
    finish
  endif
  let b:did_ftplugin = 1
]])

-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*.md",
--   callback = function()
--     vim.opt.wrap = false
--   end
-- })
--

-- =================================================
-- ==== RENDER-MARKDOWN 
-- =================================================
vim.g.mkdp_auto_close = 0
require("render-markdown").setup({
  heading = {
    icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
  },
  -- completions = { blink = { enabled = true } },
})
vim.keymap.set("n", "<localleader>p", "<cmd>MarkdownPreviewToggle<CR>", { desc = "preview" })

-- =================================================
-- ====ZK-NVIM 
-- =================================================
-- Add the key mappings only for Markdown files in a zk notebook.
if require("zk.util").notebook_root(vim.fn.expand('%:p')) ~= nil then
  local function map(...) vim.api.nvim_buf_set_keymap(0, ...) end
  local opts = { noremap=true, silent=false }
  map("n", "K",           "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
  map("n", "<CR>",        "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

  map("n", "<leader>zn",  "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
  map("n", "<leader>zl",  "<Cmd>ZkLinks<CR>", opts)
  map("n", "<leader>zb",  "<Cmd>ZkBacklinks<CR>", opts)
  --map('n', '<leader>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)

  map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)
  map("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
  map("v", "<leader>zi",  ":'<,'>ZkInsertLinkAtSelection { title = vim.fn.input('Title: ') }<CR>", opts)
  map("v", "<leader>za",  ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
