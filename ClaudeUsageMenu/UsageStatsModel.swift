import Foundation

// MARK: - Main Stats Model

struct UsageStats: Codable {
    let version: Int
    let lastComputedDate: String
    let dailyActivity: [DailyActivity]
    let dailyModelTokens: [DailyModelTokens]
    let modelUsage: [String: ModelUsage]
    let totalSessions: Int
    let totalMessages: Int
    let longestSession: LongestSession
    let firstSessionDate: String
    let hourCounts: [String: Int]
}

struct DailyActivity: Codable {
    let date: String
    let messageCount: Int
    let sessionCount: Int
    let toolCallCount: Int
}

struct DailyModelTokens: Codable {
    let date: String
    let tokensByModel: [String: Int]
}

struct ModelUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadInputTokens: Int
    let cacheCreationInputTokens: Int
    let webSearchRequests: Int
    let costUSD: Double
    let contextWindow: Int
    let maxOutputTokens: Int
}

struct LongestSession: Codable {
    let sessionId: String
    let duration: Int
    let messageCount: Int
    let timestamp: String
}

// MARK: - Computed Properties Extension

extension UsageStats {
    var todayActivity: DailyActivity? {
        let today = ISO8601DateFormatter.dateOnlyFormatter.string(from: Date())
        return dailyActivity.first { $0.date == today }
    }

    var totalTokens: Int {
        modelUsage.values.reduce(0) { sum, model in
            sum + model.inputTokens + model.outputTokens + model.cacheReadInputTokens + model.cacheCreationInputTokens
        }
    }

    var formattedFirstSession: String {
        String(firstSessionDate.prefix(10))
    }

    var longestSessionDurationFormatted: String {
        let totalSeconds = longestSession.duration / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

extension ModelUsage {
    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadInputTokens + cacheCreationInputTokens
    }
}

// MARK: - Number Formatting

extension Int {
    var formattedCompact: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", Double(self) / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", Double(self) / 1_000)
        }
        return "\(self)"
    }
}

// MARK: - Date Formatting

extension ISO8601DateFormatter {
    static let dateOnlyFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}

// MARK: - Stats Manager

@MainActor
class StatsManager: ObservableObject {
    @Published var stats: UsageStats?
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var refreshCount: Int = 0

    private let statsFilePath: String
    private var fileWatcher: StatsFileWatcher?

    init() {
        self.statsFilePath = NSString(string: "~/.claude/stats-cache.json").expandingTildeInPath
        loadStats()
        setupFileWatcher()
    }

    func loadStats() {
        let url = URL(fileURLWithPath: statsFilePath)

        // Check if file exists first
        guard FileManager.default.fileExists(atPath: statsFilePath) else {
            error = "no-stats-file"
            stats = nil
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            stats = try decoder.decode(UsageStats.self, from: data)
            error = nil
            lastUpdated = Date()
            refreshCount += 1
        } catch let decodingError as DecodingError {
            error = "Failed to parse stats: \(decodingError.localizedDescription)"
            stats = nil
        } catch {
            self.error = "Failed to load stats: \(error.localizedDescription)"
            stats = nil
        }
    }

    private func setupFileWatcher() {
        fileWatcher = StatsFileWatcher(path: statsFilePath) { [weak self] in
            Task { @MainActor in
                self?.loadStats()
            }
        }
        fileWatcher?.start()
    }

    deinit {
        fileWatcher?.stop()
    }
}
