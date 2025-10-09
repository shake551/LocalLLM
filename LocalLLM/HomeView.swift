import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Local LLM")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("ローカルAIアシスタント")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    NavigationLink(destination: ChatView()) {
                        FeatureCard(
                            icon: "message.fill",
                            title: "チャット",
                            description: "Apple Intelligence搭載チャット",
                            color: .blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TranscriptionView()) {
                        FeatureCard(
                            icon: "mic.fill",
                            title: "音声文字起こし",
                            description: "音声をテキストに変換",
                            color: .green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Apple Intelligence & Ollama対応")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("Local LLM")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
}