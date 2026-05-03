import Foundation

struct Message: Identifiable {
    let id = UUID()
    var content: String
    let isUser: Bool
    var toolEvents: [ToolEvent] = []
    var isStreaming: Bool = false
}

struct ToolEvent: Identifiable {
    let id = UUID()
    let toolName: String
    let input: String
    var output: String?
    var isComplete: Bool = false
    var isError: Bool = false
}
