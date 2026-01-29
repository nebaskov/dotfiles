return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("claudecode").setup({})
    vim.keymap.set("t", "<C-q>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Toggle Claude focus" })
    vim.keymap.set("n", "<C-q>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Toggle Claude focus" })
  end,
  lazy = false,
  keys = {
    { "<leader>lc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>lf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>lr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>lC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>lm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>lb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>ls", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>ls",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    -- Diff management
    { "<leader>la", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ld", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
