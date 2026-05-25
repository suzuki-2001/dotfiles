#!/usr/bin/env sh
# Bootstrap: install chezmoi if missing, then apply this repo to $HOME.
# Works on macOS and Linux (HPCI), no root required.
#
# Usage:
#   sh install.sh
#
# What this does:
#   1. Installs chezmoi to ~/.local/bin/ if not on PATH.
#   2. Runs `chezmoi init --apply` from this repo, which:
#        - prompts for name / Gmail / git commit email / Outlook on first run
#          (values are cached in ~/.config/chezmoi/chezmoi.toml — not in repo)
#        - applies all dotfiles to $HOME
#        - fetches external assets (gruvbox theme, mutt_oauth2.py)
#        - runs .chezmoiscripts/ (Doom Emacs install + sync)
#
# Next steps after this script — see docs/SETUP.md for details:
#   * macOS:   brew bundle --file=Brewfile
#   * Linux:   install starship / fzf / zoxide / eza / bat / fd / delta
#              individually (single-binary, no root needed)
#   * Mail:    register Gmail app password, run mutt_oauth2.py --authorize
#              for Outlook (one-time)
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
BINDIR="${HOME}/.local/bin"

echo "==> bootstrapping dotfiles from ${REPO}"

if command -v chezmoi >/dev/null 2>&1; then
    CHEZMOI="$(command -v chezmoi)"
    echo "    chezmoi found at ${CHEZMOI}"
else
    echo "    chezmoi not found — installing to ${BINDIR}"
    mkdir -p "$BINDIR"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BINDIR"
    CHEZMOI="${BINDIR}/chezmoi"
fi

echo "==> running 'chezmoi init --apply'"
"$CHEZMOI" init --apply --source="$REPO"

echo
echo "==> dotfiles applied. Next steps:"
case "$(uname -s)" in
    Darwin)
        echo "    brew bundle --file=${REPO}/Brewfile     # install CLI tools, fonts, aerc, emacs"
        ;;
    Linux)
        echo "    # install CLI tools individually (no root needed) — see docs/SETUP.md §1.4"
        ;;
esac
echo "    exec zsh                                 # load new shell setup"
echo "    less ${REPO}/docs/SETUP.md               # secrets setup (Gmail / Outlook OAuth2)"
echo
echo "==> use 'chezmoi diff' to preview future changes; 'chezmoi update' to git pull + apply"
