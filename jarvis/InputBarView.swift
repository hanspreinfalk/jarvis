import SwiftUI

/// The text field + toolbar row shared between the floating bar and the chat panel.
struct InputBarView: View {
    @Binding var inputText: String
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            TextField("Ask anything", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .lineLimit(1...8)
                .onSubmit(onSend)

            HStack(spacing: 0) {
                ToolbarIconButton(name: "plus")
                ToolbarIconButton(name: "globe")
                ToolbarIconButton(name: "lasso")
                ToolbarIconButton(name: "character.magnify")

                Button(action: {}) {
                    Text("Auto")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.7))
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    ToolbarIconButton(name: "record.circle")
                    ToolbarIconButton(name: "mic")

                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(inputText.isEmpty ? Color(white: 0.62) : Color.black)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
            }
        }
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
                .font(.system(size: 17))
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
