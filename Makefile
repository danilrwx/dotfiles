all:
	mkdir -p ~/.config
	make console-font
	make base
	make i3
	make laptop
	make desktop
	make git
	make git-change-remote

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/vconsole.conf

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/.config/helix ~/.config/
	ln -snf $(PWD)/.config/htop ~/.config/
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

base-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip \
		jq keychain ripgrep neofetch mosh podman rsync \
		bash-completion fzf wget rustup \
		lf lazygit fd exa bat bc

i3: i3-packages i3-config

i3-packages:
	sudo pacman -S --needed i3 dmenu clipmenu passmenu maim xclip xdotool dunst \
		hsetroot xcompmgr xfce4-terminal ttf-iosevkaterm-nerd ttf-iosevka-nerd

i3-config:
	ln -sf $(PWD)/.bash_profile ~/.bash_profile
	ln -sf $(PWD)/.xinitrc ~/.xinitrc
	ln -snf $(PWD)/.config/i3 ~/.config/
	ln -snf $(PWD)/.config/dunst ~/.config/
	ln -snf $(PWD)/.config/xfce4 ~/.config/

git:
	git config --global core.editor "hx"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true


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

desktop: desktop-packages

desktop-packages:
	sudo pacman -S --needed dex xdg-user-dirs \
		xdg-user-dirs-gtk xdg-utils ffmpeg udisks2 \
		mpd mpv yt-dlp libnotify firefox discord \
		telegram-desktop

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

asdf-setup:
	asdf plugin-add golang
	asdf plugin-add ruby
	asdf plugin-add nodejs

asdf-inst:
	asdf install nodejs 16.20.2
	asdf install golang 1.21.0
	asdf install ruby 3.0.1
	asdf install ruby 3.1.2

lsp-install:
	npm i -g "awk-language-server@>=0.5.2" bash-language-server vscode-langservers-extracted typescript typescript-language-server sql-language-server yaml-language-server@next
	go install golang.org/x/tools/gopls@latest
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/cmd/goimports@latest
	gem install --user-install solargraph
	rustup component add rust-analyzer
	cargo install taplo-cli --locked --features lsp

helix-install:
	hx --grammar fetch
	hx --grammar build

sad-install:
	cargo install --locked --all-features --git https://github.com/ms-jpq/sad --branch senpai

go-tools-install:
	go install github.com/jesseduffield/lazygit@latest
	env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest


yay:
	sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

yay-install:
	yay -S xkblayout-state-git helix-git sad bashmount
