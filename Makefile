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

