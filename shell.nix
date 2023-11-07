{ pkgs ? import (
    builtins.fetchGit {
      name = "nixos-unstable-2023-06-18";
      url = "https://github.com/nixos/nixpkgs/";
      # Commit hash for nixos-unstable as of 2023-06-18
      # `git ls-remote https://github.com/nixos/nixpkgs nixos-unstable`
      ref = "refs/heads/nixos-unstable";
      rev = "d1250206995000485096be3bedc5660ec956c46b";
    }
  ) {}
}:

pkgs.mkShell {
  packages = [
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.jq
    pkgs.yq-go
    pkgs.nodePackages.markdown-link-check
    pkgs.nodePackages.markdownlint-cli
    pkgs.nodePackages.prettier
    pkgs.python311
    pkgs.python311Packages.pyyaml
    pkgs.python311Packages.requests
    pkgs.python311Packages.lxml
    pkgs.python311Packages.pandas
    pkgs.python311Packages.beautifulsoup4
    pkgs.python311Packages.towncrier
    pkgs.shellcheck
    pkgs.golangci-lint
    pkgs.go
    pkgs.kind
  ];
}
## Output of `make tool-versions`:
#
# kubectl version --client=true --short 2>/dev/null
# Client Version: v1.27.2
# Kustomize Version: v5.0.1
# helm version
# version.BuildInfo{Version:"v3.12.1", GitCommit:"v3.12.1", GitTreeState:"", GoVersion:"go1.20.5"}
# jq --version
# jq-1.6
# yq --version
# yq (https://github.com/mikefarah/yq/) version v4.34.1
# markdown-link-check --version
# 3.11.2
# markdownlint --version
# 0.34.0
# prettier --version
# 2.8.8
# python -V
# Python 3.11.4
# towncrier --version
# towncrier, version 22.12.0
# shellcheck --version
# ShellCheck - shell script analysis tool
# version: 0.9.0
# license: GNU General Public License, version 3
# website: https://www.shellcheck.net
# golangci-lint version
# golangci-lint has version 1.53.3 built with go1.20.5 from v1.53.3 on 19700101-00:00:00
# go version
# go version go1.20.5 linux/amd64
# kind version
# kind v0.20.0 go1.20.5 linux/amd64
