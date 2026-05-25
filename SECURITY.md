# Security policy

This repository is a public dotfiles set. The following principles are
enforced and verified before each push.

## What is never committed

- Passwords (Gmail app password, IMAP credentials, etc.)
- OAuth tokens or refresh tokens (Microsoft 365, Google, anything)
- API keys or access tokens
- Personal identifiers (real name, email, organisation addresses) — these
  come from chezmoi prompts and are cached locally in
  `~/.config/chezmoi/chezmoi.toml`, which is gitignored

## Where secrets actually live at runtime

| Secret | Storage | Retrieved by |
|--------|---------|--------------|
| Gmail app password | macOS Keychain (`security`) or Linux `pass` | aerc `*-cred-cmd` |
| Outlook OAuth2 tokens | `~/.config/aerc/outlook.tokens` (mode 600) | `~/.local/bin/aerc-oauth2` wrapper |
| Identity (name / email) | `~/.config/chezmoi/chezmoi.toml` | chezmoi templates |

None of these files are tracked by this repository. `.gitignore` covers
common credential filenames as a safety net.

## Reporting a problem

If you spot a way this repository as configured could leak a credential
or identifier — or notice a secret accidentally introduced — please open
an issue on GitHub.
