# tree-sitter-polar

A tree-sitter parser genreator for the Polar language.

## Prerequisites

Install the tree-sitter and formatting CLIs

```sh
cargo install --locked tree-sitter-cli
cargo install --locked topiary-cli
```

And [entr](https://github.com/eradman/entr) (needed for development watcher scripts).

## Development

### Parser/Grammer dev

1. Pick a Polar policy you want to validate against
2. Start the watcher: `./watchparse.sh <path/to/policy.polar>`
   * Any additional positional args will be passed through to `tree-sitter
     parse`.
3. Edit `grammar.js`. The output from the `watchparse.sh` session will update
   when either the policy or grammar files are updated.

Additional tree exploration can take place in the playground:

```sh
tree-sitter build --wasm && \
    tree-sitter playground --grammar-path .
```

### Highlight dev

#### Neovim

To avoid negative interactions with existing Neovim plugins, it's recommended
that you use a fresh config for development. This can be accomplished through
the use of an `APPNAME`.

```sh
# Linux
mkdir -p ~/.config/nvim-polar/queries/polar/
touch ~/.config/nvim-polar/init.lua
ln -s /path/to/tree-sitter-polar/queries/highlights.scm ~/.config/nvim-polar/queries/polar/
```

Then, update the newly-created `init.lua` with a plugin manager and tree-sitter
config. Note that you'll need to update the parser URL to point to this
repository on your system

<details>
<summary>`init.lua`</summary>

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        {
            "scottmckendry/cyberdream.nvim",
            lazy = false,
            priority = 1000,
            opts = {
                italic_comments = true,
            },
        },
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            event = { "BufReadPost", "BufNewFile" },
            opts = {
                indent = {
                    enable = false
                },
                highlight = {
                    enable = true,
                    disable = {},
                    additional_vim_regex_highlighting = false
                }
            },
            config = function(_, opts)
                require("nvim-treesitter.configs").setup(opts)
            end,
        }
    },
    -- automatically check for plugin updates
    checker = { enabled = true },
})

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.polar = {
  install_info = {
    url = "/path/to/tree-sitter-polar", -- local path or git repo
    files = {"src/parser.c"},
    generate_requires_npm = false, -- if stand-alone parser without npm dependencies
    requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
  },
  filetype = "polar",
}

vim.api.nvim_create_autocmd("BufRead", { pattern = "*.polar", command = "set ft=polar" })
vim.treesitter.language.register("polar", "polar")
```
</details>

Then, launch Neovim: `NVIM_APPNAME=nvim-polar nvim`


Lazy.nvim and the associated plugins should
automatically install, but it's generally a safe call to restart nvim for a
fresh session.

Once launched, install the Treesitter parser `:TSInstall polar`.

If you load a Polar file and it isn't being highlighted, you may need to ensure;

* The Treesitter parser is enabled for the buffer: `:TSBufEnable polar`
* Neovim is treating the Polar file as such: `:set ft=polar`

Once everything looks good, you can experiment with queries by writing
S-expressions in the `:EditQuery` prompt. Placing the cursor over the capture
name in the query buffer should highlight the relevant code segments in the
Polar buffer.

Once you're happy with the state of your query in the editor, you can copy it
back to `queries/highlights.scm`, and then restart Neovim to observe and refine
your changes.


### Formatter dev

Assuming tree-sitter is already configured on your system, create the topiary config:

```sh
mkdir -p ~/.config/topiary/queries/
ln -s /path/to/tree-sitter-polar/queries/formatter.scm ~/.config/topiary/queries/polar.scm
```

0. `export TOPIARY_LANGUAGE_DIR=~/.config/topiary/queries` in a shell.
1. Pick a Polar policy you want to validate against
2. Start the watcher: `./watchformat.sh <path/to/policy.polar>` in the same
   shell `TOPIARY_LANGUAGE_DIR` is set.
   * Any additional positional args will be passed through to `topiary format`.
3. Edit `formatter.scm`. The output from the `watchformat.sh` session will
   update when either the policy or format query files are updated.

### Query Linting

We use [ts_query_ls](https://github.com/ribru17/ts_query_ls) to format and
validate tree-sitter queries.

```sh
# Lint queries
make lintquery

# Format queries
make formatquery

# Check queries for issues (lints and formats, used by CI)
make checkquery

# Do all of the above in order
make query
```
