require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls" }
vim.lsp.enable(servers)

vim.lsp.enable("roslyn_ls")

vim.lsp.config("roslyn_ls", {
  filetypes = { "razor", "cs" },

  settings = {
    -- better performance
    ["csharp|background_analysis"] = {
      dotnet_analyzer_diagnostics_scope = "openFiles",
      dotnet_compiler_diagnostics_scope = "openFiles",
    },
  },
})

