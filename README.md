# YOUGET.nvim

YOUGET is a plugin that integrates nuget package managing into neovim.
It aims to be simple and elegant, in the spirit of the rest of neovims features.

## Prerequisites
- **dotnet cli** must be installed.
- **telescope** wonderful plugin that youget depends upon (https://github.com/nvim-telescope/telescope.nvim)

## Features
Update the package under the cursor to the latest version
![Preview](https://files.catbox.moe/9rk765.gif)

Choose any available version for the package under the cursor
![Preview](https://files.catbox.moe/4zigh1.gif)

From anywhere within the project, live search and add a new package
![Preview](https://files.catbox.moe/53n1cg.gif)

## Configuration
```lua
require('youget.nvim').setup{
    dotnet_path = "/path/to/dotnet", --only necessary if it is not on path
    include_prerelease = true --Should prereleases of nuget packages be included?
}
```

## Install
Using nvim.lazy
```lua
{
'tompish/youget.nvim',
dependencies = 'nvim-telescope/telescope.nvim'
}
```

Using pckr
```lua
{
'tompish/youget.nvim',
requires = 'nvim-telescope/telescope.nvim'
}
```

## Putting it all together
An example setup, using lazy, would be as follow:
```lua
{
'tompish/youget.nvim',
dependencies = 'nvim-telescope/telescope.nvim',
config = function()
    local youget = require('youget')

    youget.setup{ include_prerelease = true }

    vim.keymap.set('n', '<leader>nu', require("youget").update, {})
	vim.keymap.set('n', '<leader>na', require("youget").add, {})
	vim.keymap.set('n', '<leader>nc', require("youget").choose, {})
end
}
```
