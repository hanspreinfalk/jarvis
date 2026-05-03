import SwiftUI
import AppKit

struct ContentView: View {
    @State private var inputText = ""
    @State private var isExpanded = false
    @State private var messages: [Message] = []

    private let claudeService = ClaudeCodeService()
    private let defaultWorkingDir = URL(fileURLWithPath: NSHomeDirectory())

    var body: some View {
        Group {
            if isExpanded {
                ChatPanelView(
                    inputText: $inputText,
                    messages: $messages,
                    onClose: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    },
                    onNewChat: newChat,
                    onSend: sendMessage
                )
            } else {
                FloatingBarView(
                    inputText: $inputText,
                    onSend: sendMessage
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(WindowAccessor(callback: configureWindow))
        .onChange(of: isExpanded) { _, expanded in
            resizeWindow(expanded: expanded)
        }
    }

    // MARK: - Window setup

    private func configureWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.level = NSWindow.Level(rawValue: Int(NSWindow.Level.floating.rawValue) + 1)
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let size = NSSize(width: AppLayout.barWidth, height: AppLayout.barHeight)
            window.setFrame(
                NSRect(x: sf.midX - size.width / 2, y: sf.minY + AppLayout.windowBottomOffset, width: size.width, height: size.height),
                display: false
            )
        }
    }

    // MARK: - Actions

    private func newChat() {
        claudeService.cancel()
        messages = []
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""

        var userMsg = Message(isUser: true)
        userMsg.content = text
        messages.append(userMsg)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = true
        }

        var assistantMessage = Message(isUser: false)
        assistantMessage.isStreaming = true
        messages.append(assistantMessage)
        let idx = messages.count - 1

        claudeService.send(prompt: text, apiKey: APIKeys.anthropic, workingDir: defaultWorkingDir) { event in
            switch event {
            case .text(let chunk):
                // Append to last text item, or start a new one
                if case .text(let id, let existing) = messages[idx].items.last {
                    messages[idx].items[messages[idx].items.count - 1] = .text(id: id, content: existing + chunk)
                } else {
                    messages[idx].items.append(.text(id: UUID(), content: chunk))
                }

            case .thinking:
                break

            case .toolUse(let name, let input):
                messages[idx].items.append(.tool(ToolEvent(toolName: name, input: input)))

            case .toolResult(let output, let isError):
                // Find the last tool item and mark it complete
                for i in stride(from: messages[idx].items.count - 1, through: 0, by: -1) {
                    if case .tool(var event) = messages[idx].items[i] {
                        event.output = output
                        event.isComplete = true
                        event.isError = isError
                        messages[idx].items[i] = .tool(event)
                        break
                    }
                }

            case .done:
                messages[idx].isStreaming = false

            case .error(let err):
                messages[idx].items.append(.text(id: UUID(), content: "Error: \(err)"))
                messages[idx].isStreaming = false
            }
        }
    }

    private func resizeWindow(expanded: Bool) {
        guard let window = NSApp.windows.first(where: { $0.styleMask.contains(.fullSizeContentView) }) else { return }
        let current = window.frame
        let newSize = expanded
            ? NSSize(width: AppLayout.chatWindowWidth, height: AppLayout.chatWindowHeight)
            : NSSize(width: AppLayout.barWidth, height: AppLayout.barHeight)
        window.setFrame(NSRect(
            x: current.midX - newSize.width / 2,
            y: current.minY,
            width: newSize.width,
            height: newSize.height
        ), display: true, animate: true)
    }
}

#Preview {
    ContentView()
}
