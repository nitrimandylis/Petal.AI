import SwiftUI

struct MessageBubble: View {
    let message: Message
    @State private var loadingDots = ""
    @State private var dotCount = 0

    let loadingTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var processedMessage: String {
        message.text
    }
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            if message.loading {
                Text("Thinking" + loadingDots)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .onReceive(loadingTimer) { _ in
                        dotCount = (dotCount + 1) % 4
                        loadingDots = String(repeating: ".", count: dotCount)
                    }
            } else {
                Text(processedMessage)
                    .padding(12)
                    .background(message.isUser ? Theme.accentColor : Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }

            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(message: Message(id: UUID(), text: "**Hello!** _How are you?_", isUser: true))
            MessageBubble(message: Message(id: UUID(), text: "• I'm doing great!\n• Thanks for asking!", isUser: false))
        }
        .padding()
        .background(Theme.primaryPink)
    }
}
