{ pkgs ? import (
    builtins.fetchGit {
      name = "nixos-unstable-2023-04-13";
      url = "https://github.com/nixos/nixpkgs/";
      # Commit hash for nixos-unstable as of 2023-04-13
      # `git ls-remote https://github.com/nixos/nixpkgs nixos-unstable`
      ref = "refs/heads/nixos-unstable";
      rev = "fe2ecaf706a5907b5e54d979fbde4924d84b65fc";
    }
    ) {
      overlays = [(self: super: {
        kind-podman = super.kind.overrideAttrs(final: prev: {
          # The combination of e2e-framework v0.2.0 + kind + podman is broken
          # until e2e-framework v0.3.0 due to a warning logged by kind about
          # the podman provider. This patches kind to work with e2e framework
          # until we upgrade.
          # https://github.com/kubernetes-sigs/e2e-framework/pull/84
          patches = prev.patches ++ [ ./nix/kind-silence-podman-warning.patch ];
        });
      })];
    }
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
    pkgs.kind-podman
  ];
}
## Output of `make tool-versions`:
#
# kubectl version --client=true --short 2>/dev/null
# Client Version: v1.26.3
# Kustomize Version: v4.5.7
# helm version
# version.BuildInfo{Version:"v3.11.2", GitCommit:"v3.11.2", GitTreeState:"", GoVersion:"go1.20.3"}
# jq --version
# jq-1.6
# yq --version
# yq (https://github.com/mikefarah/yq/) version v4.33.2
# markdown-link-check --version
# 3.10.3
# markdownlint --version
# 0.33.0
# prettier --version
# 2.8.4
# python -V
# Python 3.11.2
# towncrier --version
# towncrier, version 22.12.0
# shellcheck --version
# ShellCheck - shell script analysis tool
# version: 0.9.0
# license: GNU General Public License, version 3
# website: https://www.shellcheck.net
# golangci-lint version
# golangci-lint has version 1.52.2 built with go1.20.3 from v1.52.2 on 19700101-00:00:00
# go version
# go version go1.20.3 linux/amd64
# kind version
# kind v0.17.0 go1.20.3 linux/amd64
