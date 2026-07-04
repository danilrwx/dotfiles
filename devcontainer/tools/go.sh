#!/usr/bin/env bash

# Go-installed tools (into the user's GOPATH bin): pinned ginkgo and the tools
# with no brew formula. Run as the target user.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

go install "github.com/onsi/ginkgo/v2/ginkgo@${GINKGO_VERSION}"
go install github.com/matryer/moq@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/google/go-containerregistry/cmd/crane@latest
