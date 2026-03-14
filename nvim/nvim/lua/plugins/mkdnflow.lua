return {
    'jakewvincent/mkdnflow.nvim',
    config = function()
        require('mkdnflow').setup({})

        local opts = { noremap = true, silent = true }
        vim.api.nvim_set_keymap(
            'n', '<leader>ll', ':MkdnFollowLink<cr>', opts
        )
    end
}
