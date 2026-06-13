import SwiftUI

@main
struct LocalStatApp: App {
    // Core Services
    @State private var themeManager = ThemeManager()
    @State private var systemMonitor = SystemMonitor()
    @State private var diskMonitor = DiskMonitor()
    @State private var gpuMonitor = GPUMonitor()
    @State private var networkMonitor = NetworkMonitor()
    
    // AI Trackers
    @State private var claudeTracker = ClaudeTracker()
    @State private var geminiTracker = GeminiTracker()
    @State private var copilotTracker = CopilotTracker()
    
    @State private var processMonitor = NetworkProcessMonitor()
    
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon: Bool = true
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "cpu"
    
    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView(
                systemMonitor: systemMonitor,
                diskMonitor: diskMonitor,
                gpuMonitor: gpuMonitor,
                networkMonitor: networkMonitor,
                claudeTracker: claudeTracker,
                geminiTracker: geminiTracker,
                copilotTracker: copilotTracker,
                processMonitor: processMonitor
            )
            .environment(themeManager)
        } label: {
            // Icon to display in the macOS menu bar
            Image(systemName: menuBarIconName)
        }
        .menuBarExtraStyle(.window)
    }
}
