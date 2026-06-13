import SwiftUI

/// Display network speeds with up/down arrows
struct NetworkWidget: View {
    @Environment(ThemeManager.self) private var theme
    
    let bytesIn: Double
    let bytesOut: Double
    let isConnected: Bool
    let interfaceName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon & Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: iconForInterface(interfaceName))
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    Circle()
                        .fill(isConnected ? theme.success : theme.error)
                        .frame(width: 6, height: 6)
                }
                
                Text(interfaceName.isEmpty ? "Net" : interfaceName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.subtextSecondary)
            }
            .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            // Speeds
            VStack(alignment: .trailing, spacing: 4) {
                // Upload
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.warning)
                        .frame(width: 12)
                    
                    Text(formatSpeed(bytesOut))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.text)
                }
                
                // Download
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.success)
                        .frame(width: 12)
                    
                    Text(formatSpeed(bytesIn))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.text)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(theme.surfaceAlt.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func iconForInterface(_ name: String) -> String {
        if name == "Wi-Fi" {
            return "wifi"
        } else if name == "Ethernet" {
            return "network"
        } else if name == "Cellular" {
            return "antenna.radiowaves.left.and.right"
        } else {
            return "network"
        }
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1000 {
            return "\(Int(bytesPerSec)) B/s"
        } else if bytesPerSec < 1_000_000 {
            return String(format: "%.1f KB/s", bytesPerSec / 1000)
        } else if bytesPerSec < 1_000_000_000 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_000_000)
        } else {
            return String(format: "%.2f GB/s", bytesPerSec / 1_000_000_000)
        }
    }
}
