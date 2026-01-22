import SwiftUI

@main
struct ClaudeUsageMenuApp: App {
    @StateObject private var statsManager = StatsManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(statsManager: statsManager)
        } label: {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
        }
        .menuBarExtraStyle(.window)
    }
}
