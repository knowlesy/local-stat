import Foundation

struct DiskDataPoint: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let readBytes: Double
    let writeBytes: Double
    let readLatency: Double
    let writeLatency: Double
}

/// Hardware-level monitor for Disk usage using FileManager and IOKit
@Observable
@MainActor
final class DiskMonitor: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    var totalSpace: Double = 0.0 // GB
    var usedSpace: Double = 0.0  // GB
    var freeSpace: Double = 0.0  // GB
    var usagePercentage: Double = 0.0
    
    var readBytesPerSec: Double = 0.0
    var writeBytesPerSec: Double = 0.0
    var readLatencyMs: Double = 0.0
    var writeLatencyMs: Double = 0.0
    
    var history: [DiskDataPoint] = []
    
    var isRunning: Bool = false
    
    // MARK: - Private State
    
    private var timer: Timer?
    private let refreshInterval: TimeInterval
    
    private var previousReadBytes: UInt64 = 0
    private var previousWriteBytes: UInt64 = 0
    private var previousReadOps: UInt64 = 0
    private var previousWriteOps: UInt64 = 0
    private var previousReadTime: UInt64 = 0
    private var previousWriteTime: UInt64 = 0
    private var previousTimestamp: CFAbsoluteTime = 0
    
    // MARK: - Initialization
    
    init(refreshInterval: TimeInterval = 2.0) { // Disk stats updated more frequently for bandwidth
        self.refreshInterval = refreshInterval
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Initial fetch
        updateStats()
        updateIOStats()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }
            Task { @MainActor in
                self.updateStats()
                self.updateIOStats()
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
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            
            if let capacity = values.volumeTotalCapacity, let available = values.volumeAvailableCapacityForImportantUsage {
                let totalGB = Double(capacity) / 1_000_000_000.0 // Apple uses base 10 for storage
                let availableGB = Double(available) / 1_000_000_000.0
                let usedGB = totalGB - availableGB
                
                self.totalSpace = totalGB
                self.usedSpace = usedGB
                self.freeSpace = availableGB
                self.usagePercentage = totalGB > 0 ? (usedGB / totalGB) : 0.0
            }
        } catch {
            print("Failed to get disk usage: \(error.localizedDescription)")
        }
    }
    
    private func updateIOStats() {
        Task.detached { [weak self] in
            let task = Process()
            task.launchPath = "/usr/sbin/ioreg"
            task.arguments = ["-c", "IOBlockStorageDriver", "-r", "-d", "1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        self?.parseIOStats(output)
                    }
                }
            } catch {
                print("Failed to run ioreg for disk: \(error)")
            }
        }
    }
    
    private func parseIOStats(_ output: String) {
        // Find "Statistics" = {...}
        // Extract Bytes (Read), Bytes (Write), Operations (Read), Operations (Write), Total Time (Read), Total Time (Write)
        
        func extract(key: String, from dictStr: String) -> UInt64 {
            let escapedKey = key.replacingOccurrences(of: "(", with: "\\(").replacingOccurrences(of: ")", with: "\\)")
            let pattern = "\"\(escapedKey)\"=(\\d+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: dictStr, range: NSRange(dictStr.startIndex..., in: dictStr)) {
                if let range = Range(match.range(at: 1), in: dictStr) {
                    return UInt64(dictStr[range]) ?? 0
                }
            }
            return 0
        }
        
        var totalReadBytes: UInt64 = 0
        var totalWriteBytes: UInt64 = 0
        var totalReadOps: UInt64 = 0
        var totalWriteOps: UInt64 = 0
        var totalReadTime: UInt64 = 0 // typically nanoseconds in IOKit stats
        var totalWriteTime: UInt64 = 0
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if let range = line.range(of: "\"Statistics\" = {") {
                let dictStr = String(line[range.upperBound...])
                
                totalReadBytes += extract(key: "Bytes (Read)", from: dictStr)
                totalWriteBytes += extract(key: "Bytes (Write)", from: dictStr)
                totalReadOps += extract(key: "Operations (Read)", from: dictStr)
                totalWriteOps += extract(key: "Operations (Write)", from: dictStr)
                totalReadTime += extract(key: "Total Time (Read)", from: dictStr)
                totalWriteTime += extract(key: "Total Time (Write)", from: dictStr)
            }
        }
        
        let currentTimestamp = CFAbsoluteTimeGetCurrent()
        
        if previousTimestamp > 0 {
            let timeDelta = currentTimestamp - previousTimestamp
            if timeDelta > 0 {
                let bytesReadDelta = totalReadBytes >= previousReadBytes ? totalReadBytes - previousReadBytes : 0
                let bytesWriteDelta = totalWriteBytes >= previousWriteBytes ? totalWriteBytes - previousWriteBytes : 0
                
                self.readBytesPerSec = Double(bytesReadDelta) / timeDelta
                self.writeBytesPerSec = Double(bytesWriteDelta) / timeDelta
                
                let opsReadDelta = totalReadOps >= previousReadOps ? totalReadOps - previousReadOps : 0
                let opsWriteDelta = totalWriteOps >= previousWriteOps ? totalWriteOps - previousWriteOps : 0
                
                let timeReadDelta = totalReadTime >= previousReadTime ? totalReadTime - previousReadTime : 0
                let timeWriteDelta = totalWriteTime >= previousWriteTime ? totalWriteTime - previousWriteTime : 0
                
                // Total Time is in nanoseconds. Latency per operation in milliseconds = (TotalTimeDelta(ns) / OpsDelta) / 1,000,000
                if opsReadDelta > 0 {
                    self.readLatencyMs = Double(timeReadDelta) / Double(opsReadDelta) / 1_000_000.0
                } else {
                    self.readLatencyMs = 0
                }
                
                if opsWriteDelta > 0 {
                    self.writeLatencyMs = Double(timeWriteDelta) / Double(opsWriteDelta) / 1_000_000.0
                } else {
                    self.writeLatencyMs = 0
                }
                
                // Add to history
                let dataPoint = DiskDataPoint(
                    timestamp: Date(),
                    readBytes: self.readBytesPerSec,
                    writeBytes: self.writeBytesPerSec,
                    readLatency: self.readLatencyMs,
                    writeLatency: self.writeLatencyMs
                )
                
                self.history.append(dataPoint)
                // 300 points is 10 minutes at 2s interval
                if self.history.count > 300 {
                    self.history.removeFirst(self.history.count - 300)
                }
            }
        }
        
        self.previousReadBytes = totalReadBytes
        self.previousWriteBytes = totalWriteBytes
        self.previousReadOps = totalReadOps
        self.previousWriteOps = totalWriteOps
        self.previousReadTime = totalReadTime
        self.previousWriteTime = totalWriteTime
        self.previousTimestamp = currentTimestamp
    }
}
