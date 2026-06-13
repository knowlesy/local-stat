import Foundation
import Network

struct NetworkDataPoint: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let bytesIn: Double
    let bytesOut: Double
}

/// Hardware-level monitor for Network usage using sysctl/netstat and NWPathMonitor
@Observable
@MainActor
final class NetworkMonitor: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    var bytesInPerSecond: Double = 0.0
    var bytesOutPerSecond: Double = 0.0
    
    var isConnected: Bool = false
    var interfaceType: String = "Unknown"
    var interfaceName: String = ""
    var localIPs: [String] = []
    var publicIP: String? = nil
    
    var history: [NetworkDataPoint] = []
    
    var isRunning: Bool = false
    
    // MARK: - Private State
    
    private var timer: Timer?
    private var publicIPTimer: Timer?
    private let refreshInterval: TimeInterval
    private let maxHistoryPoints: Int
    
    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var previousTimestamp: CFAbsoluteTime = 0
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.localstat.networkmonitor")
    
    // MARK: - Initialization
    
    init(refreshInterval: TimeInterval = 3.0) {
        self.refreshInterval = refreshInterval
        // 30 minutes of history = (30 * 60) / refreshInterval
        self.maxHistoryPoints = Int((30.0 * 60.0) / refreshInterval)
        setupPathMonitor()
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Initial fetch
        updateStats()
        fetchPublicIP()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }
            Task { @MainActor in
                self.updateStats()
            }
        }
        
        // Public IP timer (every 10 minutes)
        publicIPTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }
            self.fetchPublicIP()
        }
        
        pathMonitor.start(queue: monitorQueue)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        publicIPTimer?.invalidate()
        publicIPTimer = nil
        pathMonitor.cancel()
        isRunning = false
    }
    
    // MARK: - Internal Monitoring
    
    private func fetchPublicIP() {
        Task.detached { [weak self] in
            guard let url = URL(string: "https://api.ipify.org") else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let ip = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        self?.publicIP = ip
                    }
                }
            } catch {
                print("Failed to fetch public IP: \(error)")
            }
        }
    }
    
    // MARK: - Internal Monitoring
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.interfaceType = "Wi-Fi"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.interfaceType = "Ethernet"
                } else if path.usesInterfaceType(.cellular) {
                    self?.interfaceType = "Cellular"
                } else if path.usesInterfaceType(.loopback) {
                    self?.interfaceType = "Loopback"
                } else {
                    self?.interfaceType = "Other"
                }
            }
        }
    }
    
    private func updateStats() {
        Task.detached { [weak self] in
            // Run netstat -ib to get interface statistics
            let task = Process()
            task.launchPath = "/usr/sbin/netstat"
            task.arguments = ["-ib"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe() // ignore errors
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        self?.parseNetstatOutput(output)
                    }
                }
            } catch {
                print("Failed to run netstat: \(error)")
            }
        }
    }
    
    private func parseNetstatOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        guard lines.count > 1 else { return }
        
        var totalBytesIn: UInt64 = 0
        var totalBytesOut: UInt64 = 0
        var activeInterface = ""
        
        // Skip header
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Format: Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
            // Indices:  0     1      2             3                   4     5         6        7     8         9     10
            
            guard columns.count >= 10 else { continue }
            let name = columns[0]
            
            // Filter out loopback and non-active interfaces (heuristics)
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                // Determine which column contains bytes. 
                // Sometimes MAC address shifts columns, so we parse backwards from end or use index 6 and 9 as base
                // A more robust approach looks for the columns that actually parse as UInt64 and are large
                
                // netstat output is notoriously variable. Let's find the Ibytes and Obytes columns
                // Typically Ibytes is column 6 (or 7 if MAC address is present)
                // We'll just sum all large numbers found in the row for active data interfaces
                
                var rowBytesIn: UInt64 = 0
                var rowBytesOut: UInt64 = 0
                
                if let ibytes = UInt64(columns[6]), let obytes = UInt64(columns[9]) {
                    rowBytesIn = ibytes
                    rowBytesOut = obytes
                } else if columns.count > 10, let ibytes = UInt64(columns[7]), let obytes = UInt64(columns[10]) {
                    rowBytesIn = ibytes
                    rowBytesOut = obytes
                }
                
                if rowBytesIn > 0 || rowBytesOut > 0 {
                    totalBytesIn += rowBytesIn
                    totalBytesOut += rowBytesOut
                    if activeInterface.isEmpty {
                        activeInterface = name
                    }
                }
            }
        }
        
        let currentTimestamp = CFAbsoluteTimeGetCurrent()
        
        if previousTimestamp > 0 {
            let timeDelta = currentTimestamp - previousTimestamp
            if timeDelta > 0 {
                // Handle potential wrap-around and ignore the very first tick to prevent a massive spike
                var bytesInDelta: UInt64 = 0
                var bytesOutDelta: UInt64 = 0
                
                if previousBytesIn > 0 && totalBytesIn >= previousBytesIn {
                    bytesInDelta = totalBytesIn - previousBytesIn
                }
                if previousBytesOut > 0 && totalBytesOut >= previousBytesOut {
                    bytesOutDelta = totalBytesOut - previousBytesOut
                }
                
                self.bytesInPerSecond = Double(bytesInDelta) / timeDelta
                self.bytesOutPerSecond = Double(bytesOutDelta) / timeDelta
                
                // Add to history
                let dataPoint = NetworkDataPoint(
                    timestamp: Date(),
                    bytesIn: self.bytesInPerSecond,
                    bytesOut: self.bytesOutPerSecond
                )
                
                self.history.append(dataPoint)
                if self.history.count > self.maxHistoryPoints {
                    self.history.removeFirst(self.history.count - self.maxHistoryPoints)
                }
            }
        }
        
        self.previousBytesIn = totalBytesIn
        self.previousBytesOut = totalBytesOut
        self.previousTimestamp = currentTimestamp
        self.interfaceName = activeInterface
        
        updateLocalIPs()
    }
    
    private func updateLocalIPs() {
        Task.detached { [weak self] in
            let task = Process()
            task.launchPath = "/sbin/ifconfig"
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    var ips: [String] = []
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasPrefix("inet ") && !trimmed.contains("127.0.0.1") {
                            let parts = trimmed.components(separatedBy: .whitespaces)
                            if parts.count > 1 {
                                ips.append(parts[1])
                            }
                        }
                    }
                    await MainActor.run {
                        self?.localIPs = ips
                    }
                }
            } catch {
                print("Failed to get IPs: \(error)")
            }
        }
    }
}
