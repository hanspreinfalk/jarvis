import Foundation

struct MessageAttachment: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isImage: Bool
}

struct Message: Identifiable {
    let id = UUID()
    let isUser: Bool
    var content: String = ""
    var attachments: [MessageAttachment] = []
    var items: [ContentItem] = []
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
