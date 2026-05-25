# Setup — full environment guide

What `chezmoi apply` puts on disk is just the **configuration files**. The
tools they configure, and the secrets those tools need, are installed and
registered separately. This guide walks through everything in the order
you'd hit it on a fresh machine.

[日本語版 / Japanese](../ja/SETUP.md)

---

## 1. Bringing this repo to a new machine

### 1.1 Install chezmoi

| OS | Command |
|----|---------|
| macOS | `brew install chezmoi` |
| Linux / HPCI | `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin` |

The bundled [`install.sh`](../../install.sh) does this automatically if
chezmoi is missing, so you usually just run that.

### 1.2 Clone and apply

```sh
git clone https://github.com/suzuki-2001/dotfiles ~/.local/share/chezmoi
sh ~/.local/share/chezmoi/install.sh
```

`install.sh` does four things:

1. Installs chezmoi to `~/.local/bin/` if it isn't already on `PATH`.
2. Runs `chezmoi init --apply`, which prompts for your identity values
   and caches them in `~/.config/chezmoi/chezmoi.toml` (never committed),
   then applies every dotfile to `$HOME`.
3. Fetches external assets declared in `.chezmoiexternal.toml`
   (gruvbox theme, `mutt_oauth2.py`).
4. Runs `.chezmoiscripts/`, which sets up Doom Emacs on first apply and
   re-syncs whenever the Doom config changes.

You'll be asked for:

| Prompt | Value | Used by |
|--------|-------|---------|
| Full name | `<your full name>` | git `user.name`, Doom `user-full-name` |
| Personal Gmail address | `<you>@gmail.com` | aerc Gmail account, Doom mail address |
| Git commit email | GitHub noreply address recommended | git `user.email` (e.g. `12345678+username@users.noreply.github.com`) |
| Organization Outlook | Microsoft 365 address (blank to skip) | aerc Outlook account |

To re-ask later: `chezmoi init --prompt`.

### 1.3 macOS — install the rest via Brewfile

```sh
brew bundle --file=~/.local/share/chezmoi/Brewfile
exec zsh
```

The Brewfile installs:

- **Core**: chezmoi, git, emacs (for Doom), cmake (for `vterm`), aerc, w3m.
- **Shell experience**: starship, tmux, fzf, zoxide, eza, bat, fd, ripgrep,
  git-delta, tealdeer.
- **Font**: JetBrainsMono Nerd Font (used by ghostty and i3).

After `exec zsh`, the starship prompt is active and the modern CLI
integrations kick in (Ctrl-R fzf history search, `z <dir>` for zoxide,
etc.).

### 1.4 Linux / HPCI — install tools individually

Without `brew`, install each tool yourself. **All of them ship as a
single binary and need no root** — drop them into `~/.local/bin/`.

```sh
mkdir -p ~/.local/bin && cd ~/.local/bin

# starship — one-line installer
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin -y

# fzf, zoxide, eza, bat, fd, ripgrep, git-delta — from GitHub Releases.
# Pick the linux-x86_64 (or aarch64) tarball for the latest release of each:
#   https://github.com/junegunn/fzf/releases
#   https://github.com/ajeetdsouza/zoxide/releases
#   https://github.com/eza-community/eza/releases
#   https://github.com/sharkdp/bat/releases
#   https://github.com/sharkdp/fd/releases
#   https://github.com/BurntSushi/ripgrep/releases
#   https://github.com/dandavison/delta/releases
```

The managed `dot_zprofile.tmpl` adds `~/.local/bin` to `PATH` for you;
`exec zsh` or re-login picks it up.

For aerc on HPCI either `go install git.sr.ht/~rjarry/aerc@latest`
(if Go ≥ 1.21 is available) or grab a [pre-built binary](https://git.sr.ht/~rjarry/aerc/refs).

---

## 2. Secrets

Mail credentials are intentionally absent from this repo. Register them
locally with the system's secure store.

### 2.1 Gmail — app password

Gmail no longer accepts regular passwords for IMAP/SMTP. Issue an
**app password** instead:

1. Enable 2-factor auth on your Google account.
2. Create a 16-character password at <https://myaccount.google.com/apppasswords>.
3. Store it without committing it:

```sh
# macOS — login Keychain
security add-generic-password -a "$USER" -s aerc-gmail -w

# Linux / HPCI — pass (password-store)
#   first time: gpg --gen-key && pass init <your GPG ID>
pass insert email/gmail
```

`accounts.conf`'s `source-cred-cmd` and `outgoing-cred-cmd` retrieve it at
runtime via `security find-generic-password` (macOS) or `pass show` (Linux).

### 2.2 Outlook (Microsoft 365) — OAuth2 device-code flow

Microsoft 365 retired basic auth. IMAP/SMTP require **OAuth2 (XOAUTH2)**.
Tokens are managed by `mutt_oauth2.py` (auto-fetched by `chezmoi apply`
into `~/.local/bin/`).

**Step 1 — confirm the Outlook address is configured.**
If you entered an Outlook address during `chezmoi init --apply`,
`~/.config/aerc/accounts.conf` will already contain an `[Outlook]` section.
Re-run `chezmoi init --prompt` if you left it blank.

**Step 2 — one-time authorization.**

```sh
python3 ~/.local/bin/mutt_oauth2.py ~/.config/aerc/outlook.tokens \
  --verbose --authorize \
  --provider microsoft \
  --authflow devicecode \
  --email '<your-org-m365-address>' \
  --client-id '9e5f94bc-e8a4-4e73-b8be-63364c29d753' \
  --encryption-pipe cat --decryption-pipe cat
```

- When asked for `Client secret:`, **press Enter with nothing typed**
  (the Thunderbird client ID is a public client).
- A URL (`https://microsoft.com/devicelogin`) and an 8-digit code will
  print. Open the URL in any browser (phone works), enter the code, sign
  in with your org account, and approve access.

The resulting tokens land in `~/.config/aerc/outlook.tokens` (mode 600).
From then on, aerc fetches them via the `aerc-oauth2` wrapper.

> **About the `aerc-oauth2` wrapper.** It sits between aerc and
> `mutt_oauth2.py` to fix two failure modes that would otherwise surface
> as recurring `authentication failed` / `invalid duration` errors:
>
> 1. **Refresh serialization.** aerc runs the credential command twice —
>    once for receiving, once for sending. If both fire while the access
>    token has expired they refresh concurrently; Microsoft rotates the
>    refresh token, and the loser's write corrupts the token file. An
>    atomic `mkdir` mutex (macOS has no `flock(1)`) serialises them.
> 2. **Output sanitisation.** A failed refresh makes `mutt_oauth2.py`
>    print multi-line error text on stdout. aerc reads the second line as
>    a cache duration and fails with `time: invalid duration ...`. The
>    wrapper emits only the JWT line (a whitespace-free token).
>
> See [`dot_local/bin/executable_aerc-oauth2`](../../home/dot_local/bin/executable_aerc-oauth2)
> for the script.

> **Organisational policy may still block you.** If your tenant has IMAP
> disabled, or Conditional Access blocks the Thunderbird app ID above,
> ask the admin to enable IMAP or register your own Azure app and
> substitute its client ID.

### 2.3 Launch aerc

```sh
aerc
```

`?` lists keys. A practical cheat sheet is at
[`dot_config/aerc/cheatsheet.md`](../../home/dot_config/aerc/cheatsheet.md) —
keep it open in a tmux/ghostty split:

```sh
less ~/.config/aerc/cheatsheet.md
```

---

## 3. Shell — zsh, starship, tmux

`chezmoi apply` puts these in place:

- `~/.zshrc` — history (50000 entries, shared, deduped), completion,
  prefix-match history search on arrow keys, aliases, and conditional
  hooks for modern CLI tools.
- `~/.zprofile` — `brew shellenv` on macOS, `~/.local/bin` on `PATH`
  everywhere.
- `~/.zshenv` — pins `XDG_CONFIG_HOME` so XDG-aware tools stay consistent.
- `~/.config/starship.toml` — prompt config (conda env displayed).
- `~/.tmux.conf` — gruvbox status line, `C-a` prefix, `|` / `-` splits,
  vim-style pane navigation.

### 3.1 Machine-specific shell init (`~/.zshrc.local`)

Tool initialisers like `conda init`, `nvm`, and `bun` write blocks
containing **absolute home paths** into `~/.zshrc`. Those don't belong in
a shared repo. The managed `~/.zshrc` sources `~/.zshrc.local`
(intentionally untracked) — put your tool blocks there.

```sh
conda init zsh                    # appends a block to ~/.zshrc
# move that block to ~/.zshrc.local, then restore ~/.zshrc:
$EDITOR ~/.zshrc ~/.zshrc.local
chezmoi apply ~/.zshrc
```

### 3.2 Quiet conda's prompt prefix

starship already shows the active conda environment. Disable conda's own
`(base)` prefix so it doesn't double-print:

```sh
conda config --set changeps1 False
```

### 3.3 tmux for SSH

When you SSH to HPCI, wrap the session in tmux so a dropped connection
doesn't lose state.

```sh
tmux              # new session
tmux a            # attach to last session
C-a d             # detach (session keeps running)
C-a | / C-a -     # split vertical / horizontal
C-a h/j/k/l       # move between panes (vim-style)
C-a r             # reload ~/.tmux.conf
```

---

## 4. Doom Emacs

Doom installs and syncs itself via two scripts in
[`.chezmoiscripts/`](../../home/.chezmoiscripts/) — no manual `git clone` needed.

| Script | Role |
|--------|------|
| `run_once_after_20-install-doom` | Verifies Emacs, clones doomemacs, runs `doom install`. |
| `run_onchange_after_30-doom-sync` | Hashes `init.el` / `config.el.tmpl` / `packages.el`; re-runs `doom sync` on any change. |

The only prerequisite is **Emacs ≥ 28 on `PATH`**.

- **macOS**: the run-script will pull Emacs from `Brewfile` if it isn't
  installed.
- **Linux / HPCI**: Emacs is out of scope for this repo — install it any
  way that works in your environment, then `chezmoi apply` again. Some
  options:
  - `module avail emacs && module load emacs/<version>`
  - `conda install -c conda-forge emacs`
  - Source build: `./configure --prefix=$HOME/.local --with-native-compilation`

`run_once_*` scripts are not recorded as "done" on failure, so once
Emacs is available `chezmoi apply` will resume the bootstrap.

Edit `init.el` / `config.el.tmpl` / `packages.el`, run `chezmoi apply`,
and `doom sync` runs automatically.

---

## 5. i3 (Linux only)

Skipped on macOS via `.chezmoiignore`. On Linux:

```sh
apt install i3 i3status dmenu        # Debian/Ubuntu
```

Configs land at `~/.config/i3/config` and `~/.config/i3status/config`.
Modkey is `Mod4` (Super/Win), terminal on `Mod4+Return`, launcher on
`Mod4+d`. Install JetBrainsMono Nerd Font so the bar renders correctly.

---

## 6. gruvbox

`.chezmoiexternal.toml` auto-clones [morhetz/gruvbox](https://github.com/morhetz/gruvbox)
into `~/.vim/pack/themes/start/gruvbox` (refreshed every 168 hours).
`dot_vimrc` loads it.

For Neovim, either add `~/.vim` to its `runtimepath` or change the clone
target to somewhere under `~/.config/nvim/`.

Other tools are already themed:
ghostty (`Gruvbox Dark`), aerc (`stylesets/gruvbox`), i3 (hand-coded
palette), Doom (`doom-gruvbox`), tmux (status line colours), bat
(`BAT_THEME=gruvbox-dark`).

---

## 7. Troubleshooting

### 7.1 aerc Outlook: `authenticate failed` or `invalid duration`

- **Cause**: cred-cmd contention or token-file corruption. The
  `aerc-oauth2` wrapper prevents both classes of failure, so on a fresh
  setup you shouldn't see them.
- **Fix**:
  1. In aerc's Outlook tab: `:connect`.
  2. If unchanged, quit aerc (`q`) and restart.
  3. If still failing, the token file may be corrupted — re-run the
     `--authorize` flow from §2.2.
- **Diagnose**: `mutt_oauth2.py --test ...` directly tests IMAP / POP /
  SMTP auth and prints which succeeded.

### 7.2 `chezmoi apply` fails on `gitEmail`

If you edited `.chezmoi.toml.tmpl` (added a new prompt key), the cached
`~/.config/chezmoi/chezmoi.toml` is missing the new key. Run
`chezmoi init` once; existing values are preserved.

### 7.3 Doom sync script fails

Make sure Emacs ≥ 28 is on `PATH`. On HPCI install Emacs first (§4) and
re-run `chezmoi apply` — `run_once_*` will pick up from where it stopped.

### 7.4 starship prompt missing or shows boxes

- `command -v starship` — is the binary installed?
- Is your terminal using a Nerd Font? ghostty config sets
  `font-family = "JetBrainsMono Nerd Font"` — install it from `Brewfile`
  (macOS) or download from <https://www.nerdfonts.com/>.
- `~/.zshrc` runs `eval "$(starship init zsh)"` at the end. Reload with
  `exec zsh`.
