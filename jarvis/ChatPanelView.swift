import SwiftUI

private let bubbleSurface = Color.primary.opacity(0.1)

struct ChatPanelView: View {
    @Binding var inputText: String
    @Binding var messages: [Message]
    let onClose: () -> Void
    let onNewChat: () -> Void
    let onSend: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPanelHovered = false

    private var inputBarBackground: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.91)
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
        .frame(width: AppLayout.chatPanelWidth, height: AppLayout.chatPanelHeight)
        .onHover { isPanelHovered = $0 }
        .background(colorScheme == .light ? AnyShapeStyle(Color(white: 0.97)) : AnyShapeStyle(Material.ultraThick), in: RoundedRectangle(cornerRadius: 20))
//        .background(colorScheme == .dark ? Color.black.opacity(0.65) : Color.clear,
//                    in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
                .allowsHitTesting(false)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.1), lineWidth: 1.5))
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

                Button(action: onNewChat) {
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
                            AIBubble(items: message.items, isStreaming: message.isStreaming)
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
            .onChange(of: messages.last?.items.count) {
                proxy.scrollTo("scrollBottom", anchor: .bottom)
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
    let items: [ContentItem]
    let isStreaming: Bool

    private let actionIcons = ["doc.on.doc", "speaker.wave.2", "hand.thumbsup", "hand.thumbsdown", "arrow.clockwise"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if items.isEmpty && isStreaming {
                ThinkingText()
            }

            // Render items in chronological order: text and tools interleaved
            ForEach(items) { item in
                switch item {
                case .text(_, let content):
                    if !content.isEmpty {
                        MarkdownText(source: content)
                    }
                case .tool(let event):
                    ToolEventRow(event: event)
                }
            }

            if !isStreaming && !items.isEmpty {
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

private struct ToolEventRow: View {
    let event: ToolEvent
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isExpanded.toggle() } } label: {
                HStack(spacing: 7) {
                    statusDot
                    Image(systemName: toolIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(event.toolName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !event.input.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("INPUT")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(0.8)
                            Text(event.input)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let output = event.output, !output.isEmpty {
                        Divider().opacity(0.4)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("OUTPUT")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(0.8)
                            Text(output)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(event.isError ? .red : .secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var statusDot: some View {
        if event.isComplete {
            Circle()
                .fill(event.isError ? Color.red.opacity(0.8) : Color.green.opacity(0.7))
                .frame(width: 6, height: 6)
        } else {
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 6, height: 6)
                .opacity(0.9)
        }
    }

    private var toolIcon: String {
        switch event.toolName.lowercased() {
        case "bash":               return "terminal"
        case "read":               return "doc.text"
        case "write":              return "pencil.and.outline"
        case "edit":               return "pencil"
        case "grep":               return "magnifyingglass"
        case "glob":               return "folder"
        case "websearch":          return "magnifyingglass.circle"
        case "webfetch":           return "globe"
        case "task":               return "checklist"
        case "todowrite":          return "list.bullet"
        default:                   return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Markdown renderer

private struct MarkdownText: View {
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments(source).enumerated()), id: \.offset) { _, seg in
                switch seg {
                case .text(let s):
                    inlineView(s)
                case .code(let lang, let code):
                    codeBlockView(lang: lang, code: code)
                }
            }
        }
    }

    // Split on fenced code blocks (``` ... ```)
    private enum Segment { case text(String); case code(String?, String) }

    private func segments(_ s: String) -> [Segment] {
        var result: [Segment] = []
        let parts = s.components(separatedBy: "```")
        for (i, part) in parts.enumerated() {
            if i % 2 == 0 {
                if !part.isEmpty { result.append(.text(part)) }
            } else {
                let lines = part.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
                let lang = lines.first?.trimmingCharacters(in: .whitespaces)
                let code = lines.dropFirst().joined(separator: "\n")
                result.append(.code(lang?.isEmpty == true ? nil : lang, code.isEmpty ? part : code))
            }
        }
        return result
    }

    @ViewBuilder
    private func inlineView(_ s: String) -> some View {
        let lines = s.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Color.clear.frame(height: 2)
                } else if let attr = try? AttributedString(markdown: line) {
                    Text(attr)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(line)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func codeBlockView(lang: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let lang, !lang.isEmpty {
                    Text(lang)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                CopyButton(text: code)
            }
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 2)

            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .padding(10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
    }
}

private struct ThinkingText: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let phase = CGFloat((t.truncatingRemainder(dividingBy: 1.5)) / 1.5) * 1.6 - 0.3
            Text("Thinking…")
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(shimmer(phase: phase))
        }
    }

    private func shimmer(phase: CGFloat) -> LinearGradient {
        func cl(_ v: CGFloat) -> CGFloat { min(1, max(0, v)) }
        return LinearGradient(
            stops: [
                .init(color: .secondary.opacity(0.3),  location: 0),
                .init(color: .secondary.opacity(0.3),  location: cl(phase - 0.25)),
                .init(color: .primary.opacity(0.95),   location: cl(phase)),
                .init(color: .secondary.opacity(0.3),  location: cl(phase + 0.25)),
                .init(color: .secondary.opacity(0.3),  location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    ChatPanelView(
        inputText: .constant("Type something here..."),
        messages: .constant([
            Message(isUser: true, content: "Hey, can you help me build a SwiftUI app?"),
            Message(isUser: false, items: [
                .text(id: UUID(), content: "Sure! Let me check the existing files first."),
                .tool(ToolEvent(toolName: "Read", input: "ContentView.swift", output: "import SwiftUI\n...", isComplete: true)),
                .text(id: UUID(), content: "Got it — a floating assistant window. I can walk you through the whole thing."),
            ]),
            Message(isUser: true, content: "A floating assistant like this one, actually."),
            Message(isUser: false, items: [
                .tool(ToolEvent(toolName: "Bash", input: "ls -la", output: "total 42\n...", isComplete: true)),
                .text(id: UUID(), content: "Nice — a borderless floating window with regularMaterial, always on top."),
            ]),
        ]),
        onClose: {},
        onNewChat: {},
        onSend: {}
    )
}
