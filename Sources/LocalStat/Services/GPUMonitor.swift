import Foundation

/// Hardware-level monitor for Apple Silicon GPU using IOKit/ioreg (Sudoless)
@Observable
@MainActor
final class GPUMonitor: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    var gpuUsage: Double = 0.0
    var isAvailable: Bool = true // Set to false if not an Apple Silicon Mac
    var isRunning: Bool = false
    
    // MARK: - Private State
    
    private var timer: Timer?
    private let refreshInterval: TimeInterval
    
    // MARK: - Initialization
    
    init(refreshInterval: TimeInterval = 5.0) {
        self.refreshInterval = refreshInterval
        checkAvailability()
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning, isAvailable else { return }
        isRunning = true
        
        // Initial fetch
        updateStats()
        
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
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // MARK: - Internal Monitoring
    
    private func checkAvailability() {
        var size: size_t = 0
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        isAvailable = size > 0
    }
    
    private func updateStats() {
        guard isAvailable else { return }
        
        Task.detached { [weak self] in
            // Use ioreg to get Apple Silicon GPU stats without sudo
            let task = Process()
            task.launchPath = "/usr/sbin/ioreg"
            task.arguments = ["-c", "IOGPU", "-r", "-d", "1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe() // ignore errors
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        self?.parseIoregOutput(output)
                    }
                }
            } catch {
                print("Failed to run ioreg: \(error)")
            }
        }
    }
    
    private func parseIoregOutput(_ output: String) {
        // Look for: "Device Utilization %" = 42
        let pattern = "\"Device Utilization %\" = (\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsString = output as NSString
        let results = regex.matches(in: output, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            let valueStr = nsString.substring(with: match.range(at: 1))
            if let value = Double(valueStr) {
                self.gpuUsage = value / 100.0 // Store as 0.0 - 1.0
            }
        }
    }
}
