# Dev Rewindへの貢献

Dev Rewindは、指定したGitリポジトリの作業状況を読み取り、朝の計画や夕方の振り返りを支援するテキスト形式のスキルです。バグ報告、説明の改善、再現可能なテストを歓迎します。

## 利用と開発の準備

利用者向けの導入・最初の実行は[スキルREADME](skills/dev-rewind/README.md)にまとめています。Claude CodeとCodexの配置先、macOS/Linux ShellとWindows PowerShellの安全なコピー例もそちらを参照してください。開発・テストだけなら個人用skillsフォルダへのインストールは不要です。

| 作業 | 必要なもの |
| --- | --- |
| ソースの取得・Gitテスト | Git |
| 自動テスト・ZIP作成 | Python 3.9以上（標準ライブラリのみ） |
| Shell検査 | BashとShellCheck（warning以上を失敗扱い） |
| 導入例の検証 | POSIX ShellとPowerShell。WindowsではGit for WindowsのGit BashとWindows PowerShellを利用可能 |
| スキルの実行確認 | 対応するエージェントと、その環境で許可されたGitアクセス |
| GitHub情報の取得 | 必要な場合だけGitHub CLIなどの認証済み接続 |

WSL、Node.js、npm、curlはPythonテストやコアスキルの導入には不要です。通知などの補助機能には別の前提条件があります。[任意操作の説明](skills/dev-rewind/references/optional-operations.md)を確認してください。npmのMCPサーバーはこのスキルZIPとは別の成果物です。

リポジトリをクローンした後、そのルートで作業します。Pythonのコマンド名が異なる環境では、以下の `python` を `python3` または `py -3` に読み替えてください。

## 構成

```text
skills/dev-rewind/       スキル本体、README、テンプレート、参照文書、架空の例
skills/standup/          互換エントリと既存の補助スクリプト
scripts/                スキル検査・配布ZIP作成
tests/                  合成データと一時ディレクトリによる自動テスト
.github/workflows/      GitHub Actions
docs/                   設計・配布に関する文書
LICENSE                 MITライセンス
```

現在の動作はmainにある実装とスキルREADMEで確認してください。未マージのPRや設計案を利用可能な機能として案内しないでください。

## 変更の進め方

1. 既存Issueを確認し、バグなら再現手順・期待結果・実際の結果を整理します。OS、Python、Shell、使用したエージェントのバージョンも添えてください。
2. 最新のmainから作業ブランチを作ります。例: `docs/improve-first-run`、`fix/package-validation`、`ci/skill-checks`。
3. 問題に必要な範囲だけ変更し、不具合修正には失敗を再現するテストを追加します。
4. 下記の検証を実施し、実行環境・結果・未検証範囲をPRに記載します。
5. 通常のPRを作成し、レビューとCIの結果を確認します。関連Issueはリンクし、そのPRで完了する場合だけ `Closes #番号` を使います。

タイトルと本文は日本語で構いません。タイトルは変更の目的を短く示し、本文には「問題と変更後の動作」「変更範囲」「検証と制約」を記載してください。テスト未実行を成功と記載しないでください。

## スキルとコードの品質基準

- `SKILL.md` のfrontmatterでは `name` と `description` を明確にし、descriptionに利用場面とトリガーを記述します。エージェント固有の追加項目は必須と決めつけません。
- 本文では入力、出力、手順、実行例、情報が取得できない場合の扱いを示します。手順は初心者が順に実行できる粒度にします。
- Gitの観測事実とユーザーの回答・推測を区別します。ログがないことを「作業していない」と断定しません。
- コアは読み取り中心とし、外部送信、ファイル保存、Git変更などは対象と許可の条件を明記します。
- READMEの導入手順を別文書に複製せず、正規の説明へリンクします。説明するコマンド・オプションは実装と一致させます。
- Pythonは3.9以上で動く標準ライブラリを優先し、パスは `pathlib`、外部コマンドは引数配列と明示的な失敗判定を使います。
- Shellではパス・変数を引用し、終了コードを伝播します。`set -euo pipefail` だけで全失敗を検出できるとは限らないため、不正入力のテストも行います。
- 新しい依存や配布物を追加する場合は、ライセンスと配布対象を確認します。スキル本体に不要なサービス・モデルの導入を増やしません。

## 検証

リポジトリのルートで実行します。

```text
python -m unittest discover -s tests -v
```

Gitの読み取り、READMEの導入例、スキル検査、ZIPの許可リスト・元ファイル一致・上書き防止を検証します。テストは架空のリポジトリや一時領域を使い、実際の個人用skillsフォルダ、通知先、会話履歴には触れません。Shellが見つからずskipされたテストは未検証として報告してください。

BashとShellCheckがPATHにある場合:

```text
python scripts/check_skills.py --shellcheck shellcheck
```

WindowsでGit Bashを明示する場合（ShellCheckも実際の配置先に合わせる）:

```powershell
python scripts/check_skills.py --bash 'C:/Program Files/Git/bin/bash.exe' --shellcheck 'C:/tools/shellcheck.exe'
```

この検査は各スキル直下の `SKILL.md` の存在を確認し、`skills/` 配下の全Shellスクリプトに構文検査とShellCheckを実行します。1ファイルの失敗でも非ゼロ終了します。補助スクリプトを本番データで実行する必要はありません。

配布候補は未使用の出力ファイル名を指定して作成します。

```text
python scripts/package_skill.py --output ../dev-rewind-review.zip
python -m zipfile -t ../dev-rewind-review.zip
git diff --check
```

ZIP作成は既存の出力を上書きしません。中身は明示された6つのテキストファイルのみです。内容を変更した場合は、架空のサンプルだけであること、リンク、表現、ライセンスも目視確認してください。ZIPの生成やCI成功は、マーケット出品やエージェント上の動作確認を意味しません。

CIではLinux上のShell検査、Linux（Python 3.9/3.13）・Windows・macOS（Python 3.13）の自動テストとZIP作成・整合性検査を行います。外部通知やスキルの自動インストールは行いません。

## プライバシーとレビュー前チェック

- [ ] 実会話、非公開業務データ、認証情報、個人用の絶対パスを例・テスト・ログ・ZIPに含めていない。
- [ ] バグの再現には匿名化した最小例を使い、秘密情報を含むファイル本文を収集していない。
- [ ] 変更に対応したテストとCIの結果を確認し、未検証のOS・エージェントを明記した。
- [ ] 配布対象や権限を変えた場合は、理由と影響を説明した。
- [ ] 実装されていない機能、未確認の掲載実績、サポート提供の約束を追加していない。

質問や不具合は[GitHub Issues](https://github.com/t1k2a/claude-hurikaeri/issues)へ、秘密情報を除いた内容で投稿してください。
