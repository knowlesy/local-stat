import SwiftUI

/// Compact card for AI tokens
struct TokenCard: View {
    @Environment(ThemeManager.self) private var theme
    
    let serviceName: String
    let shortLabel: String
    let iconName: String
    let session: TokenSession?
    let isAvailable: Bool
    let setupURL: URL?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header
            Button(action: {
                if isAvailable {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // Icon + Status Dot
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: iconName)
                            .font(.system(size: 16))
                            .foregroundColor(isAvailable ? theme.accent : theme.subtextSecondary)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(theme.surface, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                    
                    // Label
                    Text(shortLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isAvailable ? theme.text : theme.subtextSecondary)
                        .frame(width: 32, alignment: .leading)
                    
                    if isAvailable {
                        let totalTokens = (session?.inputTokens ?? 0) + (session?.outputTokens ?? 0)
                        let dailyLimit = 1_000_000 // Placeholder 1M token budget
                        let percentage = min(Double(totalTokens) / Double(dailyLimit), 1.0)
                        let remaining = dailyLimit - totalTokens
                        
                        // Usage Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.surfaceAlt)
                                
                                if totalTokens > 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.success, theme.warning],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * CGFloat(percentage), 2))
                                }
                            }
                        }
                        .frame(height: 8)
                        
                        // Percentage and Trend
                        HStack(spacing: 2) {
                            if totalTokens > 0 {
                                Text("\(remaining / 1000)k left")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.text)
                            } else {
                                Text("Idle")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.text)
                                    .help("Local usage reported only")
                            }
                        }
                    } else {
                        Text("Not Detected")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.subtextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Button("Setup") {
                            if let url = setupURL {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.accent.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isExpanded ? theme.surfaceAlt : theme.surface)
            }
            .buttonStyle(.plain)
            
            // Expanded Detail View
            if isExpanded {
                VStack(spacing: 8) {
                    Divider().background(theme.surfaceAlt)
                    
                    if let session = session {
                        HStack {
                            Text(session.model ?? "Unknown Model")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.subtextPrimary)
                            
                            Spacer()
                            
                            if let cost = session.costEstimate {
                                Text(String(format: "$%.3f", cost))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.warning)
                            }
                        }
                        
                        // Token breakdown bars
                        HStack(spacing: 12) {
                            tokenStatCol(title: "IN", count: session.inputTokens, color: theme.blue)
                            tokenStatCol(title: "OUT", count: session.outputTokens, color: theme.accent)
                            if session.cacheReadTokens > 0 {
                                tokenStatCol(title: "CACHE", count: session.cacheReadTokens, color: theme.success)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        HStack {
                            Text("No local data found.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.subtextSecondary)
                            
                            Spacer()
                            
                            Button("View Dashboard") {
                                if let url = setupURL {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accent.opacity(0.1))
                            .cornerRadius(4)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.surface)
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.surfaceAlt, lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        guard isAvailable else { return theme.subtextSecondary }
        return session != nil ? theme.success : theme.warning
    }
    
    private func tokenStatCol(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtextSecondary)
            }
            
            Text(formatTokenCount(count))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
