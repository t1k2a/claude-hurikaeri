# Claude Code スキルをマーケットプレイスに公開するまでの完全ガイド

## はじめに

**結論から言うと、Claude Code スキルの公開は超簡単でした。**

この記事では、朝会・夕会を自動化するスキルを作って SkillsMP に掲載するまでの重要ポイントを共有します。

---

## Claude Code スキル公開に必要なもの

最低限必要なのは3つだけです：

| ファイル/設定 | 役割 |
|---|---|
| `SKILL.md` | スキルの本体（Claude への指示） |
| `plugin.json` | プラグインのメタデータ（名刺） |
| GitHub Topics | マーケットプレイスへの索引 |

`SKILL.md` だけでも Claude Code 上では動作しますが、
マーケットプレイスに掲載されるには `plugin.json` と Topics の設定が必要です。
次のセクションからそれぞれの書き方を説明します。

---

## SKILL.md の書き方

`SKILL.md` はスキルの本体です。Claude への指示書であり、**ユーザーが `/スキル名` を呼び出したときに実行される動作**をすべてここに記述します。

### 最小構成

フロントマターと指示本文の2部構成です：

```yaml
---
name: standup
description: >
  GitHub の作業状況を収集して朝会・夕会を行う。
  Use when the user says "standup" or "朝会" or invokes /standup.
argument-hint: "[morning|evening] [hours]"
---

# ここから Claude への指示を書く（Markdown）
```

フロントマターは最初の `---` から次の `---` までです。それ以降がスキルの指示本文になります。

### フロントマターのフィールド

| フィールド | 必須 | 役割 |
|---|---|---|
| `name` | ✅ | スキル名（`/name` で呼び出される） |
| `description` | 推奨 | いつ使うかを Claude に伝える（自動検出に影響） |
| `argument-hint` | オプション | 引数のヒント表示 |

### 指示本文のコツ

**Step に分けて書く**と Claude が迷わず実行できます：

```markdown
## Step 1: リポジトリ情報を収集する

現在のディレクトリで以下のコマンドを順番に実行してください。
失敗した場合はスキップして次に進んでください。

\`\`\`bash
# ブランチ名を取得
git branch --show-current

# 過去24時間のコミット履歴
git log --since="24 hours ago" --oneline --no-merges

# 未コミットの変更
git diff --stat
git diff | head -200

# オープン中のPR（gh CLI がある場合のみ）
command -v gh >/dev/null 2>&1 && \
  gh pr list --author="@me" --state=open --json number,title,url
\`\`\`

**注意**: `gh` CLI がない場合は PR 情報をスキップし、
「GitHub CLI がないため PR 情報は取得できませんでした」と記載する。

## Step 2: 結果をまとめる

以下の形式でレポートを作成する...

## Step 3: ユーザーと対話する

1. 挨拶する
2. 質問する
```

ポイントは「**失敗した場合はスキップ**」という指示を入れること。これがないと途中でエラーが出たときに Claude が止まります。

**`$ARGUMENTS` で引数を受け取れます：**

```markdown
## 引数の解釈

`$ARGUMENTS` を以下のように解釈してください：
- `morning` → 朝会モード
- `evening` → 夕会モード
- 引数なし → デフォルトは朝会
```

### 配置場所

```
skills/
└── standup/        ← スキル名のディレクトリ
    └── SKILL.md    ← ここに置く
```

`skills/` はリポジトリルートに置く必要があります（`.claude-plugin/` の中ではない）。

---

## plugin.json が必要な理由

`plugin.json` は**リポジトリを Claude Code プラグインとして識別するためのマニフェストファイル**です。

`SKILL.md` だけでもスキルは動作しますが、`plugin.json` がないと以下の問題が起きます：

- **マーケットプレイスのクローラーに認識されない**
  SkillsMP などは `plugin.json` の存在をプラグインリポジトリの判定条件にしています
- **バージョン管理ができない**
  `version` フィールドがないと、更新時にユーザーへの通知が機能しません
- **メタデータが欠落する**
  説明・ライセンス・リポジトリURLなどの情報がマーケットプレイス上に表示されません

つまり `plugin.json` は「このリポジトリはスキルです」という**宣言**です。`SKILL.md` が実装本体なら、`plugin.json` は名刺に相当します。

## plugin.json の書き方

[公式ドキュメント](https://code.claude.com/docs/en/plugins-reference)を確認したところ、**必須フィールドは `name` のみ**でした。

### 最小構成

```json
{
  "name": "claude-hurikaeri",
  "version": "1.0.0",
  "description": "...",
  "repository": "https://github.com/...",
  "license": "MIT"
}
```

`version` 以降はオプションですが、マーケットプレイス掲載には推奨です。公式スキーマに準拠することで、自動インデックスがスムーズに機能します。

---

## SkillsMP への自動掲載の仕組み

[SkillsMP](https://skillsmp.com) は**手動申請不要**で、以下の条件を満たせば24〜48時間で自動掲載されます：

1. GitHub 公開リポジトリ
2. `SKILL.md` ファイルが存在
3. GitHub Topics に **`claude-code-skill`** を含む
4. **最低 2 スター**（品質フィルター）

### GitHub Topics の設定

特に `claude-code-skill` は**必須トピック**です。GitHub CLI で一発設定：

```bash
gh api --method PUT repos/USER/REPO/topics --input - <<'EOF'
{
  "names": ["claude-code", "claude-code-skill", "standup"]
}
EOF
```

---

## ディレクトリ構造の罠

`.claude-plugin/` にスキルを入れると認識されません！正しい構造：

```
├── .claude-plugin/
│   └── plugin.json       ← メタデータのみ
├── skills/               ← ルートレベルに配置
│   └── standup/
│       └── SKILL.md
```

---

## 公開手順まとめ

1. `SKILL.md` を作成
2. `plugin.json` を**公式スキーマに準拠**して作成
3. GitHub Topics に `claude-code-skill` を設定
4. 2スター獲得（友人に頼むでOK）
5. 24〜48時間待つ → 自動掲載！

---

## 学んだこと

- **推測で実装しない**：必ず公式ドキュメントを確認
- **エラーハンドリング必須**：`gh` CLI なしでも動作するように
- **ドキュメント充実**：README と LICENSE は最初から用意

---

**参考リンク:**
- [リポジトリ](https://github.com/t1k2a/claude-hurikaeri)
- [公式ドキュメント](https://code.claude.com/docs/en/plugins-reference)
