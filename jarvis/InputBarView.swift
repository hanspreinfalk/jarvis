import SwiftUI

enum InputMode: String, CaseIterable, Identifiable, Equatable {
    case auto   = "Auto"
    case plan   = "Plan"
    case agent  = "Agent"
    var id: String { rawValue }
}

struct InputBarView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let onShowAPIKeys: () -> Void

    @State private var selectedMode: InputMode = .auto
    @FocusState private var textFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    private var sendButtonBackground: Color {
        inputText.isEmpty ? Color.primary.opacity(0.15) : Color.primary
    }
    private var sendButtonForeground: Color {
        inputText.isEmpty
            ? Color.primary.opacity(0.35)
            : (colorScheme == .dark ? .black : .white)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            TextField("Ask anything", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .lineLimit(1...8)
                .onSubmit(onSend)
                .focused($textFocused)

            HStack(spacing: 0) {
                ToolbarIconButton(name: "plus")
                ToolbarIconButton(name: "key.horizontal", action: onShowAPIKeys)
                ModeSelectorButton(mode: $selectedMode)

                Spacer()

                HStack(spacing: 6) {
                    ToolbarIconButton(name: "record.circle")
                    ToolbarIconButton(name: "mic")

                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(sendButtonForeground)
                            .frame(width: 34, height: 34)
                            .background(sendButtonBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            guard (note.object as? NSWindow)?.styleMask.contains(.fullSizeContentView) == true else { return }
            textFocused = true
        }
        .onChange(of: selectedMode) { _, _ in
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows
                .first(where: { $0.styleMask.contains(.fullSizeContentView) })?
                .makeKeyAndOrderFront(nil)
            textFocused = true
        }
    }
}

private struct ModeSelectorButton: View {
    @Binding var mode: InputMode
    @State private var isHovered = false

    var body: some View {
        Button(action: cycle) {
            Text(mode.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.72))
                .padding(.horizontal, 8)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private func cycle() {
        let all = InputMode.allCases
        guard let idx = all.firstIndex(of: mode) else { return }
        mode = all[(idx + 1) % all.count]
    }
}

private struct ToolbarIconButton: View {
    let name: String
    var action: () -> Void = {}
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16))
                .foregroundStyle(.primary.opacity(0.72))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    ContentView()
}
