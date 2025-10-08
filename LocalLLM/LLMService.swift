import Foundation
import Combine

class LLMService: ObservableObject {
    private let baseURL = "http://localhost:11434"
    
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
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.message.content
    }
}

enum LLMError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .requestFailed:
            return "リクエストが失敗しました"
        case .decodingError:
            return "レスポンスの解析に失敗しました"
        }
    }
}