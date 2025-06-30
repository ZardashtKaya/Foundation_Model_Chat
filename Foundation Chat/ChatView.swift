//
//  ContentView.swift
//  Foundation Chat
//
//  Created by Zardasht Kaya on 6/30/25.
//
import SwiftUI
import Foundation
import FoundationModels
internal import Combine

@MainActor
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var statusMessage: String = "Initializing model..."

    
    private var session: LanguageModelSession?

    init() {
        Task {
            await initializeModel()
        }
    }

    func initializeModel() async {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            session = LanguageModelSession()
            await session?.prewarm()
            statusMessage = "Model ready."
        case .unavailable(.deviceNotEligible):
            statusMessage = "Device not eligible for Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            statusMessage = "Please enable Apple Intelligence in Settings."
        case .unavailable(.modelNotReady):
            statusMessage = "Model not ready (downloading or unavailable)."
        default:
            statusMessage = "Unknown error: model unavailable."
        }
    }

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty,
              let session = session else { return }

        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)

        let prompt = inputText
        inputText = ""

        do {
            let response = try await session.respond(to: prompt)
            let reply = ChatMessage(content: response.content, isUser: false)
            messages.append(reply)
        } catch {
            messages.append(ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false))
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack {
            Text(viewModel.statusMessage)
                .foregroundColor(.gray)
                .font(.footnote)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id)
                    }
                }
            }

            HStack {
                
                
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)

                Button("Send") {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ChatView()
}
