import SwiftUI

// MARK: - Preferences Window Controller

class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView()
        let hostingView = NSHostingView(rootView: preferencesView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClaudeVibes Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

// MARK: - Preferences View

struct PreferencesView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gear", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Sections", icon: "square.stack", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 20)

            // Content
            Group {
                if selectedTab == 0 {
                    GeneralTabContent()
                } else {
                    SectionsTabContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 420, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.claudePink.opacity(0.8) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Preview Thumbnail

struct ThemePreviewThumbnail: View {
    let theme: ThemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Mini UI preview
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.15))
                        .frame(width: 110, height: 80)

                    VStack(spacing: 4) {
                        // Header area with "Today" mock
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.primary)
                                .frame(width: 24, height: 6)
                            Spacer()
                            Circle()
                                .fill(theme.primaryLight.opacity(0.6))
                                .frame(width: 5, height: 5)
                        }
                        .padding(.horizontal, 8)

                        // Progress bar mock
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryDark, theme.primary, theme.primaryLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 8)
                        }
                        .padding(.horizontal, 8)

                        // Stats row mock
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { i in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(theme.primary.opacity(0.7))
                                        .frame(width: 16, height: 3)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 12, height: 2)
                                }
                            }
                        }

                        // Bar chart mock
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach([0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3], id: \.self) { height in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(theme.primary.opacity(0.8))
                                    .frame(width: 8, height: CGFloat(height) * 16)
                            }
                        }
                        .frame(height: 16)
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? theme.primary.opacity(0.5) : Color.clear, radius: 8)

                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab

struct GeneralTabContent: View {
    @AppStorage("selectedTheme") private var selectedTheme = ThemePreset.claudePink.rawValue
    @AppStorage("vibeCategories") private var vibeCategoriesString = "all"
    @AppStorage("notifications_milestones") private var notifyMilestones = true

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Theme Section
            PreferenceSection(title: "Theme") {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ThemePreset.allCases, id: \.rawValue) { theme in
                        ThemePreviewThumbnail(
                            theme: theme,
                            isSelected: selectedTheme == theme.rawValue
                        ) {
                            selectedTheme = theme.rawValue
                        }
                    }
                }
            }

            // Vibes Section
            PreferenceSection(title: "Vibe Messages") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Category:", selection: $vibeCategoriesString) {
                        Text("All Categories").tag("all")
                        Divider()
                        ForEach(VibeCategory.allCases, id: \.rawValue) { category in
                            Text(category.displayName).tag(category.rawValue)
                        }
                    }
                    .frame(maxWidth: 200)

                    Text("\(currentVibes.count) messages in rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Notifications Section
            PreferenceSection(title: "Notifications") {
                Toggle("Show milestone achievements", isOn: $notifyMilestones)
                    .toggleStyle(.switch)
            }

            Spacer()
        }
        .padding(24)
    }

    private var currentVibes: [String] {
        let categories = VibeMessageProvider.parseCategories(vibeCategoriesString)
        return VibeMessageProvider.messages(for: categories)
    }
}

// MARK: - Sections Tab

struct SectionsTabContent: View {
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
        VStack(alignment: .leading, spacing: 16) {
            PreferenceSection(title: "Visible Sections") {
                VStack(alignment: .leading, spacing: 2) {
                    SectionToggle(title: "Quick Insights", subtitle: "Streak, cache rate, tools, edits", isOn: $showQuickInsights)
                    SectionToggle(title: "Peak Hours", subtitle: "24-hour activity chart", isOn: $showPeakHours)
                    SectionToggle(title: "Cache Efficiency", subtitle: "Token savings percentage", isOn: $showEfficiency)
                    SectionToggle(title: "Activity Chart", subtitle: "Last 7 days bar chart", isOn: $showActivity)
                    SectionToggle(title: "30-Day Trend", subtitle: "Sparkline with week-over-week", isOn: $showTrend)
                    SectionToggle(title: "All Time Stats", subtitle: "Messages, sessions, longest", isOn: $showAllTime)
                    SectionToggle(title: "Value Meter", subtitle: "Estimated API cost", isOn: $showValueMeter)
                    SectionToggle(title: "Token Usage", subtitle: "Model breakdown", isOn: $showTokenUsage)
                    SectionToggle(title: "Milestones", subtitle: "Achievement badges", isOn: $showMilestones)
                }
            }

            Text("Today's Activity is always visible.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Section Toggle

struct SectionToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(isOn ? 0.08 : 0.03))
        )
    }
}

// MARK: - Preference Section

struct PreferenceSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.06))
                )
        }
    }
}
