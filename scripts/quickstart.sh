#!/usr/bin/env sh
# Qompass AI K8s Quickstart
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -eu
print() { printf '[k8s-quickstart]: %s\n' "$1"; }
OS=$(uname | tr 'A-Z' 'a-z')
ARCH=$(uname -m)
case "$ARCH" in
x86_64 | amd64) ARCH=amd64 ;;
arm64 | aarch64) ARCH=arm64 ;;
*)
	print "Unsupported architecture: $ARCH"
	exit 1
	;;
esac
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="$HOME/.local/bin"
K8S_CONFIG="$XDG_CONFIG_HOME/kubernetes"
K8S_CACHE="$XDG_CACHE_HOME/kubernetes"
K8S_DATA="$XDG_DATA_HOME/kubernetes"
K8S_STATE="$XDG_STATE_HOME/kubernetes"
HELM_CONFIG="$XDG_CONFIG_HOME/helm"
KREW_DATA="$XDG_DATA_HOME/krew"
mkdir -p "$LOCAL_BIN" "$K8S_CONFIG" "$K8S_CACHE" "$K8S_DATA" "$K8S_STATE" "$HELM_CONFIG" "$KREW_DATA"
PATH="$LOCAL_BIN:$PATH"
export PATH
BANNER() {
	printf '╭────────────────────────────────────────────╮\n'
	printf '│    Qompass AI · Kubernetes Quick‑Start     │\n'
	printf '╰────────────────────────────────────────────╯\n'
	printf '    © 2025 Amor Fati Labs. All rights reserved   \n\n'
}
BANNER
print "✔ Preparing XDG directories for configs/state/cache/data..."
print "✔ Downloading latest stable kubectl for $OS/$ARCH..."
KUBECTL_URL=""
if [ "$OS" = "darwin" ]; then
	KUBECTL_URL="https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/darwin/$ARCH/kubectl"
elif [ "$OS" = "linux" ]; then
	KUBECTL_URL="https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl"
elif echo "$OS" | grep -q mingw; then
	KUBECTL_URL="https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/windows/$ARCH/kubectl.exe"
else
	print "Unsupported OS: $OS"
	exit 1
fi
(
	set -e
	cd "$LOCAL_BIN"
	if [ "$OS" = "darwin" ] || [ "$OS" = "linux" ]; then
		curl -Lo kubectl "$KUBECTL_URL"
		chmod +x kubectl
	else
		curl -Lo kubectl.exe "$KUBECTL_URL"
	fi
)
print "✔ kubectl installed to $LOCAL_BIN"
kubectl_version=$(kubectl version --client --short 2>/dev/null || echo "kubectl not on PATH")
print "✔ kubectl version: $kubectl_version"
printf "\nDo you want to install [Helm] (Kubernetes package manager)? [Y/n]: "
read -r ans
[ -z "$ans" ] && ans=Y
if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
	print "✔ Downloading helm..."
	HELM_OS="$OS"
	[ "$HELM_OS" = "darwin" ] && HELM_OS="darwin"
	[ "$HELM_OS" = "linux" ] && HELM_OS="linux"
	HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | head -n1 | cut -d\" -f4)
	HELM_TAR="helm-$HELM_VERSION-$HELM_OS-$ARCH.tar.gz"
	TMPDIR=$(mktemp -d)
	curl -fsSL -o "$TMPDIR/$HELM_TAR" "https://get.helm.sh/$HELM_TAR"
	tar -xzf "$TMPDIR/$HELM_TAR" -C "$TMPDIR"
	mv "$TMPDIR/$HELM_OS-$ARCH/helm"* "$LOCAL_BIN/"
	chmod +x "$LOCAL_BIN/helm"*
	rm -rf "$TMPDIR"
	print "✔ helm installed to $LOCAL_BIN"
	"$LOCAL_BIN/helm" version --short
fi
if [ "$OS" = "linux" ] || [ "$OS" = "darwin" ]; then
	printf "\nDo you want to install [Krew] (kubectl plugin manager)? [Y/n]: "
	read -r ans
	[ -z "$ans" ] && ans=Y
	if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
		(
			set -e
			cd /tmp
			KREW="krew-${OS}_$ARCH.tar.gz"
			curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW"
			tar zxvf "$KREW"
			./"krew-${OS}_$ARCH" install krew
			KREW_BIN="$HOME/.krew/bin"
			if [ -d "$KREW_BIN" ]; then
				print "✔ Krew installed to $KREW_BIN"
				print "✔ Add this to your PATH in your shell profile:"
				echo "export PATH=\"\$PATH:$KREW_BIN\""
			fi
		)
	fi
fi
printf "\nAdd to your shell profile for a clean XDG setup and user-level k8s:\n"
echo "export PATH=\"$LOCAL_BIN:\$PATH\""
echo "export KUBECONFIG=\"$K8S_CONFIG/config\""
echo "export HELM_CONFIG_HOME=\"$HELM_CONFIG\""
echo "export KREW_ROOT=\"$KREW_DATA\""
print "   Place your kube config at $K8S_CONFIG/config and use kubectl as your user."
print "   (Edit above exports into ~/.bashrc, ~/.zshrc, ~/.config/fish/config.fish, etc.)"
exit 0
