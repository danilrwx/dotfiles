all:
	mkdir -p ~/.config
	make base
	make packages
	make git

base: base-config

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/kak ~/.config/
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/helix ~/.config/

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/config/nvim ~/.config/nvim

packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip \
		jq keychain ripgrep neofetch rsync bash-completion fzf wget \
		lf lazygit fd sad git-delta go nodejs npm yarn httpie bat

ruby-packages:
	sudo pacman -S --needed base-devel rust libffi libyaml openssl zlib

dev-packages:
	sudo pacman -S --needed imagemagick postgresql-libs mariadb-libs shared-mime-info libwebp

yay:
	git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si && rm -rf ~/yay

asdf: asdf-install asdf-setup

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

asdf-setup:
	asdf plugin-add ruby
	asdf plugin-add nodejs
	asdf install nodejs 16.20.2
	asdf install ruby 3.0.1
	asdf install ruby 3.1.2

lsp-install:
	sudo pacman -S --needed yaml-language-server bash-language-server typescript-language-server \
		gopls marksman ansible-language-server taplo-cli vscode-json-languageserver \
		vscode-html-languageserver vscode-css-languageserver vue-language-server
	# sudo npm i -g "awk-language-server@>=0.5.2" sql-language-server
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/cmd/goimports@latest
