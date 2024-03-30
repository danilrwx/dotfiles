all:
	mkdir -p ~/.config
	make base
	make ubuntu-packages
	make git-change-remote

base: base-config

base-config:
	ln -sf $(PWD)/.bashrc ~/.bashrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/helix ~/.config/

ubuntu-packages:
	sudo apt install -y neovim htop git tmux curl man zip unzip jq ripgrep rsync bash-completion fzf wget httpie bat choose rg

git-change-remote:
	git remote set-url origin git@github.com:antoshindanil/dotfiles.git

nvim-install:
	rm -rf nvim/plugin || exit 0
	rm -rf ~/.local/share/nvim || exit 0
	rm -rf ~/.config/nvim || exit 0
	ln -snf $(PWD)/config/nvim ~/.config/nvim
	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
