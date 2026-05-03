import SwiftUI
import AppKit

/// Transparent NSView overlay whose mouseDownCanMoveWindow = true makes the
/// entire card background draggable while buttons/text fields still work normally.
struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}

    class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

/// Runs a one-shot callback as soon as the view is placed into a window,
/// giving access to the NSWindow for low-level configuration.
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.callback(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
