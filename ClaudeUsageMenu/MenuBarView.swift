import SwiftUI

// MARK: - Theme Colors (dynamic, reads from UserDefaults)

extension Color {
    private static var currentTheme: ThemePreset {
        let rawValue = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemePreset.claudePink.rawValue
        return ThemePreset(rawValue: rawValue) ?? .claudePink
    }

    static var claudePink: Color { currentTheme.primary }
    static var claudePinkLight: Color { currentTheme.primaryLight }
    static var claudePinkDark: Color { currentTheme.primaryDark }
}

struct MenuBarView: View {
    @ObservedObject var statsManager: StatsManager
    @AppStorage("selectedTheme") private var selectedTheme = ThemePreset.claudePink.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let stats = statsManager.stats {
                StatsContentView(
                    stats: stats,
                    refreshCount: statsManager.refreshCount,
                    liveTodayStats: statsManager.liveTodayStats,
                    correctedDailyActivity: statsManager.correctedDailyActivity,
                    streakData: statsManager.streakData,
                    weekOverWeek: statsManager.weekOverWeek,
                    newMilestones: statsManager.newlyAchievedMilestones,
                    onDismissMilestones: { statsManager.clearMilestoneAlert() }
                )
            } else if let error = statsManager.error {
                ErrorView(message: error)
            } else {
                LoadingView()
            }

            Divider()

            FooterView(statsManager: statsManager)
        }
        .id(selectedTheme) // Force full re-render when theme changes
        .padding(12)
        .frame(width: 300)
        .background(Color.black.opacity(0.40))
        .preferredColorScheme(.dark)
        .onAppear {
            // Refresh live stats when menu opens
            statsManager.loadLiveStats()
        }
    }
}

// MARK: - Stats Content

struct StatsContentView: View {
    let stats: UsageStats
    var refreshCount: Int = 0
    var liveTodayStats: LiveTodayStats?
    var correctedDailyActivity: [DailyActivity] = []
    var streakData: StreakData = .empty
    var weekOverWeek: Double? = nil
    var newMilestones: [MilestoneType] = []
    var onDismissMilestones: (() -> Void)? = nil

    @AppStorage("show_quickInsights") private var showQuickInsights = true
    @AppStorage("show_peakHours") private var showPeakHours = true
    @AppStorage("show_efficiency") private var showEfficiency = true
    @AppStorage("show_activity") private var showActivity = true
    @AppStorage("show_trend") private var showTrend = true
    @AppStorage("show_allTime") private var showAllTime = true
    @AppStorage("show_valueMeter") private var showValueMeter = true
    @AppStorage("show_tokenUsage") private var showTokenUsage = true
    @AppStorage("show_milestones") private var showMilestones = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with streak badge
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.claudePink)
                Text("ClaudeVibes")
                    .font(.headline)
                    .foregroundColor(.claudePink)
                Spacer()
                if streakData.currentStreak > 0 {
                    StreakBadge(streak: streakData.currentStreak)
                }
            }

            // Milestone celebration banner
            if !newMilestones.isEmpty {
                MilestoneCelebration(milestones: newMilestones, onDismiss: onDismissMilestones)
            }

            Divider()

            // Today's Activity - always shown
            TodayCard(stats: stats, seed: refreshCount, liveStats: liveTodayStats)

            if showQuickInsights {
                QuickInsightsRow(
                    streak: streakData.currentStreak,
                    cacheRate: stats.cacheAnalytics.savingsPercentage,
                    toolCalls: liveTodayStats?.toolCallCount ?? stats.todayActivity?.toolCallCount ?? 0,
                    fileEdits: liveTodayStats?.fileEditCount ?? 0
                )
            }

            if showPeakHours {
                Divider()
                SectionHeader(icon: "clock.fill", title: "Peak Hours")
                PeakHoursView(hourCounts: stats.hourCounts)
            }

            if showEfficiency {
                Divider()
                SectionHeader(icon: "gauge.with.dots.needle.33percent", title: "Efficiency")
                CacheEffectivenessView(analytics: stats.cacheAnalytics)
            }

            if showActivity {
                Divider()
                SectionHeader(icon: "calendar.badge.clock", title: "Activity")
                RecentActivityChart(dailyActivity: correctedDailyActivity, liveTodayStats: liveTodayStats)
            }

            if showTrend && correctedDailyActivity.count > 7 {
                SparklineTrend(activity: correctedDailyActivity, weekOverWeek: weekOverWeek)
            }

            if showAllTime {
                Divider()
                SectionHeader(icon: "chart.line.uptrend.xyaxis", title: "All Time")
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        MiniStatItem(label: "Messages", value: stats.totalMessages.formattedCompact)
                        MiniStatItem(label: "Sessions", value: "\(stats.totalSessions)")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        MiniStatItem(label: "Since", value: stats.formattedFirstSession)
                        MiniStatItem(label: "Longest", value: stats.longestSessionDurationFormatted)
                    }
                }
            }

            if showValueMeter {
                if !showAllTime { Divider() }
                ValueMeterRow(value: stats.estimatedValue)
            }

            if showTokenUsage {
                Divider()
                SectionHeader(icon: "cpu", title: "Token Usage")
                VStack(spacing: 8) {
                    if stats.modelDistribution.count > 1 {
                        ModelDistributionView(distribution: stats.modelDistribution)
                    }

                    ForEach(Array(stats.modelUsage.keys.sorted()), id: \.self) { modelName in
                        if let usage = stats.modelUsage[modelName] {
                            ModelUsageRow(modelName: modelName, usage: usage)
                        }
                    }
                }
            }

            if showMilestones {
                let achieved = HistoryManager.shared.allAchievedMilestones
                if !achieved.isEmpty {
                    Divider()
                    SectionHeader(icon: "trophy.fill", title: "Milestones")
                    MilestonesGridView(achieved: achieved)
                }
            }
        }
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 3) {
            Text("\u{1F525}")
                .font(.system(size: 11))
            Text("\(streak) day\(streak == 1 ? "" : "s")")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.claudePink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.claudePink.opacity(0.15))
        .cornerRadius(10)
    }
}

// MARK: - Milestone Celebration

struct MilestoneCelebration: View {
    let milestones: [MilestoneType]
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            ForEach(milestones, id: \.rawValue) { milestone in
                HStack {
                    Text(milestone.emoji)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Milestone Unlocked!")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.claudePink)
                        Text(milestone.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.claudePink.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.claudePink.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Insights Row

struct QuickInsightsRow: View {
    let streak: Int
    let cacheRate: Int
    let toolCalls: Int
    let fileEdits: Int

    var body: some View {
        HStack(spacing: 0) {
            InsightChip(icon: "flame.fill", value: "\(streak)d", label: "streak")
            Spacer()
            InsightChip(icon: "arrow.triangle.2.circlepath", value: "\(cacheRate)%", label: "cache")
            Spacer()
            InsightChip(icon: "wrench.fill", value: "\(toolCalls)", label: "tools")
            if fileEdits > 0 {
                Spacer()
                InsightChip(icon: "doc.fill", value: "\(fileEdits)", label: "edits")
            }
        }
        .padding(.horizontal, 4)
    }
}

struct InsightChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(.claudePink)
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Peak Hours View

struct PeakHoursView: View {
    let hourCounts: [String: Int]

    private var maxCount: Int {
        max(hourCounts.values.max() ?? 1, 1)
    }

    private var peakHour: Int {
        hourCounts.compactMap { (key, value) -> (Int, Int)? in
            guard let hour = Int(key) else { return nil }
            return (hour, value)
        }
        .max(by: { $0.1 < $1.1 })?.0 ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Vertical bar chart — one bar per hour
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(0..<24, id: \.self) { hour in
                    hourBar(hour: hour)
                }
            }
            .frame(height: 36)

            // Time labels
            HStack {
                Text("12a")
                Spacer()
                Text("6a")
                Spacer()
                Text("12p")
                Spacer()
                Text("6p")
                Spacer()
                Text("12a")
            }
            .font(.system(size: 8))
            .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func hourBar(hour: Int) -> some View {
        let count = hourCounts["\(hour)"] ?? 0
        let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
        let isPeak = hour == peakHour && count > 0

        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(count > 0
                    ? (isPeak ? Color.claudePink : Color.claudePink.opacity(0.5))
                    : Color.secondary.opacity(0.1))
                .frame(height: max(count > 0 ? fraction * 36 : 2, 2))
        }
    }
}

// MARK: - Cache Effectiveness View

struct CacheEffectivenessView: View {
    let analytics: CacheAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.claudePinkDark, .claudePink, .claudePinkLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * analytics.hitRate, 4))
                }
            }
            .frame(height: 10)

            HStack {
                Text("Cache hit rate")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(analytics.savingsPercentage)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.claudePink)
            }

            Text("Saving ~\(analytics.savingsPercentage)% on context reprocessing")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Sparkline Trend (30-day)

struct SparklineTrend: View {
    let activity: [DailyActivity]
    let weekOverWeek: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("30-day trend")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let wow = weekOverWeek {
                    HStack(spacing: 2) {
                        Image(systemName: wow >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8))
                        Text("\(abs(Int(wow)))% w/w")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(wow >= 0 ? .green : .orange)
                }
            }

            // Sparkline
            ActivitySparkline(
                data: activity.map { $0.messageCount },
                color: .claudePink
            )
            .frame(height: 24)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Model Distribution View

struct ModelDistributionView: View {
    let distribution: [(name: String, tokens: Int)]

    private var total: Int {
        distribution.reduce(0) { $0 + $1.tokens }
    }

    private var colors: [Color] {
        [.claudePink, .claudePinkLight, .claudePinkDark, .purple.opacity(0.6)]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mini donut chart
            DonutChart(
                segments: distribution.enumerated().map { (i, item) in
                    (value: Double(item.tokens), color: colors[i % colors.count])
                }
            )
            .frame(width: 50, height: 50)

            // Legend
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(distribution.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colors[index % colors.count])
                            .frame(width: 6, height: 6)
                        Text(shortModelName(item.name))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(total > 0 ? "\(Int(Double(item.tokens) / Double(total) * 100))%" : "0%")
                            .font(.system(size: 9, weight: .medium))
                    }
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func shortModelName(_ name: String) -> String {
        if name.contains("opus") { return "Opus 4.5" }
        if name.contains("sonnet") { return "Sonnet 4" }
        if name.contains("haiku") { return "Haiku 3.5" }
        return name
    }
}

// MARK: - Donut Chart

struct DonutChart: View {
    let segments: [(value: Double, color: Color)]

    var body: some View {
        ZStack {
            ForEach(computedSegments.indices, id: \.self) { i in
                Circle()
                    .trim(from: computedSegments[i].start, to: computedSegments[i].end)
                    .stroke(computedSegments[i].color, style: StrokeStyle(lineWidth: 7, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private var computedSegments: [(start: CGFloat, end: CGFloat, color: Color)] {
        let total = segments.reduce(0.0) { $0 + $1.value }
        guard total > 0 else { return [] }

        var result: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var current: CGFloat = 0

        for segment in segments {
            let proportion = CGFloat(segment.value / total)
            let gap: CGFloat = segments.count > 1 ? 0.005 : 0
            result.append((start: current + gap, end: current + proportion - gap, color: segment.color))
            current += proportion
        }

        return result
    }
}

// MARK: - Value Meter Row

struct ValueMeterRow: View {
    let value: ValueMeter

    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .font(.caption)
                .foregroundColor(.claudePink)
            Text("API value")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("\u{2248}\(value.estimatedValue.formattedCurrency)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.claudePink)
        }
        .padding(.vertical, 2)

        Text("Estimate based on public API pricing")
            .font(.system(size: 8))
            .foregroundColor(.secondary.opacity(0.5))
    }
}

// MARK: - Milestones Grid View

struct MilestonesGridView: View {
    let achieved: [(type: MilestoneType, date: String)]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(achieved, id: \.type.rawValue) { item in
                    HStack(spacing: 4) {
                        Text(item.type.emoji)
                            .font(.system(size: 12))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.type.displayName)
                                .font(.system(size: 9, weight: .medium))
                            Text(item.date)
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Progress toward next milestone
            if let next = nextMilestone {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 8))
                        .foregroundColor(.claudePink)
                    Text("Next: \(next.displayName)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var nextMilestone: MilestoneType? {
        let achievedSet = Set(achieved.map { $0.type })
        return MilestoneType.allCases.first { !achievedSet.contains($0) }
    }
}

// MARK: - Mini Stat Item

struct MiniStatItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Today Card

struct TodayCard: View {
    let stats: UsageStats
    var seed: Int = 0
    var liveStats: LiveTodayStats?

    @AppStorage("vibeCategories") private var vibeCategoriesString = "all"

    private var vibes: [String] {
        let categories = VibeMessageProvider.parseCategories(vibeCategoriesString)
        let messages = VibeMessageProvider.messages(for: categories)
        return messages.isEmpty ? VibeMessageProvider.allMessages : messages
    }

    private var vibeIndex: Int {
        let count = max(vibes.count, 1)
        return abs(seed) % count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.claudePink)
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let live = liveStats, live.messageCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let live = liveStats, live.messageCount > 0 {
                // Use live stats (real-time from session files)
                HStack(spacing: 12) {
                    TodayStat(value: "\(live.messageCount)", label: "msgs")
                    TodayStat(value: "\(live.sessionCount)", label: "sessions")
                    TodayStat(value: "\(live.toolCallCount)", label: "tools")
                }

                // Session timer + token summary
                SessionTimerRow(liveStats: live, stats: stats)

                Text(vibes[vibeIndex])
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.claudePink.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            } else if let today = stats.todayActivity {
                // Fall back to cached stats
                HStack(spacing: 12) {
                    TodayStat(value: "\(today.messageCount)", label: "msgs")
                    TodayStat(value: "\(today.sessionCount)", label: "sessions")
                    TodayStat(value: "\(today.toolCallCount)", label: "tools")
                }

                Text(vibes[vibeIndex])
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.claudePink.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            } else {
                // No data loaded yet — show zeroes instead of blank
                HStack(spacing: 12) {
                    TodayStat(value: "0", label: "msgs")
                    TodayStat(value: "0", label: "sessions")
                    TodayStat(value: "0", label: "tools")
                }

                Text(vibes[vibeIndex])
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.claudePink.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.claudePink.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Session Timer Row

struct SessionTimerRow: View {
    let liveStats: LiveTodayStats
    let stats: UsageStats

    var body: some View {
        HStack(spacing: 8) {
            if let earliest = liveStats.earliestTimestamp {
                // Live session timer using TimelineView
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = context.date.timeIntervalSince(earliest)
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 9))
                            .foregroundColor(.claudePink)
                        Text(formatDuration(elapsed))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.claudePink)
                    }
                }
            }

            if liveStats.earliestTimestamp != nil {
                Text("\u{00B7}")
                    .foregroundColor(.secondary)
            }

            // Token count for today (prefer live stats, fall back to cached)
            let todayTokens: Int = {
                if liveStats.totalTokens > 0 {
                    return liveStats.totalTokens
                }
                if let today = stats.todayActivity {
                    return stats.dailyModelTokens
                        .filter { $0.date == today.date }
                        .flatMap { $0.tokensByModel.values }
                        .reduce(0, +)
                }
                return 0
            }()

            if todayTokens > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "number")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text("\(todayTokens.formattedCompact) tokens")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // Deep work indicator (45+ min)
            if let earliest = liveStats.earliestTimestamp {
                let elapsed = Date().timeIntervalSince(earliest)
                if elapsed >= 2700 { // 45 min
                    HStack(spacing: 2) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                        Text("Deep")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(seconds, 0))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, secs)
        }
        return String(format: "%dm %02ds", minutes, secs)
    }
}

// MARK: - Recent Activity Chart

struct RecentActivityChart: View {
    let dailyActivity: [DailyActivity]
    var liveTodayStats: LiveTodayStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Subtitle row
            HStack {
                Text("Last 7 days (rolling)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(totalMessages.formattedCompact) msgs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Bar chart - rolling 7 days
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(rolling7Days, id: \.date) { day in
                    VStack(spacing: 4) {
                        ActivityBar(
                            value: day.messageCount,
                            maxValue: maxMessages,
                            isFuture: day.isFuture,
                            isToday: day.isToday
                        )

                        Text(day.messageCount > 0 ? day.messageCount.formattedCompact : (day.isFuture ? "\u{2013}" : "0"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(day.isFuture ? .secondary.opacity(0.3) : (day.isToday ? .claudePink : .secondary))

                        Text(day.dayLabel)
                            .font(.system(size: 9))
                            .foregroundColor(day.isFuture ? .secondary.opacity(0.3) : (day.isToday ? .claudePink : .secondary))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 65)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var totalMessages: Int {
        // Sum from rolling7Days to include live stats for today
        rolling7Days.filter { !$0.isFuture }.reduce(0) { $0 + $1.messageCount }
    }

    private var rolling7Days: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Create a lookup dictionary for existing data
        var dataByDate: [String: Int] = [:]
        for activity in dailyActivity {
            dataByDate[activity.date] = activity.messageCount
        }

        // Generate 7 days: 5 past + today + 1 future
        var days: [DayData] = []
        for offset in -5...1 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                let dateString = formatter.string(from: date)
                let dayOfMonth = calendar.component(.day, from: date)
                let isFuture = offset > 0
                let isToday = offset == 0

                // Use live stats for today if available, otherwise use cached data
                let messageCount: Int
                if isToday, let live = liveTodayStats, live.messageCount > 0 {
                    messageCount = live.messageCount
                } else {
                    messageCount = dataByDate[dateString] ?? 0
                }

                days.append(DayData(
                    date: dateString,
                    dayLabel: "\(dayOfMonth)",
                    messageCount: messageCount,
                    isFuture: isFuture,
                    isToday: isToday
                ))
            }
        }
        return days
    }

    private var maxMessages: Int {
        max(rolling7Days.filter { !$0.isFuture }.map { $0.messageCount }.max() ?? 1, 1)
    }
}

struct DayData: Identifiable {
    let date: String
    let dayLabel: String
    let messageCount: Int
    let isFuture: Bool
    let isToday: Bool

    var id: String { date }
}

struct ActivityBar: View {
    let value: Int
    let maxValue: Int
    var isFuture: Bool = false
    var isToday: Bool = false

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(height: barHeight)
        }
    }

    private var barColor: Color {
        if isFuture {
            return Color.secondary.opacity(0.15)
        } else if isToday {
            return Color.claudePink
        } else if value > 0 {
            return Color.claudePinkLight
        } else {
            return Color.secondary.opacity(0.15)
        }
    }

    private var barHeight: CGFloat {
        if isFuture {
            return 8 // skeleton height
        }
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 35
        guard maxValue > 0, value > 0 else { return minHeight }
        let height = CGFloat(value) / CGFloat(maxValue) * maxHeight
        return max(height, minHeight)
    }
}

struct TodayStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.claudePink)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Components

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.claudePink)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct ModelUsageRow: View {
    let modelName: String
    let usage: ModelUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Model name and total
            HStack {
                Text(shortModelName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.claudePink)
                Spacer()
                Text(usage.totalTokens.formattedCompact + " total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Stacked bar chart
            TokenStackedBar(usage: usage)
                .clipped()

            // Legend with values
            HStack(spacing: 0) {
                TokenLegendItem(color: .claudePink, label: "In", value: usage.inputTokens)
                Spacer()
                TokenLegendItem(color: .claudePinkLight, label: "Out", value: usage.outputTokens)
                Spacer()
                TokenLegendItem(color: .claudePinkDark, label: "Cache", value: usage.cacheReadInputTokens)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var shortModelName: String {
        if modelName.contains("opus") {
            return "Opus 4.5"
        } else if modelName.contains("sonnet") {
            return "Sonnet 4"
        } else if modelName.contains("haiku") {
            return "Haiku 3.5"
        }
        return modelName
    }
}

// MARK: - Token Stacked Bar Chart

struct TokenStackedBar: View {
    let usage: ModelUsage
    private let minSegmentWidth: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                // Input tokens
                if usage.inputTokens > 0 {
                    Rectangle()
                        .fill(Color.claudePink)
                        .frame(width: segmentWidth(for: usage.inputTokens, in: geo.size.width))
                }

                // Output tokens
                if usage.outputTokens > 0 {
                    Rectangle()
                        .fill(Color.claudePinkLight)
                        .frame(width: segmentWidth(for: usage.outputTokens, in: geo.size.width))
                }

                // Cache tokens
                if usage.cacheReadInputTokens > 0 {
                    Rectangle()
                        .fill(Color.claudePinkDark)
                        .frame(width: segmentWidth(for: usage.cacheReadInputTokens, in: geo.size.width))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 12)
    }

    private var total: Int {
        usage.inputTokens + usage.outputTokens + usage.cacheReadInputTokens
    }

    private var activeSegments: Int {
        [usage.inputTokens, usage.outputTokens, usage.cacheReadInputTokens].filter { $0 > 0 }.count
    }

    private func segmentWidth(for value: Int, in totalWidth: CGFloat) -> CGFloat {
        guard total > 0, value > 0 else { return 0 }

        // Reserve minimum space for each active segment
        let reservedWidth = minSegmentWidth * CGFloat(activeSegments)
        let spacingTotal = CGFloat(max(activeSegments - 1, 0)) * 1
        let flexibleWidth = max(totalWidth - reservedWidth - spacingTotal, 0)

        // Distribute flexible width proportionally, add minimum
        let proportionalExtra = (CGFloat(value) / CGFloat(total)) * flexibleWidth
        return minSegmentWidth + proportionalExtra
    }
}

struct TokenLegendItem: View {
    let color: Color
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value.formattedCompact)
                .font(.system(size: 9, weight: .medium))
        }
    }
}

// MARK: - Activity Sparkline (for daily activity)

struct ActivitySparkline: View {
    let data: [Int]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 1, 1)
            let stepWidth = geometry.size.width / CGFloat(max(data.count - 1, 1))

            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepWidth
                    let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Dots at each point
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                let x = CGFloat(index) * stepWidth
                let y = geometry.size.height - (CGFloat(value) / CGFloat(max(data.max() ?? 1, 1))) * geometry.size.height

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - Mini Bar Chart

struct MiniBarChart: View {
    let data: [Int]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 1, 1)
            let barWidth = (geometry.size.width - CGFloat(data.count - 1) * 2) / CGFloat(data.count)

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.3 + 0.7 * Double(value) / Double(maxValue)))
                        .frame(width: barWidth, height: max(CGFloat(value) / CGFloat(maxValue) * geometry.size.height, 2))
                }
            }
        }
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            if message == "no-stats-file" {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.claudePink)
                Text("Welcome to ClaudeVibes!")
                    .font(.headline)
                Text("No Claude Code stats found yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Use Claude Code to start tracking your vibes \u{2728}")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if message == "stats-parse-error" {
                Image(systemName: "doc.badge.gearshape")
                    .font(.title2)
                    .foregroundColor(.claudePink)
                Text("Stats Format Changed")
                    .font(.headline)
                Text("Claude Code's stats format may have updated.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Check for a ClaudeVibes update, or try refreshing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.claudePink)
                Text("Error Loading Stats")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.claudePink)
            Text("Loading stats...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct FooterView: View {
    @ObservedObject var statsManager: StatsManager
    @State private var showAbout = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "v\(version)"
    }

    var body: some View {
        VStack(spacing: 10) {
            // About section above
            if showAbout {
                VStack(spacing: 4) {
                    Link("ClaudeVibes \(appVersion)", destination: URL(string: "http://claudevibes.drewmatthews.ca")!)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    HStack(spacing: 0) {
                        Link("Drew", destination: URL(string: "https://drewmatthews.ca")!)
                            .foregroundColor(.claudePink)
                        Text(" made this with Claude Code \u{2728}")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption2)
                    Text("Not affiliated with Anthropic")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
            }

            // Button row - everything in one line
            HStack {
                Button {
                    showAbout.toggle()
                } label: {
                    Image(systemName: showAbout ? "info.circle.fill" : "info.circle")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Button {
                    PreferencesWindowController.shared.showWindow()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Text(lastUpdatedText)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    statsManager.loadStats()
                } label: {
                    if statsManager.isRefreshing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 50)
                    } else {
                        Text("Refresh")
                    }
                }
                .buttonStyle(HoverButtonStyle(color: .claudePink))
                .disabled(statsManager.isRefreshing)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(HoverButtonStyle(color: .secondary))
            }
        }
    }

    private var lastUpdatedText: String {
        if statsManager.isRefreshing {
            return "Refreshing..."
        }
        if let lastUpdated = statsManager.lastUpdated {
            return "Updated \(timeFormatter.string(from: lastUpdated))"
        }
        return ""
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Hover Button Style

struct HoverButtonStyle: ButtonStyle {
    let color: Color
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(configuration.isPressed ? color.opacity(0.5) : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovering ? color.opacity(configuration.isPressed ? 0.2 : 0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

#Preview {
    MenuBarView(statsManager: StatsManager())
}
