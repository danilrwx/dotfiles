all:
	mkdir -p ~/.config
	make console-font
	make base
	make wm
	make laptop
	make runit
	make pipewire
	make git
	make git-change-remote

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

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/rc.conf

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

base-packages:
	sudo xbps-install -Syu base-devel htop git tmux curl man zip unzip ranger jq keychain ripgrep neofetch vim lazygit mosh podman rsync bash-completion

laptop: laptop-packages desktop-packages

laptop-packages:
	sudo xbps-install -Syu acpi tlp intel-video-accel brightnessctl

desktop-packages:
	sudo xbps-install -Syu font-iosevka bashmount elogind dex xdg-user-dirs xdg-user-dirs-gtk xdg-utils libavcodec ffmpeg mesa-dri udisks2 firefox chromium

dev-packages:
	sudo xbps-install -Syu rust libffi-devel libyaml-devel zlib-devel openssl postgresql-libs postgresql-libs-devel

wm: wm-packages wm-config

wm-packages:
	sudo xbps-install -Syu bspwm sxhkd dmenu maim xclip xdotool dunst xorg hsetroot xcompmgr

wm-config:
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -snf $(PWD)/.config/bspwm ~/.config/bspwm
	ln -snf $(PWD)/.config/sxhkd ~/.config/sxhkd
	ln -snf $(PWD)/.config/dunst ~/.config/dunst

runit:
	sudo ln -sf /etc/sv/elogind /var/service/
	sudo ln -sf /etc/sv/dbus /var/service/
	sudo ln -sf /etc/sv/tlp /var/service/

pipewire:
	sudo xbps-install -Syu pipewire wireplumber pavucontrol
	sudo mkdir -p /etc/pipewire/pipewire.conf.d
	sudo ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/pipewire.desktop
	sudo ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
	sudo ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

firewall:
	sudo xbps-install -Syu ufw
	sudo ln -sf /etc/sv/ufw /var/service

virt:
	sudo xbps-install -Syu virt-manager libvirt qemu
	sudo usermod -aG libvirt $(USER)
	modprobe kvm-intel
	sudo ln -sf /etc/sv/libvirtd /var/service
	sudo ln -sf /etc/sv/virtlockd /var/service
	sudo ln -sf /etc/sv/virtlogd /var/service

git:
	git config --global core.editor "vim"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

flatpak: flatpak-add flatpak-install

flatpak-add:
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak-install:
	flatpak install -y flathub com.github.tchx84.Flatseal org.telegram.desktop io.dbeaver.DBeaverCommunity org.libreoffice.LibreOffice com.discordapp.Discord io.github.spacingbat3.webcord

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

asdf-setup:
	asdf plugin-add golang
	asdf plugin-add neovim
	asdf plugin-add ruby
	asdf plugin-add nodejs

asdf-inst:
	asdf install nodejs 16.20.2
	asdf install golang 1.21.0
	asdf install ruby 3.0.1
	asdf install ruby 3.1.2


