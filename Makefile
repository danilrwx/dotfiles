all:
	mkdir -p ~/.config
	make base
	make git

base:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/vim ~/.vim
	ln -snf $(PWD)/config/helix ~/.config/
	ln -snf $(PWD)/config/lazygit ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

dwm-install:
	cd $(PWD)/dwm && sudo make clean install
	cd $(PWD)/dmenu && sudo make clean install
	cd $(PWD)/st && sudo make clean install

dwm-config:
	ln -sf $(PWD)/Backgrounds ~/Backgrounds
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -sf $(PWD)/.profile ~/.profile
	ln -sf $(PWD)/.Xresources ~/.Xresources
	ln -snf $(PWD)/config/dunst ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

font:
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip
	mkdir -p ~/.local/share/fonts
	cd ~/.local/share/fonts && unzip $(PWD)/Iosevka.zip
	rm $(PWD)/Iosevka.zip
	fc-cache -f

base-packages:
	sudo apt install -y build-essential curl bash-completion xorg xcompmgr hsetroot \
	brightnessctl dunst acpi maim xclip xsel pipewire pipewire-pulse pavucontrol

brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit fzf httpie asdf ripgrep \
	neofetch jq keychain wget fd openssl readline libyaml gmp autoconf tmux  neovim python3 \
	yq fx yh highlight moar difftastic

brew-mac:
	brew install chromium --no-quarantine
	brew install go-task/tap/go-task
	brew install metalbear-co/mirrord/mirrord
	brew install homeport/tap/dyff

go-packages:
	go install github.com/kubernetes-sigs/controller-tools@latest

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

