# Yusosha — Godot新規プロジェクト

Godot 4.7.2 / GDScript / Compatibility。main.tscnは空の2Dシーンです。
旧プロジェクトのコードや素材は含みません。F6/F5で空の画面が開けば正常です。

## 作業の流れ

1. ブラウザ版ChatGPTに、変更したい内容と現在の関連ファイルを渡します。
2. ChatGPTから、保存先の相対パスとファイル全文を受け取ります。
3. ブラウザ版GitHubで該当ファイルを編集、またはAdd fileからアップロードし、mainへ保存します。
4. PCのGodotを閉じ、デスクトップの「Yusosha 更新してGodotを開く」を実行します。
5. GodotでF5を押して動作確認します。

ブラウザ版ChatGPTにはPCのファイルが自動共有されません。必要なファイルを添付してください。
GitHubへの保存も、自動連携を設定していなければ上記手順で行います。

## PC版Godotで編集した場合

次にGitHubの更新を取り込む前に、PCで変更したファイルをブラウザ版GitHubへアップロードして保存してください。
更新用ショートカットはPCに未保存のGit変更がある場合に停止します。
その場合はGitHub Desktopで変更内容を確認し、必要な新規変更だけをコミット・Pushしてから再実行してください。
古い退避データはアップロードしません。.godotフォルダは保存対象外です。

## ChatGPTへの依頼文

このリポジトリはmth310-sys/yusosha-godotです。Godot 4.7.2、GDScript、Compatibilityを使います。
ブラウザ版GitHubに保存してPC版Godotで実行するため、変更ファイルごとに相対パスと全文を提示してください。
現在のファイルが不足していたら、想像で置き換えず必要なファイルを確認してください。
旧Godotプロジェクトは使わず、この最小プロジェクトから制作します。Chappy5には変更を加えません。

参考: https://learn.chatgpt.com/docs/projects
