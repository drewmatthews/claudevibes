import SwiftUI

// MARK: - Claude Pink Color

extension Color {
    static let claudePink = Color(red: 0.85, green: 0.55, blue: 0.55)
    static let claudePinkLight = Color(red: 0.92, green: 0.70, blue: 0.70)
    static let claudePinkDark = Color(red: 0.75, green: 0.45, blue: 0.45)
}

struct MenuBarView: View {
    @ObservedObject var statsManager: StatsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let stats = statsManager.stats {
                StatsContentView(stats: stats, refreshCount: statsManager.refreshCount, liveTodayStats: statsManager.liveTodayStats, correctedDailyActivity: statsManager.correctedDailyActivity)
            } else if let error = statsManager.error {
                ErrorView(message: error)
            } else {
                LoadingView()
            }

            Divider()

            FooterView(statsManager: statsManager)
        }
        .padding(12)
        .frame(width: 300)
        .background(Color.black.opacity(0.40))
    }
}

// MARK: - Stats Content

struct StatsContentView: View {
    let stats: UsageStats
    var refreshCount: Int = 0
    var liveTodayStats: LiveTodayStats?
    var correctedDailyActivity: [DailyActivity] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.claudePink)
                Text("ClaudeVibes")
                    .font(.headline)
                    .foregroundColor(.claudePink)
                Spacer()
            }

            Divider()

            // Today's Activity - Prominent (using live stats!)
            TodayCard(stats: stats, seed: refreshCount, liveStats: liveTodayStats)

            // Recent Activity Chart (using corrected history data)
            Divider()
            SectionHeader(icon: "calendar.badge.clock", title: "Activity by Day")
            RecentActivityChart(dailyActivity: correctedDailyActivity, liveTodayStats: liveTodayStats)

            Divider()

            // Overall Stats
            SectionHeader(icon: "chart.line.uptrend.xyaxis", title: "All Time")
            StatRow(label: "Sessions", value: "\(stats.totalSessions)")
            StatRow(label: "Messages", value: stats.totalMessages.formattedCompact)
            StatRow(label: "Since", value: stats.formattedFirstSession)

            Divider()

            // Model Usage
            SectionHeader(icon: "cpu", title: "Token Usage")
            ForEach(Array(stats.modelUsage.keys.sorted()), id: \.self) { modelName in
                if let usage = stats.modelUsage[modelName] {
                    ModelUsageRow(modelName: modelName, usage: usage)
                }
            }

            Divider()

            // Longest Session
            SectionHeader(icon: "trophy.fill", title: "Longest Session")
            HStack {
                Text("\(stats.longestSession.messageCount.formatted()) messages")
                    .font(.caption)
                Spacer()
                Text(stats.longestSessionDurationFormatted)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.claudePink)
            }
        }
    }
}

// MARK: - Today Card

struct TodayCard: View {
    let stats: UsageStats
    var seed: Int = 0
    var liveStats: LiveTodayStats?

    private let vibes = [
        // Classic vibes
        "Brewing ideas together ☕",
        "Your AI pair programmer 🤝",
        "Making magic happen ✨",
        "Code flows like poetry 🎭",
        "Building the future 🚀",
        "In the zone together 🎯",
        "Crafting with care 🎨",
        "Turning thoughts into code 💭",
        "Your coding companion 🌟",
        "Creating something beautiful 🌸",

        // Gen Z energy
        "It's giving productive ✨",
        "Main character energy today 💅",
        "Slay the code, queen 👑",
        "No thoughts, just vibes 🧘",
        "Absolutely unhinged (affectionate) 🫶",
        "This is our Roman Empire 🏛️",
        "Living our best compile 💫",
        "The vibes are immaculate 🌊",
        "Ate and left no crumbs 🍽️",
        "Understood the assignment ✅",
        "It's giving senior dev energy 💼",
        "Core memory unlocked 🧠",
        "Real ones know 🤫",
        "Lowkey highkey slaying 🗡️",
        "No cap, we're cooking 🧑‍🍳",
        "Bussin' respectfully 🚌",
        "That's valid 💯",
        "We move different 🏃",
        "Hits different at 2am 🌙",
        "Rent free in the codebase 🏠",

        // Programmer humor
        "Works on my machine ™️",
        "No bugs, only features 🐛",
        "console.log('we got this') 📝",
        "git commit -m 'vibes' 🎸",
        "sudo make me productive 🔐",
        "404: Procrastination not found 🔍",
        "Segfault? Never heard of her 💅",
        "Compiling... and thriving 🔄",
        "Stack overflow of good vibes 📚",
        "Merge conflict? We talk it out 🤝",
        "The code review of champions 🏆",
        "Bug-free and carefree 🦋",
        "Cache invalidated, vibes validated ✓",
        "Polymorphic excellence 🧬",
        "O(1) lookup on happiness 📊",
        "Memory leak? More like memory peek 👀",
        "Production ready feelings 🚀",
        "The refactor arc begins 📖",
        "Clean code, clean mind 🧹",
        "Deploying dopamine 💉",

        // Wholesome affirmations
        "You're doing amazing 💖",
        "Progress over perfection 📈",
        "Every expert was once a beginner 🌱",
        "Trust the process 🙏",
        "You've got this 💪",
        "Small steps, big dreams 🦶",
        "Today's struggle, tomorrow's strength 🏋️",
        "Believe in your code 🌟",
        "Growth happens here 🌿",
        "Your potential is infinite ∞",
        "Mistakes are just plot twists 📚",
        "You belong in tech 🫂",
        "Imposter syndrome is a liar 🎭",
        "Celebrate the small wins 🎉",
        "Rest is productive too 😴",
        "Your ideas matter 💡",
        "Keep showing up 🚪",
        "You're learning, not failing 📚",
        "One line at a time ⌨️",
        "The journey is the destination 🛤️",

        // Chaotic/silly
        "Feral but functional 🐺",
        "Chaotic good energy ⚡",
        "Unhinged and on schedule 📅",
        "Goblin mode: activated 👺",
        "Slightly feral, fully capable 🦝",
        "Professional yapper 🗣️",
        "Built different (legally) 🏗️",
        "Cracked at code fr fr 🥚",
        "Delulu is the solulu 🔮",
        "This is fine 🔥🐕",
        "Chaos coordinator 🎪",
        "Professional overthinker 🤔",
        "Elite napper between deploys 😴",
        "Menace to tech debt 😈",
        "Feral with a keyboard 🐱",
        "Unserious but successful 🃏",
        "Silly goose, serious code 🪿",
        "Chaotic neutral programmer 🎲",
        "Agent of controlled chaos 🌪️",
        "Powered by spite and coffee ☕",

        // Coffee/energy
        "Caffeinated and motivated ☕",
        "Running on coffee and hope 🙏",
        "Espresso yourself 🫘",
        "Bean there, coded that ☕",
        "Fuel level: optimal ⛽",
        "Energy drink era 🥤",
        "Matcha-powered dev 🍵",
        "Hydrated and coding 💧",
        "Third coffee energy 🫠",
        "Redbull and regrets 🪽",
        "Decaf? Don't know her ☕",
        "Liquid inspiration loading... 🫗",
        "Brewing brilliance ☕",
        "Stimulant-adjacent productivity 💊",
        "Peak caffeine hours ⏰",

        // AI partnership
        "Human + AI synergy 🤖❤️",
        "Prompting and prospering 📝",
        "Context window: maximized 📐",
        "Token-efficient teamwork 🪙",
        "Vibing with the model 🎵",
        "The machine and I agree 🤝",
        "Neural networks, real results 🧠",
        "LLM? More like LFG 🚀",
        "Pair programming: evolved 🧬",
        "We're in this together 🫂",
        "Prompt engineer era 🔧",
        "The algorithm and I are besties 💕",
        "Training data who? 📊",
        "Tokens well spent 🎰",
        "Co-creating with AI 🎨",

        // Existential/philosophical
        "Shipping code, finding meaning 🚢",
        "Existential crisis: postponed 📆",
        "Debugging life one day at a time 🔍",
        "We're all just 1s and 0s anyway 🔢",
        "Is this the simulation? 🤔",
        "Consciousness: still loading ⏳",
        "We live in a society.js 🏙️",
        "Time is a flat circle (buffer) ⭕",
        "What if the real code was the friends we made? 👥",
        "Existence precedes exceptions 📜",

        // Seasonal/time
        "Morning code hits different ☀️",
        "Midnight oil: burning 🪔",
        "Golden hour commits 🌅",
        "Sunday scaries? Not here 📅",
        "Friday deploy confidence 💪",
        "Monday morning clarity 🌤️",
        "Witching hour productivity 🧙",
        "Post-lunch renaissance 🍝",
        "2am breakthrough pending ⏰",
        "Weekend warrior mode 🗡️",

        // Internet culture
        "Based and code-pilled 💊",
        "Touch grass later, ship now 🌱",
        "Chronically online, professionally offline 📱",
        "This goes hard 🔥",
        "Peak content right here 📈",
        "Canon event in progress 📖",
        "That's so coded of you 💅",
        "Lore being written 📜",
        "Era: productive 🏛️",
        "Streaming consciousness 📺",
        "Parasocial with my IDE 💻",
        "The algorithm provides 🎁",
        "Meme-powered development 🖼️",
        "Certified hood classic 🏆",
        "Real and true 💯",

        // Food metaphors
        "Cooking up something good 👨‍🍳",
        "This code is bussin 🍔",
        "Chef's kiss commits 💋",
        "Fresh out the oven 🥖",
        "Secret sauce: added 🥫",
        "Marinating on this idea 🥩",
        "Recipe for success 📝",
        "Extra spicy feature incoming 🌶️",
        "Comfort food coding 🍜",
        "Gourmet git history 🍽️",

        // Nature vibes
        "Touching grass mentally 🌱",
        "Grass is greener when you ship ☘️",
        "Natural born debugger 🐞",
        "Blooming where planted 🌷",
        "Rooted in good practices 🌳",
        "Weathering the code storm ⛈️",
        "Sunshine on the keyboard ☀️",
        "Calm before the deploy 🌅",
        "Seeds of innovation 🌻",
        "Growing every day 🌾",

        // Music vibes
        "In my coding era 🎵",
        "The beat drops when I ship 🎧",
        "Lo-fi beats to code to 🎹",
        "Main stage energy 🎤",
        "Remix the codebase 🔁",
        "Harmony in the merge 🎼",
        "Rhythm of the keyboard ⌨️",
        "Coding symphony 🎻",
        "Drop the feature like a beat 🎛️",
        "Headphones: on. World: out 🎧",

        // Self-care
        "Ergonomic excellence 🪑",
        "Posture check passed 🧘",
        "Hydration nation 💧",
        "Screen break appreciation 👁️",
        "Snack time, best time 🍿",
        "Stretch it out 🤸",
        "Work-life harmony 🎭",
        "Mental health: monitored 🧠",
        "Boundaries: respected 🚧",
        "Joy in the journey 🛤️",

        // Confidence boosters
        "Built for this 🏗️",
        "Different gravy 🥄",
        "Simply better 📈",
        "Top tier performance 🏅",
        "Elite mentality 🧠",
        "Can't be stopped 🚫",
        "Levels to this 📊",
        "Next level unlocked 🔓",
        "Premium vibes only 💎",
        "S-tier coding session 🎮",

        // Chill vibes
        "Cool, calm, compiling 🧊",
        "Easy breezy beautiful 💨",
        "Smooth operator 🎷",
        "Zero stress, all progress 😌",
        "Peaceful productivity 🕊️",
        "Tranquil typing 🪷",
        "Mellow yellow coding 🟡",
        "Serene scenes 🏞️",
        "Unbothered excellence 💅",
        "Cozy code corner 🛋️",

        // Iconic quotes remixed
        "Move fast, fix things 🔧",
        "To code or not to code? Code. 🎭",
        "I think, therefore I commit 🧠",
        "Keep calm and git push 🇬🇧",
        "Live, laugh, localhost 🏠",
        "Hakuna matata, no blockers 🦁",
        "To infinity and production 🚀",
        "May the source be with you ⚔️",
        "I came, I saw, I deployed 🏛️",
        "Hello, is it bugs you're looking for? 🎵",

        // Random delightful
        "Pog moment incoming 😮",
        "Wizard hours activated 🧙",
        "Galaxy brain: online 🌌",
        "Speedrunning productivity 🏃",
        "Achievement unlocked 🏆",
        "Legendary status 🐉",
        "Epic coding montage 🎬",
        "Final boss: this feature 👾",
        "Side quest: completed 📋",
        "Loading: greatness ⏳",
        "New high score 🕹️",
        "Combo multiplier: active ✖️",
        "Critical hit on that bug 🎯",
        "Power-up collected 🍄",
        "Bonus round energy 🎰",
        "Player two has entered 🎮",
        "GG, moving on 🤝",
        "No save scumming needed 💾",
        "Tutorial completed 📖",
        "Endgame content unlocked 🔓"
    ]

    private var vibeIndex: Int {
        // Use seed (refreshCount) to pick a consistent vibe until next refresh
        abs(seed) % vibes.count
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
                // No activity yet today
                Text("No activity yet today")
                    .font(.caption)
                    .foregroundColor(.secondary)

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

                        Text(day.messageCount > 0 ? day.messageCount.formattedCompact : (day.isFuture ? "–" : "0"))
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
            let maxValue = data.max() ?? 1
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
                Text("Use Claude Code to start tracking your vibes ✨")
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

    var body: some View {
        VStack(spacing: 10) {
            // About section above
            if showAbout {
                VStack(spacing: 4) {
                    Link("ClaudeVibes v1.1 (Alpha)", destination: URL(string: "http://claudevibes.drewmatthews.ca")!)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    HStack(spacing: 0) {
                        Link("Drew", destination: URL(string: "https://drewmatthews.ca")!)
                            .foregroundColor(.claudePink)
                        Text(" made this with Claude Code ✨")
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
