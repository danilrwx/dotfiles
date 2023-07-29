all: 
	mkdir -p ~/.config
	make console-font
	make base
	make seatd
	make wm
	make desktop-packages
	make git
	make git-change-remote
	make asdf

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/vconsole.conf

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

base-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip ranger jq keychain ripgrep neofetch vim lazygit mosh podman rsync bash-completion

seatd:
	sudo pacman -S --needed seatd
	sudo usermod -aG seat $(USER)
	sudo systemctl enable seatd
	sudo systemctl start seatd

laptop: laptop-packages laptop-enable

laptop-packages:
	sudo pacman -S --needed acpi acpid tlp brightnessctl throttled

laptop-enable:
	sudo systemctl enable acpid
	sudo systemctl enable tlp
	sudo systemctl enable throttled

desktop-packages:
	sudo pacman -S --needed ttc-iosevka dex xdg-user-dirs xdg-user-dirs-gtk xdg-utils ffmpeg udisks2 firefox chromium libnotify

dev-packages:
	sudo pacman -S --needed libffi libyaml openssl zlib postgresql-libs mariadb-libs imagemagic

wm: wm-packages wm-config

wm-packages:
	sudo pacman -S --needed sway swaybg mako foot wofi slurp grim wl-clipboard

wm-config:
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -snf $(PWD)/.config/sway ~/.config/sway
	ln -snf $(PWD)/.config/foot ~/.config/foot
	ln -snf $(PWD)/.config/wofi ~/.config/wofi

pipewire:
	sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol

firewall:
	sudo pacman -S --needed ufw

virt:
	sudo pacman -S --needed virt-manager libvirt qemu
	sudo usermod -aG libvirt $(USER)

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
