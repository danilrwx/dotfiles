all:
	mkdir -p ~/.config
	make base
	make git
	make asdf

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

vim-install:
	rm -rf ~/.vim
	mkdir -p ~/.vim
	ln -snf $(PWD)/.config/vim/autoload ~/.vim/autoload
	ln -sf $(PWD)/.vimrc ~/.vimrc

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc

base-packages:
	doas apt install htop git tmux curl man zip unzip jq keychain ripgrep neofetch mosh rsync bash-completion

dev-packages:
	doas  apt install autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev imagemagick libmariadb-dev libpq-dev libmagickwand-dev

debian:
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	# doas ln -sf $(PWD)/20-intel.conf /etc/X11/xorg.conf.d/
	doas apt install maim xclip i3 rofi dunst xcompmgr udisks2 sxiv qterminal firefox-esr acpi libnotify-bin

git: git-config git-change-remote

git-config:
	git config --global core.editor "nvim"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

asdf-setup:
	asdf plugin-add golang
	asdf plugin-add neovim
	asdf plugin-add ruby
	asdf plugin-add nodejs

flatpak: flatpak-add flatpak-install

flatpak-add:
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak-install:
	flatpak install flathub com.discordapp.Discord com.valvesoftware.Steam org.telegram.desktop com.github.Eloston.UngoogledChromium
