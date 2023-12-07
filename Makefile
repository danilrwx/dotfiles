all:
	mkdir -p ~/.config
	make base
	make sway
	make git
	make git-change-remote

base: base-config

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/.config/helix ~/.config/
	ln -snf $(PWD)/.config/htop ~/.config/

sway: sway-config

sway-config:
	ln -sf $(PWD)/.config/electron-flags.conf ~/.config/
	ln -snf $(PWD)/.config/sway  ~/.config/
	ln -snf $(PWD)/.config/foot  ~/.config/
	ln -snf $(PWD)/.config/dunst ~/.config/
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/.config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

flatpak: flatpak-add flatpak-install

flatpak-add:
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak-install:
	flatpak install flathub net.waterfox.waterfox xyz.armcord.ArmCord com.github.tchx84.Flatseal org.telegram.desktop org.onlyoffice.desktopeditors com.github.Eloston.UngoogledChromium io.dbeaver.DBeaverCommunity

distrobox:
	distrobox create -i archlinux dev

distrobox-ln:
	sudo ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/foot
	sudo ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak 
	sudo ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman
	sudo ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree


arch-packages:
	sudo pacman -S --needed base-devel htop git tmux curl man zip unzip \
		jq keychain ripgrep neofetch rsync bash-completion fzf wget rustup \
		lf lazygit fd sad git-delta helix go nodejs npm yarn httpie
	sudo pacman -S --needed libffi libyaml openssl zlib imagemagick postgresql-libs mariadb-libs shared-mime-info

git:
	git config --global core.editor "hx"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

asdf-setup:
	asdf plugin-add ruby
	asdf plugin-add nodejs

asdf-inst:
	asdf install nodejs 16.20.2
	asdf install ruby 3.0.1
	asdf install ruby 3.1.2

lsp-install:
	sudo npm i -g "awk-language-server@>=0.5.2" bash-language-server vscode-langservers-extracted typescript typescript-language-server sql-language-server yaml-language-server@next
	go install golang.org/x/tools/gopls@latest
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/cmd/goimports@latest
	gem install --user-install solargraph
	rustup component add rust-analyzer
	cargo install taplo-cli --locked --features lsp
