import Foundation
import Combine

class LLMService: ObservableObject {
    @Published var serverURL: String = ""
    @Published var isConnected: Bool = false
    
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://localhost:11434"
        #else
        // 実機では設定されたサーバーURLまたはデフォルト値を使用
        return serverURL.isEmpty ? "http://192.168.1.100:11434" : serverURL
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