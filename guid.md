# 🎙️ Claude 音声朝会・夕会 セットアップガイド

## 概要

GitHub の作業状況を自動収集し、Claude の音声モードで毎日の朝会・夕会を行うワークフローです。

## 必要なもの

| ツール | 用途 | インストール |
|--------|------|-------------|
| Git | コミット履歴・差分取得 | 通常インストール済み |
| GitHub CLI (`gh`) | PR・Issue 取得 | `brew install gh` |
| Claude アプリ | 音声対話 | iOS / Android / Desktop |

## 初期セットアップ

### 1. GitHub CLI の認証

```bash
gh auth login
```

### 2. スクリプトの配置

`collect.sh` は **リポジトリの中には置きません**。
`~/bin` など PATH の通った場所に1つだけ置いて、どのリポジトリからでも使えるようにします。

```bash
# ~/bin ディレクトリを作成（なければ）
mkdir -p ~/bin

# スクリプトを standup という名前でコピー
cp collect.sh ~/bin/standup
chmod +x ~/bin/standup

# PATH に追加（~/.zshrc または ~/.bashrc に書く）
# すでに ~/bin が PATH に入っていればスキップしてOK
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

これで、ターミナルのどこからでも `standup` コマンドが使えるようになります。

### 3. Claude プロジェクトの作成

1. [claude.ai](https://claude.ai) にアクセス
2. 左メニューから「Projects」→「+ Create project」
3. プロジェクト名: 「朝会・夕会」など
4. 「Instructions」に `system_prompt.md` の内容を貼り付け
5. 保存

## 毎日の使い方

### 朝会（出勤時・作業開始前）

**ステップ1: ターミナルで情報収集**

```bash
# 方法A: リポジトリに移動してから実行
cd ~/projects/my-app
standup

# 方法B: 引数でリポジトリのパスを指定（移動しなくてOK）
standup ~/projects/my-app

# 期間を変えたい場合（例: 48時間分）
SINCE_HOURS=48 standup ~/projects/my-app
```

→ `~/standup/my-app_2026-02-09.md` のようなファイルが生成され、**自動でクリップボードにコピー**されます。
リポジトリの中にはファイルを作りません。

**ステップ2: Claude で音声会話を開始**

1. claude.ai のプロジェクト「朝会・夕会」を開く
2. クリップボードの内容をペースト（Cmd+V）して送信
3. 🎤 音声モードに切り替え（マイクアイコンをタップ）
4. 声で会話しながら朝会を進める

### 夕会（作業終了時）

```bash
# 今日の作業分だけ収集（例: 10時間分）
SINCE_HOURS=10 standup ~/projects/my-app
```

あとは朝会と同じ手順で Claude に貼り付けて音声会話。

## 複数リポジトリがある場合

```bash
# それぞれ実行（~/standup/ に別々のファイルとして保存される）
standup ~/projects/repo-a   # → ~/standup/repo-a_2026-02-09.md
standup ~/projects/repo-b   # → ~/standup/repo-b_2026-02-09.md

# まとめて1つのクリップボードにしたい場合
#!/bin/bash
COMBINED="/tmp/all_standup.md"
> "$COMBINED"
for repo in ~/projects/repo-a ~/projects/repo-b; do
  standup "$repo"
  cat ~/standup/"$(basename $repo)"_"$(date '+%Y-%m-%d')".md >> "$COMBINED"
  echo -e "\n\n" >> "$COMBINED"
done
cat "$COMBINED" | pbcopy
```

## 音声モードの Tips

- **静かな環境**で使うと認識精度が上がる
- **短い文で話す**と Claude の応答が速い
- 「次」「続けて」などで会話を進められる
- 技術用語は認識されにくいこともあるので、固有名詞はチャットで補足するとよい
- 朝の通勤中に AirPods で使うのもおすすめ

## カスタマイズ例

### 出力先を変える
```bash
# デフォルトは ~/standup/
# 環境変数で変更可能
export STANDUP_DIR=~/Documents/standup
standup ~/projects/my-app
```

### 収集期間を変える
```bash
# 環境変数で指定
export SINCE_HOURS=48  # 2日分
```

### cron で自動収集（macOS）
```bash
# 毎朝 8:50 に自動実行
crontab -e
# 以下を追加:
50 8 * * 1-5 ~/bin/standup ~/projects/my-app
```

### Automator / ショートカットと組み合わせ
macOS の Automator やショートカットアプリで、スクリプト実行 → Claude を開くまでを自動化できます。

## よくある質問

**Q: collect.sh はリポジトリの中に置くの？**
A: いいえ。`~/bin/standup` として1箇所に置くだけです。スクリプトは「今いるディレクトリ」または「引数で渡したパス」の Git リポジトリ情報を収集します。リポジトリごとにコピーする必要はありません。

**Q: 出力ファイルはどこに作られる？**
A: `~/standup/` ディレクトリに `リポジトリ名_日付.md`（例: `my-app_2026-02-09.md`）として保存されます。リポジトリの中にはファイルを作りません。出力先を変えたい場合は環境変数 `STANDUP_DIR` で指定できます。

**Q: 音声モードで GitHub の情報を読み上げてくれる？**
A: はい。会話にサマリーを貼り付けておけば、Claude がその内容を理解した上で音声で要約・対話してくれます。

**Q: プライベートリポジトリでも使える？**
A: はい。`gh` CLI が認証済みなら、プライベートリポジトリの PR/Issue も取得できます。

**Q: モバイルでも使える？**
A: Claude モバイルアプリの音声モードで使えます。GitHub 情報の収集はPC側で行い、テキストをコピペするか、PCの Claude で事前に会話を始めておくとスムーズです。
