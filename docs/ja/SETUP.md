# SETUP — 環境構築の完全手順

新しいマシン（macOS／HPCI 等の Linux）にこの dotfiles を展開し、メール・シェル・
エディタまで一通り動かすための手順をまとめる。`chezmoi apply` で配置できるのは
**設定ファイルだけ**で、ツール本体のインストールとシークレット（パスワード／
トークン）の登録は別途必要になる。それを順番に消化する。

[English version](../en/SETUP.md)

---

## 1. 新しいマシンへの移行（共通フロー）

### 1.1 chezmoi をインストール

| OS | インストール |
|----|--------------|
| macOS | `brew install chezmoi` |
| Linux / HPCI | `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin` |

リポジトリ同梱の [`install.sh`](../../install.sh) が未導入なら自動で入れるので、
通常は次節の `install.sh` を実行するだけで足りる。

### 1.2 リポジトリ取得 → 適用

```sh
git clone https://github.com/suzuki-2001/dotfiles ~/.local/share/chezmoi
sh ~/.local/share/chezmoi/install.sh
```

`install.sh` は次を行う:

1. chezmoi が無ければ `~/.local/bin/chezmoi` に導入
2. `chezmoi init --apply` で初回プロンプトを聞き、`~/.config/chezmoi/chezmoi.toml`
   にキャッシュしながら全ファイルを `$HOME` に展開
3. `.chezmoiexternal.toml` に従い、gruvbox テーマと `mutt_oauth2.py` を取得
4. `.chezmoiscripts/` の run-script が Doom Emacs まで自動セットアップ
   （macOS で Emacs が無ければ `Brewfile` を呼んで自動導入。Linux では §4 を参照）

聞かれる値:

| プロンプト | 入れる値 | メモ |
|-----------|--------|------|
| Full name | `<your full name>` | git の `user.name` と Doom の `user-full-name` に使う |
| Personal Gmail address | `xxx@gmail.com` | aerc の Gmail アカウント／Doom 用 |
| Git commit email | GitHub の noreply アドレス推奨 | 例: `12345678+username@users.noreply.github.com` |
| Organization Outlook | 組織 M365 アドレス（不要なら空 Enter） | 空だと aerc に `[Outlook]` セクションが作られない |

再度プロンプトを出したい場合は `chezmoi init --prompt`。

### 1.3 macOS の場合 — Brewfile

```sh
brew bundle --file=~/.local/share/chezmoi/Brewfile
exec zsh
```

`Brewfile` で導入されるもの:

- **コア**: chezmoi, git, emacs (Doom 用), cmake (vterm 用), aerc, w3m
- **シェル体験**: starship, tmux, fzf, zoxide, eza, bat, fd, ripgrep, git-delta, tealdeer
- **フォント**: JetBrainsMono Nerd Font（ghostty / i3 用）

`exec zsh` 後は starship プロンプトと CLI ツール連携（`Ctrl-R` の fzf 履歴検索、
`z <dir>` で zoxide ジャンプ等）が有効になる。

### 1.4 Linux / HPCI の場合

`brew` が無いので、必要なものを個別に入れる。**いずれも root 不要、単一バイナリで配布されている**。

```sh
mkdir -p ~/.local/bin && cd ~/.local/bin

# starship — 公式ワンライナー
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin -y

# fzf / zoxide / eza / bat / fd / ripgrep / git-delta は GitHub Releases から:
#   https://github.com/junegunn/fzf/releases
#   https://github.com/ajeetdsouza/zoxide/releases
#   https://github.com/eza-community/eza/releases
#   https://github.com/sharkdp/bat/releases
#   https://github.com/sharkdp/fd/releases
#   https://github.com/BurntSushi/ripgrep/releases
#   https://github.com/dandavison/delta/releases
```

`dot_zprofile.tmpl` が `~/.local/bin` を PATH に通すので、初回は `exec zsh` で
反映する。

aerc は `go install git.sr.ht/~rjarry/aerc@latest`（Go ≥ 1.21）か、
[リリースのバイナリ](https://git.sr.ht/~rjarry/aerc/refs)を使う。

---

## 2. シークレット設定

### 2.1 Gmail のアプリパスワード（aerc 用）

Gmail は IMAP/SMTP で通常パスワード使用を許可しない。**アプリパスワード**を発行する:

1. Google アカウントで 2 段階認証を有効化
2. [アプリパスワード](https://myaccount.google.com/apppasswords)で 16 桁を発行
3. リポジトリには入れず、OS の安全な保管先に登録:

```sh
# macOS — ログイン Keychain に保存
security add-generic-password -a "$USER" -s aerc-gmail -w

# Linux / HPCI — pass (password-store) に保存
#   初回のみ: gpg --gen-key && pass init <GPG ID>
pass insert email/gmail
```

aerc の `accounts.conf` の `source-cred-cmd` / `outgoing-cred-cmd` が、
macOS は `security find-generic-password`、Linux は `pass show` で自動取得する。

### 2.2 Outlook（組織 M365）OAuth2 認可

M365 は基本認証を廃止済みで、IMAP/SMTP は **OAuth2 (XOAUTH2)** が必須。
`mutt_oauth2.py`（`chezmoi apply` 時に `~/.local/bin/` へ自動取得）でトークン管理する。

**手順 1 — Outlook アドレスが登録されていることを確認**

`chezmoi init --apply` の初回プロンプトで Outlook アドレスを入れていれば
`~/.config/aerc/accounts.conf` に `[Outlook]` 節が生成されている。空にしてしまった
場合は `chezmoi init --prompt` でやり直し。

**手順 2 — OAuth2 で初回認可（1 回だけ）**

```sh
python3 ~/.local/bin/mutt_oauth2.py ~/.config/aerc/outlook.tokens \
  --verbose --authorize \
  --provider microsoft \
  --authflow devicecode \
  --email '<組織 M365 アドレス>' \
  --client-id '9e5f94bc-e8a4-4e73-b8be-63364c29d753' \
  --encryption-pipe cat --decryption-pipe cat
```

- `Client secret:` は**空のまま Enter**（public client なので secret 無し）。
- 続いて `https://microsoft.com/devicelogin` と 8 桁前後のコードが表示される。
  ブラウザでその URL を開き、コードを入力し、組織アカウントでサインイン →
  アクセスを承認する（スマホのブラウザでも可）。

完了するとトークンが `~/.config/aerc/outlook.tokens`（mode 600）に保存され、
以降は `~/.local/bin/aerc-oauth2` 経由でアクセスされる。

> **`aerc-oauth2` ラッパーについて**: `mutt_oauth2.py` を直接呼ばずに同梱の
> [`dot_local/bin/executable_aerc-oauth2`](../../home/dot_local/bin/executable_aerc-oauth2)
> をラッパーとして噛ませている。理由:
>
> 1. **直列化** — aerc は受信用と送信用で credential コマンドを別々に走らせる。
>    トークン期限切れの瞬間に両方が同時に refresh を投げると Microsoft 側で
>    refresh token がローテーションされ、トークンファイルが破損して以降の認証が
>    失敗する。`mkdir` 排他ロック（macOS は `flock` を持たない）で同時実行を防ぐ。
> 2. **出力整形** — `mutt_oauth2.py` は refresh 失敗時にエラー文を複数行 stdout に
>    出すが、aerc は cred-cmd 出力の 2 行目以降を cache duration として解釈し、
>    `invalid duration` で落ちる。ラッパーは「空白なしの 1 行 = トークン」だけを
>    aerc に渡す。

> **組織のポリシー次第で失敗することがある。** IMAP 自体が無効化されている、
> または条件付きアクセスで非承認アプリ（上記 Thunderbird ID）が弾かれる場合は
> 管理者に IMAP 有効化を依頼するか、組織で独自の Azure アプリ登録を行って
> Client ID を差し替える。

### 2.3 起動

```sh
aerc
```

`?` でキー一覧。実用キーは [dot_config/aerc/cheatsheet.md](../../home/dot_config/aerc/cheatsheet.md)
を分割ペインで開いておくとよい:

```sh
less ~/.config/aerc/cheatsheet.md
```

---

## 3. シェル（zsh / starship / tmux）

`chezmoi apply` で次が配置される:

- `~/.zshrc` — 履歴 50000・session 共有・重複除去、補完、エイリアス、CLI ツール連携
- `~/.zprofile` — `brew shellenv` (macOS のみ) + `~/.local/bin` PATH 追加
- `~/.zshenv` — `XDG_CONFIG_HOME` 固定
- `~/.config/starship.toml` — プロンプト設定
- `~/.tmux.conf` — gruvbox、prefix `C-a`、`|`/`-` 分割

### 3.1 マシン固有 init（conda / nvm 等）の置き場所

`conda init` や `nvm`、`bun` 等が `~/.zshrc` に追記する内容は**絶対パスを含み
マシン固有**なので、リポジトリ管理の `~/.zshrc` には入れない。代わりに
**`~/.zshrc.local`**（Git 管理外）に書く。dotfiles 管理の `~/.zshrc` 冒頭で
これを source する仕組みにしてある。

```sh
# 新マシンでツールを入れた後の流れ
conda init zsh                    # 既存の ~/.zshrc に追記される
# ↓ その追記分を ~/.zshrc.local に移し、~/.zshrc 側は chezmoi 管理に戻す
$EDITOR ~/.zshrc ~/.zshrc.local
chezmoi apply ~/.zshrc            # ~/.zshrc を再生成
```

### 3.2 conda の二重プロンプト対策

starship 自体が conda 環境名を表示するので、conda 側のプロンプト改変を切る:

```sh
conda config --set changeps1 False
```

### 3.3 tmux（SSH 切断耐性）

HPCI へ SSH するときは tmux を間に挟むと、回線が切れても作業状態が残る。

```sh
tmux              # 新規セッション開始
tmux a            # 既存セッションへ再接続
C-a d             # detach（セッションは生きたまま離脱）
C-a |  /  C-a -   # 縦／横分割
C-a h/j/k/l       # ペイン移動（vim 風）
C-a r             # 設定ファイルを reload
```

---

## 4. Doom Emacs

**Doom 本体の clone と sync は `chezmoi apply` 時に自動実行される**（[.chezmoiscripts/](../../home/.chezmoiscripts/)）。
手動 clone は不要。

| スクリプト | 役割 |
|------------|------|
| `run_once_after_20-install-doom` | Emacs を確認し、doomemacs を clone → `doom install` |
| `run_onchange_after_30-doom-sync` | `init.el`/`config.el.tmpl`/`packages.el` が変わるたび `doom sync` |

唯一の前提は **Emacs 28 以上が PATH にあること**。

- **macOS**: Emacs が無ければ run-script が `Brewfile` から自動導入する。
- **Linux/HPCI**: Emacs は dotfiles の管轄外（root 不要の導入方法は環境依存）。
  未導入だと run-script が手順を表示して停止するので、以下のいずれかで Emacs を
  入れてから `chezmoi apply` を再実行する:
  - `module avail emacs && module load emacs/<version>`
  - `conda install -c conda-forge emacs`
  - ソースビルド: `./configure --prefix=$HOME/.local --with-native-compilation`

`run_once_` スクリプトは失敗しても「実行済み」にならないので、Emacs 導入後に
`chezmoi apply` するだけで続きから自動で進む。

設定（`init.el` 等）を編集 → `chezmoi apply` で `doom sync` まで自動。

---

## 5. i3（Linux のみ）

macOS では `.chezmoiignore` により展開されない。Linux では:

```sh
apt install i3 i3status dmenu        # Debian/Ubuntu 系
```

設定は `~/.config/i3/config` と `~/.config/i3status/config`。
modkey は `Mod4`（Super/Win キー）。`Mod4+Return` で端末、`Mod4+d` でランチャ。
フォントに JetBrainsMono Nerd Font を使うのでインストールしておくこと。

---

## 6. gruvbox

`.chezmoiexternal.toml` が `chezmoi apply` 時に
[morhetz/gruvbox](https://github.com/morhetz/gruvbox) を
`~/.vim/pack/themes/start/gruvbox` に自動 clone する（168 時間ごとに更新）。
`dot_vimrc` がそれを読み込む。

Neovim で使うなら `~/.vim` を runtimepath に加えるか、clone 先を `~/.config/nvim`
配下に変更する。

ツールごとの gruvbox 化は全て設定済み:
ghostty (`Gruvbox Dark`)、aerc (`stylesets/gruvbox`)、i3（パレット直書き）、
Doom (`doom-gruvbox`)、tmux（status line に直書き）、bat (`BAT_THEME=gruvbox-dark`)。

---

## 7. トラブルシュート

### 7.1 aerc Outlook: `authenticate failed` / `invalid duration`

- **原因**: cred-cmd の競合またはトークンファイル破損。`aerc-oauth2`
  ラッパーが直列化＋出力整形をするので新環境では発生しないはず。
- **対処**:
  1. aerc の Outlook タブで `:connect` で再接続。
  2. 直らなければ aerc を `q` で終了して再起動。
  3. それでも駄目ならトークンファイルが壊れている可能性があるので §2.2 の
     `--authorize` をやり直す。
- **診断**: `mutt_oauth2.py --test ...` で IMAP/POP/SMTP の認証可否を直接確認できる。

### 7.2 `chezmoi apply` が `gitEmail` で失敗

`.chezmoi.toml.tmpl` を編集した直後は、キャッシュ済みの `~/.config/chezmoi/chezmoi.toml`
に新しいキーが入っていない。`chezmoi init` を一度走らせれば足りる（既存値は保持される）。

### 7.3 doom-sync スクリプトが失敗する

Emacs 28+ が PATH にあるか確認。HPCI 等で未導入のときは §4 の手順で導入してから
再度 `chezmoi apply`。`run_once_` は失敗時には記録されないので何度でもやり直せる。

### 7.4 starship プロンプトが出ない / 文字化け

- starship が PATH にあるか: `command -v starship`
- ターミナルが Nerd Font を使っているか（ghostty の `font-family` が
  `JetBrainsMono Nerd Font` になっていれば OK）
- `~/.zshrc` の末尾で `eval "$(starship init zsh)"` が走っているはず。`echo $PROMPT`
  で確認、もしくは `exec zsh` で読み直す。
