import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognitionService: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var partialText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }
    
    func startRecording() throws {
        print("録音開始を試行中...")
        
        // 権限チェック
        guard canRecord else {
            print("権限が不足しています。authorizationStatus: \(authorizationStatus)")
            throw RecognitionError.permissionDenied
        }
        
        // 既存のタスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 音声認識の利用可能性を再チェック
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("音声認識が利用できません。speechRecognizer: \(String(describing: speechRecognizer)), isAvailable: \(speechRecognizer?.isAvailable ?? false)")
            #if targetEnvironment(simulator)
            // シミュレーターではデモ機能を提供
            startDemoRecording()
            return
            #else
            throw RecognitionError.recognitionUnavailable
            #endif
        }
        
        print("音声認識サービスが利用可能です。録音を開始します...")
        
        do {
            // オーディオセッションの設定
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // 認識リクエストを作成
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                throw RecognitionError.recognitionRequestFailed
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // requiresOnDeviceRecognition を設定（プライバシー重視）
            if #available(iOS 13.0, *) {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
            
            // オーディオエンジンが利用可能かチェック
            let inputNode = audioEngine.inputNode
            
            // 認識タスクを開始
            print("音声認識タスクを開始します...")
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    var isFinal = false
                    
                    if let result = result {
                        let transcribedText = result.bestTranscription.formattedString
                        print("音声認識結果: \(transcribedText), isFinal: \(result.isFinal)")
                        
                        if result.isFinal {
                            // 最終結果：空でない場合のみ更新
                            if !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self?.recognizedText = transcribedText
                                print("最終結果を保存: \(transcribedText)")
                            } else {
                                // 最終結果が空の場合、直前の部分結果を使用
                                if let partialText = self?.partialText, !partialText.isEmpty {
                                    self?.recognizedText = partialText
                                    print("部分結果を最終結果として使用: \(partialText)")
                                }
                            }
                            self?.partialText = ""
                            isFinal = true
                        } else {
                            // 部分的結果：リアルタイム表示用
                            self?.partialText = transcribedText
                            self?.recognizedText = transcribedText
                            print("リアルタイム更新: \(transcribedText)")
                        }
                    }
                    
                    if let error = error {
                        // エラーの詳細を確認してシミュレーター特有のエラーや一般的なエラーを処理
                        let errorMessage = error.localizedDescription
                        print("音声認識エラー詳細: \(errorMessage)")
                        
                        // 無視するエラー（ログに出力しない）
                        let ignorableErrors = [
                            "Failed to access assets",
                            "IOSurfaceClient",
                            "No speech detected"
                        ]
                        
                        let shouldIgnore = ignorableErrors.contains { ignorableError in
                            errorMessage.contains(ignorableError)
                        }
                        
                        if !shouldIgnore {
                            print("重要な音声認識エラー: \(errorMessage)")
                        }
                        
                        // シミュレーターの場合または特定のエラーの場合はデモモードに切り替え
                        #if targetEnvironment(simulator)
                        if errorMessage.contains("Failed to access assets") || 
                           errorMessage.contains("No speech detected") {
                            print("シミュレーターエラーのためデモモードに切り替えます")
                            self?.stopRecording()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self?.startDemoRecording()
                            }
                            return
                        }
                        #endif
                        
                        // "No speech detected"エラーの場合は録音を継続
                        if errorMessage.contains("No speech detected") {
                            // このエラーは録音を停止せず、継続する
                            print("音声が検出されませんが、録音を継続します")
                            return
                        }
                        
                        print("録音を停止します")
                        self?.stopRecording()
                    } else if isFinal {
                        // 最終結果が確定したら録音を継続するか停止するかは呼び出し側で制御
                        // ここでは自動停止しない（連続認識のため）
                        print("最終結果が確定しました")
                    }
                }
            }
            
            // オーディオフォーマットを設定
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            recognizedText = ""
            partialText = ""
            
            print("録音開始完了。isRecording: \(isRecording)")
            
        } catch {
            stopRecording()
            throw error
        }
    }
    
    func stopRecording() {
        print("録音停止処理を開始...")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        partialText = ""
        
        print("録音停止完了。最終結果: \(recognizedText)")
    }
    
    var canRecord: Bool {
        #if targetEnvironment(simulator)
        // シミュレーターでは常に録音可能とする
        return authorizationStatus == .authorized
        #else
        return authorizationStatus == .authorized && speechRecognizer?.isAvailable == true
        #endif
    }
    
    // シミュレーター用のデモ録音機能
    private func startDemoRecording() {
        isRecording = true
        recognizedText = ""
        partialText = ""
        
        // デモテキストの配列
        let demoTexts = [
            "こんにちは、今日はとても良い天気ですね。",
            "ローカルLLMを使った音声認識のテストを行っています。",
            "この機能はオフラインでも動作するので、プライバシーが保護されます。",
            "人工知能の技術は日々進歩していて、とても興味深いです。",
            "音声認識の精度も向上しており、実用的になってきました。"
        ]
        
        let selectedText = demoTexts.randomElement() ?? demoTexts[0]
        
        // 文字を一文字ずつ表示するアニメーション
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                if currentIndex < selectedText.count {
                    let endIndex = selectedText.index(selectedText.startIndex, offsetBy: currentIndex + 1)
                    let currentText = String(selectedText[..<endIndex])
                    
                    self.recognizedText = currentText
                    self.partialText = currentText
                    
                    currentIndex += 1
                } else {
                    timer.invalidate()
                    // 最終結果を設定
                    self.recognizedText = selectedText
                    self.partialText = ""
                }
            }
        }
    }
}

enum RecognitionError: Error, LocalizedError {
    case recognitionRequestFailed
    case audioEngineFailed
    case recognitionFailed
    case permissionDenied
    case recognitionUnavailable
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "音声認識リクエストの作成に失敗しました"
        case .audioEngineFailed:
            return "オーディオエンジンの開始に失敗しました"
        case .recognitionFailed:
            return "音声認識に失敗しました"
        case .permissionDenied:
            return "音声認識の権限が許可されていません。設定で権限を有効にしてください。"
        case .recognitionUnavailable:
            return "音声認識機能が利用できません。ネットワーク接続を確認するか、実機で試してください。"
        }
    }
}
