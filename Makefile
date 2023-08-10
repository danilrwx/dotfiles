all:
	mkdir -p ~/.config
	make console-font
	make base
	make wm
	make laptop
	make git
	make git-change-remote
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

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/vconsole.conf

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

base-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip jq keychain ripgrep neofetch vim lazygit mosh podman rsync bash-completion lf helix

laptop: laptop-packages laptop-enable laptop-gpu desktop-packages

laptop-packages:
	sudo pacman -S --needed acpi acpid tlp brightnessctl throttled

laptop-enable:
	sudo systemctl enable acpid
	sudo systemctl enable tlp
	sudo systemctl enable throttled

laptop-gpu:
	sudo pacman -S --needed xf86-video-intel
	sudo ln -sf $(PWD)/20-intel.conf /etc/X11/xorg.conf.d/

desktop-packages:
	sudo pacman -S --needed ttc-iosevka dex xdg-user-dirs xdg-user-dirs-gtk xdg-utils ffmpeg udisks2 firefox chromium libnotify polkit starship sxiv

desktop-install:
	xdg-mime default sxiv.desktop image/jpeg

dev-packages:
	sudo pacman -S --needed libffi libyaml openssl zlib postgresql-libs mariadb-libs imagemagick

wm: wm-packages wm-config

wm-packages:
	sudo pacman -S --needed i3 dmenu maim xclip xdotool dunst xorg xorg-xinit hsetroot xcompmgr

wm-config:
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -snf $(PWD)/.config/i3 ~/.config/i3
	ln -snf $(PWD)/.config/i3status ~/.config/i3status
	ln -snf $(PWD)/.config/dunst ~/.config/dunst
	ln -snf $(PWD)/.config/kitty ~/.config/kitty

pipewire:
	sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol

firewall:
	sudo pacman -S --needed ufw

virt:
	sudo pacman -S --needed virt-manager qemu-desktop dnsmasq iptables
	sudo usermod -aG libvirt danil
	echo "unix_sock_group = 'libvirt'" | sudo tee -a /etc/libvirt/libvirtd.conf
	echo "unix_sock_rw_perms = '0770'" | sudo tee -a /etc/libvirt/libvirtd.conf
	echo 'user = "$(USER)"' | sudo tee -a /etc/libvirt/qemu.conf
	echo 'group = "$(USER)"' | sudo tee -a /etc/libvirt/qemu.conf
	sudo systemctl enable libvirtd

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
	flatpak install -y flathub com.github.tchx84.Flatseal org.telegram.desktop io.github.spacingbat3.webcord

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
