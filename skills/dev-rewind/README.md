# Dev Rewind

**Plan your day. Reflect on your work.**

Gitの作業記録を見ながら朝会・夕会を進める、日本語中心のAgent Skillです。
コミット、未コミット変更の概要、任意のGitHub PR/Issueから、短いMarkdownの下書きと
今日/次回の行動を整理します。Gitに記録されない仕事や本人の予定は会話で補います。

## 必要なもの

- SKILL.mdを読み、ローカルコマンドを実行できるエージェント。
- Git。GitHub PR/Issueを使う場合のみGitHub CLI (`gh`) と必要なリポジトリへの認証。
- このSkillにNode.js、npm、MCPサーバー、WSL、ローカルLLMは不要。
- 利用するエージェント自体の契約・利用料やデータ取扱いは各提供元に従います。

これはプロンプトと手順の配布物です。各フラグはエージェントが解釈する依頼で、
専用CLIコマンドではありません。Shell/ファイル/HTTP機能がないホストでは一部を実行できません。

## インストール

以下はGitHubのソース、または作者から直接入手したZIPをローカルに配置する手順です。
マーケットプレイス経由の利用方法・導入可否は各サービスで確認してください。

### ZIPから配置する場合

ZIPを展開して `dev-rewind/SKILL.md` があることを確認します。
下記の**いずれか1つ**の場所へ `dev-rewind` フォルダごと置きます。
既存の同名フォルダがある場合は内容をバックアップして比較し、無断で上書きしないでください。

| ホスト | 個人用の配置先 | 備考 |
|---|---|---|
| Claude Code | `~/.claude/skills/dev-rewind/` | `/dev-rewind morning` で呼び出し |
| Codex | `~/.agents/skills/dev-rewind/` | Skill選択、または「Dev Rewindで朝会をして」 |
| その他 | そのホストが指定するSkillの場所 | 読込方式・権限・呼出し方法を確認。動作保証なし |

`~` は自分のホームディレクトリです。Windows例: `C:\Users\<you>\.agents\skills\dev-rewind\`。
Claude Codeのプロジェクト限定なら `<project>/.claude/skills/dev-rewind/`。
Codexのプロジェクト限定なら `<project>/.agents/skills/dev-rewind/`。
配置後、ホストの再読込/新しいセッションでSkillの表示を確認します。

### リポジトリからコマンドで配置する場合

以下は、取得済みリポジトリのルート（`skills/dev-rewind/SKILL.md` がある場所）で実行します。
配布ZIPを展開しただけのフォルダでは使わず、上の手動配置手順を使ってください。

**Claude Codeは `agent` を `claude` のまま、Codexは `codex` に変えて**、使うOSのブロック全体を実行します。
個人用ディレクトリへのコピーです。ホストやGitのインストール、ログイン、通信は行いません。

#### macOS / Linux（sh・bash・zsh）

```sh
(
  set -eu
  agent=claude
  case "$agent" in
    claude) skills_relative=.claude/skills ;;
    codex) skills_relative=.agents/skills ;;
    *) printf '%s\n' 'Choose claude or codex.' >&2; exit 1 ;;
  esac
  source_dir=./skills/dev-rewind
  skills_parent="$HOME/$skills_relative"
  destination="$skills_parent/dev-rewind"

  if [ ! -d "$source_dir" ] || [ ! -f "$source_dir/SKILL.md" ]; then
    printf '%s\n' 'Source missing: run from the repository root.' >&2
    exit 1
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'Destination already exists; not overwritten: %s\n' "$destination" >&2
    exit 1
  fi
  mkdir -p "$skills_parent"
  mkdir "$destination"
  cp -R "$source_dir/." "$destination/"
  printf 'Installed: %s\n' "$destination"
)
```

#### Windows PowerShell

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $agent = 'claude'
    $skillsRelative = switch ($agent) {
        'claude' { '.claude/skills' }
        'codex' { '.agents/skills' }
        default { throw 'Choose claude or codex.' }
    }
    $sourceDir = Join-Path (Get-Location).Path 'skills/dev-rewind'
    $skillsParent = Join-Path $HOME $skillsRelative
    $destination = Join-Path $skillsParent 'dev-rewind'

    if (-not (Test-Path -LiteralPath $sourceDir -PathType Container) -or
        -not (Test-Path -LiteralPath (Join-Path $sourceDir 'SKILL.md') -PathType Leaf)) {
        throw 'Source missing: run from the repository root.'
    }
    if (Test-Path -LiteralPath $destination) {
        throw "Destination already exists; not overwritten: $destination"
    }
    New-Item -ItemType Directory -Path $skillsParent -Force | Out-Null
    New-Item -ItemType Directory -Path $destination -ErrorAction Stop | Out-Null
    Get-ChildItem -LiteralPath $sourceDir -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -ErrorAction Stop
    }
    Write-Output "Installed: $destination"
}
```

コピー元がない場合は配置先を作らず停止します。同名の配置先がある場合も上書きせず停止します。
成功すると `Installed:` と配置先を表示します。コピー途中で失敗した場合は成功と扱わず、
表示された配置先を確認してください。再実行しても既存フォルダには上書きしません。
配置後は新しいセッションでDev Rewindを選び、対象Gitリポジトリで実行します。

導入コマンドはWindows PowerShell 5.1とWindows上のGit Bashで、一時フォルダを使い
初回成功・同名コピー先あり・コピー元なしを両ホストの配置先について検証しました。
macOS/Linux実機と、各エージェントによるスキル読込・実利用のE2Eは未検証です。

配置先は2026-10-13に [Claude Code公式](https://code.claude.com/docs/en/skills)と
[Codex公式](https://developers.openai.com/codex/skills/)で確認しました。
ローカル実行のホスト向けであり、クラウドセッションへ自動配置するものではありません。


### 最初の実行

対象Gitリポジトリを作業ディレクトリとして開き、次のように依頼します。

> Dev Rewindで朝会をして。過去24時間を確認し、保存や通知はしないで。

Claude Codeの例:

```text
/dev-rewind morning
/dev-rewind evening 8
/dev-rewind morning 48 "C:\Projects\demo app"
```

リポジトリ、期間、根拠付きの作業要約と「未確認」の予定が出たら、確認質問に答えます。
朝会は今日の予定、夕会は次回の予定を決めます。[架空の会話例](examples/synthetic-session.md)も参照。

## データと追加操作

既定では指定repoのコミット件名・差分統計・未追跡ファイル名だけを読み、会話内に出力。
差分本文、秘密ファイル、他の会話履歴を自動収集せず、保存や送信もしません。
GitHub取得にはGitHubとの通信が発生し、収集結果は利用中のAIホストに渡ります。
ファイル名や件名にも秘密が含まれ得るので、利用前に対象とホストのデータポリシーを確認してください。

| 任意の依頼 | 読取/書込/通信 |
|---|---|
| `--save` | `~/.standup-history/` にJSONを書込。既存ファイルは上書きしない |
| `--search deploy` / `--summary weekly` / `--summary monthly` | 同ディレクトリ直下のJSONだけ読取 |
| `--export html` / `--open` | 現在の作業ディレクトリへ単体HTMLを書込。指定時だけ表示 |
| `--template <path>` | 指定Markdownを読取 |
| `--notify slack`, `--notify discord`, `--notify chatwork` | 明示された宛先へ本文を送信。設定とホスト機能が必要 |

詳細と失敗時の動作は [追加操作](references/optional-operations.md)。追加操作は手順の提供であり、
全ホスト/通知サービスでの実機検証済み機能ではありません。

## 困ったとき

- Gitがない: インストール済みと仮定せず、まず `git --version`。作業メモの手動入力も可能。
- ghがない/未認証: Gitだけで続行します。PR/Issueが取得できなかった旨を表示します。
- Gitリポジトリでない: パスを指定し直してください。元のファイルは変更しません。
- 予定が未確認: 不具合ではありません。回答するか、下書きとして受け取ってください。
- Skillが見えない: 二重フォルダになっていないか、SKILL.mdの場所とホストの再読込を確認。

## 対応・ライセンス

Windows上のGit収集コマンドとZIP作成は検証対象です。Claude Code/Codex/Gemini CLI各アプリの
エンドツーエンド検証や通知の実送信は未実施。配置先の案内だけで動作保証はしません。
README/SKILL.md等のテキストのみを同梱。既存MITライセンスは同梱LICENSEを参照。
Skillの実行依存ソフト自体は同梱しません。

元リポジトリ: https://github.com/t1k2a/claude-hurikaeri
不具合報告: https://github.com/t1k2a/claude-hurikaeri/issues
公開npm `claude-hurikaeri-mcp` は別の配布物で、このZIPには含まれません。
このZIPは `dev-rewind` スキル単体です。
