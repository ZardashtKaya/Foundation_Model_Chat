import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/zardashtkaya/Downloads/Foundation Chat/Foundation Chat/ContentView.swift", line: 1)
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
            statusMessage = __designTimeString("#9711_0", fallback: "Model ready.")
        case .unavailable(.deviceNotEligible):
            statusMessage = __designTimeString("#9711_1", fallback: "Device not eligible for Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            statusMessage = __designTimeString("#9711_2", fallback: "Please enable Apple Intelligence in Settings.")
        case .unavailable(.modelNotReady):
            statusMessage = __designTimeString("#9711_3", fallback: "Model not ready (downloading or unavailable).")
        default:
            statusMessage = __designTimeString("#9711_4", fallback: "Unknown error: model unavailable.")
        }
    }

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty,
              let session = session else { return }

        let userMessage = ChatMessage(content: inputText, isUser: __designTimeBoolean("#9711_5", fallback: true))
        messages.append(userMessage)

        let prompt = inputText
        inputText = __designTimeString("#9711_6", fallback: "")

        do {
            let response = try await session.respond(to: prompt)
            let reply = ChatMessage(content: response.content, isUser: __designTimeBoolean("#9711_7", fallback: false))
            messages.append(reply)
        } catch {
            messages.append(ChatMessage(content: "Error: \(error.localizedDescription)", isUser: __designTimeBoolean("#9711_8", fallback: false)))
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
                    LazyVStack(alignment: .leading, spacing: __designTimeInteger("#9711_9", fallback: 12)) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue.opacity(__designTimeFloat("#9711_10", fallback: 0.2)))
                                        .cornerRadius(__designTimeInteger("#9711_11", fallback: 12))
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(__designTimeFloat("#9711_12", fallback: 0.2)))
                                        .cornerRadius(__designTimeInteger("#9711_13", fallback: 12))
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
                
                
                TextField(__designTimeString("#9711_14", fallback: "Type a message..."), text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: __designTimeInteger("#9711_15", fallback: 30))

                Button(__designTimeString("#9711_16", fallback: "Send")) {
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
