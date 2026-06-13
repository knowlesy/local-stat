import SwiftUI
import Charts

/// A compact sparkline widget displaying an icon, a tiny chart, and two metrics
struct SparklineWidget: View {
    @Environment(ThemeManager.self) private var theme
    
    let title: String
    let iconName: String
    
    let isConnected: Bool // for network status
    let showConnectionDot: Bool
    
    // Series 1 (e.g. Upload, Write)
    let primaryValue: Double
    let primaryIcon: String
    let primaryColor: Color
    let primaryData: [(Date, Double)]
    
    // Series 2 (e.g. Download, Read)
    let secondaryValue: Double
    let secondaryIcon: String
    let secondaryColor: Color
    let secondaryData: [(Date, Double)]
    
    let formatSpeed: (Double) -> String
    
    var body: some View {
        HStack(spacing: 8) {
            // Left: Icon & Label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    if showConnectionDot {
                        Circle()
                            .fill(isConnected ? theme.success : theme.error)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtextSecondary)
                    .lineLimit(1)
            }
            .frame(width: 44, alignment: .leading)
            
            // Middle: Sparkline Chart
            Chart {
                ForEach(secondaryData, id: \.0) { point in
                    LineMark(
                        x: .value("Time", point.0),
                        y: .value("Val", point.1),
                        series: .value("Type", "Secondary")
                    )
                    .foregroundStyle(secondaryColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(primaryData, id: \.0) { point in
                    LineMark(
                        x: .value("Time", point.0),
                        y: .value("Val", point.1),
                        series: .value("Type", "Primary")
                    )
                    .foregroundStyle(primaryColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: .automatic(includesZero: true))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: 24)
            .frame(maxWidth: .infinity)
            
            // Right: Values
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: primaryIcon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(primaryColor)
                        .frame(width: 10)
                    Text(formatSpeed(primaryValue))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.text)
                }
                HStack(spacing: 4) {
                    Image(systemName: secondaryIcon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(secondaryColor)
                        .frame(width: 10)
                    Text(formatSpeed(secondaryValue))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.text)
                }
            }
            .frame(width: 65, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surfaceAlt.opacity(0.3))
        .cornerRadius(6)
    }
}
