{ pkgs ? import (
    builtins.fetchGit {
      name = "nixos-unstable-2024-03-28";
      url = "https://github.com/nixos/nixpkgs/";
      # Commit hash for nixos-unstable as of 2024-03-28
      # `git ls-remote https://github.com/nixos/nixpkgs nixos-unstable`
      ref = "refs/heads/nixos-unstable";
      rev = "2726f127c15a4cc9810843b96cad73c7eb39e443";
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
# kubectl version --client=true 2>/dev/null
# Client Version: v1.29.3
# Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
# helm version
# version.BuildInfo{Version:"v3.14.3", GitCommit:"v3.14.3", GitTreeState:"", GoVersion:"go1.22.1"}
# jq --version
# jq-1.7.1
# yq --version
# yq (https://github.com/mikefarah/yq/) version v4.43.1
# markdown-link-check --version
# 3.12.1
# markdownlint --version
# 0.39.0
# prettier --version
# 3.2.5
# python -V
# Python 3.11.8
# towncrier --version
# towncrier, version 23.11.0
# shellcheck --version
# ShellCheck - shell script analysis tool
# version: 0.9.0
# license: GNU General Public License, version 3
# website: https://www.shellcheck.net
# golangci-lint version
# golangci-lint has version 1.57.1 built with go1.22.1 from v1.57.1 on 19700101-00:00:00
# go version
# go version go1.22.1 linux/amd64
# kind version
# kind v0.22.0 go1.22.1 linux/amd64
