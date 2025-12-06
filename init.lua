-- ==========================================
--    SYSTEM-SPEZIFISCHE PFADE
-- ==========================================
-- Diese Pfade kannst du anpassen für verschiedene Systeme

-- Java Pfade (für JDTLS)
local JAVA_HOME = "/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk"
local JAVA_BIN = JAVA_HOME .. "/bin/java"

-- JDTLS Installation
local JDTLS_PATH = vim.fn.expand("~/.local/share/nvim/jdtls")
local JDTLS_CONFIG = JDTLS_PATH .. "/config_linux"
local JDTLS_WORKSPACE = vim.fn.expand("~/.cache/jdtls-workspace")

-- Lazy.nvim Pfad
local LAZY_PATH = vim.fn.expand("~/.local/share/nvim/lazy/lazy.nvim")

-- ==========================================
--    GRUNDEINSTELLUNGEN
-- ==========================================
vim.g.have_nerd_font = true
vim.opt.number = true  -- Zeilennummern anzeigen
-- Leader bleibt auf Default (Backslash \)

-- Termguicolors für bessere Farben (wichtig für Treesitter!)
vim.opt.termguicolors = true

-- Diagnostics (Fehler/Warnungen) konfigurieren mit Nerd Font Icons
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = 'if_many',
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
  },
})

-- Diagnostics Zeichen in der Gutter mit Nerd Font Icons
local signs = {
  Error = "󰅚",
  Warn = "󰀪",
  Hint = "󰌶",
  Info = "󰋽"
}
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  -- Lazy.nvim Setup
  vim.opt.rtp:prepend(LAZY_PATH)

  require("lazy").setup({
    -- LSP
    "neovim/nvim-lspconfig",

    -- multi Cursor
    'mg979/vim-visual-multi',

    -- Icons für Neovim (WICHTIG für nvim-tree!)
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
    require('nvim-web-devicons').setup({
      override = {},
      default = true,
    })
    end
  },

  -- moderner Filetree mit Icons
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
    require('nvim-tree').setup({
      renderer = {
        icons = {
          glyphs = {
            default = "󰈚",
            symlink = "",
            folder = {
              default = "",
              empty = "",
              empty_open = "",
              open = "",
              symlink = "",
              symlink_open = "",
              arrow_open = "",
              arrow_closed = "",
            },
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
    })
    end
  },

  -- Status Line mit Icons
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = 'tokyonight',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    })
    end,
  },

  -- Autocompletion
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",

  -- Modernes Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
    vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- Treesitter für besseres Syntax Highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        -- System & Config
        "bash", "fish",
        "vim", "vimdoc", "lua",
        "regex", "markdown", "markdown_inline",

        -- Web Development
        "html", "css", "scss", "javascript", "typescript",
        "tsx", "json", "yaml", "toml",

        -- Backend
        "python", "rust", "go", "c", "cpp",
        "java", "kotlin", "swift",
        "ruby", "php", "elixir",

        -- Functional
        "haskell", "ocaml", "erlang",

        -- Data & Query
        "sql", "graphql",

        -- Build & Tools
        "make", "cmake", "dockerfile",
        "git_config", "git_rebase", "gitcommit", "gitignore",

        -- Markup & Docs
        "xml", "latex", "bibtex",

        -- Other
        "diff", "comment",
      },

      auto_install = true,
      sync_install = false,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      indent = {
        enable = true
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
    })
    end,
  },
  }, {
    rocks = {
      enabled = false,
    },
  })

  -- Suppress lspconfig warnings
  vim.notify = function(msg, log_level, _)
  if msg:match("lspconfig") then return end
    vim.api.nvim_echo({{msg}}, true, {})
    end

    -- Capabilities für alle LSPs
    local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if cmp_ok then
      capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- nvim-cmp Setup mit einfachen Icons
      if cmp_ok then
        local cmp = require("cmp")

        cmp.setup({
          completion = {
            completeopt = "menu,menuone,noselect"
          },
          formatting = {
            format = function(entry, vim_item)
              -- Icon Map (ohne externe Library)
        local kind_icons = {
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",
          Field = "󰜢",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "",
        }

        -- Icon setzen
        vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind] or "", vim_item.kind)

        -- Source anzeigen
        vim_item.menu = ({
          nvim_lsp = "[LSP]",
        })[entry.source.name]

        return vim_item
        end
          },
          mapping = cmp.mapping.preset.insert({
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
                                              ["<Tab>"] = cmp.mapping.confirm({ select = true }),
                                              ["<C-n>"] = cmp.mapping.select_next_item(),
                                              ["<C-p>"] = cmp.mapping.select_prev_item(),
                                              ["<C-Space>"] = cmp.mapping.complete(),
          }),
          sources = {
            { name = "nvim_lsp" },
          },
        })
        end

        -- LSP on_attach Funktion
        local function on_attach(client, bufnr)
        local opts = { buffer = bufnr, silent = true }

        -- Keybindings
        vim.keymap.set("n", "<C-space>", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<Leader>a", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<Leader>r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<Leader>f", vim.lsp.buf.format, opts)

        -- DIAGNOSTICS Keybindings
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<Leader>q", vim.diagnostic.setloclist, opts)

        -- Inlay Hints aktivieren (Neovim 0.10+)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

          -- Toggle mit Keybinding
          vim.keymap.set("n", "<Leader>h", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, opts)
          end
          end

          local lspconfig = require("lspconfig")

          -- ==========================================
          --    GO (GOPLS)
          -- ==========================================
          lspconfig.gopls.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
            on_attach(client, bufnr)

            -- Format on Save für Go
            if client.server_capabilities.documentFormattingProvider then
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                -- Organize imports und Format
                local params = vim.lsp.util.make_range_params()
                params.context = {only = {"source.organizeImports"}}
                local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
                for _, res in pairs(result or {}) do
                  for _, r in pairs(res.result or {}) do
                    if r.edit then
                      vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
                      else
                        vim.lsp.buf.execute_command(r.command)
                        end
                        end
                        end
                        vim.lsp.buf.format({ async = false })
                        end,
              })
              end
              end,
              settings = {
                gopls = {
                  analyses = {
                    unusedparams = true,
                    shadow = true,
                    nilness = true,
                    unusedwrite = true,
                  },
                  staticcheck = true,
                  gofumpt = true,
                  hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                  },
                },
              },
          })

          -- ==========================================
          --    RUBY (RUBY-LSP)
          -- ==========================================
          lspconfig.ruby_lsp.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
            on_attach(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            end,
            init_options = {
              enabledFeatures = {
                "documentHighlights",
                "documentSymbols",
                "foldingRanges",
                "selectionRanges",
                "semanticHighlighting",
                "codeActions",
                "diagnostics",
                "hover",
                "completion",
                "documentLink",
              },
              formatter = "none",
            },
          })

          -- Rubocop Formatting für Ruby-Files
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "ruby",
            callback = function(args)
            local bufnr = args.buf

            vim.keymap.set("n", "<Leader>f", function()
            local file = vim.fn.expand("%:p")
            local output = vim.fn.system("rubocop -A " .. vim.fn.shellescape(file) .. " 2>&1")

            if vim.v.shell_error == 0 or output:match("no offenses detected") or output:match("offense") then
              vim.cmd("silent! edit!")
              print("✓ Ruby formatted with Rubocop")
              else
                print("✗ Rubocop error: " .. output)
                end
                end, { buffer = bufnr, desc = "Format Ruby with Rubocop" })

            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
              local file = vim.fn.expand("%:p")
              vim.fn.system("rubocop -A " .. vim.fn.shellescape(file) .. " 2>&1")
              vim.cmd("silent! edit!")
              end,
            })
            end,
          })

          -- ==========================================
          --    RUST ANALYZER
          -- ==========================================
          lspconfig.rust_analyzer.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
            on_attach(client, bufnr)

            if client.server_capabilities.documentFormattingProvider then
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                vim.lsp.buf.format({ async = false })
                end,
              })
              end
              end,
              settings = {
                ["rust-analyzer"] = {
                  check = {
                    command = "clippy"
                  },
                  inlayHints = {
                    enable = true,
                    bindingModeHints = { enable = true },
                    chainingHints = { enable = true },
                    closingBraceHints = { enable = true, minLines = 0 },
                    closureReturnTypeHints = { enable = "always" },
                    lifetimeElisionHints = { enable = "always", useParameterNames = true },
                    parameterHints = { enable = true },
                    typeHints = {
                      enable = true,
                      hideClosureInitialization = false,
                      hideNamedConstructor = false
                    },
                    maxLength = 25,
                    renderColons = true,
                  },
                  hover = {
                    actions = {
                      enable = true,
                      references = { enable = true },
                      run = { enable = true }
                    },
                    documentation = {
                      enable = true,
                      keywords = { enable = true }
                    }
                  },
                  hoverActions = {
                    references = false
                  },
                  cargo = {
                    allFeatures = true,
                    loadOutDirsFromCheck = true,
                  },
                  procMacro = {
                    enable = true
                  },
                },
              },
          })

          -- ==========================================
          --    C/C++ (CLANGD)
          -- ==========================================
          lspconfig.clangd.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
            on_attach(client, bufnr)

            if client.server_capabilities.documentFormattingProvider then
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                vim.lsp.buf.format({ async = false })
                end,
              })
              end
              end,
              cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=iwyu",
                "--completion-style=detailed",
                "--function-arg-placeholders",
                "--fallback-style=llvm",
                "--all-scopes-completion",
                "--header-insertion-decorators",
                "--pch-storage=memory",
              },
              init_options = {
                clangdFileStatus = true,
                usePlaceholders = true,
                completeUnimported = true,
                semanticHighlighting = true,
              },
              filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
          })

          -- ==========================================
          --    JAVA (JDTLS)
          -- ==========================================
          if vim.fn.executable(JAVA_BIN) == 1 and JAVA_HOME then
            local jdtls_jar = vim.fn.glob(JDTLS_PATH .. "/plugins/org.eclipse.equinox.launcher_*.jar")

            if vim.fn.filereadable(jdtls_jar) == 1 then
              vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                once = true,
                callback = function()
                print("Java Home: " .. JAVA_HOME)
                print("JDTLS Jar: " .. jdtls_jar)
                print("JDTLS startet...")
                end
              })

              lspconfig.jdtls.setup({
                capabilities = capabilities,
                on_attach = function(client, bufnr)
                on_attach(client, bufnr)
                print("JDTLS erfolgreich gestartet!")

                local opts = { buffer = bufnr, silent = true }
                vim.keymap.set("n", "<Leader>oi", "<Cmd>lua require'jdtls'.organize_imports()<CR>", opts)

                if client.server_capabilities.documentFormattingProvider then
                  vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    callback = function()
                    vim.lsp.buf.format({ async = false })
                    end,
                  })
                  end
                  end,
                  handlers = {
                    ["language/status"] = function() end,
                  },
                  cmd = {
                    JAVA_BIN,
                    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                    "-Dosgi.bundles.defaultStartLevel=4",
                    "-Declipse.product=org.eclipse.jdt.ls.core.product",
                    "-Dlog.protocol=true",
                    "-Dlog.level=ERROR",
                    "-Xms512m",
                    "-Xmx1g",
                    "--add-modules=ALL-SYSTEM",
                    "--add-opens", "java.base/java.util=ALL-UNNAMED",
                    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
                    "-jar", jdtls_jar,
                    "-configuration", JDTLS_CONFIG,
                    "-data", JDTLS_WORKSPACE .. "/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
                  },
                  root_dir = function(fname)
                  local root = lspconfig.util.root_pattern('pom.xml', 'build.gradle', 'build.gradle.kts', '.git')(fname)
                  if not root then
                    root = vim.fn.getcwd()
                    local classpath_file = root .. "/.classpath"
                    if vim.fn.filereadable(classpath_file) == 0 then
                      local classpath_content = [[<?xml version="1.0" encoding="UTF-8"?>
                      <classpath>
                      <classpathentry kind="src" path=""/>
                      <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
                      <classpathentry kind="output" path="bin"/>
                      </classpath>]]
                      vim.fn.writefile(vim.split(classpath_content, "\n"), classpath_file)
                      end
                      end
                      return root
                      end,
                      init_options = {
                        bundles = {},
                        extendedClientCapabilities = {
                          progressReportProvider = false,
                          classFileContentsSupport = true,
                          generateToStringPromptSupport = true,
                          hashCodeEqualsPromptSupport = true,
                          advancedExtractRefactoringSupport = true,
                          advancedOrganizeImportsSupport = true,
                          generateConstructorsPromptSupport = true,
                          generateDelegateMethodsPromptSupport = true,
                          moveRefactoringSupport = true,
                          overrideMethodsPromptSupport = true,
                          inferSelectionSupport = {"extractMethod", "extractVariable", "extractConstant"},
                        }
                      },
                      settings = {
                        java = {
                          home = JAVA_HOME,
                          jdt = {
                            ls = {
                              java = {
                                home = JAVA_HOME
                              },
                              vmargs = "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx1g -Xms100m"
                            }
                          },
                          eclipse = {
                            downloadSources = true,
                          },
                          maven = {
                            downloadSources = true,
                          },
                          implementationsCodeLens = {
                            enabled = true,
                          },
                          referencesCodeLens = {
                            enabled = true,
                          },
                          references = {
                            includeDecompiledSources = true,
                          },
                          format = {
                            enabled = true,
                          },
                          signatureHelp = { enabled = true },
                          contentProvider = { preferred = 'fernflower' },
                          completion = {
                            favoriteStaticMembers = {
                              "org.junit.Assert.*",
                              "org.junit.Assume.*",
                              "org.junit.jupiter.api.Assertions.*",
                              "org.mockito.Mockito.*",
                            },
                            filteredTypes = {
                              "com.sun.*",
                              "java.awt.*",
                              "jdk.*",
                              "sun.*",
                            },
                            importOrder = {
                              "java",
                              "javax",
                              "com",
                              "org"
                            }
                          },
                          sources = {
                            organizeImports = {
                              starThreshold = 9999,
                              staticStarThreshold = 9999,
                            }
                          },
                          codeGeneration = {
                            toString = {
                              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                            },
                            useBlocks = true,
                          },
                          configuration = {
                            runtimes = {
                              {
                                name = "JavaSE-21",
                                path = JAVA_HOME,
                                default = true
                              }
                            },
                            updateBuildConfiguration = "automatic"
                          },
                          inlayHints = {
                            parameterNames = {
                              enabled = "all"
                            }
                          }
                        }
                      }
              })
              end
              end

              -- ==========================================
              --    PYTHON (PYRIGHT + RUFF)
              -- ==========================================
              lspconfig.pyright.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                  python = {
                    analysis = {
                      typeCheckingMode = "basic",
                      autoSearchPaths = true,
                      useLibraryCodeForTypes = true,
                      diagnosticMode = "workspace",
                      autoImportCompletions = true,
                      diagnosticSeverityOverrides = {
                        reportUnusedVariable = "warning",
                        reportUnusedImport = "warning",
                        reportMissingTypeStubs = "none",
                        reportMissingImports = "error",
                        reportUndefinedVariable = "error",
                      },
                      completeFunctionParens = true,
                    },
                    inlayHints = {
                      variableTypes = true,
                      functionReturnTypes = true,
                      parameterTypes = true,
                    }
                  }
                }
              })

              lspconfig.ruff_lsp.setup({
                capabilities = capabilities,
                on_attach = function(client, bufnr)
                client.server_capabilities.hoverProvider = false
                client.server_capabilities.completionProvider = false
                on_attach(client, bufnr)

                vim.keymap.set("n", "<Leader>F", function()
                vim.lsp.buf.code_action({
                  context = {
                    only = { "source.fixAll" },
                    diagnostics = {},
                  },
                  apply = true,
                })
                end, { buffer = bufnr, desc = "Ruff: Fix all auto-fixable" })

                vim.keymap.set("n", "<Leader>o", function()
                vim.lsp.buf.code_action({
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {},
                  },
                  apply = true,
                })
                end, { buffer = bufnr, desc = "Ruff: Organize imports" })
                end,
                init_options = {
                  settings = {
                    args = {
                      "--line-length=88",
                      "--select=ALL",
                      "--ignore=E501",
                    },
                  }
                }
              })

              -- ==========================================
              --    FILETYPE-SPEZIFISCHE EINSTELLUNGEN
              -- ==========================================

              vim.api.nvim_create_autocmd("FileType", {
                pattern = "go",
                callback = function()
                vim.bo.expandtab = false
                vim.bo.shiftwidth = 4
                vim.bo.tabstop = 4
                vim.bo.softtabstop = 4
                end,
              })

              vim.api.nvim_create_autocmd("FileType", {
                pattern = "ruby",
                callback = function()
                vim.bo.expandtab = true
                vim.bo.shiftwidth = 2
                vim.bo.tabstop = 2
                vim.bo.softtabstop = 2
                end,
              })

              vim.api.nvim_create_autocmd("FileType", {
                pattern = "python",
                callback = function()
                vim.bo.expandtab = true
                vim.bo.shiftwidth = 4
                vim.bo.tabstop = 4
                vim.bo.softtabstop = 4
                vim.bo.fixendofline = true
                vim.bo.endofline = true
                end,
              })

              vim.api.nvim_create_autocmd("BufWritePre", {
                pattern = "*.py",
                callback = function()
                if vim.fn.executable("black") == 1 then
                  local view = vim.fn.winsaveview()
                  local bufnr = vim.api.nvim_get_current_buf()
                  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                  local input = table.concat(content, "\n")
                  local result = vim.fn.systemlist("black --quiet - 2>/dev/null", input)

                  if vim.v.shell_error == 0 and #result > 0 then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
                    end

                    vim.fn.winrestview(view)
                    end
                    end,
              })

              vim.api.nvim_create_autocmd("FileType", {
                pattern = "rust",
                callback = function()
                vim.bo.expandtab = true
                vim.bo.shiftwidth = 4
                vim.bo.tabstop = 4
                end,
              })

              vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp" },
                callback = function()
                vim.bo.expandtab = true
                vim.bo.shiftwidth = 2
                vim.bo.tabstop = 2
                vim.bo.softtabstop = 2
                end,
              })

              vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function()
                vim.bo.expandtab = true
                vim.bo.shiftwidth = 4
                vim.bo.tabstop = 4
                vim.bo.softtabstop = 4
                end,
              })

              vim.api.nvim_create_autocmd("LspAttach", {
                pattern = "*.rs",
                callback = function(args)
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.server_capabilities.inlayHintProvider then
                  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                  end
                  end,
              })
