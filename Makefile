all:
	mkdir -p ~/.config
	make base
	make git
	make packages
	make asdf

base:
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

packages: copr-packages base-packages ruby-packages dev-packages

copr-packages:
	sudo dnf copr enable yohane-shiro/nekoray

base-packages:
	sudo dnf install -y  htop git tmux curl man zip unzip jq keychain \
		ripgrep neofetch rsync bash-completion fzf wget fd-find go httpie \
		bat openssl kubernetes-client podman nekoray

ruby-packages:
	sudo dnf install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel \
	libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

dev-packages:
	sudo dnf install -y ImageMagick-devel postgresql-devel mariadb-devel shared-mime-info libwebp

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit

asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0


