import SwiftUI

/// Main popover window contents
struct MenuBarView: View {
    @Environment(ThemeManager.self) private var theme
    
    // Services
    @Bindable var systemMonitor: SystemMonitor
    @Bindable var diskMonitor: DiskMonitor
    @Bindable var gpuMonitor: GPUMonitor
    @Bindable var networkMonitor: NetworkMonitor
    
    @Bindable var claudeTracker: ClaudeTracker
    @Bindable var geminiTracker: GeminiTracker
    @Bindable var copilotTracker: CopilotTracker
    
    @Bindable var processMonitor: NetworkProcessMonitor
    
    enum Tab {
        case system, network, ai, settings
    }
    
    @State private var selectedTab: Tab = .system
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LocalStat")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(theme.text)
                
                Spacer()
                
                // Custom Tab Bar
                HStack(spacing: 4) {
                    tabButton(icon: "chart.pie.fill", tab: .system)
                    tabButton(icon: "globe", tab: .network)
                    tabButton(icon: "sparkles.rectangle.stack.fill", tab: .ai)
                    tabButton(icon: "gearshape.fill", tab: .settings)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(theme.background)
            
            // Accent Line
            Rectangle()
                .fill(theme.accent)
                .frame(height: 2)
            
            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .system:
                        SystemMonitorView(
                            systemMonitor: systemMonitor,
                            diskMonitor: diskMonitor,
                            gpuMonitor: gpuMonitor,
                            networkMonitor: networkMonitor
                        )
                        
                    case .network:
                        NetworkView(
                            networkMonitor: networkMonitor,
                            processMonitor: processMonitor
                        )
                        
                    case .ai:
                        AIUsageView(
                            claudeTracker: claudeTracker,
                            geminiTracker: geminiTracker,
                            copilotTracker: copilotTracker
                        )
                        
                    case .settings:
                        SettingsView()
                    }
                }
                .padding(16)
            }
            .background(theme.background)
            
            // Footer
            HStack {
                Text(theme.selectedTheme.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.subtextPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.surface)
        }
        .frame(width: 420, height: 580)
    }
    
    private func tabButton(icon: String, tab: Tab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                .foregroundColor(selectedTab == tab ? theme.accent : theme.subtextSecondary)
                .frame(width: 32, height: 28)
                .background(selectedTab == tab ? theme.accent.opacity(0.15) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
