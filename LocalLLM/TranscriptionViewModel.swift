import Foundation
import SwiftUI
import Combine

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcriptions: [TranscriptionItem] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let speechService = SpeechRecognitionService()
    private let llmService = LLMService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 録音状態の変化を監視
        speechService.$isRecording
            .sink { [weak self] isRecording in
                // 録音が停止した時に最終結果を処理
                if !isRecording {
                    if let recognizedText = self?.speechService.recognizedText,
                       !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("録音停止時に最終結果を処理: \(recognizedText)")
                        // 少し遅延を入れて最終結果を確実に取得
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.processTranscription(recognizedText)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    var speechRecognitionService: SpeechRecognitionService {
        return speechService
    }
    
    func startRecording() {
        errorMessage = nil
        do {
            try speechService.startRecording()
        } catch {
            let errorDescription = error.localizedDescription
            
            #if targetEnvironment(simulator)
            // シミュレーターでは特定のエラーは無視してデモモードの案内を表示
            if errorDescription.contains("Failed to access assets") || 
               errorDescription.contains("recognitionUnavailable") ||
               errorDescription.contains("No speech detected") {
                errorMessage = "シミュレーターでは実際の音声認識が制限されています。デモモードで動作します。"
            } else {
                errorMessage = errorDescription
            }
            #else
            // 実機でも「No speech detected」は録音継続のメッセージに変更
            if errorDescription.contains("No speech detected") {
                errorMessage = "音声が検出されませんでした。もう一度お試しください。"
            } else {
                errorMessage = errorDescription
            }
            #endif
        }
    }
    
    func stopRecording() {
        speechService.stopRecording()
    }
    
    private func processTranscription(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // 同じテキストが既に保存されていないかチェック
        if transcriptions.contains(where: { $0.originalText.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedText }) {
            print("processTranscription: 同じテキストが既に保存されているため、スキップします: \(trimmedText)")
            return
        }
        
        let transcription = TranscriptionItem(
            originalText: trimmedText,
            timestamp: Date()
        )
        
        transcriptions.append(transcription)
        print("processTranscription: 新しい音声認識結果を自動保存: \(trimmedText)")
        
        // LLMで要約や改善を行う（オプション）
        Task {
            await enhanceTranscription(transcription)
        }
    }
    
    private func enhanceTranscription(_ transcription: TranscriptionItem) async {
        isProcessing = true
        
        do {
            let prompt = """
            以下の音声認識結果を、読みやすく整理してください。
            句読点を適切に追加し、文章として自然になるように修正してください。
            
            音声認識結果:
            \(transcription.originalText)
            """
            
            let enhancedText = try await llmService.sendMessage(prompt, conversationHistory: [])
            
            if let index = transcriptions.firstIndex(where: { $0.id == transcription.id }) {
                transcriptions[index].enhancedText = enhancedText
            }
        } catch {
            errorMessage = "テキスト改善中にエラーが発生しました: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func clearTranscriptions() {
        transcriptions.removeAll()
        errorMessage = nil
    }
    
    func deleteTranscription(_ transcription: TranscriptionItem) {
        transcriptions.removeAll { $0.id == transcription.id }
    }
    
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    func saveTranscription(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 同じテキストが既に保存されていないかチェック
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if transcriptions.contains(where: { $0.originalText.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedText }) {
            print("同じテキストが既に保存されているため、スキップします: \(trimmedText)")
            speechService.recognizedText = ""
            return
        }
        
        let transcription = TranscriptionItem(
            originalText: trimmedText,
            timestamp: Date()
        )
        
        transcriptions.append(transcription)
        print("新しい音声認識結果を保存: \(trimmedText)")
        
        // LLMで文章改善を実行
        Task {
            await enhanceTranscription(transcription)
        }
        
        // 保存後はリアルタイムテキストをクリア
        speechService.recognizedText = ""
    }
    
    func addDemoTranscription() {
        let demoTexts = [
            "こんにちは今日はとてもいい天気ですね",
            "ローカルLLMを使った音声認識の機能をテストしています",
            "人工知能の技術が日々進歩していてとても興味深いです",
            "この文字起こし機能はオフラインでも動作するのでプライバシーが保護されます"
        ]
        
        let randomText = demoTexts.randomElement() ?? demoTexts[0]
        let transcription = TranscriptionItem(
            originalText: randomText,
            timestamp: Date()
        )
        
        transcriptions.append(transcription)
        
        // デモではすぐにLLM改善を実行
        Task {
            await enhanceTranscription(transcription)
        }
    }
}

struct TranscriptionItem: Identifiable, Codable {
    let id: UUID
    let originalText: String
    var enhancedText: String?
    let timestamp: Date
    
    init(originalText: String, timestamp: Date) {
        self.id = UUID()
        self.originalText = originalText
        self.enhancedText = nil
        self.timestamp = timestamp
    }
    
    var displayText: String {
        return enhancedText ?? originalText
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}