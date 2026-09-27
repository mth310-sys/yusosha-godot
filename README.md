# Yusosha — Godot Restart

Godot 4.7.2 / GDScript / GL Compatibility を基準とする新規プロジェクトです。
旧Godotプロジェクトは持ち込まず、必要な資産だけを後から選別して再利用します。

## 開発経路

GitHubを正本とします。

1. ChatGPTが mth310-sys/yusosha-godot の設計・コード・シーンを編集します。
2. PCのGitHub Desktopで Fetch / Pull して変更を取得します。
3. Godot 4.7.2でプロジェクトを開き、実行・表示・操作を確認します。
4. PC側で必要な変更を行った場合は、GitHub Desktopで内容を確認してCommit / Pushします。
5. ChatGPTがGitHub上の最新状態を確認して次の変更を行います。

## 方針

- Engine: Godot 4.7.2
- Language: GDScript
- Renderer: GL Compatibility
- GitHub repository: mth310-sys/yusosha-godot
- main branchを現行の正本とする
- .godot/ はGit管理しない
- Chappy5および旧Godotワークスペースには変更を加えない
- 有料API・有料外部サービスを前提にしない

## Connection Test

main.tscnを実行して次の表示が出れば、ChatGPT → GitHub → PC → Godot の更新経路は正常です。

YUSOSHA GODOT RESTART

ChatGPT → GitHub → Godot : CONNECTED
