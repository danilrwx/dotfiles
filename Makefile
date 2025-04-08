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
	ln -snf $(PWD)/config/vim ~/.vim
	ln -snf $(PWD)/config/k9s ~/.config/
	ln -snf $(PWD)/config/nvim ~/.config/
	ln -snf $(PWD)/config/htop ~/.config/
	ln -snf $(PWD)/config/lazygit ~/.config/
	ln -snf $(PWD)/config/ghostty ~/.config/

sway:
	ln -snf $(PWD)/config/sway ~/.config/
	ln -snf $(PWD)/config/foot ~/.config/
	ln -snf $(PWD)/config/waybar ~/.config/

git:
	git remote set-url origin git@github.com:danilrwx/dotfiles.git

font:
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip
	mkdir -p ~/.local/share/fonts
	cd ~/.local/share/fonts && unzip $(PWD)/Iosevka.zip
	rm $(PWD)/Iosevka.zip
	fc-cache -f

ubuntu-packages:
	sudo apt install -y curl bash-completion unzip

fedora-copr:
	sudo dnf copr enable atim/lazygit -y
	sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm
	sudo dnf install -y lame\* --exclude=lame-devel
	sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel

fedora-packages:
	sudo dnf install -y google-chrome-stable sensors jq difft wl-clipboard docker htop tmux curl man zip unzip keychain openssl kubernetes-client

brew-install:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages:
	brew install kubectl lazygit jq keychain openssl tmux difftastic

brew-mac:
	brew install chromium --no-quarantine
	brew install go-task/tap/go-task
	brew install homeport/tap/dyff

go-packages:
	go install github.com/kubernetes-sigs/controller-tools@latest

docker:
	sudo systemctl start docker.socket
	sudo systemctl enable docker.socket
	sudo usermod -aG docker $(USER)

