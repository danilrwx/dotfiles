all:
	mkdir -p ~/.config
	make base
	make sway
	make git
	make git-change-remote

console-font:
	echo 'FONT="cyr-sun16"' | sudo tee -a /etc/vconsole.conf

base: base-config

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/.config/helix ~/.config/
	ln -snf $(PWD)/.config/htop ~/.config/

sway: sway-config

sway-config:
	ln -sf $(PWD)/.config/electron-flags.conf ~/.config/
	ln -sf $(PWD)/.bash_profile.wayland ~/.bash_profile
	ln -snf $(PWD)/.config/sway  ~/.config/
	ln -snf $(PWD)/.config/foot  ~/.config/
	ln -snf $(PWD)/.config/dunst ~/.config/
	ln -snf $(PWD)/Backgrounds ~/Backgrounds

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
	asdf plugin-add golang
	asdf plugin-add ruby
	asdf plugin-add nodejs

asdf-inst:
	asdf install nodejs 16.20.2
	asdf install golang 1.21.0
	asdf install ruby 3.0.1
	asdf install ruby 3.1.2

