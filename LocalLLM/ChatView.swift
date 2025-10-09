import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("考え中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("閉じる") {
                        viewModel.errorMessage = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            HStack {
                TextField("メッセージを入力...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .disabled(viewModel.isLoading)
                    .keyboardType(.default)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading ? .gray : .blue)
                }
                .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Local LLM Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    if viewModel.llmService.isAppleIntelligenceAvailable {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("Apple AI")
                            .font(.caption)
                            .foregroundColor(.purple)
                    } else {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.green)
                        Text("オフライン")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.llmService.isUsingLocalLLM)
                .animation(.easeInOut(duration: 0.3), value: viewModel.llmService.isAppleIntelligenceAvailable)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // オフライン専用モード表示
                    Label("オフライン専用モード", systemImage: "wifi.slash")
                        .foregroundColor(.green)
                    
                    // Apple Intelligence状態表示
                    Label("Apple Intelligence: \(viewModel.llmService.appleIntelligenceStatus)", 
                          systemImage: viewModel.llmService.isAppleIntelligenceAvailable ? "brain.head.profile" : "exclamationmark.triangle")
                        .foregroundColor(viewModel.llmService.isAppleIntelligenceAvailable ? .purple : .orange)
                    
                    Divider()
                    
                    Button("チャットをクリア") {
                        viewModel.clearChat()
                    }
                    .disabled(viewModel.messages.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
