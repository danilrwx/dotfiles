#!/usr/bin/env bash

# Go-installed tools (into the user's GOPATH bin). Run as the target user.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

go install "github.com/onsi/ginkgo/v2/ginkgo@${GINKGO_VERSION}"
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/gopls@latest
go install github.com/matryer/moq@latest
go install github.com/google/go-containerregistry/cmd/crane@latest
