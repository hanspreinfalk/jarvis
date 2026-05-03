import SwiftUI

private let bubbleSurface = Color.primary.opacity(0.1)

struct ChatPanelView: View {
    @Binding var inputText: String
    @Binding var messages: [Message]
    let onClose: () -> Void
    let onSend: () -> Void
    let onShowAPIKeys: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPanelHovered = false

    private var inputBarBackground: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.87)
    }
    private var inputBarBorder: Color {
        colorScheme == .dark ? Color(white: 0.30) : Color(white: 0.75)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            messageList
            embeddedInputBar
        }
        .frame(width: 430, height: 544)
        .onHover { isPanelHovered = $0 }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
                .allowsHitTesting(false)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
        .padding(16)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 14) {
                Button(action: {}) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(isPanelHovered ? 1 : 0)
        .animation(.easeInOut(duration: 0.18), value: isPanelHovered)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(messages) { message in
                        if message.isUser {
                            UserBubble(text: message.content)
                        } else {
                            AIBubble(text: message.content, isStreaming: message.isStreaming)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                Color.clear.frame(height: 1).id("scrollBottom")
            }
            .onChange(of: messages.count) {
                withAnimation { proxy.scrollTo("scrollBottom", anchor: .bottom) }
            }
            .onChange(of: messages.last?.content) {
                proxy.scrollTo("scrollBottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Embedded input bar

    private var embeddedInputBar: some View {
        InputBarView(inputText: $inputText, onSend: onSend, onShowAPIKeys: onShowAPIKeys)
            .padding(.trailing, 10)
            .padding(.leading, 15)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(inputBarBackground, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(inputBarBorder, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .padding(10)
    }
}

// MARK: - Message bubble views

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(bubbleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct AIBubble: View {
    let text: String
    let isStreaming: Bool

    private let actionIcons = ["doc.on.doc", "speaker.wave.2", "hand.thumbsup", "hand.thumbsdown", "arrow.clockwise"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if text.isEmpty && isStreaming {
                Text("Thinking…")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }

            if !isStreaming {
                HStack(spacing: 14) {
                    ForEach(actionIcons, id: \.self) { icon in
                        Button(action: {}) {
                            Image(systemName: icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 40)
        .animation(.easeIn(duration: 0.2), value: isStreaming)
    }
}


#Preview {
    ChatPanelView(
        inputText: .constant("Type something here..."),
        messages: .constant([
            Message(content: "Hey, can you help me build a SwiftUI app?", isUser: true),
            Message(content: "Absolutely! SwiftUI is great for macOS and iOS. What kind of app do you have in mind?", isUser: false),
            Message(content: "A floating assistant like this one, actually.", isUser: true),
            Message(content: "Nice — a borderless floating window with regularMaterial, always on top. I can walk you through the whole thing.", isUser: false),
        ]),
        onClose: {},
        onSend: {},
        onShowAPIKeys: {}
    )
}
