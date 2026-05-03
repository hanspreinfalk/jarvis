import SwiftUI

@main
struct jarvisApp: App {
    var body: some Scene {
        Window("Jarvis", id: "main") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra("Jarvis", systemImage: "sparkles") {
            Button("Show Jarvis") {
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
