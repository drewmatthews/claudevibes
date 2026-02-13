import SwiftUI
import Combine

class AppSettings: ObservableObject {
    // Theme
    @AppStorage("theme") var themeName: String = "rosePink" {
        didSet { objectWillChange.send() }
    }

    // Section visibility
    @AppStorage("visible_peakHours") var showPeakHours: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_efficiency") var showEfficiency: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_activity") var showActivity: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_sparkline") var showSparkline: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_allTime") var showAllTime: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_valueMeter") var showValueMeter: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_tokenUsage") var showTokenUsage: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_milestones") var showMilestones: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("visible_quickInsights") var showQuickInsights: Bool = true {
        didSet { objectWillChange.send() }
    }

    // Notifications
    @AppStorage("notify_milestones") var notifyMilestones: Bool = true {
        didSet { objectWillChange.send() }
    }

    // Vibe messages
    @AppStorage("vibes_enabled") var vibesEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("vibes_categories") var vibeCategories: String = "all" {
        didSet { objectWillChange.send() }
    }

    // Refresh
    @AppStorage("refresh_interval") var refreshInterval: Double = 30.0 {
        didSet { objectWillChange.send() }
    }

    // Value meter display mode
    @AppStorage("value_meter_display") var valueMeterDisplay: String = "total" {
        didSet { objectWillChange.send() }
    }

    // Computed theme accessor
    var theme: ThemePreset {
        ThemePreset(rawValue: themeName) ?? .rosePink
    }

    // Computed vibe category set
    var enabledVibeCategories: Set<VibeCategory> {
        get { VibeMessageProvider.parseCategories(vibeCategories) }
        set { vibeCategories = VibeMessageProvider.categoryString(from: newValue) }
    }
}
