all:
	mkdir -p ~/.config
	make base
	make git
	make asdf

base:
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/kitty ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

packages: base-packages system-packages ruby-packages dev-packages

copr-packages:
	sudo dnf copr enable principis/howdy

system-packages:
	sudo dnf install gnome-extensions-app gnome-shell-extension-appindicator \
	perl-FindBin wl-clipboard touchegg howdy

base-packages:
	sudo dnf install -y  htop git tmux curl man zip unzip jq keychain \
		ripgrep neofetch rsync bash-completion fzf wget fd-find go httpie \
		bat openssl kubernetes-client

ruby-packages:
	sudo dnf install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel \
	libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

dev-packages:
	sudo dnf install -y ImageMagick-devel postgresql-devel mariadb-devel shared-mime-info libwebp

brew-packages:
	brew install brew-cask-completion sops regctl k9s lazygit

asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

kanata:
	sudo groupadd uinput
	sudo usermod -aG input $USER
	sudo usermod -aG uinput $USER
	echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee -a /etc/udev/rules.d/99-input.rules
	mkdir -p ~/.config/systemd/user
	ln -sf $(PWD)/kanata/kanata.service ~/.config/systemd/user/
	systemctl --user enable kanata.service
	systemctl --user start kanata.service


