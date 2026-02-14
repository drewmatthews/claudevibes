import SwiftUI

@main
struct LouApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var statsManager = StatsManager()

    init() {
        migrateThemeDefaults()
    }

    private func migrateThemeDefaults() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "theme") == "claudePink" {
            defaults.set("rosePink", forKey: "theme")
        }
        if defaults.string(forKey: "selectedTheme") == "claudePink" {
            defaults.set("rosePink", forKey: "selectedTheme")
        }
    }

    var body: some Scene {
        // Normal mode: menu bar extra
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

// MARK: - App Delegate for Screenshot Mode

class AppDelegate: NSObject, NSApplicationDelegate {
    var screenshotWindow: NSWindow?
    var statsManager: StatsManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for screenshot mode
        if CommandLine.arguments.contains("--screenshot") {
            showScreenshotWindow()
        }
    }

    @MainActor func showScreenshotWindow() {
        statsManager = StatsManager()

        // Get output path from arguments (--output /path/to/file.png)
        var outputPath = "/tmp/lou_screenshot.png"
        if let outputIndex = CommandLine.arguments.firstIndex(of: "--output"),
           outputIndex + 1 < CommandLine.arguments.count {
            outputPath = CommandLine.arguments[outputIndex + 1]
        }

        // Create the SwiftUI view
        let contentView = ScreenshotWindowView(statsManager: statsManager!)

        // Create a window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "Lou Screenshot"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Store reference
        screenshotWindow = window

        // Wait for content to render, then capture and exit
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.captureAndSave(window: window, to: outputPath)
        }
    }

    @MainActor func captureAndSave(window: NSWindow, to path: String) {
        guard let contentView = window.contentView else {
            print("ERROR: No content view")
            NSApplication.shared.terminate(nil)
            return
        }

        // Get the bounds of the content
        let bounds = contentView.bounds

        // Create bitmap representation
        guard let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            print("ERROR: Could not create bitmap")
            NSApplication.shared.terminate(nil)
            return
        }

        contentView.cacheDisplay(in: bounds, to: bitmapRep)

        // Convert to PNG
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("ERROR: Could not create PNG data")
            NSApplication.shared.terminate(nil)
            return
        }

        // Write to file
        let url = URL(fileURLWithPath: path)
        do {
            // Create directory if needed
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try pngData.write(to: url)
            print("SCREENSHOT_SAVED:\(path)")

            // Write path to temp file for script
            try path.write(toFile: "/tmp/lou_screenshot_path", atomically: true, encoding: .utf8)
        } catch {
            print("ERROR: Could not save screenshot: \(error)")
        }

        // Exit the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - Screenshot Window View

struct ScreenshotWindowView: View {
    @ObservedObject var statsManager: StatsManager

    var body: some View {
        MenuBarView(statsManager: statsManager)
            .background(VisualEffectBackground())
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(20) // Padding around for shadow visibility
    }
}

// MARK: - Visual Effect Background (matches menu bar popover style)

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
