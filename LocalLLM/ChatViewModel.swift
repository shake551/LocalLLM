import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @ObservedObject var llmService = LLMService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // LLMServiceの状態変化を監視
        llmService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
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