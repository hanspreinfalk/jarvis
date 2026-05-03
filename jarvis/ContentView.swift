import SwiftUI
import AppKit

struct ContentView: View {
    @State private var inputText = ""
    @State private var isOverApp = false
    @State private var isExpanded = false
    @State private var showAPIKeys = false
    @State private var messages: [Message] = []

    @AppStorage("anthropicAPIKey") private var anthropicKey = ""

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
                    onSend: sendMessage,
                    onShowAPIKeys: toggleAPIKeys
                )
            } else {
                VStack(spacing: 0) {
                    if showAPIKeys {
                        APIKeysView(onDismiss: toggleAPIKeys)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    FloatingBarView(
                        inputText: $inputText,
                        isOverApp: isOverApp,
                        onSend: sendMessage,
                        onShowAPIKeys: toggleAPIKeys
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .background(WindowAccessor(callback: configureWindow))
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(
            for: NSWorkspace.didActivateApplicationNotification
        )) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundle = app?.bundleIdentifier ?? ""
            isOverApp = bundle != "com.apple.finder" && bundle != Bundle.main.bundleIdentifier
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded { showAPIKeys = false }
            resizeWindow(expanded: expanded, apiKeys: false)
        }
        .onChange(of: showAPIKeys) { _, show in
            guard !isExpanded else { return }
            resizeWindow(expanded: false, apiKeys: show)
        }
    }

    // MARK: - Window setup

    private func configureWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.alphaValue = 0
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(NSWindow.Level.floating.rawValue) + 1)
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let size = NSSize(width: 465, height: 127)
            window.setFrame(
                NSRect(x: sf.midX - size.width / 2, y: sf.minY + 80, width: size.width, height: size.height),
                display: false
            )
        }
        DispatchQueue.main.async { window.alphaValue = 1 }
    }

    // MARK: - Actions

    private func newChat() {
        claudeService.cancel()
        messages = []
    }

    private func toggleAPIKeys() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showAPIKeys.toggle()
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""

        messages.append(Message(content: text, isUser: true))

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = true
        }

        let assistantMessage = Message(content: "", isUser: false, isStreaming: true)
        messages.append(assistantMessage)
        let idx = messages.count - 1

        let key = anthropicKey.isEmpty ? "" : anthropicKey

        claudeService.send(prompt: text, apiKey: key, workingDir: defaultWorkingDir) { event in
            switch event {
            case .text(let chunk):
                messages[idx].content += chunk

            case .thinking(let chunk):
                messages[idx].thinking = (messages[idx].thinking ?? "") + chunk

            case .toolUse(let name, let input):
                messages[idx].toolEvents.append(ToolEvent(toolName: name, input: input))

            case .toolResult(let output, let isError):
                guard !messages[idx].toolEvents.isEmpty else { return }
                let last = messages[idx].toolEvents.count - 1
                messages[idx].toolEvents[last].output = output
                messages[idx].toolEvents[last].isComplete = true
                messages[idx].toolEvents[last].isError = isError

            case .done:
                messages[idx].isStreaming = false

            case .error(let err):
                messages[idx].content = "Error: \(err)"
                messages[idx].isStreaming = false
            }
        }
    }

    private func resizeWindow(expanded: Bool, apiKeys: Bool) {
        guard let window = NSApp.windows.first(where: { $0.styleMask.contains(.fullSizeContentView) }) else { return }
        let current = window.frame
        let newSize: NSSize
        if expanded {
            newSize = NSSize(width: 462, height: 576)
        } else if apiKeys {
            newSize = NSSize(width: 465, height: 316)
        } else {
            newSize = NSSize(width: 465, height: 127)
        }
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
