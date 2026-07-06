#!/usr/bin/env bash

# Go-installed dev tools (into the user's GOPATH bin). Run as the target user.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

go install "github.com/onsi/ginkgo/v2/ginkgo@${GINKGO_VERSION}"
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
go install golang.org/x/tools/gopls@latest
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/matryer/moq@latest
go install github.com/google/go-containerregistry/cmd/crane@latest
go install github.com/go-task/task/v3/cmd/task@latest
