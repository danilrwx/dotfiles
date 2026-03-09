all:
	mkdir -p ~/.config
	make base
	make git
	make asdf

base:
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.profile ~/.profile
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

locale:
	echo 'ru_RU.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen
	echo 'LANG=ru_RU.UTF-8' | sudo tee -a /etc/locale.conf
	sudo locale-gen

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

fedora-packages:
	sudo dnf copr enable yohane-shiro/nekoray
	sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
	sudo dnf install -y lame\* --exclude=lame-devel
	sudo dnf group upgrade -y --with-optional Multimedia
	sudo dnf install -y telegram-desktop discord wireguard-tools nvtop nekoray
	sudo dnf install -y  htop git tmux curl man zip unzip jq keychain ripgrep neofetch rsync bash-completion fzf wget fd-find go httpie bat openssl kubernetes-client podman zsh
	sudo dnf install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
	sudo dnf install -y ImageMagick-devel postgresql-devel mariadb-devel shared-mime-info libwebp

arch-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip jq keychain ripgrep neofetch rsync bash-completion fzf wget lf lazygit fd sad git-delta go nodejs npm yarn httpie bat docker zsh openssh helm sops age kubectl k9s fluxcd inetutils man-pages man-pages-ru
	sudo pacman -S --needed base-devel rust libffi libyaml openssl zlib
	sudo pacman -S --needed imagemagick postgresql-libs mariadb-libs shared-mime-info libwebp
	git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si && sudo rm -rf ~/yay


brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

