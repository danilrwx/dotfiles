all: config-base
config-base:
	ln -snf $(PWD)/.config/helix ~/.config/helix
	ln -snf $(PWD)/.config/htop ~/.config/htop
	ln -snf $(PWD)/.config/lazygit ~/.config/lazygit
	ln -sf $(PWD)/.zshrc ~/.zshrc

config-sway:
	ln -sf $(PWD)/.zprofile ~/.zprofile
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/.config/waybar ~/.config/waybar
	ln -sf $(PWD)/.config/electron-flags.conf ~/.config/electron-flags.conf
	ln -sf $(PWD)/.config/code-flags.conf ~/.config/code-flags.conf

config-i3:
	ln -sf $(PWD)/.zprofile ~/.zprofile
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/.config/i3 ~/.config/i3
	ln -snf $(PWD)/.config/alacritty ~/.config/alacritty

arch-base:
	sudo pacman --needed -S htop git curl zsh firefox lazygit helix go rust otf-font-awesome ttc-iosevka man base-devel libffi libyaml openssl zlib postgresql-libs mariadb-libs imagemagick

arch-i3:
	sudo pacman --needed -S udiskie udisks2 gnome-keyring keychain feh alacritty

arch-sway:
	sudo pacman --needed -S seatd tlp acpid waybar lua-language-server brightnessctl udiskie udisks2 mako xorg-xwayland xdg-desktop-portal wofi swaybg gnome-keyring keychain thermald

wsl-base:
	sudo apt install htop git curl zsh autoconf bison patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev imagemagick libmariadb-dev libpq-dev libmagickwand-dev

deps: deps-gem deps-npm deps-go

deps-go:
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/gopls@latest
	go install -tags 'clickhouse' github.com/xo/usql@latest
deps-gem:
	gem install solargraph

deps-npm:
	npm install -g typescript typescript-language-server vscode-langservers-extracted

systemd:
	sudo usermod -a -G seat $(USER)
	systemctl enable seatd
	systemctl enable tlp
	systemctl enable acpid
	systemctl enable thermald

git:
	git config --global core.editor "helix"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

ohmyzsh:
	sh -c "$$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

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
	rm -rf ~/yay

printer:
	yay -S pantum-driver gscan2pdf ghostscript

flatpak-install:
	flatpak install flathub com.github.tchx84.Flatseal org.telegram.desktop com.google.Chrome org.telegram.desktop io.dbeaver.DBeaverCommunity org.libreoffice.LibreOffice de.shorsh.discord-screenaudio
