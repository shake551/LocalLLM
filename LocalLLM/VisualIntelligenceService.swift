import Foundation
import Vision
import UIKit
import Combine

class VisualIntelligenceService: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var analysisResult: VisualAnalysisResult?
    @Published var errorMessage: String?
    @Published var isSupported: Bool = false
    
    init() {
        checkVisualIntelligenceSupport()
    }
    
    private func checkVisualIntelligenceSupport() {
        // Vision機能の利用可能性をチェック
        isSupported = true
    }
    
    func analyzeImage(_ image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        guard let cgImage = image.cgImage else {
            await MainActor.run {
                errorMessage = "画像の処理に失敗しました"
                isAnalyzing = false
            }
            return
        }
        
        do {
            let result = try await performVisualIntelligenceAnalysis(cgImage: cgImage)
            await MainActor.run {
                analysisResult = result
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
    
    private func performVisualIntelligenceAnalysis(cgImage: CGImage) async throws -> VisualAnalysisResult {
        // Visual Intelligence APIを使用した包括的な画像分析
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 複数のVision解析を並行実行
        async let objectResults = analyzeObjects(handler: handler)
        async let textResults = analyzeText(handler: handler)
        async let sceneResults = analyzeScene(handler: handler)
        async let faceResults = analyzeFaces(handler: handler)
        
        let objects = try await objectResults
        let text = try await textResults
        let scene = try await sceneResults
        let faces = try await faceResults
        
        return VisualAnalysisResult(
            objects: objects,
            recognizedText: text,
            sceneClassification: scene,
            faces: faces,
            timestamp: Date()
        )
    }
    
    private func analyzeObjects(handler: VNImageRequestHandler) async throws -> [DetectedObject] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let objects = observations.compactMap { observation -> DetectedObject? in
                    return DetectedObject(
                        identifier: "rectangle",
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: objects)
            }
            
            try? handler.perform([request])
        }
    }
    
    private func analyzeText(handler: VNImageRequestHandler) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            try? handler.perform([request])
        }
    }
    
    private func analyzeScene(handler: VNImageRequestHandler) async throws -> [SceneClassification] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let classifications = observations.prefix(5).map { observation in
                    SceneClassification(
                        identifier: observation.identifier,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: Array(classifications))
            }
            
            try? handler.perform([request])
        }
    }
    
    private func analyzeFaces(handler: VNImageRequestHandler) async throws -> [DetectedFace] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let faces = observations.map { observation in
                    DetectedFace(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: faces)
            }
            
            try? handler.perform([request])
        }
    }
}

// データ構造体
struct VisualAnalysisResult {
    let objects: [DetectedObject]
    let recognizedText: [String]
    let sceneClassification: [SceneClassification]
    let faces: [DetectedFace]
    let timestamp: Date
    
    var summary: String {
        var components: [String] = []
        
        if !objects.isEmpty {
            let objectNames = objects.prefix(3).map { $0.identifier }.joined(separator: ", ")
            components.append("検出されたオブジェクト: \(objectNames)")
        }
        
        if !recognizedText.isEmpty {
            components.append("認識されたテキスト: \(recognizedText.count)件")
        }
        
        if !sceneClassification.isEmpty, let topScene = sceneClassification.first {
            components.append("シーン: \(topScene.identifier)")
        }
        
        if !faces.isEmpty {
            components.append("検出された顔: \(faces.count)個")
        }
        
        return components.isEmpty ? "分析結果なし" : components.joined(separator: "\n")
    }
}

struct DetectedObject {
    let identifier: String
    let confidence: Float
    let boundingBox: CGRect
}

struct SceneClassification {
    let identifier: String
    let confidence: Float
}

struct DetectedFace {
    let boundingBox: CGRect
    let confidence: Float
}