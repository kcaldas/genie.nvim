# genie.nvim

A Neovim plugin for the [Genie CLI](https://github.com/kcaldas/genie). Ask questions about your code or open Genie in a floating terminal.

## Installation

### lazy.nvim
```lua
{
  "kcaldas/genie.nvim",
  config = function()
    require("genie").setup()
  end
}
```

### packer.nvim
```lua
use {
  "kcaldas/genie.nvim",
  config = function()
    require("genie").setup()
  end
}
```

## Commands

- **`:Genie`** - Open Genie in floating terminal
- **`:GenieAsk "question"`** - Ask a quick question with file context
- **`:GenieEdit`** - Open buffer editor to craft detailed questions

## Usage

### Quick Questions
```vim
:GenieAsk "How do I optimize this function?"
```
Automatically includes your current file reference and selected code.

### Buffer Editor
```vim
:GenieEdit
```
Opens an editor showing the context that will be sent. Type your question and press `<Enter>` to send, `<Esc>` to cancel.

### Interactive Mode
```vim
:Genie
```
Full Genie TUI in a floating window.

## Key Mappings

```lua
vim.keymap.set('n', '<leader>gg', ':Genie<CR>')
vim.keymap.set('n', '<leader>ga', ':GenieEdit<CR>')
vim.keymap.set('v', '<leader>ga', ':GenieEdit<CR>')
```

## Prerequisites

- Neovim >= 0.8.0
- [Genie CLI](https://github.com/kcaldas/genie) installed

Download Genie from: https://github.com/kcaldas/genie/releases

## License

MIT