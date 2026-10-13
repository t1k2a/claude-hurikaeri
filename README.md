# Dev Rewind

**Plan your day. Reflect on your work.**

Gitの作業記録から、朝会で今日の予定を、夕会で次の一歩を整理するAgent Skillです。
npmの `claude-hurikaeri-mcp` は別配布物であり、このSkillの実行には不要です。

## はじめる

1. [SkillのREADME](skills/dev-rewind/README.md)で必要なGit/ホスト権限を確認します。
2. `skills/dev-rewind` を使うエージェントのskillsディレクトリへフォルダごとコピーします。
   Claude Codeは `~/.claude/skills/`、Codexは `~/.agents/skills/`。
   [macOS/Linux・PowerShellの導入コマンド](skills/dev-rewind/README.md#リポジトリからコマンドで配置する場合)を利用できます。同名の配置先がある場合は停止します。
3. 対象Gitリポジトリを開いて「Dev Rewindで朝会をして」と依頼します。

Claude Codeでは `/dev-rewind morning` / `/dev-rewind evening 8`。
[架空の実行例](skills/dev-rewind/examples/synthetic-session.md)で入出力を確認できます。

既定は指定repoのGit情報を読んで会話内にMarkdownを出すだけです。予定は本人に確認します。
保存、クリップボード変更、外部通知を自動で行いません。
PR/Issueを使う場合は認証済みGitHub CLIが必要です。ghがなくてもGitのみで続行します。
コミット件名やファイル名は利用中のAIホストに渡るため、完全オフラインのツールではありません。

## 対応範囲

ホスト非依存のSKILL.md手順と、Windows PowerShellでも呼べるGitコマンドを提供します。
配置先は[Claude Code公式](https://code.claude.com/docs/en/skills)と
[Codex公式](https://developers.openai.com/codex/skills/)を参照しています。
WindowsのGitコマンドとパッケージテストは実行しますが、Claude Code/Codex/Gemini CLIの
各アプリでのエンドツーエンド対応を保証するものではありません。詳細は[検証記録](docs/distribution.md)。

## 配布ZIPの作成（メンテナー用）

Python 3.9以上の標準ライブラリだけを使用します。Skill利用者にPythonは不要です。

```text
python -m unittest discover -s tests -v
python scripts/package_skill.py --output ../dev-rewind-skill.zip
```

作成先が存在する場合は上書きせず失敗します。
固定リストのテキスト6ファイルだけを格納し、LICENSEはrootの原文を保持します。
履歴、認証設定、実レポート、npm tarball、補助スクリプトは入りません。
[出品紹介文・配布内容・公開前の未決事項](docs/distribution.md)を参照してください。

## ライセンス

[MIT License](LICENSE)。
不具合報告はこのリポジトリのIssuesへ。
