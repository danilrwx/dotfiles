all:
	mkdir -p ~/.config
	make base
	make git

base:
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/helix ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

sway-config:
	ln -sf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/config/sway ~/.config/
	ln -snf $(PWD)/config/dunst ~/.config/
	ln -snf $(PWD)/config/foot ~/.config/

i3-config:
	ln -sf $(PWD)/Backgrounds ~/Backgrounds
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -sf $(PWD)/.profile ~/.profile
	ln -sf $(PWD)/.Xresources ~/.Xresources
	ln -snf $(PWD)/config/i3 ~/.config/
	ln -snf $(PWD)/config/dunst ~/.config/
	ln -snf $(PWD)/config/xfce4 ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

ubuntu-packages:
	sudo apt install -y build-essential curl bash-completion xorg i3 xcompmgr hsetroot \
	xfce4-terminal pavucontrol dunst acpi maim xclip xsel

brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit fzf httpie asdf ripgrep neofetch \
	 jq keychain wget fd openssl readline libyaml gmp autoconf tmux  neovim

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

