import SwiftUI

struct FloatingBarView: View {
    @Binding var inputText: String
    @Binding var attachments: [AttachmentItem]
    let onSend: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var barBackground: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(Color(white: 0.97))
            : AnyShapeStyle(Material.regular)
    }

    var body: some View {
        InputBarView(inputText: $inputText, attachments: $attachments, onSend: onSend)
            .padding(.trailing, 10)
            .padding(.leading, 15)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(barBackground, in: RoundedRectangle(cornerRadius: 26))
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
