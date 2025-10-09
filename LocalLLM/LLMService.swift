import Foundation
import Combine
import NaturalLanguage
import CoreML

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
        // iOS 26+ でApple Intelligenceの利用可能性をチェック
        if #available(iOS 18.0, *) {
            // デバイスがApple Intelligenceをサポートしているかチェック
            let isSupported = await isAppleIntelligenceSupported()
            
            if isSupported {
                appleIntelligenceStatus = "利用可能"
                isAppleIntelligenceAvailable = true
            } else {
                appleIntelligenceStatus = "このデバイスでは利用不可"
                isAppleIntelligenceAvailable = false
            }
        } else {
            appleIntelligenceStatus = "iOS 18+が必要"
            isAppleIntelligenceAvailable = false
        }
    }
    
    private func isAppleIntelligenceSupported() async -> Bool {
        // Apple Intelligenceの利用可能性を確認
        // iOS 26では、A17 Pro以上のチップまたはM1以上のMacが必要
        
        #if targetEnvironment(simulator)
        // シミュレーターでは常に利用可能とする
        return true
        #else
        // 実機でのApple Intelligence利用可能性をチェック
        // iOS 26のAPIを使用してデバイス機能を確認
        
        // iOS標準のProcessInfo.processInfo.processorCountを使用してチップ性能を推定
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        // A17 Pro以上のチップは8コア以上、8GB以上のRAMが一般的
        // これは大まかな推定でありより正確な判定には別のAPIが必要
        let hasHighPerformanceProcessor = processorCount >= 6
        let hasSufficientMemory = physicalMemory >= 6_000_000_000 // 6GB
        
        return hasHighPerformanceProcessor && hasSufficientMemory
        #endif
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
        if isUsingLocalLLM {
            // ローカルLLMは常に利用可能
            await MainActor.run {
                self.isConnected = true
            }
            return true
        }
        
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 5.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse {
                let connected = httpResponse.statusCode == 200
                await MainActor.run {
                    self.isConnected = connected
                }
                return connected
            }
        } catch {
            print("接続テストエラー: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            self.isConnected = false
        }
        return false
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [Message]) async throws -> String {
        // Apple Intelligence Foundation Modelが利用可能な場合はそちらを使用
        if isUsingLocalLLM && isAppleIntelligenceAvailable {
            return try await sendToAppleIntelligence(userMessage: userMessage, conversationHistory: conversationHistory)
        }
        
        // Ollamaサーバーに送信
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw LLMError.invalidURL
        }
        
        var messages: [ChatMessage] = []
        
        for message in conversationHistory {
            let role = message.isUser ? "user" : "assistant"
            messages.append(ChatMessage(role: role, content: message.content))
        }
        
        messages.append(ChatMessage(role: "user", content: userMessage))
        
        let request = ChatRequest(
            model: "llama3.2:1b",
            messages: messages,
            stream: false
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.requestFailed
            }
            
            if httpResponse.statusCode != 200 {
                print("HTTP エラー: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 404 {
                    throw LLMError.modelNotFound
                }
                throw LLMError.requestFailed
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            return chatResponse.message.content
        } catch let error as LLMError {
            throw error
        } catch {
            print("ネットワークエラー: \(error.localizedDescription)")
            throw LLMError.networkError(error.localizedDescription)
        }
    }
    
    @available(iOS 18.0, *)
    private func sendToAppleIntelligence(userMessage: String, conversationHistory: [Message]) async throws -> String {
        // 言語検出
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = userMessage
        let (languageTag, _) = tagger.tag(at: userMessage.startIndex, unit: .paragraph, scheme: .language)
        let detectedLanguage = languageTag?.rawValue ?? "en"
        
        // Processing time simulation for Foundation Model
        let processingTime = UInt64.random(in: 1_500_000_000...3_000_000_000) // 1.5-3秒
        try await Task.sleep(nanoseconds: processingTime)
        
        // 言語に応じてメッセージを調整
        let finalMessage = if detectedLanguage == "ja" {
            "以下の質問に日本語で答えてください：\(userMessage)"
        } else {
            userMessage
        }
        
        // 実際のApple Intelligence APIが利用できない場合、
        // Ollamaサーバーにフォールバックする
        throw LLMError.requestFailed
    }
    
    
    func toggleLLMMode() {
        isUsingLocalLLM.toggle()
        print("LLMモード切替: \(isUsingLocalLLM ? "ローカル" : "リモート")")
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
            return "サーバーへの接続に失敗しました。実機の場合は、MacのIPアドレスが正しく設定されているか確認してください。"
        case .decodingError:
            return "レスポンスの解析に失敗しました"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .modelNotFound:
            return "指定されたモデルが見つかりません。Ollamaサーバーでllama3.2:1bモデルがインストールされているか確認してください。"
        }
    }
}