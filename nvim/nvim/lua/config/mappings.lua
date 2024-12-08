local function on_attach(client, bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
end

local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap(
    "n",
    "<leader>gl",
    '<cmd>lua vim.diagnostic.open_float()<cr>',
    opts
)
