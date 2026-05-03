import SwiftUI

/// Expanded chat panel shown after the first message is sent.
struct ChatPanelView: View {
    @Binding var inputText: String
    @Binding var messages: [Message]
    let onClose: () -> Void
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
            messageList
            embeddedInputBar
        }
        .frame(width: 430, height: 640)
        .background(Color(white: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color(white: 0.82), lineWidth: 1))
        .padding(16)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(white: 0.55))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 14) {
                Button(action: {}) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(white: 0.5))
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(white: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
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
                            AIBubble(text: message.content)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Color.clear.frame(height: 1).id("scrollBottom")
            }
            .onChange(of: messages.count) {
                withAnimation { proxy.scrollTo("scrollBottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Embedded input bar

    private var embeddedInputBar: some View {
        InputBarView(inputText: $inputText, onSend: onSend)
            .padding(.trailing, 10)
            .padding(.leading, 15)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color(white: 0.78), lineWidth: 1)
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
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(white: 0.87))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct AIBubble: View {
    let text: String

    private let actionIcons = ["doc.on.doc", "speaker.wave.2", "hand.thumbsup", "hand.thumbsdown", "arrow.clockwise"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                ForEach(actionIcons, id: \.self) { icon in
                    Button(action: {}) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(white: 0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 40)
    }
}
