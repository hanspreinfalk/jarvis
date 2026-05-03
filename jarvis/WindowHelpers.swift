import SwiftUI
import AppKit

/// Runs a one-shot callback the moment the view joins a window —
/// synchronously, before the window is ever shown on screen.
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> CallbackView { CallbackView(callback: callback) }
    func updateNSView(_ nsView: CallbackView, context: Context) {}

    final class CallbackView: NSView {
        private let callback: (NSWindow?) -> Void
        private var didFire = false

        init(callback: @escaping (NSWindow?) -> Void) {
            self.callback = callback
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard !didFire, window != nil else { return }
            didFire = true
            callback(window)
        }
    }
}
