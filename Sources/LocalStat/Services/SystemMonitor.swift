import Foundation
import Darwin

/// Hardware-level system monitor for CPU and Memory stats
/// Uses Mach kernel APIs for maximum efficiency without external dependencies
@Observable
@MainActor
final class SystemMonitor: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    var cpuUsage: Double = 0.0
    var perCoreUsage: [Double] = []
    
    var memoryPressure: Double = 0.0
    var memoryTotal: UInt64 = 0
    var memoryUsed: UInt64 = 0
    
    var isRunning: Bool = false
    
    // MARK: - Private State
    
    private var timer: Timer?
    private var previousTicks: [Int32] = []
    private var numCPUs: natural_t = 0
    private var cpuInfoLock = NSLock()
    
    private let refreshInterval: TimeInterval
    
    // MARK: - Initialization
    
    init(refreshInterval: TimeInterval = 2.0) {
        self.refreshInterval = refreshInterval
        
        // Get number of CPUs
        var mib = [CTL_HW, HW_NCPU]
        var size = MemoryLayout<natural_t>.size
        sysctl(&mib, 2, &numCPUs, &size, nil, 0)
        
        // Get total physical memory
        var memMib = [CTL_HW, HW_MEMSIZE]
        var memSize = MemoryLayout<UInt64>.size
        sysctl(&memMib, 2, &memoryTotal, &memSize, nil, 0)
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning else { return }
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
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // MARK: - Internal Monitoring
    
    private func updateStats() {
        updateCPUUsage()
        updateMemoryUsage()
    }
    
    private func updateCPUUsage() {
        cpuInfoLock.lock()
        defer { cpuInfoLock.unlock() }
        
        var numCPUInfo: mach_msg_type_number_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUsU: natural_t = 0
        
        // Fetch current CPU load info
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCPUInfo)
        
        guard result == KERN_SUCCESS, let currentInfo = cpuInfo else {
            print("Failed to get CPU info")
            return
        }
        
        let currentTicks = Array(UnsafeBufferPointer(start: currentInfo, count: Int(numCPUInfo)))
        
        // Free mach memory immediately
        let cpuInfoSize = Int(numCPUInfo) * MemoryLayout<integer_t>.stride
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: currentInfo), vm_size_t(cpuInfoSize))
        
        var coreUsages: [Double] = []
        var totalUsage: Double = 0
        
        if !previousTicks.isEmpty {
            for i in 0..<Int(numCPUs) {
                let inUse = currentTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)]
                          + currentTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)]
                          + currentTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)]
                          - previousTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)]
                          - previousTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)]
                          - previousTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)]
                
                let total = inUse + (currentTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)]
                                  - previousTicks[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)])
                
                let usage = total > 0 ? Double(inUse) / Double(total) : 0
                coreUsages.append(usage)
                totalUsage += usage
            }
            
            // Average across all cores
            self.cpuUsage = totalUsage / Double(numCPUs)
            self.perCoreUsage = coreUsages
        } else {
            // First run, just initialize arrays
            self.perCoreUsage = Array(repeating: 0.0, count: Int(numCPUs))
            self.cpuUsage = 0.0
        }
        
        // Store current info for next delta
        self.previousTicks = currentTicks
    }
    
    private func updateMemoryUsage() {
        var hostInfo = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            print("Failed to get memory info")
            return
        }
        
        // Pages
        let pageSize = UInt64(getpagesize())
        let active = UInt64(hostInfo.active_count) * pageSize
        let wired = UInt64(hostInfo.wire_count) * pageSize
        let compressed = UInt64(hostInfo.compressor_page_count) * pageSize
        
        let used = active + wired + compressed
        self.memoryUsed = used
        
        // Pressure percentage
        if memoryTotal > 0 {
            self.memoryPressure = Double(used) / Double(memoryTotal)
        }
    }
}
