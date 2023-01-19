{ pkgs ? import (
    builtins.fetchGit {
      name = "nixos-unstable-2023-02-08";
      url = "https://github.com/nixos/nixpkgs/";
      # Commit hash for nixos-unstable as of 2023-02-08
      # `git ls-remote https://github.com/nixos/nixpkgs nixos-unstable`
      ref = "refs/heads/nixos-unstable";
      rev = "fab09085df1b60d6a0870c8a89ce26d5a4a708c2";
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
# Client Version: v1.26.1
# Kustomize Version: v4.5.7
# helm version
# version.BuildInfo{Version:"v3.11.0", GitCommit:"v3.11.0", GitTreeState:"", GoVersion:"go1.19.5"}
# jq --version
# jq-1.6
# yq --version
# yq (https://github.com/mikefarah/yq/) version v4.30.8
# markdown-link-check --version
# 3.10.3
# markdownlint --version
# 0.33.0
# prettier --version
# 2.8.3
# python -V
# Python 3.11.1
# towncrier --version
# towncrier, version 22.12.0
# shellcheck --version
# ShellCheck - shell script analysis tool
# version: 0.9.0
# license: GNU General Public License, version 3
# website: https://www.shellcheck.net
# golangci-lint version
# golangci-lint has version 1.51.0 built from v1.51.0 on 19700101-00:00:00
# go version
# go version go1.19.5 linux/amd64
# kind version
# kind v0.17.0 go1.19.5 linux/amd64
