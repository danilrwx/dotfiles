all:
	mkdir -p ~/.config
	make base
	make ubuntu-packages
	make git
	make git-change-remote

base: base-config

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/

ubuntu-packages:
	sudo apt install -y neovim htop git tmux curl man zip unzip jq ripgrep rsync bash-completion fzf wget httpie bat

git:
	git config --global core.editor "code"
	git config --global user.name "Danil Antoshin"
	git config --global user.email antoshindanil@ya.ru
	git config --global pull.rebase true

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git
