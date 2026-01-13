# YOUGET.nvim

YOUGET is a plugin that integrates nuget package managing into neovim.
It aims to be simple and elegant, merging with the rest of neovims features.

## Prerequisites
- **dotnet cli** must be installed.
- **telescope** wonderful plugin that youget depends upon (https://github.com/nvim-telescope/telescope.nvim)

## Features
Update the package under the cursor to the latest version
![Preview](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHpncHRodHJuZ2h3eTIxOHF1enl2c2FuN2dha3dkdWc3NDBpdzc2eCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gElj3vJpCSMEnKIwI0/giphy.gif)

Choose any available version for the package under the cursor
![Preview](https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExeHpoc2dpMnE2dHpzcThtdXh6ejFqMzVmdjFhNWk2cjBlNmNlOHVwZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/VGkPO2ep6nezxG9v19/giphy.gif)

From anywhere within the project, live search and add a new package
![Preview](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExc3pjYzB4Yjg0eTRrNHF2Z2pxMnE1cTIyanJmcmwxN3ZlMHd5dmVuMiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/UTNHuDTqPCZyQeiFEP/giphy.gif)

## Configuration
```lua
require('youget.nvim').setup{
    dotnet_path = "", --only necessary if it is not on path
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
