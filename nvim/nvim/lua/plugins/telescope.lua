return {
    'nvim-telescope/telescope.nvim',
    version = '0.1.5',
    dependencies = { {'nvim-lua/plenary.nvim'} },
    config = function ()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
        vim.keymap.set('n', '<leader>fw', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") });
        end)
        vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
    end
}
