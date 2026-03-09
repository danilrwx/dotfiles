all: config-base
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

arch-base:
	sudo pacman --needed -S htop git curl lazygit go man base-devel zip unzip ranger jq

arch-xorg:
	sudo pacman --needed -S udiskie udisks2 firefox gnome-keyring otf-font-awesome ttc-iosevka keychain alacritty maim xclip xdotool ttf-nerd-fonts-symbols ttf-jetbrains-mono ttf-jetbrains-mono-nerd

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
	git config --global pull.rebase false

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

yay:
	git clone https://aur.archlinux.org/yay.git ~/yay
	cd ~/yay; makepkg -si
	rm -rf ~/yay
