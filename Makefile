all: config-base

PACKER_PATH=~/.local/share/nvim/site/pack/packer/start

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	rm -rf $(PACKER_PATH) || exit 0
	git clone --depth 1 https://github.com/wbthomason/packer.nvim $(PACKER_PATH)/packer.nvim
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

config-base:
	ln -snf $(PWD)/.config/htop ~/.config/htop
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.vimrc ~/.vimrc

config-xorg:
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/.config/awesome ~/.config/awesome
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -snf $(PWD)/.config/kitty ~/.config/kitty
	ln -sf $(PWD)/.xinitrc ~/.xinitrc

config-wayland:
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -sf $(PWD)/.bash_profile.wayland ~/.bash_profile
	ln -snf $(PWD)/.config/sway ~/.config/sway
	ln -snf $(PWD)/.config/foot ~/.config/foot
	ln -snf $(PWD)/.config/wofi ~/.config/wofi
	ln -snf $(PWD)/.config/i3blocks ~/.config/i3blocks
	ln -sf $(PWD)/.config/electron-flags.conf ~/.config/electron-flags.conf
	ln -sf $(PWD)/.config/code-flags.conf ~/.config/code-flags.conf

arch-base:
	sudo pacman --needed -S htop git curl lazygit go man base-devel zip unzip ranger jq keychain ripgrep

arch-xorg:
	sudo pacman --needed -S udiskie udisks2 firefox gnome-keyring otf-font-awesome ttc-iosevka kitty maim xclip xdotool ttf-nerd-fonts-symbols ttf-jetbrains-mono ttf-jetbrains-mono-nerd

arch-wayland:
		sudo pacman --needed -S udiskie udisks2 mako xorg-xwayland xdg-desktop-portal wofi swaybg gnome-keyring  sway slurp grim wl-clipboard i3blocks

arch-libs:
		sudo pacman --needed -S libffi libyaml openssl zlib postgresql-libs mariadb-libs imagemagick

arch-laptop:
	sudo pacman --needed -S tlp acpid brightnessctl thermald

wsl-base:
	sudo apt install htop git curl zsh autoconf bison patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev imagemagick libmariadb-dev libpq-dev libmagickwand-dev

systemd:
	systemctl enable tlp
	systemctl enable acpid
	systemctl enable thermald

git:
	git config --global core.editor "vim"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

yay:
	git clone https://aur.archlinux.org/yay.git ~/yay
	cd ~/yay; makepkg -si
	rm -rf ~/yay
