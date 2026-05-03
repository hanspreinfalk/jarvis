import SwiftUI

/// Compact floating input card shown when no conversation is open.
/// Uses regularMaterial over the wallpaper; fades to near-solid white when
/// another app's window sits beneath it.
struct FloatingBarView: View {
    @Binding var inputText: String
    let isOverApp: Bool
    let onSend: () -> Void

    var body: some View {
        InputBarView(inputText: $inputText, onSend: onSend)
            .padding(.trailing, 10)
            .padding(.leading, 15)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                // Near-solid white tint when a real app window is visible beneath
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white.opacity(isOverApp ? 0.55 : 0))
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.25), value: isOverApp)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color(white: 0.78), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.13), radius: 3, x: 0, y: 1)
            .frame(width: 433)
            .padding(16)
    }
}

#Preview {
    ContentView()
}
