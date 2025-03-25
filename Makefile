all:
	make base
	make git

base:
	mkdir -p ~/.config
	ln -sf $(PWD)/.zshrc ~/.zshrc
	ln -sf $(PWD)/.gitconfig ~/.gitconfig
	ln -sf $(PWD)/.gitignore_global ~/.gitignore_global
	ln -sf $(PWD)/.tmux.conf ~/.tmux.conf
	ln -sf $(PWD)/.vimrc ~/.vimrc
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/vim ~/.vim
	ln -snf $(PWD)/config/lazygit ~/.config/
	ln -snf $(PWD)/config/ghostty ~/.config/
	ln -snf $(PWD)/config/k9s ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

font:
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip
	mkdir -p ~/.local/share/fonts
	cd ~/.local/share/fonts && unzip $(PWD)/Iosevka.zip
	rm $(PWD)/Iosevka.zip
	fc-cache -f

ubuntu-packages:
	sudo apt install -y curl bash-completion  unzip

fedora-packages:
	sudo dnf copr enable pgdev/ghostty -y
	sudo dnf copr enable atim/lazygit -y
	sudo dnf install ghostty lazygit
	sudo dnf install google-chrome-stable neovim unzip htop sensors zsh fzf jq \
		keychain wget tmux yq kubernetes-client difft wl-clipboard

brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install brew-cask-completion sops regclient k9s lazygit fzf httpie asdf ripgrep \
	neofetch jq keychain wget fd openssl readline libyaml gmp autoconf tmux neovim \
	yq fx yh highlight moar difftastic

brew-mac:
	brew install chromium --no-quarantine
	brew install go-task/tap/go-task
	brew install metalbear-co/mirrord/mirrord
	brew install homeport/tap/dyff

go-packages:
	go install github.com/kubernetes-sigs/controller-tools@latest

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

