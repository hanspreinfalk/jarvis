import SwiftUI
import AppKit

struct ContentView: View {
    @State private var inputText = ""
    @State private var isOverApp = false
    @State private var isExpanded = false
    @State private var messages: [Message] = []

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
                    onSend: sendMessage
                )
            } else {
                FloatingBarView(
                    inputText: $inputText,
                    isOverApp: isOverApp,
                    onSend: sendMessage
                )
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
            resizeWindow(expanded: expanded)
        }
    }

    // MARK: - Window setup

    private func configureWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(NSWindow.Level.floating.rawValue) + 1)
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        window.appearance = NSAppearance(named: .aqua)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.setContentSize(NSSize(width: 465, height: 127))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let screen = NSScreen.main else { return }
            let sf = screen.visibleFrame
            let wf = window.frame
            window.setFrameOrigin(NSPoint(x: sf.midX - wf.width / 2, y: sf.minY + 80))
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        messages.append(Message(content: text, isUser: true))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            messages.append(Message(content: "Hey—what's up?", isUser: false))
        }
    }

    private func resizeWindow(expanded: Bool) {
        guard let window = NSApp.windows.first(where: { $0.styleMask.contains(.fullSizeContentView) }) else { return }
        let current = window.frame
        let newSize = expanded
            ? NSSize(width: 462, height: 672)   // ChatPanel 430×640 + 16pt padding each side
            : NSSize(width: 465, height: 127)   // FloatingBar 433 + 32pt padding
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
