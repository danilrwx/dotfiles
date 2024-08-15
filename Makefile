all:
	mkdir -p ~/.config
	make base
	make git
	make packages
	make locale
	make docker
	make asdf
	make yay

base:
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

locale:
	echo 'ru_RU.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen
	echo 'LANG=ru_RU.UTF-8' | sudo tee -a /etc/locale.conf
	sudo locale-gen

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

packages: base-packages ruby-packages dev-packages

base-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip \
		jq keychain ripgrep neofetch rsync bash-completion fzf wget \
		lf lazygit fd sad git-delta go nodejs npm yarn httpie bat docker zsh \
	  openssh helm sops age kubectl k9s fluxcd inetutils man-pages man-pages-ru

ruby-packages:
	sudo pacman -S --needed base-devel rust libffi libyaml openssl zlib

dev-packages:
	sudo pacman -S --needed imagemagick postgresql-libs mariadb-libs shared-mime-info libwebp

yay:
	git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si && rm -rf ~/yay

asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0


