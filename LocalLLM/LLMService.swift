import Foundation
import Combine
import NaturalLanguage
import CoreML
import FoundationModels

class LLMService: ObservableObject {
    @Published var serverURL: String = ""
    @Published var isConnected: Bool = false
    @Published var isUsingLocalLLM: Bool = true
    @Published var isAppleIntelligenceAvailable: Bool = false
    @Published var appleIntelligenceStatus: String = "確認中..."
    
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://localhost:11434"
        #else
        // 実機では設定されたサーバーURLまたはデフォルト値を使用
        return serverURL.isEmpty ? "http://192.168.1.100:11434" : serverURL
        #endif
    }
    
    
    init() {
        Task {
            await checkAppleIntelligenceAvailability()
        }
    }
    
    @MainActor
    private func checkAppleIntelligenceAvailability() async {
        // iOS 26+ でApple Intelligence Foundation Modelsの利用可能性をチェック
        if #available(iOS 26.0, *) {
            // Apple Intelligence Foundation Model APIの利用可能性をチェック
            switch SystemLanguageModel.default.availability {
            case .available:
                appleIntelligenceStatus = "利用可能"
                isAppleIntelligenceAvailable = true
            case .unavailable(let reason):
                let message = switch reason {
                case .appleIntelligenceNotEnabled:
                    "Apple Intelligenceが無効"
                case .deviceNotEligible:
                    "デバイス非対応"
                case .modelNotReady:
                    "モデル準備中"
                @unknown default:
                    "利用不可"
                }
                appleIntelligenceStatus = message
                isAppleIntelligenceAvailable = false
            }
        } else {
            appleIntelligenceStatus = "iOS 26+が必要"
            isAppleIntelligenceAvailable = false
        }
    }
    
    
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatResponse: Codable {
        let message: ChatMessage
        let done: Bool
    }
    
    func testConnection() async -> Bool {
        // オフライン専用モード：常にローカル接続成功を返す
        await MainActor.run {
            self.isConnected = true
        }
        return true
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [Message]) async throws -> String {
        // Apple Intelligence Foundation Modelが利用可能な場合はそちらを使用
        if #available(iOS 26.0, *), isUsingLocalLLM && isAppleIntelligenceAvailable {
            return try await sendToAppleIntelligence(userMessage: userMessage, conversationHistory: conversationHistory)
        }
        
        // Apple Intelligence利用不可の場合はエラーとして処理
        throw LLMError.requestFailed
    }
    
    @available(iOS 26.0, *)
    private func sendToAppleIntelligence(userMessage: String, conversationHistory: [Message]) async throws -> String {
        // Apple Intelligence Foundation Model（完全オンデバイス処理）
        
        // 言語検出
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = userMessage
        let (languageTag, _) = tagger.tag(at: userMessage.startIndex, unit: .paragraph, scheme: .language)
        let detectedLanguage = languageTag?.rawValue ?? "en"
        
        // 言語に応じた指示文
        let instructions = if detectedLanguage == "ja" {
            "あなたは親切で知識豊富なAIアシスタントです。質問に対して正確で役立つ回答を日本語で提供してください。"
        } else {
            "You are a helpful and knowledgeable AI assistant. Provide accurate and helpful responses in English."
        }
        
        // Apple Intelligence Foundation Model APIを使用
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: instructions
        )
        
        // 会話履歴をセッションに追加（最新10件のみ）
        for message in conversationHistory.suffix(10) {
            if message.isUser {
                _ = try await session.respond(to: message.content)
            }
        }
        
        // ユーザーメッセージを直接Apple Intelligence Foundation Modelに送信
        let response = try await session.respond(to: userMessage)
        return response.content
    }
    
    
}


enum LLMError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingError
    case networkError(String)
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .requestFailed:
            return "AI機能が利用できません。Apple Intelligence Foundation Modelが利用可能なデバイスで再度お試しください。"
        case .decodingError:
            return "レスポンスの解析に失敗しました"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .modelNotFound:
            return "指定されたモデルが見つかりません。Ollamaサーバーでllama3.2:1bモデルがインストールされているか確認してください。"
        }
    }
}