# Homebrew packages for the macOS environment.
# Apply manually with:  brew bundle --file=Brewfile
# The Doom bootstrap script (.chezmoiscripts) runs this automatically
# when Emacs is missing on macOS.

brew "chezmoi"   # dotfiles manager
brew "git"
brew "emacs"     # Doom Emacs needs Emacs 28+
brew "cmake"     # builds the vterm native module
brew "libtool"   # provides `glibtool`, required by libvterm's build
brew "aerc"      # terminal mail client
brew "w3m"       # renders text/html mail in aerc

# shell / terminal experience — wired up in dot_zshrc when present
brew "starship"   # cross-shell prompt
brew "tmux"       # terminal multiplexer (persistent SSH sessions)
brew "fzf"        # fuzzy finder (Ctrl-R history, Ctrl-T files)
brew "zoxide"     # smarter cd  (`z <dir>` jumps by frecency)
brew "eza"        # modern ls   (icons, git status, tree)
brew "bat"        # modern cat  (syntax highlighting, paging)
brew "fd"         # modern find (fast, sane defaults)
brew "ripgrep"    # fast recursive grep (rg)
brew "git-delta"  # readable git diffs
brew "tealdeer"   # fast `tldr` client — concise command examples

cask "font-jetbrains-mono-nerd-font"   # font used by ghostty / i3
