# smart-im.nvim

`smart-im.nvim` is a neovim plugin aimed to switch input method automatically and smartly while you are editing **comments** or **literal string** ([default](https://github.com/MSDimos/smart-im.nvim/blob/main/lua/smart-im/utils.lua#L137))

> If you are native English user, you may not need it.
>
> If you are Chinese, Japanese, Korean, etc. user, you may need it.

This plugin needs `nvim-treesitter` as dependency, it uses `nvim-treesitter`'s magic power to detect comments and literal string.

## Support

Current version works for NeoVim on:

- MacOS: [macism](https://github.com/laishulu/macism)
- Windows and WSL: [im-select]([GitHub - daipeihust/im-select: 📟 Switch your input method through terminal](https://github.com/daipeihust/im-select))
- Linux
  - Fcitx5
  - Fcitx(only switch between inactive and active)
  - IBus

> NOTICE: [im-select.nvim](https://github.com/keaising/im-select.nvim) use [im-select]([GitHub - daipeihust/im-select: 📟 Switch your input method through terminal](https://github.com/daipeihust/im-select)) on MacOS, but it can't work on my macbook (and I googled it, it's a long-time existed BUG), I tested it and decided to use [macism](https://github.com/laishulu/macism)

## Install

1. Install one corresponding tool list above. Make sure the executable file in a path that NeoVim can execute them.

2. Install this nvim plugin using your favorite plugin manager

### lazy.nvim

```lua
return {
    "MSDimos/smart-im.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "LazyFile",
    opts = {} -- your options
}
```

### packer.nvim

````lua
use(
    "MSDimos/smart-im.nvim",
    requires = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("smart-im").setup({ -- your options })
    end
)

## options

```lua
local utils = require("smart-im.utils")
local smartIM = require("smart-im")

-- default options
{
    override_cmd = '', -- For most users, it's useless. If you have other cmd to switch cmd, change it.
    sync = false, -- Execute cmd sync, default is async
    -- insert input method to switch
    -- for example, if you are Chinese user, you can set it as "com.apple.inputmethod.SCIM.ITABC"
    enter_insert_mode = "com.apple.keylayout.ABC",
    back_normal_mode = function ()
		return smartIM.previous_im or "com.apple.keylayout.ABC"
    end,
    -- accept a TSNode|nil to decide if switch IM or not use
    -- default: https://github.com/MSDimos/smart-im.nvim/blob/main/lua/smart-im/utils.lua#L137
    allow_changing_im = utils.allow_changing_im,
    -- This plugin will detect whether switch IM or not on TextChangedI
    -- for better performance, it will only detect the first `max_detect_input_count` TextChangedI event
    -- after that, it will do nothing
    max_detect_input_count = 5,
    ft = nil,
    ignore_ft = nil
}
````

For most users, the only option you need to change is `enter_insert_mode`, for example:

```lua
-- lazy.nvim
return {
    {
        "MSDimos/smart-im.nvim",
        event = "LazyFile",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
            enter_insert_mode = "com.apple.inputmethod.SCIM.ITABC",
        },
    }
}
```

## Third-dependency

### 1.1 Windows / WSL

#### Install

Please install `im-select.exe` and put it into your `PATH`.

Download URL: [im-select](https://github.com/daipeihust/im-select)
(For `x64` platform, please download the `64-bit` version.)

#### Check

You can check if the `im-select` executable can be properly accessed from Neovim/Vim by running the following command from your Command Prompt:

```bash
# find the command
$ where im-select.exe

# Get current im name
$ im-select.exe

# Try to switch to English keyboard
$ im-select.exe 1033
```

Or run shell command directly from NeoVim

```bash
:!where im-select.exe

:!im-select.exe 1003
```

### 1.2 macOS

#### Install

Please install [macism](https://github.com/laishulu/macism)

#### Check

Check installation in bash/zsh

```bash
# find binary
$ which macism

# Get current im name
$ macism

# Try to switch to English keyboard
$ macism com.apple.keylayout.ABC
```

Check in NeoVim

```bash
:!which macism
```

### 1.3 Linux

#### Install

Please install and config one of Input Methods: Fcitx / Fcitx5 / IBus

#### Check

Check installation in bash/zsh

**> Fcitx**

```bash
# find
$ which fcitx-remote

# activate IM
$ fcitx-remote -o

# inactivate IM
$ fcitx-remote -c
```

**> Fcitx5**

```bash
# find
$ which fcitx5-remote

# Get current im name
$ fcitx5-remote -n

# Try to switch to English keyboard
$ fcitx5-remote keyboard-us
```

**> IBus**

```bash
# find
$ which ibus

# Get current im name
$ ibus engine

# Try to switch to English keyboard
$ ibus xkb:us::eng
```

Check in NeoVim

```bash
# find
:!which fcitx
:!which fcitx5
:!which ibus
```

## Thanks

Thanks for [im-select.nvim](https://github.com/keaising/im-select.nvim)'s preliminary work, I have referred some of its codes, for details, see source code.
