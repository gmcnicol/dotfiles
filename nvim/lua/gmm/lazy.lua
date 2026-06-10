local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
      require("catppuccin").setup({
        flavour = "mocha",
        background = {
          light = "mocha",
          dark = "mocha",
        },
        transparent_background = false,
        default_integrations = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          harpoon = true,
          mason = true,
          native_lsp = {
            enabled = true,
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          telescope = {
            enabled = true,
          },
          treesitter = true,
          which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("gmm.whichkey").setup()
    end,
  },
  { "tpope/vim-sleuth" },
  { "tpope/vim-commentary" },
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", opts = {} },

  { "nvim-lua/plenary.nvim" },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gmm.harpoon").setup()
    end,
  },
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "mrjones2014/smart-splits.nvim",
    config = function()
      require("gmm.splits").setup()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("gmm.treesitter").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = vim.fn.has("nvim-0.10") == 1,
    opts = {},
  },

  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },
  { "neovim/nvim-lspconfig" },
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },

  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip" },
  { "rafamadriz/friendly-snippets" },

  {
    "stevearc/conform.nvim",
    config = function()
      require("gmm.format").setup()
    end,
  },
  {
    "stevearc/overseer.nvim",
    config = function()
      require("gmm.tasks").setup()
    end,
  },

  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("gmm.dap").setup()
    end,
  },
  { "theHamsta/nvim-dap-virtual-text", opts = {} },
}, {
  change_detection = {
    notify = false,
  },
})

require("gmm.cmp").setup()
require("gmm.lsp").setup()
