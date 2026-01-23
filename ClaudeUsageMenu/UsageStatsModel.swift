import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudevibes", category: "stats")

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

// MARK: - Local History Storage

struct LocalHistory: Codable {
    var dailyStats: [String: DailyActivity] // date string -> activity
    var lastUpdated: Date

    init() {
        self.dailyStats = [:]
        self.lastUpdated = Date()
    }

    /// Merge new activity, keeping the higher values for each metric
    mutating func merge(_ activity: DailyActivity) {
        if let existing = dailyStats[activity.date] {
            dailyStats[activity.date] = DailyActivity(
                date: activity.date,
                messageCount: max(existing.messageCount, activity.messageCount),
                sessionCount: max(existing.sessionCount, activity.sessionCount),
                toolCallCount: max(existing.toolCallCount, activity.toolCallCount)
            )
        } else {
            dailyStats[activity.date] = activity
        }
        lastUpdated = Date()
    }

    /// Merge live today stats
    mutating func mergeLive(_ live: LiveTodayStats, for date: String) {
        let activity = DailyActivity(
            date: date,
            messageCount: live.messageCount,
            sessionCount: live.sessionCount,
            toolCallCount: live.toolCallCount
        )
        merge(activity)
    }

    /// Get corrected daily activity array (sorted by date, last 30 days)
    func getCorrectedActivity() -> [DailyActivity] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return dailyStats.values
            .filter { activity in
                if let date = formatter.date(from: activity.date) {
                    return date >= cutoff
                }
                return false
            }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - History Manager

class HistoryManager {
    static let shared = HistoryManager()

    private let historyURL: URL
    private var history: LocalHistory

    private init() {
        // Setup app support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ClaudeVibes", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        self.historyURL = appDir.appendingPathComponent("history.json")
        self.history = LocalHistory()

        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: historyURL),
              let loaded = try? JSONDecoder().decode(LocalHistory.self, from: data) else {
            logger.info("No existing history found, performing initial scan")
            performFullHistoricalScan()
            return
        }
        self.history = loaded
        logger.info("Loaded history with \(self.history.dailyStats.count) days")
    }

    /// Scan all session files to rebuild complete historical data (runs on first launch)
    private func performFullHistoricalScan() {
        logger.info("Starting full historical scan of session files...")

        let projectsPath = NSString(string: "~/.claude/projects").expandingTildeInPath
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: projectsPath) else {
            logger.warning("Could not enumerate projects directory")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var dailyStats: [String: (messages: Int, sessions: Set<String>, toolCalls: Int)] = [:]

        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".jsonl") {
                let fullPath = (projectsPath as NSString).appendingPathComponent(file)
                parseSessionFileForHistory(at: fullPath, into: &dailyStats)
            }
        }

        // Convert to DailyActivity and merge into history
        for (date, stats) in dailyStats {
            let activity = DailyActivity(
                date: date,
                messageCount: stats.messages,
                sessionCount: stats.sessions.count,
                toolCallCount: stats.toolCalls
            )
            self.history.merge(activity)
        }

        save()
        logger.info("Historical scan complete: found \(self.history.dailyStats.count) days of activity")
    }

    private func parseSessionFileForHistory(at path: String, into dailyStats: inout [String: (messages: Int, sessions: Set<String>, toolCalls: Int)]) {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return
        }

        let lines = content.components(separatedBy: .newlines)
        let decoder = JSONDecoder()

        for line in lines {
            guard !line.isEmpty, let lineData = line.data(using: .utf8) else { continue }

            do {
                let entry = try decoder.decode(SessionEntry.self, from: lineData)

                guard let timestamp = entry.timestamp, timestamp.count >= 10 else { continue }
                let date = String(timestamp.prefix(10)) // Extract yyyy-MM-dd

                // Initialize if needed
                if dailyStats[date] == nil {
                    dailyStats[date] = (messages: 0, sessions: [], toolCalls: 0)
                }

                // Count user messages
                if entry.type == "user" {
                    dailyStats[date]!.messages += 1
                    if let sessionId = entry.sessionId {
                        dailyStats[date]!.sessions.insert(sessionId)
                    }
                }

                // Count tool calls from assistant messages
                if entry.type == "assistant",
                   let message = entry.message,
                   let content = message.content {
                    dailyStats[date]!.toolCalls += content.toolCallCount
                }
            } catch {
                continue // Skip malformed lines
            }
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self.history)
            try data.write(to: historyURL)
            let count = self.history.dailyStats.count
            logger.info("Saved history with \(count) days")
        } catch {
            logger.error("Failed to save history: \(error.localizedDescription)")
        }
    }

    func merge(_ activities: [DailyActivity]) {
        for activity in activities {
            self.history.merge(activity)
        }
        save()
    }

    func mergeLive(_ live: LiveTodayStats) {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        self.history.mergeLive(live, for: today)
        save()
    }

    func getCorrectedActivity() -> [DailyActivity] {
        self.history.getCorrectedActivity()
    }

    func getActivity(for date: String) -> DailyActivity? {
        self.history.dailyStats[date]
    }

    /// Force a full rescan of all session files (rebuilds history from scratch)
    func forceRescan() {
        self.history = LocalHistory()
        performFullHistoricalScan()
    }

    var isEmpty: Bool {
        self.history.dailyStats.isEmpty
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
    @Published var correctedDailyActivity: [DailyActivity] = []

    private let statsFilePath: String
    private var fileWatcher: StatsFileWatcher?
    private var sessionFileWatchers: [StatsFileWatcher] = []
    private let liveParser = LiveSessionParser()
    private var liveRefreshTimer: Timer?
    private let historyManager = HistoryManager.shared

    init() {
        self.statsFilePath = NSString(string: "~/.claude/stats-cache.json").expandingTildeInPath

        // Disable App Nap to prevent file access issues after idle
        ProcessInfo.processInfo.disableAutomaticTermination("Monitoring stats file")
        ProcessInfo.processInfo.disableSuddenTermination()

        // Load existing history immediately
        correctedDailyActivity = historyManager.getCorrectedActivity()

        loadStats()
        setupFileWatcher()
        loadLiveStats()
        setupLiveRefresh()
    }

    func loadStats() {
        isRefreshing = true

        // Stop file watcher before reading to release file descriptor
        fileWatcher?.stop()

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

            // Retry up to 3 times with small delays to handle transient file access issues
            var lastError: Error?
            var stats: UsageStats?

            logger.info("Loading stats from \(path)")

            // Log file state for diagnostics
            let attrs = try? fileManager.attributesOfItem(atPath: path)
            let fileSize = attrs?[.size] as? Int ?? -1
            let isReadable = fileManager.isReadableFile(atPath: path)
            logger.info("File state - size: \(fileSize), readable: \(isReadable)")

            for attempt in 1...3 {
                do {
                    // Use FileHandle for more robust file access
                    guard let fileHandle = FileHandle(forReadingAtPath: path) else {
                        throw NSError(domain: NSCocoaErrorDomain, code: 256, userInfo: [NSLocalizedDescriptionKey: "Could not open file handle"])
                    }
                    let data = fileHandle.readDataToEndOfFile()
                    try fileHandle.close()

                    let decoder = JSONDecoder()
                    stats = try decoder.decode(UsageStats.self, from: data)
                    lastError = nil
                    if attempt > 1 {
                        logger.info("Stats loaded successfully on attempt \(attempt)")
                    }
                    break
                } catch {
                    lastError = error
                    logger.warning("Attempt \(attempt) failed: \(error.localizedDescription)")
                    if attempt < 3 {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms (longer delay)
                    }
                }
            }

            if let stats = stats {
                loadedStats = stats
                loadedError = nil
                logger.info("Stats loaded: \(stats.totalMessages) messages, \(stats.totalSessions) sessions")
            } else if let error = lastError as? DecodingError {
                loadedStats = nil
                loadedError = "Failed to parse stats: \(error.localizedDescription)"
                logger.error("Failed to parse stats after 3 attempts: \(error.localizedDescription)")
            } else {
                loadedStats = nil
                loadedError = lastError.map { "Failed to load stats: \($0.localizedDescription)" }
                logger.error("Failed to load stats after 3 attempts: \(lastError?.localizedDescription ?? "unknown")")
            }

            // Load live stats
            let loadedLiveStats = parser.getTodayStats()

            // Capture values for MainActor
            let finalStats = loadedStats
            let finalError = loadedError
            let finalLiveStats = loadedLiveStats

            // Merge with local history (keeps higher values)
            if let stats = loadedStats {
                HistoryManager.shared.merge(stats.dailyActivity)
            }
            if loadedLiveStats.messageCount > 0 {
                HistoryManager.shared.mergeLive(loadedLiveStats)
            }
            let corrected = HistoryManager.shared.getCorrectedActivity()

            // Update UI on main thread
            await MainActor.run {
                self.stats = finalStats
                self.error = finalError
                self.liveTodayStats = finalLiveStats
                self.correctedDailyActivity = corrected
                self.lastUpdated = Date()
                self.refreshCount += 1
                self.isRefreshing = false
                self.setupFileWatcher() // Restart file watcher with fresh descriptor
                self.setupSessionFileWatchers()
            }
        }
    }

    func loadLiveStats() {
        let parser = liveParser
        Task.detached(priority: .userInitiated) {
            let newLiveStats = parser.getTodayStats()

            // Merge live stats with history
            if newLiveStats.messageCount > 0 {
                HistoryManager.shared.mergeLive(newLiveStats)
            }
            let corrected = HistoryManager.shared.getCorrectedActivity()

            await MainActor.run {
                self.liveTodayStats = newLiveStats
                self.correctedDailyActivity = corrected
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
