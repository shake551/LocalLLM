import SwiftUI
import PhotosUI

struct VisualIntelligenceView: View {
    @StateObject private var visualService = VisualIntelligenceService()
    @StateObject private var llmService = LLMService()
    @State private var selectedImage: PhotosPickerItem?
    @State private var displayImage: UIImage?
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var aiAnalysis: String = ""
    @State private var isAnalyzingWithLLM = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 画像表示エリア
                    imageDisplaySection
                    
                    // ボタンエリア
                    buttonSection
                    
                    // 分析結果エリア
                    if visualService.isAnalyzing || isAnalyzingWithLLM {
                        analysisLoadingSection
                    } else if let result = visualService.analysisResult {
                        analysisResultSection(result: result)
                    }
                    
                    // AI分析結果
                    if !aiAnalysis.isEmpty {
                        aiAnalysisSection
                    }
                    
                    // エラー表示
                    if let errorMessage = visualService.errorMessage {
                        errorSection(errorMessage: errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("Visual Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if visualService.isSupported {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.purple)
                            Text("Vision対応")
                                .font(.caption)
                                .foregroundColor(.purple)
                        } else {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("非対応")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                displayImage = image
                analyzeImage(image)
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    displayImage = image
                    analyzeImage(image)
                }
            }
        }
    }
    
    private var imageDisplaySection: some View {
        Group {
            if let displayImage = displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("画像を選択してください")
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
    
    private var buttonSection: some View {
        HStack(spacing: 15) {
            Button(action: { showingCamera = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("カメラ")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: { showingImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("写真選択")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private var analysisLoadingSection: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(1.2)
            Text(visualService.isAnalyzing ? "画像を分析中..." : "AI分析中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func analysisResultSection(result: VisualAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.purple)
                Text("Visual Intelligence 分析結果")
                    .font(.headline)
                Spacer()
                Button("AI詳細分析") {
                    analyzeWithLLM(result: result)
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Text(result.summary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // 詳細結果
            if !result.objects.isEmpty {
                detailSection(title: "検出されたオブジェクト", items: result.objects.map { "\($0.identifier) (\(Int($0.confidence * 100))%)" })
            }
            
            if !result.recognizedText.isEmpty {
                detailSection(title: "認識されたテキスト", items: result.recognizedText)
            }
            
            if !result.sceneClassification.isEmpty {
                detailSection(title: "シーン分類", items: result.sceneClassification.map { "\($0.identifier) (\(Int($0.confidence * 100))%)" })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func detailSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(items.prefix(3), id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI詳細分析")
                    .font(.headline)
                Spacer()
            }
            
            Text(aiAnalysis)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func errorSection(errorMessage: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func analyzeImage(_ image: UIImage) {
        Task {
            await visualService.analyzeImage(image)
        }
    }
    
    private func analyzeWithLLM(result: VisualAnalysisResult) {
        Task {
            isAnalyzingWithLLM = true
            
            let prompt = """
            以下の画像分析結果について、詳しく説明してください：
            
            検出されたオブジェクト: \(result.objects.map { $0.identifier }.joined(separator: ", "))
            認識されたテキスト: \(result.recognizedText.joined(separator: ", "))
            シーン分類: \(result.sceneClassification.first?.identifier ?? "不明")
            顔の検出: \(result.faces.count)個
            
            この画像について、どのような場面や状況が考えられるか、詳しく分析してください。
            """
            
            do {
                let response = try await llmService.sendMessage(prompt, conversationHistory: [])
                await MainActor.run {
                    aiAnalysis = response
                    isAnalyzingWithLLM = false
                }
            } catch {
                await MainActor.run {
                    aiAnalysis = "AI分析に失敗しました: \(error.localizedDescription)"
                    isAnalyzingWithLLM = false
                }
            }
        }
    }
}

#Preview {
    VisualIntelligenceView()
}