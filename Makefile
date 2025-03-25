all:
	make base
	make git

base:
	mkdir -p ~/.config
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.gitignore_global ~/.gitignore_global
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/vim ~/.config/vim
	ln -snf $(PWD)/config/lazygit ~/.config/
	ln -snf $(PWD)/config/ghostty ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

sway:
	ln -snf $(PWD)/config/sway ~/.config/
	ln -snf $(PWD)/config/foot ~/.config/
	ln -snf $(PWD)/config/waybar ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

font:
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip
	mkdir -p ~/.local/share/fonts
	cd ~/.local/share/fonts && unzip $(PWD)/Iosevka.zip
	rm $(PWD)/Iosevka.zip
	fc-cache -f

ubuntu-packages:
	sudo apt install -y curl bash-completion  unzip

fedora-copr:
	sudo dnf copr enable atim/lazygit -y
	sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install -y lame\* --exclude=lame-devel
	sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel

fedora-packages:
	sudo dnf install lazygit
	sudo dnf install -y google-chrome-stable neovim sensors jq yq difft wl-clipboard docker htop tmux curl man zip unzip jq keychain ripgrep rsync fzf wget fd-find openssl kubernetes-client zsh
	sudo dnf install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
	sudo dnf install -y ImageMagick-devel postgresql-devel mariadb-devel shared-mime-info libwebp

brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit fzf httpie asdf ripgrep \
	neofetch jq keychain wget fd openssl readline libyaml gmp autoconf tmux neovim \
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

