import SwiftUI

enum InputMode: String, CaseIterable, Identifiable, Equatable {
    case auto   = "Auto"
    case plan   = "Plan"
    case agent  = "Agent"
    var id: String { rawValue }
}

/// The text field + toolbar row shared between the floating bar and the chat panel.
struct InputBarView: View {
    @Binding var inputText: String
    @State private var selectedMode: InputMode = .auto
    @FocusState private var textFocused: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            TextField("Ask anything", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .foregroundStyle(Color.black)
                .lineLimit(1...8)
                .onSubmit(onSend)
                .focused($textFocused)

            HStack(spacing: 0) {
                ToolbarIconButton(name: "plus")
                ModeSelectorButton(mode: $selectedMode)

                Spacer()

                HStack(spacing: 6) {
                    ToolbarIconButton(name: "record.circle")
                    ToolbarIconButton(name: "mic")

                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(inputText.isEmpty ? Color(white: 0.62) : Color(NSColor.black))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
            }
        }
        .onChange(of: selectedMode) { _, _ in
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows
                .first(where: { $0.styleMask.contains(.fullSizeContentView) })?
                .makeKey()
            textFocused = true
        }
    }
}

/// Mode picker — cycles Auto → Plan → Agent on each click.
/// Plain button keeps the floating window as key and never disrupts TextField focus.
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

/// Single toolbar icon that shows a rounded-rect highlight on hover.
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
