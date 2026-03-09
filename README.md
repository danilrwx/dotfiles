## Requirements

* Linux or Mac
* git (for automatic installation)
* make (for automatic installation)
* paru (AUR helper)
* [Nvim](https://github.com/neovim/neovim/wiki/Installing-Neovim) (version >= 0.4.4)

## Recommendations

* [Oh My Zsh!](https://github.com/ohmyzsh/ohmyzsh)

## Setup

```sh
git clone git@github.com:antoshindanil/dotfiles.git ~/dotfiles 
cd dotfiles

# arch
make arch-prepare

# configs
make nvim-install

# install all additional packages for languages (See Makefile for install packages for some language)
make deps

# update
make arch-update
```
