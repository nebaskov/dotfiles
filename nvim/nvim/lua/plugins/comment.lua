return {
    'numToStr/Comment.nvim',
    config = function ()
        require("Comment").setup({
            ignore = '^$',
            toggler = {
                line = '<leader>/',
                block = '<leader>//',
            },
            opleader = {
                line = '<leader>',
                block = '<leader>/',
            },
        })
    end
}
