# 遊創舎 Godot 基盤（準備用）

この `godot-ready` ブランチは、将来の `yusosha-godot` 専用リポジトリとして使用するための空の基盤です。まだ実行可能なゲームはありません。

- `projects/slot-test/`: スロット試作の配置先
- `projects/management-test/`: 経営ゲーム試作の配置先
- `shared/audio/`, `shared/ui/`, `shared/save/`, `shared/data/`, `shared/debug/`: 共通資産の整理先
- `docs/`: 開発資料

各試作は独立したGodotプロジェクトとして作成してください。共通資産を各プロジェクトに取り込む方法は、実際のプロジェクト作成時に決めます。

## 保存済み資産

元のDesign Labは `main` ブランチに履歴ごと保持しています。統合先は https://github.com/mth310-sys/yusosha-slot/tree/main/design-lab 、公開先は https://mth310-sys.github.io/yusosha-slot/design-lab/ です。

旧main、デフォルトブランチ、GitHub Pages設定、リポジトリ名は変更していません。名前を `yusosha-godot` に変更すると旧Pages URLに影響するため、ユーザー確認後に切り替えます。

Chappy5 および作成途中の slot-pachiro-godot（ぱち郎）とは独立した基盤です。そちらのファイルをコピー・変更していません。
