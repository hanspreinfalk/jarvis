import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// SETUP — change these if you install Claude Code differently or use a
//          different package manager.
// ─────────────────────────────────────────────────────────────────────────────

enum ClaudeSetup {
    /// Path to the claude binary relative to $HOME.
    /// Common alternatives:
    ///   ".npm/bin/claude"          (npm global install)
    ///   ".local/bin/claude"        (pipx / manual)
    ///   "/opt/homebrew/bin/claude" (absolute, Homebrew on Apple Silicon)
    ///   "/usr/local/bin/claude"    (absolute, Homebrew on Intel)
    static let claudeRelativePath = ".bun/bin/claude"

    /// Extra directories prepended to PATH when running the claude subprocess.
    /// Add any directory your shell normally puts on PATH so claude can find
    /// node, git, or other tools it needs.
    static let extraPATH: [String] = [
        "$HOME/.bun/bin",
        "$HOME/Library/pnpm",
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
    ]
}

// ─────────────────────────────────────────────────────────────────────────────
// API Keys
// ─────────────────────────────────────────────────────────────────────────────

enum APIKeys {
    /// Your Anthropic API key — get one at https://console.anthropic.com
    /// Leave empty ("") to use Claude Code's own login (`claude /login`).
    static let anthropic = ""
}

// ─────────────────────────────────────────────────────────────────────────────
// Window & layout sizes  (pixels, before display scaling)
// ─────────────────────────────────────────────────────────────────────────────

enum AppLayout {
    /// Collapsed floating bar
    static let barWidth:  CGFloat = 465
    static let barHeight: CGFloat = 127

    /// Expanded chat panel window
    static let chatWindowWidth:  CGFloat = 462
    static let chatWindowHeight: CGFloat = 576

    /// Distance from the bottom of the screen when the window first appears
    static let windowBottomOffset: CGFloat = 80

    /// Inner SwiftUI frame of the chat panel card
    static let chatPanelWidth:  CGFloat = 430
    static let chatPanelHeight: CGFloat = 544
}
