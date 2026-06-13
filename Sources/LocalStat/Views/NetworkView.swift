import SwiftUI
import Charts

struct NetworkView: View {
    @Environment(ThemeManager.self) private var theme
    
    @Bindable var networkMonitor: NetworkMonitor
    @Bindable var processMonitor: NetworkProcessMonitor
    
    @AppStorage("enableClipboardCommands") private var enableClipboardCommands: Bool = true
    
    // Derived property for sorting processes
    private var sortedProcesses: [NetworkProcess] {
        processMonitor.processes.sorted {
            ($0.currentBytesIn + $0.currentBytesOut) > ($1.currentBytesIn + $1.currentBytesOut)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        guard enableClipboardCommands else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header: Interfaces and IPs
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("IP Addresses")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.text)
                    Spacer()
                    if networkMonitor.isConnected {
                        Text("Connected: \(networkMonitor.interfaceType)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.success)
                    } else {
                        Text("Disconnected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.error)
                    }
                }
                
                if let publicIP = networkMonitor.publicIP {
                    HStack {
                        Text("Public:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.subtextSecondary)
                        Text(publicIP)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(theme.subtextPrimary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { copyToClipboard("curl icanhazip.com") }
                    .help(enableClipboardCommands ? "Click to copy public IP command" : "")
                }
                
                if networkMonitor.localIPs.isEmpty {
                    Text("No local IPs found")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(theme.subtextSecondary)
                } else {
                    HStack {
                        Text("Local:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.subtextSecondary)
                        Text(networkMonitor.localIPs.joined(separator: ", "))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(theme.subtextPrimary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { copyToClipboard("ifconfig") }
                    .help(enableClipboardCommands ? "Click to copy local interface command" : "")
                }
            }
            .padding(12)
            .background(theme.surfaceAlt.opacity(0.3))
            .cornerRadius(8)
            
            // Graph: Up/Down Last 30 Minutes
            VStack(alignment: .leading, spacing: 12) {
                Text("Traffic History (30m)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
                
        if networkMonitor.history.isEmpty {
                    Text("Waiting for data...")
                        .font(.system(size: 11))
                        .foregroundColor(theme.subtextSecondary)
                        .frame(height: 120, alignment: .center)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart {
                        // Download Series (Blue)
                        ForEach(networkMonitor.history) { point in
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Download", point.bytesIn),
                                series: .value("Type", "Download")
                            )
                            .foregroundStyle(theme.blue.opacity(0.3))
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Download", point.bytesIn),
                                series: .value("Type", "Download")
                            )
                            .foregroundStyle(theme.blue)
                            .interpolationMethod(.catmullRom)
                        }
                        
                        // Upload Series (Red)
                        ForEach(networkMonitor.history) { point in
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Upload", point.bytesOut),
                                series: .value("Type", "Upload")
                            )
                            .foregroundStyle(theme.error.opacity(0.3))
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Upload", point.bytesOut),
                                series: .value("Type", "Upload")
                            )
                            .foregroundStyle(theme.error)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(theme.surfaceAlt)
                            AxisValueLabel() {
                                if let doubleValue = value.as(Double.self) {
                                    Text(formatSpeed(doubleValue))
                                        .font(.system(size: 9))
                                        .foregroundColor(theme.subtextSecondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(theme.surfaceAlt)
                        }
                    }
                    .frame(height: 120)
                }
            }
            .padding(12)
            .background(theme.surfaceAlt.opacity(0.3))
            .cornerRadius(8)
            
            // Top Processes
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Network Processes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
                
                if sortedProcesses.isEmpty {
                    Text("No active processes detected.")
                        .font(.system(size: 11))
                        .foregroundColor(theme.subtextSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(sortedProcesses.prefix(10)) { proc in
                            HStack {
                                Text(proc.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(theme.text)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 8) {
                                    Text("↓ " + formatSpeed(proc.currentBytesIn))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(theme.blue)
                                        .frame(width: 65, alignment: .trailing)
                                    
                                    Text("↑ " + formatSpeed(proc.currentBytesOut))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(theme.error)
                                        .frame(width: 65, alignment: .trailing)
                                }
                            }
                            .padding(.vertical, 6)
                            
                            Divider().background(theme.surfaceAlt)
                        }
                    }
                }
            }
            .padding(12)
            .background(theme.surfaceAlt.opacity(0.3))
            .cornerRadius(8)
            
            Spacer()
        }
        .onAppear {
            networkMonitor.start()
            processMonitor.start()
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
