import Foundation

struct NetworkProcess: Identifiable, Sendable {
    let id: String // e.g., "Safari.1234"
    let name: String
    let pid: Int
    var currentBytesIn: Double
    var currentBytesOut: Double
    var totalBytesIn: Double
    var totalBytesOut: Double
    var lastUpdated: CFAbsoluteTime
}

/// Monitors per-process network usage using `nettop`
@Observable
@MainActor
final class NetworkProcessMonitor: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    var processes: [NetworkProcess] = []
    var isRunning: Bool = false
    
    // MARK: - Private State
    
    private var timer: Timer?
    private let refreshInterval: TimeInterval
    
    private var processMap: [String: NetworkProcess] = [:]
    
    // MARK: - Initialization
    
    init(refreshInterval: TimeInterval = 3.0) {
        self.refreshInterval = refreshInterval
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        updateStats()
        
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }
            Task { @MainActor in
                self.updateStats()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // MARK: - Internal Monitoring
    
    private func updateStats() {
        Task.detached { [weak self] in
            let task = Process()
            task.launchPath = "/usr/bin/nettop"
            // -P: No periodic updates, run once and exit after printing
            // -L 1: Print 1 sample
            // -J bytes_in,bytes_out: Only print specific columns
            task.arguments = ["-P", "-L", "1", "-J", "bytes_in,bytes_out"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        self?.parseNettopOutput(output)
                    }
                }
            } catch {
                print("Failed to run nettop: \(error)")
            }
        }
    }
    
    private func parseNettopOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        guard lines.count > 1 else { return }
        
        let currentTimestamp = CFAbsoluteTimeGetCurrent()
        
        // Output format: time,name.pid,bytes_in,bytes_out,...
        // Usually the first line is header. We'll skip header by checking if bytes parse as ints.
        
        for line in lines {
            let cols = line.components(separatedBy: ",")
            // Expecting something like: "", "Safari.1234", "1000", "500", "" (due to trailing commas)
            // Column 1 is process name.pid, Column 2 is bytes_in, Column 3 is bytes_out
            
            // nettop output can vary, usually empty first col if time is disabled or missing
            let validCols = cols.filter { !$0.isEmpty }
            
            if validCols.count >= 3 {
                let id = validCols[0]
                if id == "bytes_in" || id == "time" || id.hasPrefix("time") { continue }
                
                guard let totalIn = Double(validCols[1]),
                      let totalOut = Double(validCols[2]) else { continue }
                
                // Parse Name and PID
                var name = id
                var pid = 0
                if let lastDotIdx = id.lastIndex(of: ".") {
                    name = String(id[..<lastDotIdx])
                    let pidStr = String(id[id.index(after: lastDotIdx)...])
                    pid = Int(pidStr) ?? 0
                }
                
                if var existing = processMap[id] {
                    let deltaIn = totalIn >= existing.totalBytesIn ? totalIn - existing.totalBytesIn : 0
                    let deltaOut = totalOut >= existing.totalBytesOut ? totalOut - existing.totalBytesOut : 0
                    
                    let timeDelta = currentTimestamp - existing.lastUpdated
                    
                    if timeDelta > 0 {
                        existing.currentBytesIn = deltaIn / timeDelta
                        existing.currentBytesOut = deltaOut / timeDelta
                    }
                    
                    existing.totalBytesIn = totalIn
                    existing.totalBytesOut = totalOut
                    existing.lastUpdated = currentTimestamp
                    
                    processMap[id] = existing
                } else {
                    let newProc = NetworkProcess(
                        id: id,
                        name: name,
                        pid: pid,
                        currentBytesIn: 0,
                        currentBytesOut: 0,
                        totalBytesIn: totalIn,
                        totalBytesOut: totalOut,
                        lastUpdated: currentTimestamp
                    )
                    processMap[id] = newProc
                }
            }
        }
        
        // Clean up dead processes (not seen in last 10 seconds)
        for (id, proc) in processMap {
            if currentTimestamp - proc.lastUpdated > 10.0 {
                processMap.removeValue(forKey: id)
            }
        }
        
        // Update published array
        self.processes = Array(processMap.values)
    }
}
