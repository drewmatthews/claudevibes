import Foundation

// MARK: - Session Entry Models

struct SessionEntry: Codable {
    let type: String?
    let timestamp: String?
    let sessionId: String?
    let message: SessionMessage?
}

struct SessionMessage: Codable {
    let role: String?
    let content: SessionContent?
    let usage: TokenUsage?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case usage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        usage = try container.decodeIfPresent(TokenUsage.self, forKey: .usage)

        // Content can be a string or an array of objects
        if let contentArray = try? container.decode([ContentItem].self, forKey: .content) {
            content = .array(contentArray)
        } else if let contentString = try? container.decode(String.self, forKey: .content) {
            content = .string(contentString)
        } else {
            content = nil
        }
    }
}

struct TokenUsage: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
    let cache_creation_input_tokens: Int?
    let cache_read_input_tokens: Int?
}

enum SessionContent: Codable {
    case string(String)
    case array([ContentItem])

    var toolCallCount: Int {
        switch self {
        case .string:
            return 0
        case .array(let items):
            return items.filter { $0.type == "tool_use" }.count
        }
    }

    var fileEditCount: Int {
        switch self {
        case .string:
            return 0
        case .array(let items):
            return items.filter { item in
                guard item.type == "tool_use", let name = item.name else { return false }
                let lower = name.lowercased()
                return lower.contains("write") || lower.contains("edit") || lower.contains("create")
            }.count
        }
    }
}

struct ContentItem: Codable {
    let type: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case type, name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}

// MARK: - Live Stats

struct LiveTodayStats {
    var messageCount: Int = 0
    var sessionCount: Int = 0
    var toolCallCount: Int = 0
    var fileEditCount: Int = 0
    var sessionIds: Set<String> = []
    var earliestTimestamp: Date? = nil
    var latestTimestamp: Date? = nil

    // Token usage
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0
    var cacheReadTokens: Int = 0

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}

// MARK: - Live Session Parser

class LiveSessionParser {
    private let projectsPath: String
    private let dateFormatter: ISO8601DateFormatter
    private let todayFormatter: DateFormatter

    init() {
        self.projectsPath = NSString(string: "~/.claude/projects").expandingTildeInPath

        self.dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        self.todayFormatter = DateFormatter()
        todayFormatter.dateFormat = "yyyy-MM-dd"
    }

    func getTodayStats() -> LiveTodayStats {
        var stats = LiveTodayStats()
        let today = todayFormatter.string(from: Date())

        // Only scan files modified today for performance
        let activeFiles = getActiveSessionFiles()
        for fullPath in activeFiles {
            parseSessionFile(at: fullPath, today: today, stats: &stats)
        }

        stats.sessionCount = stats.sessionIds.count
        return stats
    }

    private func parseSessionFile(at path: String, today: String, stats: inout LiveTodayStats) {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? fileHandle.close() }

        guard let data = try? fileHandle.readToEnd(),
              let content = String(data: data, encoding: .utf8) else {
            return
        }

        let lines = content.components(separatedBy: .newlines)
        let decoder = JSONDecoder()

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8) else {
                continue
            }

            do {
                let entry = try decoder.decode(SessionEntry.self, from: lineData)

                // Check if this entry is from today (convert UTC timestamp to local date)
                guard let timestamp = entry.timestamp,
                      let date = dateFormatter.date(from: timestamp) else {
                    continue
                }
                let localDateString = todayFormatter.string(from: date)
                guard localDateString == today else {
                    continue
                }

                // Track timestamps for session timing
                if stats.earliestTimestamp == nil || date < stats.earliestTimestamp! {
                    stats.earliestTimestamp = date
                }
                if stats.latestTimestamp == nil || date > stats.latestTimestamp! {
                    stats.latestTimestamp = date
                }

                // Count user messages
                if entry.type == "user" {
                    stats.messageCount += 1

                    if let sessionId = entry.sessionId {
                        stats.sessionIds.insert(sessionId)
                    }
                }

                // Count tool calls, file edits, and tokens from assistant messages
                if entry.type == "assistant",
                   let message = entry.message {
                    if let content = message.content {
                        stats.toolCallCount += content.toolCallCount
                        stats.fileEditCount += content.fileEditCount
                    }

                    // Track token usage
                    if let usage = message.usage {
                        stats.inputTokens += usage.input_tokens ?? 0
                        stats.outputTokens += usage.output_tokens ?? 0
                        stats.cacheCreationTokens += usage.cache_creation_input_tokens ?? 0
                        stats.cacheReadTokens += usage.cache_read_input_tokens ?? 0
                    }
                }

            } catch {
                // Skip malformed lines
                continue
            }
        }
    }

    // Get list of active session files (modified today)
    func getActiveSessionFiles() -> [String] {
        // Use shell command for reliable file enumeration (avoids FileManager issues)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        task.arguments = [projectsPath, "-name", "*.jsonl", "-mtime", "-1", "-type", "f"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("[Parser] ERROR: Could not decode find output")
                return []
            }

            let files = output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            return files
        } catch {
            print("[Parser] ERROR: find command failed: \(error.localizedDescription)")
            return []
        }
    }
}
