## dotfiles

A small terminal home, managed with chezmoi.

### inside

```text
shell    zsh · starship · tmux
mail     aerc · Gmail · Outlook XOAUTH2
editor   Doom Emacs · vim
desktop  ghostty · i3
theme    gruvbox
```

### setup

```console
❯ git clone https://github.com/suzuki-2001/dotfiles ~/.local/share/chezmoi
❯ sh ~/.local/share/chezmoi/install.sh
==> chezmoi init --apply  (prompts once for name and email)
==> ready.
```

### day-to-day

```console
❯ chezmoi edit ~/.zshrc       # edit a managed file
❯ chezmoi apply               # apply changes
❯ chezmoi update              # git pull + apply
```

→ [docs/](docs/)
