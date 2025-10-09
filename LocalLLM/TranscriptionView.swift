import SwiftUI
import Speech

struct TranscriptionView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        VStack {
            // ヘッダー情報
            if viewModel.speechRecognitionService.authorizationStatus != .authorized {
                PermissionView(viewModel: viewModel)
            } else {
                // 録音コントロール
                RecordingControlsView(viewModel: viewModel)
                
                // エラー表示
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
                
                // 文字起こし結果リスト
                TranscriptionListView(viewModel: viewModel)
            }
        }
        .navigationTitle("音声文字起こし")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("クリア") {
                    viewModel.clearTranscriptions()
                }
                .disabled(viewModel.transcriptions.isEmpty)
            }
        }
    }
}

struct PermissionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("音声認識権限が必要です")
                .font(.headline)
            
            if viewModel.speechRecognitionService.authorizationStatus == .notDetermined {
                Text("音声認識機能を使用するには権限の許可が必要です")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("権限を許可") {
                    viewModel.speechRecognitionService.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("設定アプリで音声認識とマイクの使用を許可してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("設定を開く") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct RecordingControlsView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 録音ボタン
            Button(action: {
                if viewModel.speechRecognitionService.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.speechRecognitionService.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: viewModel.speechRecognitionService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .disabled(!viewModel.speechRecognitionService.canRecord)
            .scaleEffect(viewModel.speechRecognitionService.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.speechRecognitionService.isRecording)
            
            // ステータステキスト
            VStack(spacing: 4) {
                Text(viewModel.speechRecognitionService.isRecording ? "録音中..." : "タップして録音開始")
                    .font(.subheadline)
                    .foregroundColor(viewModel.speechRecognitionService.isRecording ? .red : .secondary)
                
                if viewModel.speechRecognitionService.isRecording {
                    Text("デバイスに向かって話してください")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // リアルタイム認識テキスト
            if viewModel.speechRecognitionService.isRecording {
                RealtimeTranscriptionView(
                    speechService: viewModel.speechRecognitionService,
                    onSave: { text in
                        viewModel.saveTranscription(text)
                    }
                )
                .padding(.horizontal)
                .onAppear {
                    print("RealtimeTranscriptionView 表示開始")
                }
                .onDisappear {
                    print("RealtimeTranscriptionView 表示終了")
                }
            }
        }
        .padding()
    }
}

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
            Button("閉じる", action: onDismiss)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct TranscriptionListView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        if viewModel.transcriptions.isEmpty {
            EmptyStateView(viewModel: viewModel)
        } else {
            List {
                ForEach(viewModel.transcriptions) { transcription in
                    TranscriptionItemView(
                        transcription: transcription,
                        onCopy: { text in
                            viewModel.copyToClipboard(text)
                        },
                        onDelete: {
                            viewModel.deleteTranscription(transcription)
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteTranscription(viewModel.transcriptions[index])
                    }
                }
            }
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("文字起こし結果はここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("マイクボタンをタップして録音を開始してください")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            #if targetEnvironment(simulator)
            VStack(spacing: 8) {
                Text("シミュレーターでテストする場合:")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Button("デモテキストを追加") {
                    viewModel.addDemoTranscription()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding(.top)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TranscriptionItemView: View {
    let transcription: TranscriptionItem
    let onCopy: (String) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transcription.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(transcription.displayText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button("コピー") {
                    onCopy(transcription.displayText)
                }
                .font(.caption)
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("削除") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RealtimeTranscriptionView: View {
    @ObservedObject var speechService: SpeechRecognitionService
    var onSave: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("リアルタイム認識")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if speechService.isRecording && !speechService.recognizedText.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechService.isRecording)
                        
                        Text("認識中")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 4) {
                        if speechService.recognizedText.isEmpty {
                            Text("話してください...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(speechService.recognizedText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .id("realtimeText")
                                .onAppear {
                                    print("RealtimeTranscriptionView: テキスト表示 - '\(speechService.recognizedText)'")
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .onChange(of: speechService.recognizedText) {
                        print("RealtimeTranscriptionView: テキスト更新 - \(speechService.recognizedText)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("realtimeText", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minHeight: 60, maxHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(speechService.isRecording ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                            .animation(.easeInOut(duration: 0.3), value: speechService.isRecording)
                    )
            )
            
            if !speechService.recognizedText.isEmpty {
                HStack {
                    Text("\(speechService.recognizedText.count) 文字")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("コピー") {
                        UIPasteboard.general.string = speechService.recognizedText
                    }
                    .font(.caption2)
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                    
                    if let onSave = onSave, !speechService.isRecording {
                        Button("保存") {
                            onSave(speechService.recognizedText)
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: speechService.recognizedText.isEmpty)
    }
}

#Preview {
    NavigationView {
        TranscriptionView()
    }
}