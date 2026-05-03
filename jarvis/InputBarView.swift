import SwiftUI
import Speech
import AVFoundation
import Combine

enum InputMode: String, CaseIterable, Identifiable, Equatable {
    case auto  = "Auto"
    case plan  = "Plan"
    case agent = "Agent"
    var id: String { rawValue }
}

struct InputBarView: View {
    @Binding var inputText: String
    let onSend: () -> Void

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
                BarIconButton(name: "plus")
                ModeSelectorButton(mode: $selectedMode)

                Spacer()

                HStack(spacing: 6) {
                    BarIconButton(name: "record.circle")
                    MicIconButton(inputText: $inputText)
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

private struct BarIconButton: View {
    let name: String
    @State private var isHovered = false

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(.primary.opacity(0.72))
            .frame(width: 32, height: 32)
            .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(isHovered ? 0.08 : 0)))
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

@MainActor
private final class MicRecorder: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false

    private let recognizer = SFSpeechRecognizer(locale: .current)
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var onTranscript: ((String) -> Void)?

    func toggle(onTranscript: @escaping (String) -> Void) {
        isRecording ? stop() : start(onTranscript: onTranscript)
    }

    private func start(onTranscript: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.beginSession(onTranscript: onTranscript) }
            }
        }
    }

    private func beginSession(onTranscript: @escaping (String) -> Void) {
        self.onTranscript = onTranscript
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        let input = engine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in req.append(buf) }

        do {
            try engine.start()
        } catch {
            return
        }

        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let text = result?.bestTranscription.formattedString {
                DispatchQueue.main.async { onTranscript(text) }
            }
            if result?.isFinal == true || error != nil {
                DispatchQueue.main.async { self.stop() }
            }
        }
        isRecording = true
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        request?.endAudio()
        task?.finish()
        request = nil
        task = nil
        isRecording = false
    }
}

private struct MicIconButton: View {
    @Binding var inputText: String
    @State private var isHovered = false
    @StateObject private var recorder = MicRecorder()
    @Environment(\.colorScheme) var colorScheme

    private var iconColor: Color {
        if recorder.isRecording { return .red }
        return colorScheme == .light ? Color.primary.opacity(0.72) : Color.white.opacity(0.72)
    }

    var body: some View {
        Button {
            recorder.toggle { text in inputText = text }
        } label: {
            Image("white-microphone")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(iconColor)
                .frame(width: 42, height: 42)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(
                    recorder.isRecording ? 0.12 : (isHovered ? 0.08 : 0)
                )))
                .animation(.easeInOut(duration: 0.12), value: isHovered)
                .animation(.easeInOut(duration: 0.12), value: recorder.isRecording)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
