import SwiftUI

/// Compact floating input card shown when no conversation is open.
/// Background is pure regularMaterial — it adapts naturally to whatever
/// is behind the window (wallpaper tint, app colour, etc.).
struct FloatingBarView: View {
    @Binding var inputText: String
    let isOverApp: Bool
    let onSend: () -> Void
    let onShowAPIKeys: () -> Void

    var body: some View {
        InputBarView(inputText: $inputText, onSend: onSend, onShowAPIKeys: onShowAPIKeys)
            .padding(.trailing, 10)
            .padding(.leading, 15)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .frame(width: 433)
            .padding(16)
    }
}

#Preview {
    ContentView()
}
