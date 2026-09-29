return {
  cmd = { 'helm-ls', 'serve' }, -- `go install github.com/mrjosh/helm-ls` names it helm-ls
  filetypes = { 'helm', 'yaml.helm-values' },
  root_markers = { 'Chart.yaml' },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
}
