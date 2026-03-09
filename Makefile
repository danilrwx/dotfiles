all:
	mkdir -p ~/.config
	make base
	make git
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

base: base-config base-packages

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc

base-packages:
	sudo dnf install htop git tmux curl man zip unzip jq keychain ripgrep neofetch neovim mosh rsync bash-completion

fedora-sway:
	ln -snf $(PWD)/.config/foot ~/.config/
	ln -snf $(PWD)/.config/waybar ~/.config/
	ln -snf $(PWD)/.config/sway ~/.config/

dev-packages:
	sudo dnf install gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

git: git-config git-change-remote

git-config:
	git config --global core.editor "nvim"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

asdf: asdf-install

asdf-install:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
