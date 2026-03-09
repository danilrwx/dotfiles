all: 
	make base-packages
	make base-config
	make console-font
	make sway-packages
	make sway-config
	make runit
	make pipewire
	make virt 
	make docker
	make firewall
	make flatpak
	make flatpak-install
	make git
	make git-change-remote
	make disable-wpa

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/Backgrounds ~/Backgrounds
	ln -snf $(PWD)/.config/i3blocks ~/.config/i3blocks

base-packages:
	sudo xbps-install -Syu base-devel htop git tmux curl man zip unzip ranger jq keychain ripgrep acpi bashmount neofetch neovim i3blocks font-iosevka pipewire wireplumber pavucontrol elogind brightnessctl tlp intel-video-accel flatpak connman lazygit dex xdg-user-dirs xdg-utils xdg-desktop-portal-wlr

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/rc.conf

disable-wpa:
	sudo rm /var/service/wpa_supplicant
	sudo rm /var/service/dhcpcd

sway-packages:
	sudo xbps-install -Syu sway foot mako wofi swaybg slurp grim wl-clipboard mesa-dri

sway-config:
	ln -sf $(PWD)/.bash_profile.wayland ~/.bash_profile
	ln -snf $(PWD)/.config/foot ~/.config/foot
	ln -snf $(PWD)/.config/wofi ~/.config/wofi
	ln -snf $(PWD)/.config/sway ~/.config/sway

runit:
	sudo ln -sf /etc/sv/elogind /var/service/
	sudo ln -sf /etc/sv/dbus /var/service/
	sudo ln -sf /etc/sv/connmand /var/service/
	sudo ln -sf /etc/sv/tlp /var/service/

pipewire:
	sudo mkdir -p /etc/pipewire/pipewire.conf.d
	sudo ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/pipewire.desktop
	sudo ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
	sudo ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

docker:
	sudo xbps-install -Syu docker
	sudo usermod -aG docker $(USER)
	sudo ln -sf /etc/sv/containerd /var/service
	sudo ln -sf /etc/sv/docker /var/service

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

flatpak:
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak-install:
	flatpak install -y flathub com.github.tchx84.Flatseal org.telegram.desktop com.google.Chrome org.telegram.desktop io.dbeaver.DBeaverCommunity org.libreoffice.LibreOffice org.mozilla.firefox io.github.spacingbat3.webcord com.github.wwmm.easyeffects
