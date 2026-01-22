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

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decodeIfPresent(String.self, forKey: .role)

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
}

struct ContentItem: Codable {
    let type: String?
}

// MARK: - Live Stats

struct LiveTodayStats {
    var messageCount: Int = 0
    var sessionCount: Int = 0
    var toolCallCount: Int = 0
    var sessionIds: Set<String> = []
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

                // Check if this entry is from today
                guard let timestamp = entry.timestamp,
                      timestamp.hasPrefix(today) else {
                    continue
                }

                // Count user messages
                if entry.type == "user" {
                    stats.messageCount += 1

                    if let sessionId = entry.sessionId {
                        stats.sessionIds.insert(sessionId)
                    }
                }

                // Count tool calls from assistant messages
                if entry.type == "assistant",
                   let message = entry.message,
                   let content = message.content {
                    stats.toolCallCount += content.toolCallCount
                }

            } catch {
                // Skip malformed lines
                continue
            }
        }
    }

    // Get list of active session files (modified today)
    func getActiveSessionFiles() -> [String] {
        var files: [String] = []
        let fileManager = FileManager.default
        let today = Calendar.current.startOfDay(for: Date())

        guard let enumerator = fileManager.enumerator(atPath: projectsPath) else {
            return files
        }

        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".jsonl") {
                let fullPath = (projectsPath as NSString).appendingPathComponent(file)

                if let attrs = try? fileManager.attributesOfItem(atPath: fullPath),
                   let modDate = attrs[.modificationDate] as? Date,
                   modDate >= today {
                    files.append(fullPath)
                }
            }
        }

        return files
    }
}
