all: config-install

config-install:
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf  $(PWD)/.config/sway ~/.config/sway
	ln -snf $(PWD)/.config/foot ~/.config/foot
	ln -snf $(PWD)/.config/helix ~/.config/helix
	ln -snf $(PWD)/.config/waybar ~/.config/waybar
	ln -snf $(PWD)/.config/htop ~/.config/htop
	ln -snf $(PWD)/.config/lazygit ~/.config/lazygit
	ln -sf $(PWD)/.config/electron-flags.conf ~/.config/electron-flags.conf
	ln -sf $(PWD)/.zprofile ~/.zprofile
	ln -sf $(PWD)/.zshrc ~/.zshrc

arch-prepare:
	sudo pacman --needed -S seatd htop git curl zsh firefox telegram-desktop discord tlp acpid waybar lua-language-server lazygit helix brightnessctl udiskie udisks2 go rust mako xorg-xwayland xdg-desktop-portal wofi otf-font-awesome ttc-iosevka man base-devel libffi libyaml openssl zlib postgresql-libs mariadb-libs imagemagick swaybg
deps: deps-gem deps-npm deps-go

deps-go:
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/gopls@latest
deps-gem:
	gem install solargraph

deps-npm:
	npm install -g typescript typescript-language-server vscode-langservers-extracted

systemd:
	sudo usermod -a -G seat $(USER)
	systemctl enable seatd
	systemctl enable tlp
	systemctl enable acpid

git:
	git config --global core.editor "helix"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

ohmyzsh:
	sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2
	~/.asdf/bin/asdf plugin-add ruby
	~/.asdf/bin/asdf plugin-add nodejs

asdf-install:
	~/.asdf/bin/asdf install ruby 3.1.2
	~/.asdf/bin/asdf install nodejs 14.21.3
	~/.asdf/bin/asdf global ruby 3.1.2
	~/.asdf/bin/asdf global nodejs 14.21.3

yay:
	git clone https://aur.archlinux.org/yay.git ~/yay
	cd ~/yay; makepkg -si
