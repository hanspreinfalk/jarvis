import SwiftUI

struct APIKeysView: View {
    @AppStorage(StorageKey.anthropicAPIKey) private var anthropicKey = ""
    @AppStorage(StorageKey.geminiAPIKey)    private var geminiKey = ""
    @AppStorage(StorageKey.openAIAPIKey)    private var openAIKey = ""
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("API Keys")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            APIKeyRow(label: "Anthropic", placeholder: "sk-ant-...", value: $anthropicKey)
            Divider().padding(.leading, 16)
            APIKeyRow(label: "Gemini", placeholder: "AIza...", value: $geminiKey)
            Divider().padding(.leading, 16)
            APIKeyRow(label: "OpenAI", placeholder: "sk-...", value: $openAIKey)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

private struct APIKeyRow: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Group {
                if isRevealed {
                    TextField(placeholder, text: $value)
                } else {
                    SecureField(placeholder, text: $value)
                }
            }
            .font(.system(size: 13, design: .monospaced))
            .textFieldStyle(.plain)
            Button { isRevealed.toggle() } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
