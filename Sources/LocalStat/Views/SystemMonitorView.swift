import SwiftUI

/// Grid of hardware system monitors
struct SystemMonitorView: View {
    @Environment(ThemeManager.self) private var theme
    
    // Services
    @Bindable var systemMonitor: SystemMonitor
    @Bindable var diskMonitor: DiskMonitor
    @Bindable var gpuMonitor: GPUMonitor
    @Bindable var networkMonitor: NetworkMonitor
    
    @AppStorage("enableClipboardCommands") private var enableClipboardCommands: Bool = true
    @AppStorage("useBtopCommands") private var useBtopCommands: Bool = false
    
    // 3 columns for top row
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Row: CPU, Memory, GPU
            HStack(spacing: 16) {
                GaugeWidget(
                    title: "CPU",
                    percentage: systemMonitor.cpuUsage,
                    valueText: "\(Int(systemMonitor.cpuUsage * 100))%"
                )
                .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "top -o cpu") }
                .help(enableClipboardCommands ? "Click to copy CPU command" : "")
                
                GaugeWidget(
                    title: "MEM",
                    percentage: systemMonitor.memoryPressure,
                    valueText: formatMemory(systemMonitor.memoryUsed)
                )
                .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "top -o mem") }
                .help(enableClipboardCommands ? "Click to copy MEM command" : "")
                
                if gpuMonitor.isAvailable {
                    GaugeWidget(
                        title: "GPU",
                        percentage: gpuMonitor.gpuUsage,
                        valueText: "\(Int(gpuMonitor.gpuUsage * 100))%"
                    )
                    .onTapGesture { copyToClipboard("sudo powermetrics --samplers gpu_power -n 1") }
                    .help(enableClipboardCommands ? "Click to copy GPU command" : "")
                }
            }
            .padding(.horizontal, 16)
            
            Divider().background(theme.surfaceAlt)
            
            // Network Block
            SparklineWidget(
                title: networkMonitor.interfaceType.uppercased(),
                iconName: networkMonitor.interfaceType == "Wi-Fi" ? "wifi" : "network",
                isConnected: networkMonitor.isConnected,
                showConnectionDot: true,
                primaryValue: networkMonitor.bytesOutPerSecond,
                primaryIcon: "arrow.up",
                primaryColor: theme.error,
                primaryData: networkMonitor.history.map { ($0.timestamp, $0.bytesOut) },
                secondaryValue: networkMonitor.bytesInPerSecond,
                secondaryIcon: "arrow.down",
                secondaryColor: theme.blue,
                secondaryData: networkMonitor.history.map { ($0.timestamp, $0.bytesIn) },
                formatSpeed: formatDiskSpeed
            )
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "nettop -m route -L 0") }
            .help(enableClipboardCommands ? "Click to copy Network command" : "")
            
            Divider().background(theme.surfaceAlt)
            
            // Disk Space Row
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("DISK SPACE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.subtextPrimary)
                    Spacer()
                    Text("\(Int(diskMonitor.freeSpace)) GB free")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.subtextSecondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.surfaceAlt)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.gaugeColor(for: diskMonitor.usagePercentage))
                            .frame(width: geo.size.width * CGFloat(diskMonitor.usagePercentage))
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "sudo du -h -d 2 ~/ 2>/dev/null | sort -rh | head -n 30") }
            .help(enableClipboardCommands ? "Click to copy Disk Space command" : "")
            
            Divider().background(theme.surfaceAlt)
            
            // Disk I/O Blocks (Bandwidth and Latency stacked vertically)
            VStack(spacing: 8) {
                SparklineWidget(
                    title: "DISK I/O",
                    iconName: "internaldrive",
                    isConnected: true,
                    showConnectionDot: false,
                    primaryValue: diskMonitor.writeBytesPerSec,
                    primaryIcon: "w.circle.fill",
                    primaryColor: theme.error,
                    primaryData: diskMonitor.history.map { ($0.timestamp, $0.writeBytes) },
                    secondaryValue: diskMonitor.readBytesPerSec,
                    secondaryIcon: "r.circle.fill",
                    secondaryColor: theme.blue,
                    secondaryData: diskMonitor.history.map { ($0.timestamp, $0.readBytes) },
                    formatSpeed: formatDiskSpeed
                )
                .contentShape(Rectangle())
                .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "iostat -w 1") }
                .help(enableClipboardCommands ? "Click to copy Disk I/O command" : "")
                
                SparklineWidget(
                    title: "LATENCY",
                    iconName: "clock",
                    isConnected: true,
                    showConnectionDot: false,
                    primaryValue: diskMonitor.writeLatencyMs,
                    primaryIcon: "w.circle.fill",
                    primaryColor: theme.error,
                    primaryData: diskMonitor.history.map { ($0.timestamp, $0.writeLatency) },
                    secondaryValue: diskMonitor.readLatencyMs,
                    secondaryIcon: "r.circle.fill",
                    secondaryColor: theme.blue,
                    secondaryData: diskMonitor.history.map { ($0.timestamp, $0.readLatency) },
                    formatSpeed: { val in String(format: "%.1f ms", val) }
                )
                .contentShape(Rectangle())
                .onTapGesture { copyToClipboard(useBtopCommands ? "btop" : "ping 8.8.8.8") }
                .help(enableClipboardCommands ? "Click to copy Latency command" : "")
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(theme.surface)
        .cornerRadius(12)
        .onAppear {
            systemMonitor.start()
            diskMonitor.start()
            gpuMonitor.start()
            networkMonitor.start()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        guard enableClipboardCommands else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_000_000_000.0 // Apple uses base-10
        if gb >= 10 {
            return String(format: "%.0f GB", gb)
        } else if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", Double(bytes) / 1_000_000.0)
        }
    }
    
    private func formatDiskSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1_000_000 {
            return String(format: "%.1f KB/s", bytesPerSec / 1000)
        } else {
            return String(format: "%.1f MB/s", bytesPerSec / 1_000_000)
        }
    }
}
