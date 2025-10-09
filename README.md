# LocalLLM

iOS 26の Apple Intelligence Foundation Model を使用した完全オンデバイスAIアシスタントアプリです。

## 概要

このアプリは以下の機能を提供します：

- 🧠 **Apple Intelligence Chat** - Foundation Model による高品質なAI会話
- 🎤 **音声文字起こし** - 音声をリアルタイムでテキストに変換
- 👁️ **Visual Intelligence** - 画像の AI 分析とオブジェクト検出
- 📱 SwiftUIベースのモダンなインターフェース
- 🔒 **完全プライベート** - すべての処理がデバイス上で実行
- ⚡ **ネットワーク接続不要** - 完全オフライン動作
- 🏠 **統合ホーム画面** - 全機能への簡単アクセス

## 必要要件

- **Xcode 26.0** 以上
- **iOS 26.0** 以上
- **Apple Intelligence対応デバイス** (A17 Pro以上のチップまたはApple Silicon Mac)
- **Apple Intelligence有効化** (設定 → Apple Intelligence & Siri)

## セットアップ手順

### 1. Apple Intelligenceの設定

1. **設定アプリ** を開く
2. **Apple Intelligence & Siri** に移動
3. **Apple Intelligence** をオンにする
4. 利用規約に同意し、セットアップを完了

### 2. プロジェクトのビルドと実行

```bash
# プロジェクトディレクトリに移動
cd /path/to/LocalLLM

# Xcodeでプロジェクトを開く
open LocalLLM.xcodeproj

# または、コマンドラインでビルド
xcodebuild -project LocalLLM.xcodeproj -scheme LocalLLM -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 機能詳細

### 🧠 Apple Intelligence Chat

- **Foundation Model**: iOS 26の30億パラメータオンデバイスモデル
- **自然な会話**: 事前定義レスポンスなしの本格的なAI対話
- **言語自動検出**: 日本語・英語に自動対応
- **会話履歴**: セッション内での文脈保持
- **完全プライベート**: データが端末を離れることなし

### 🎤 音声文字起こし

- **リアルタイム認識**: 話している内容をリアルタイムで表示
- **高精度変換**: iOS Speech Recognitionによる高品質な音声認識
- **自動保存**: 認識結果の自動保存機能
- **履歴管理**: 過去の文字起こし結果を一覧表示
- **コピー機能**: ワンタップでクリップボードにコピー

### 👁️ Visual Intelligence

- **画像分析**: カメラまたはフォトライブラリからの画像分析
- **オブジェクト検出**: 画像内のオブジェクト自動識別
- **テキスト認識**: 画像内のテキスト抽出（OCR）
- **シーン分類**: 画像の内容・場面の自動分類
- **顔検出**: 画像内の顔の検出と位置特定

## 使用方法

### Apple Intelligence Chat

1. ホーム画面から **「Apple Intelligence Chat」** をタップ
2. 画面下部の入力フィールドにメッセージを入力
3. 送信ボタンをタップまたはEnterキーで送信
4. Foundation Modelからの応答を待つ

### 音声文字起こし

1. ホーム画面から **「音声文字起こし」** をタップ
2. **「録音開始」** ボタンをタップ
3. マイクに向かって話す
4. **「録音停止」** ボタンで終了
5. 認識結果が自動的に保存される

### Visual Intelligence

1. ホーム画面から **「Visual Intelligence」** をタップ
2. **「カメラ」** で撮影、または **「写真選択」** で既存画像を選択
3. 自動的に画像分析が実行される
4. **「AI詳細分析」** で Foundation Model による詳細解説

## トラブルシューティング

### Apple Intelligence関連

1. **「AI機能が利用できません」エラー**
   - Apple Intelligence が有効化されているか確認
   - 対応デバイス（A17 Pro以上）を使用しているか確認
   - iOS 26がインストールされているか確認

2. **「Apple Intelligenceが無効」表示**
   - 設定 → Apple Intelligence & Siri → Apple Intelligence をオンにする
   - デバイスの再起動を試す

3. **「デバイス非対応」表示**
   - A17 Pro以上のチップを搭載したデバイスが必要
   - Apple Silicon Macでは利用可能

### 音声認識関連

1. **マイクアクセス許可**
   - 設定 → プライバシーとセキュリティ → マイク → LocalLLM をオンにする

2. **音声認識許可**
   - 設定 → プライバシーとセキュリティ → 音声認識 → LocalLLM をオンにする

### Visual Intelligence関連

1. **カメラアクセス許可**
   - 設定 → プライバシーとセキュリティ → カメラ → LocalLLM をオンにする

## 技術仕様

### アーキテクチャ

- **UI Framework**: SwiftUI + Combine
- **AI Engine**: Apple Intelligence Foundation Models
- **Image Processing**: Vision + VisionKit
- **Speech**: Speech Recognition + AVFoundation
- **Language Detection**: Natural Language
- **Minimum iOS**: 26.0
- **Language**: Swift 5.0

### Apple Intelligence統合

- **FoundationModels Framework**: iOS 26の新フレームワーク
- **SystemLanguageModel**: Apple の30億パラメータモデル
- **LanguageModelSession**: 会話セッション管理
- **完全オンデバイス**: ネットワーク通信なし

### ファイル構成

```
LocalLLM/
├── LocalLLMApp.swift              # アプリエントリーポイント
├── ContentView.swift              # メインビュー
├── HomeView.swift                 # ホーム画面
├── ChatView.swift                 # Apple Intelligence チャット
├── ChatViewModel.swift            # チャット状態管理
├── TranscriptionView.swift        # 音声文字起こしUI
├── TranscriptionViewModel.swift   # 文字起こし状態管理
├── VisualIntelligenceView.swift   # Visual Intelligence UI
├── VisualIntelligenceService.swift # 画像分析サービス
├── CameraView.swift              # カメラ機能
├── SpeechRecognitionService.swift # 音声認識サービス
├── MessageView.swift             # メッセージ表示コンポーネント
├── Message.swift                 # メッセージデータモデル
├── LLMService.swift              # Apple Intelligence API
└── Assets.xcassets/              # アプリリソース
```

## プライバシーとセキュリティ

### 完全オンデバイス処理

- **データ外部送信なし**: すべての処理がデバイス内で完結
- **ネットワーク通信なし**: インターネット接続は一切不要
- **プライバシー保護**: 会話内容・音声・画像が外部に送信されない

### 権限管理

- **マイク**: 音声文字起こし機能でのみ使用
- **カメラ**: Visual Intelligence機能でのみ使用
- **写真**: 画像選択時のみアクセス

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

バグ報告や機能追加の提案は、GitHubのIssuesまでお願いします。

---

**開発者向け情報**: 詳細な開発ガイドは `CLAUDE.md` を参照してください。