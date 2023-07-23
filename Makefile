all: config-base

PACKER_PATH=~/.local/share/nvim/site/pack/packer/start

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	rm -rf $(PACKER_PATH) || exit 0
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

void-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -sf $(PWD)/.Xresources ~/.Xresources
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/.config/i3 ~/.config/i3
	ln -snf $(PWD)/.config/i3blocks ~/.config/i3blocks

void-base:
	sudo xbps-install base-devel htop git curl man zip unzip ranger jq keychain ripgrep acpi bashmount

void-xorg:
	sudo xbps-install firefox rxvt-unicode maim xclip xdotool i3blocks rofi dunst feh i3 font-iosevka pipewire wireplumber pavucontrol elogind brightnessctl tlp dex xss-lock neofetch xorg intel-video-accel flatpak

runit:
	sudo ln -s /etc/sv/elogind /var/service/
	sudo ln -s /etc/sv/dbus /var/service/
	sudo ln -s /etc/sv/connmand /var/service/
	sudo ln -s /etc/sv/tlp /var/service/

git:
	git config --global core.editor "vim"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

flatpak-install:
	flatpak install flathub com.github.tchx84.Flatseal org.telegram.desktop com.google.Chrome org.telegram.desktop io.dbeaver.DBeaverCommunity org.libreoffice.LibreOffice com.discordapp.Discord
