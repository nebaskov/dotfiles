return {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        require('telescope').setup({
            defaults = {
                file_ignore_patterns = { '.git/' },
                mappings = {
                    i = {
                        ['<C-h>'] = 'which_key',
                    },
                },
            },
            pickers = {
                find_files = {
                    hidden = true,
                },
                live_grep = {
                    additional_args = { '--hidden' },
                },
            },
        })

        require('telescope').load_extension('fzf')

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
        vim.keymap.set('n', '<leader>fr', function()
                builtin.oldfiles({ cwd_only = true })
            end,
            { desc = 'Telescope find recently opened files in the current project' })
    end,
}
