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
    @Published var liveTodayStats: LiveTodayStats?
    @Published var isRefreshing: Bool = false

    private let statsFilePath: String
    private var fileWatcher: StatsFileWatcher?
    private var sessionFileWatchers: [StatsFileWatcher] = []
    private let liveParser = LiveSessionParser()
    private var liveRefreshTimer: Timer?

    init() {
        self.statsFilePath = NSString(string: "~/.claude/stats-cache.json").expandingTildeInPath
        loadStats()
        setupFileWatcher()
        loadLiveStats()
        setupLiveRefresh()
    }

    func loadStats() {
        isRefreshing = true

        // Do all I/O on background thread to keep UI responsive
        let path = statsFilePath
        let parser = liveParser

        Task.detached(priority: .userInitiated) {
            // Load cached stats
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: path) else {
                await MainActor.run {
                    self.error = "no-stats-file"
                    self.stats = nil
                    self.isRefreshing = false
                }
                return
            }

            let loadedStats: UsageStats?
            let loadedError: String?

            do {
                let url = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                loadedStats = try decoder.decode(UsageStats.self, from: data)
                loadedError = nil
            } catch let decodingError as DecodingError {
                loadedStats = nil
                loadedError = "Failed to parse stats: \(decodingError.localizedDescription)"
            } catch {
                loadedStats = nil
                loadedError = "Failed to load stats: \(error.localizedDescription)"
            }

            // Load live stats
            let loadedLiveStats = parser.getTodayStats()

            // Capture values for MainActor
            let finalStats = loadedStats
            let finalError = loadedError
            let finalLiveStats = loadedLiveStats

            // Update UI on main thread
            await MainActor.run {
                self.stats = finalStats
                self.error = finalError
                self.liveTodayStats = finalLiveStats
                if finalStats != nil {
                    self.lastUpdated = Date()
                    self.refreshCount += 1
                }
                self.isRefreshing = false
                self.setupSessionFileWatchers()
            }
        }
    }

    func loadLiveStats() {
        let parser = liveParser
        Task.detached(priority: .userInitiated) {
            let newLiveStats = parser.getTodayStats()
            await MainActor.run {
                self.liveTodayStats = newLiveStats
                self.setupSessionFileWatchers()
            }
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

    private func setupSessionFileWatchers() {
        // Stop existing watchers
        sessionFileWatchers.forEach { $0.stop() }
        sessionFileWatchers.removeAll()

        // Watch active session files
        let activeFiles = liveParser.getActiveSessionFiles()
        for file in activeFiles {
            let watcher = StatsFileWatcher(path: file) { [weak self] in
                Task { @MainActor in
                    self?.loadLiveStats()
                    self?.refreshCount += 1
                }
            }
            watcher.start()
            sessionFileWatchers.append(watcher)
        }
    }

    private func setupLiveRefresh() {
        // Also refresh every 30 seconds as a fallback
        liveRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadLiveStats()
            }
        }
    }

    deinit {
        fileWatcher?.stop()
        sessionFileWatchers.forEach { $0.stop() }
        liveRefreshTimer?.invalidate()
    }
}
