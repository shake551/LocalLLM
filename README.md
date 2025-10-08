# LocalLLM

ローカルLLMを使用したiOSチャットアプリです。Ollamaを使用してローカル環境でAIモデルと対話できます。

## 概要

このアプリは以下の機能を提供します：

- 📱 SwiftUIベースのモダンなチャットインターフェース
- 🤖 Ollama経由でのローカルLLMとの対話
- 💬 リアルタイムメッセージ表示
- 📝 会話履歴の保持
- 🎤 **音声文字起こし機能** - 音声をリアルタイムでテキストに変換
- ✨ **AI文章改善** - 音声認識結果をLLMで自動的に読みやすく整理
- 🏠 **ホーム画面** - チャットと文字起こし機能への簡単アクセス
- ⚡ 高速なローカル処理（インターネット接続不要）

## 必要要件

- **Xcode 16.0** 以上
- **iOS 26.0** 以上（シミュレーター対応）
- **macOS** (Ollamaサーバー用)
- **Homebrew** (Ollamaインストール用)

## セットアップ手順

### 1. Ollamaのインストール

```bash
# Homebrewを使用してOllamaをインストール
brew install ollama
brew services start ollama
```

### 2. LLMモデルのダウンロード

```bash
# 軽量モデル（推奨）
ollama pull llama3.2:1b

# または他のモデル（より高性能だが重い）
ollama pull llama3.2:3b
ollama pull llama3.2:7b
```

### 3. Ollamaサーバーの起動

```bash
# Ollamaサーバーを起動（ポート11434で実行）
ollama serve
```

**注意**: Ollamaサーバーは常に起動させておく必要があります。新しいターミナルウィンドウで実行することをお勧めします。

### 4. プロジェクトのビルドと実行

```bash
# プロジェクトディレクトリに移動
cd /path/to/LocalLLM

# Xcodeでプロジェクトを開く
open LocalLLM.xcodeproj

# または、コマンドラインでビルド
xcodebuild -project LocalLLM.xcodeproj -scheme LocalLLM -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 使用方法

### 基本操作

1. **アプリを起動**: Xcodeからシミュレーターでアプリを実行
2. **メッセージ入力**: 画面下部の入力フィールドにメッセージを入力
3. **送信**: 紙飛行機アイコンをタップまたはEnterキーで送信
4. **AI応答**: しばらく待つとAIからの返答が表示されます

### 機能

- **チャットクリア**: 右上の「クリア」ボタンで会話履歴をリセット
- **エラー表示**: 接続エラーなどが発生した場合、画面上部に赤いエラーメッセージが表示
- **ローディング表示**: AI処理中は「考え中...」のメッセージが表示

## 設定とカスタマイズ

### モデルの変更

`LLMService.swift` の24行目でモデル名を変更できます：

```swift
let request = ChatRequest(
    model: "llama3.2:1b",  // ここを変更
    messages: messages,
    stream: false
)
```

利用可能なモデル：
- `llama3.2:1b` - 高速、軽量（推奨）
- `llama3.2:3b` - バランス型
- `llama3.2:7b` - 高性能、重い

### サーバーURLの変更

`LLMService.swift` の5行目でOllamaサーバーのURLを変更できます：

```swift
private let baseURL = "http://localhost:11434"  // ここを変更
```

## トラブルシューティング

### よくある問題

1. **「リクエストが失敗しました」エラー**
   - Ollamaサーバーが起動しているか確認: `ollama serve`
   - ポート11434が使用されていないか確認

2. **「モデルが見つかりません」エラー**
   - モデルがダウンロードされているか確認: `ollama list`
   - 必要に応じてモデルを再ダウンロード: `ollama pull llama3.2:1b`

3. **ビルドエラー**
   - Xcodeが最新バージョンか確認
   - Derived Dataをクリア: Xcode → Product → Clean Build Folder

### ログの確認

```bash
# Ollamaのログを確認
ollama logs

# 利用可能なモデルを確認
ollama list

# Ollamaサーバーの状態を確認
curl http://localhost:11434/api/tags
```

## 技術仕様

### アーキテクチャ

- **UI**: SwiftUI + Combine
- **ネットワーク**: URLSession + async/await
- **LLM**: Ollama REST API
- **最小iOS**: 26.0
- **言語**: Swift 5.0

### ファイル構成

```
LocalLLM/
├── LocalLLMApp.swift      # アプリエントリーポイント
├── ContentView.swift      # メインビュー
├── ChatView.swift         # チャットインターフェース
├── ChatViewModel.swift    # チャット状態管理
├── MessageView.swift      # メッセージ表示コンポーネント
├── Message.swift          # メッセージデータモデル
├── LLMService.swift       # Ollama API通信
└── Assets.xcassets/       # アプリリソース
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

バグ報告や機能追加の提案は、GitHubのIssuesまでお願いします。

---

**開発者向け情報**: 詳細な開発ガイドは `CLAUDE.md` を参照してください。
