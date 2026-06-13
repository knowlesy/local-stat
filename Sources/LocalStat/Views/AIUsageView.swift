import SwiftUI

/// Section displaying AI Token Usage cards
struct AIUsageView: View {
    @Environment(ThemeManager.self) private var theme
    
    // Trackers
    @Bindable var claudeTracker: ClaudeTracker
    @Bindable var geminiTracker: GeminiTracker
    @Bindable var copilotTracker: CopilotTracker
    @State private var timeToRefresh: Int = 60
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Usage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
                
                Spacer()
                
                Text("Refreshes in \(timeToRefresh)s")
                    .font(.system(size: 10))
                    .foregroundColor(theme.subtextSecondary)
                
                Button(action: {
                    refreshAll()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.subtextPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .onReceive(timer) { _ in
                if timeToRefresh > 0 {
                    timeToRefresh -= 1
                } else {
                    refreshAll()
                }
            }
            
            VStack(spacing: 8) {
                TokenCard(
                    serviceName: claudeTracker.serviceName,
                    shortLabel: claudeTracker.shortLabel,
                    iconName: claudeTracker.iconName,
                    session: claudeTracker.currentSession,
                    isAvailable: claudeTracker.isAvailable,
                    setupURL: claudeTracker.setupURL
                )
                
                TokenCard(
                    serviceName: geminiTracker.serviceName,
                    shortLabel: geminiTracker.shortLabel,
                    iconName: geminiTracker.iconName,
                    session: geminiTracker.currentSession,
                    isAvailable: geminiTracker.isAvailable,
                    setupURL: geminiTracker.setupURL
                )
                
                TokenCard(
                    serviceName: copilotTracker.serviceName,
                    shortLabel: copilotTracker.shortLabel,
                    iconName: copilotTracker.iconName,
                    session: copilotTracker.currentSession,
                    isAvailable: copilotTracker.isAvailable,
                    setupURL: copilotTracker.setupURL
                )
            }
        }
        .padding(16)
        .background(theme.surfaceAlt.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func refreshAll() {
        timeToRefresh = 60
        Task {
            await claudeTracker.refresh()
            await geminiTracker.refresh()
            await copilotTracker.refresh()
        }
    }
}
