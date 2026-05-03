import Foundation

struct Message: Identifiable {
    let id = UUID()
    let isUser: Bool
    var content: String = ""      // user messages only
    var items: [ContentItem] = [] // AI messages: ordered text + tool blocks
    var isStreaming: Bool = false
}

enum ContentItem: Identifiable {
    case text(id: UUID, content: String)
    case tool(ToolEvent)

    var id: UUID {
        switch self {
        case .text(let id, _): return id
        case .tool(let e):     return e.id
        }
    }
}

struct ToolEvent: Identifiable {
    let id = UUID()
    let toolName: String
    let input: String
    var output: String?
    var isComplete: Bool = false
    var isError: Bool = false
}
