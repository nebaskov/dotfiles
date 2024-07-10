return {
    "nvimtools/none-ls.nvim", -- configure formatters & linters
    lazy = true,
    -- event = { "BufReadPre", "BufNewFile" }, -- to enable uncomment this
    dependencies = {
        "jay-babu/mason-null-ls.nvim",
    },
    config = function()
        local mason_null_ls = require("mason-null-ls")

        local null_ls = require("null-ls")

        local null_ls_utils = require("null-ls.utils")

        mason_null_ls.setup({
            ensure_installed = {
                "flake8", -- python linter
                "eslint_d", -- js linter
                "trivy", -- general purpose linter
            },
        })

        local diagnostics = null_ls.builtins.diagnostics

        null_ls.setup({
            root_dir = null_ls_utils.root_pattern(".null-ls-root", "Makefile", ".git", "package.json"),
            sources = {
                diagnostics.flake8,
                diagnostics.estlint_d.with({
                    condition = function()
                        return utils.root_has_file(".estlintrc.js", ".estlintrc.cjs")
                    end
                }),
                diagnostics.trivy
            }
        })
    end
}
