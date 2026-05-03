import Foundation

enum ClaudeEvent {
    case text(String)
    case thinking(String)
    case toolUse(name: String, input: String)
    case toolResult(output: String, isError: Bool)
    case done
    case error(String)
}

class ClaudeCodeService {
    private var process: Process?
    private var streamTask: Task<Void, Never>?
    private var sessionId: String?

    func send(prompt: String, apiKey: String, workingDir: URL, onEvent: @escaping (ClaudeEvent) -> Void) {
        stopCurrentTask()

        let process = Process()
        self.process = process

        let home = NSHomeDirectory()
        let bunClaude = URL(fileURLWithPath: home)
            .appendingPathComponent(ClaudeSetup.claudeRelativePath)
            .resolvingSymlinksInPath()

        process.executableURL = bunClaude

        // Use --resume to continue the conversation if we have a session ID
        var args = ["--dangerously-skip-permissions", "--output-format", "stream-json",
                    "--verbose", "--include-partial-messages"]
        if let sid = sessionId {
            args += ["--resume", sid]
        }
        args += ["--print", prompt]
        process.arguments = args

        var env = ProcessInfo.processInfo.environment
        env["HOME"] = home
        let resolvedPATH = ClaudeSetup.extraPATH
            .map { $0.replacingOccurrences(of: "$HOME", with: home) }
            .joined(separator: ":")
        env["PATH"] = resolvedPATH
        if !apiKey.isEmpty { env["ANTHROPIC_API_KEY"] = apiKey }
        process.environment = env
        process.currentDirectoryURL = workingDir

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            onEvent(.error("Failed to launch claude: \(error.localizedDescription)"))
            return
        }

        streamTask = Task {
            do {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    guard !Task.isCancelled else { break }
                    guard !line.isEmpty else { continue }
                    for event in parseEvents(line) {
                        await MainActor.run { onEvent(event) }
                    }
                }
                await MainActor.run { onEvent(.done) }
            } catch {
                await MainActor.run { onEvent(.error(error.localizedDescription)) }
            }
        }
    }

    // Called when the user starts a new chat — resets session context
    func cancel() {
        stopCurrentTask()
        sessionId = nil
    }

    // Stops the running process/task without clearing the session ID
    private func stopCurrentTask() {
        streamTask?.cancel()
        streamTask = nil
        process?.terminate()
        process = nil
    }

    private func parseEvents(_ line: String) -> [ClaudeEvent] {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else { return [] }

        switch type {
        case "stream_event":
            guard let event = json["event"] as? [String: Any],
                  let eventType = event["type"] as? String,
                  eventType == "content_block_delta",
                  let delta = event["delta"] as? [String: Any]
            else { return [] }
            let deltaType = delta["type"] as? String
            if deltaType == "text_delta", let text = delta["text"] as? String {
                return [.text(text)]
            }
            if deltaType == "thinking_delta", let thinking = delta["thinking"] as? String {
                return [.thinking(thinking)]
            }
            return []

        case "assistant":
            guard let message = json["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]] else { return [] }
            return content.compactMap { block -> ClaudeEvent? in
                guard block["type"] as? String == "tool_use" else { return nil }
                let name = block["name"] as? String ?? "Unknown"
                let input = (block["input"] as? [String: Any])
                    .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) }
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                return .toolUse(name: name, input: input)
            }

        case "tool_result":
            let isError = json["is_error"] as? Bool ?? false
            let output = (json["content"] as? [[String: Any]])?.first?["text"] as? String ?? ""
            return [.toolResult(output: output, isError: isError)]

        case "result":
            // Capture the session ID so the next message resumes this conversation
            if let sid = json["session_id"] as? String {
                sessionId = sid
            }
            return [.done]

        default:
            return []
        }
    }
}
