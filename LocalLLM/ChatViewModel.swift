import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let llmService = LLMService()
    
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        currentInput = ""
        
        let newUserMessage = Message(content: userMessage, isUser: true)
        messages.append(newUserMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await llmService.sendMessage(userMessage, conversationHistory: messages)
            let assistantMessage = Message(content: response, isUser: false)
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
            print("エラー: \(error)")
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
}