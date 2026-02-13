import Foundation
import os.log
import UserNotifications

private let logger = Logger(subsystem: "com.lou", category: "stats")

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

// MARK: - New Analytics Models

struct StreakData: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String

    static let empty = StreakData(currentStreak: 0, longestStreak: 0, lastActiveDate: "")
}

struct CacheAnalytics {
    let hitRate: Double
    let savingsPercentage: Int
}

struct ValueMeter {
    let estimatedValue: Double
    let breakdown: [String: Double]
}

enum MilestoneType: String, Codable, CaseIterable {
    case messages1K = "messages_1k"
    case messages10K = "messages_10k"
    case messages100K = "messages_100k"
    case sessions100 = "sessions_100"
    case sessions1K = "sessions_1k"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case tokens1M = "tokens_1m"
    case tokens10M = "tokens_10m"
    case tokens100M = "tokens_100m"

    var displayName: String {
        switch self {
        case .messages1K: return "1K Messages"
        case .messages10K: return "10K Messages"
        case .messages100K: return "100K Messages"
        case .sessions100: return "100 Sessions"
        case .sessions1K: return "1K Sessions"
        case .streak7: return "7-Day Streak"
        case .streak30: return "30-Day Streak"
        case .tokens1M: return "1M Tokens"
        case .tokens10M: return "10M Tokens"
        case .tokens100M: return "100M Tokens"
        }
    }

    var threshold: Int {
        switch self {
        case .messages1K: return 1_000
        case .messages10K: return 10_000
        case .messages100K: return 100_000
        case .sessions100: return 100
        case .sessions1K: return 1_000
        case .streak7: return 7
        case .streak30: return 30
        case .tokens1M: return 1_000_000
        case .tokens10M: return 10_000_000
        case .tokens100M: return 100_000_000
        }
    }

    var emoji: String {
        switch self {
        case .messages1K: return "💬"
        case .messages10K: return "🗣️"
        case .messages100K: return "🏆"
        case .sessions100: return "💻"
        case .sessions1K: return "🖥️"
        case .streak7: return "🔥"
        case .streak30: return "🌟"
        case .tokens1M: return "🪙"
        case .tokens10M: return "💎"
        case .tokens100M: return "👑"
        }
    }

    var icon: String {
        switch self {
        case .messages1K: return "bubble.left.fill"
        case .messages10K: return "bubble.left.and.bubble.right.fill"
        case .messages100K: return "star.bubble.fill"
        case .sessions100: return "terminal.fill"
        case .sessions1K: return "desktopcomputer"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.circle.fill"
        case .tokens1M: return "circlebadge.fill"
        case .tokens10M: return "circlebadge.2.fill"
        case .tokens100M: return "crown.fill"
        }
    }

    var shortName: String {
        switch self {
        case .messages1K: return "1K"
        case .messages10K: return "10K"
        case .messages100K: return "100K"
        case .sessions100: return "100"
        case .sessions1K: return "1K"
        case .streak7: return "7d"
        case .streak30: return "30d"
        case .tokens1M: return "1M"
        case .tokens10M: return "10M"
        case .tokens100M: return "100M"
        }
    }

    func isAchieved(totalMessages: Int, totalSessions: Int, currentStreak: Int, totalTokens: Int) -> Bool {
        switch self {
        case .messages1K: return totalMessages >= threshold
        case .messages10K: return totalMessages >= threshold
        case .messages100K: return totalMessages >= threshold
        case .sessions100: return totalSessions >= threshold
        case .sessions1K: return totalSessions >= threshold
        case .streak7: return currentStreak >= threshold
        case .streak30: return currentStreak >= threshold
        case .tokens1M: return totalTokens >= threshold
        case .tokens10M: return totalTokens >= threshold
        case .tokens100M: return totalTokens >= threshold
        }
    }
}

// MARK: - Computed Properties Extension

extension UsageStats {
    var todayActivity: DailyActivity? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
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

    // MARK: Cache Analytics

    var cacheAnalytics: CacheAnalytics {
        let totalInput = modelUsage.values.reduce(0) {
            $0 + $1.inputTokens + $1.cacheReadInputTokens + $1.cacheCreationInputTokens
        }
        let cacheRead = modelUsage.values.reduce(0) { $0 + $1.cacheReadInputTokens }
        let hitRate = totalInput > 0 ? Double(cacheRead) / Double(totalInput) : 0
        return CacheAnalytics(hitRate: hitRate, savingsPercentage: Int(hitRate * 100))
    }

    // MARK: Peak Hour

    var peakHour: Int {
        let hourInts = hourCounts.compactMap { (key, value) -> (Int, Int)? in
            guard let hour = Int(key) else { return nil }
            return (hour, value)
        }
        return hourInts.max(by: { $0.1 < $1.1 })?.0 ?? 12
    }

    var peakHourFormatted: String {
        formatHour(peakHour)
    }

    // MARK: Value Estimation (based on public API pricing per 1M tokens)

    var estimatedValue: ValueMeter {
        var total = 0.0
        var breakdown: [String: Double] = [:]

        for (modelName, usage) in modelUsage {
            let rates = apiRates(for: modelName)
            let value = Double(usage.inputTokens) / 1_000_000.0 * rates.input
                + Double(usage.outputTokens) / 1_000_000.0 * rates.output
                + Double(usage.cacheReadInputTokens) / 1_000_000.0 * rates.cacheRead
            total += value
            breakdown[modelName] = value
        }

        return ValueMeter(estimatedValue: total, breakdown: breakdown)
    }

    private func apiRates(for model: String) -> (input: Double, output: Double, cacheRead: Double) {
        let name = model.lowercased()
        if name.contains("opus") {
            return (15.0, 75.0, 1.50)
        } else if name.contains("sonnet") {
            return (3.0, 15.0, 0.30)
        } else if name.contains("haiku") {
            return (0.80, 4.0, 0.08)
        }
        return (3.0, 15.0, 0.30) // default to Sonnet pricing
    }

    // MARK: Model Distribution

    var modelDistribution: [(name: String, tokens: Int)] {
        modelUsage.map { (name, usage) in
            (name: name, tokens: usage.totalTokens)
        }.sorted { $0.tokens > $1.tokens }
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

extension Double {
    var formattedCurrency: String {
        if self >= 100 {
            return String(format: "$%.0f", self)
        } else if self >= 10 {
            return String(format: "$%.1f", self)
        }
        return String(format: "$%.2f", self)
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

func formatHour(_ hour: Int) -> String {
    if hour == 0 { return "12am" }
    if hour < 12 { return "\(hour)am" }
    if hour == 12 { return "12pm" }
    return "\(hour - 12)pm"
}

// MARK: - Local History Storage

struct LocalHistory: Codable {
    var dailyStats: [String: DailyActivity] // date string -> activity
    var lastUpdated: Date
    var achievedMilestones: [String: String] // milestone rawValue -> date achieved

    enum CodingKeys: String, CodingKey {
        case dailyStats, lastUpdated, achievedMilestones
    }

    init() {
        self.dailyStats = [:]
        self.lastUpdated = Date()
        self.achievedMilestones = [:]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyStats = try container.decode([String: DailyActivity].self, forKey: .dailyStats)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        achievedMilestones = (try? container.decode([String: String].self, forKey: .achievedMilestones)) ?? [:]
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

    // MARK: Streak Calculation

    func calculateStreak() -> StreakData {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = calendar.startOfDay(for: Date())
        let todayString = formatter.string(from: today)
        let yesterdayString = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: today)!)

        // Determine starting point for current streak
        var currentStreak = 0
        let startDate: Date

        if dailyStats[todayString] != nil {
            startDate = today
        } else if dailyStats[yesterdayString] != nil {
            startDate = calendar.date(byAdding: .day, value: -1, to: today)!
        } else {
            // No recent activity
            let lastDate = dailyStats.keys.sorted().last ?? ""
            return StreakData(currentStreak: 0, longestStreak: calculateLongestStreak(), lastActiveDate: lastDate)
        }

        // Count current streak backwards
        var checkDate = startDate
        while true {
            let dateString = formatter.string(from: checkDate)
            if dailyStats[dateString] != nil {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        let longestStreak = calculateLongestStreak()
        let lastDate = dailyStats.keys.sorted().last ?? ""

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: max(longestStreak, currentStreak),
            lastActiveDate: lastDate
        )
    }

    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let allDates = dailyStats.keys
            .compactMap { formatter.date(from: $0) }
            .map { calendar.startOfDay(for: $0) }
            .sorted()

        guard !allDates.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<allDates.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: allDates[i - 1]),
               calendar.isDate(allDates[i], inSameDayAs: nextDay) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
        }

        return longest
    }

    // MARK: Week-over-Week

    func weekOverWeekChange() -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var thisWeek = 0
        var lastWeek = 0

        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let dateStr = formatter.string(from: date)
                thisWeek += dailyStats[dateStr]?.messageCount ?? 0
            }
            if let date = calendar.date(byAdding: .day, value: -(offset + 7), to: today) {
                let dateStr = formatter.string(from: date)
                lastWeek += dailyStats[dateStr]?.messageCount ?? 0
            }
        }

        guard lastWeek > 0 else { return nil }
        return Double(thisWeek - lastWeek) / Double(lastWeek) * 100
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
        let appDir = appSupport.appendingPathComponent("Lou", isDirectory: true)

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

    private static let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let localDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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

                guard let timestamp = entry.timestamp,
                      let parsedDate = Self.isoParser.date(from: timestamp) else { continue }
                let date = Self.localDateFormatter.string(from: parsedDate)

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

    // MARK: Streak

    func calculateStreak() -> StreakData {
        self.history.calculateStreak()
    }

    // MARK: Week-over-Week

    func weekOverWeekChange() -> Double? {
        self.history.weekOverWeekChange()
    }

    // MARK: Milestones

    func hasMilestone(_ type: MilestoneType) -> Bool {
        history.achievedMilestones[type.rawValue] != nil
    }

    func achieveMilestone(_ type: MilestoneType) {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        history.achievedMilestones[type.rawValue] = today
        save()
    }

    func achievedMilestoneDate(_ type: MilestoneType) -> String? {
        history.achievedMilestones[type.rawValue]
    }

    var allAchievedMilestones: [(type: MilestoneType, date: String)] {
        MilestoneType.allCases.compactMap { type in
            guard let date = history.achievedMilestones[type.rawValue] else { return nil }
            return (type: type, date: date)
        }
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
    @Published var streakData: StreakData = .empty
    @Published var weekOverWeek: Double? = nil
    @Published var newlyAchievedMilestones: [MilestoneType] = []

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

        // Request notification permission for milestones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                logger.info("Notification permission granted")
            }
        }

        // Load existing history immediately
        correctedDailyActivity = historyManager.getCorrectedActivity()
        streakData = historyManager.calculateStreak()
        weekOverWeek = historyManager.weekOverWeekChange()

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

                    // Check for empty file
                    if data.isEmpty {
                        throw NSError(domain: "Lou", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stats file is empty"])
                    }

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
                // Provide detailed decoding error info
                let errorDetail: String
                switch error {
                case .keyNotFound(let key, _):
                    errorDetail = "Missing field: \(key.stringValue)"
                case .typeMismatch(let type, let context):
                    errorDetail = "Type mismatch for \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): expected \(type)"
                case .valueNotFound(let type, let context):
                    errorDetail = "Missing value for \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): expected \(type)"
                case .dataCorrupted(let context):
                    errorDetail = "Corrupted data at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                @unknown default:
                    errorDetail = error.localizedDescription
                }
                loadedError = "stats-parse-error"
                logger.error("Failed to parse stats: \(errorDetail)")
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
            let streak = HistoryManager.shared.calculateStreak()
            let wow = HistoryManager.shared.weekOverWeekChange()

            // Check milestones
            var newMilestones: [MilestoneType] = []
            if let stats = loadedStats {
                for type in MilestoneType.allCases {
                    if !HistoryManager.shared.hasMilestone(type) &&
                       type.isAchieved(
                           totalMessages: stats.totalMessages,
                           totalSessions: stats.totalSessions,
                           currentStreak: streak.currentStreak,
                           totalTokens: stats.totalTokens
                       ) {
                        HistoryManager.shared.achieveMilestone(type)
                        newMilestones.append(type)
                    }
                }
            }

            // Capture for concurrency safety
            let achievedMilestones = newMilestones

            // Send notifications for new milestones (if enabled in preferences)
            let notificationsEnabled = UserDefaults.standard.object(forKey: "notifications_milestones") as? Bool ?? true
            if notificationsEnabled {
                for milestone in achievedMilestones {
                    let content = UNMutableNotificationContent()
                    content.title = "Lou Milestone! \(milestone.emoji)"
                    content.body = "You've achieved: \(milestone.displayName)"
                    content.sound = .default

                    let request = UNNotificationRequest(
                        identifier: "milestone-\(milestone.rawValue)",
                        content: content,
                        trigger: nil
                    )
                    try? await UNUserNotificationCenter.current().add(request)
                }
            }

            // Update UI on main thread
            await MainActor.run {
                self.stats = finalStats
                self.error = finalError
                self.liveTodayStats = finalLiveStats
                self.correctedDailyActivity = corrected
                self.streakData = streak
                self.weekOverWeek = wow
                self.lastUpdated = Date()
                self.refreshCount += 1
                self.isRefreshing = false
                if !achievedMilestones.isEmpty {
                    self.newlyAchievedMilestones = achievedMilestones
                }
                self.setupFileWatcher() // Restart file watcher with fresh descriptor
                self.setupSessionFileWatchers()
            }
        }
    }

    func loadLiveStats() {
        // Run on main thread to avoid background execution restrictions
        let newLiveStats = liveParser.getTodayStats()

        // Merge live stats with history
        if newLiveStats.messageCount > 0 {
            HistoryManager.shared.mergeLive(newLiveStats)
        }
        let corrected = HistoryManager.shared.getCorrectedActivity()
        let streak = HistoryManager.shared.calculateStreak()

        self.liveTodayStats = newLiveStats
        self.correctedDailyActivity = corrected
        self.streakData = streak
        // Only set up watchers if we don't have any yet (avoid file descriptor churn)
        if sessionFileWatchers.isEmpty {
            self.setupSessionFileWatchers()
        }
    }

    func clearMilestoneAlert() {
        newlyAchievedMilestones = []
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
        // Refresh every 15 seconds as a fallback
        liveRefreshTimer?.invalidate()
        liveRefreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.loadLiveStats()
        }
        // Ensure timer fires even during menu tracking
        if let timer = liveRefreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        fileWatcher?.stop()
        sessionFileWatchers.forEach { $0.stop() }
        liveRefreshTimer?.invalidate()
    }
}
