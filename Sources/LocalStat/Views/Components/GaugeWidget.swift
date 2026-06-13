import SwiftUI

/// A reusable circular gauge widget for displaying system stats (0-100%)
struct GaugeWidget: View {
    @Environment(ThemeManager.self) private var theme
    
    let title: String
    let percentage: Double // 0.0 to 1.0
    let valueText: String
    
    var lineWidth: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background track
                Circle()
                    .stroke(theme.surfaceAlt, lineWidth: lineWidth)
                
                // Foreground progress
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(percentage, 0.0), 1.0)))
                    .stroke(
                        theme.gaugeColor(for: percentage),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                
                // Center value
                Text(valueText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.text)
            }
            .frame(width: 54, height: 54)
            
            // Title
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.subtextPrimary)
        }
    }
}
