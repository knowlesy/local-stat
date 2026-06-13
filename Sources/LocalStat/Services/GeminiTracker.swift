import Foundation

/// Tracker for Antigravity token usage
/// Reads from ~/.gemini/antigravity/brain/ transcript files
@Observable
@MainActor
final class GeminiTracker: AITokenTracker {
    
    // MARK: - Protocol Conformance
    
    let serviceName = "Antigravity"
    let shortLabel = "AG"
    let iconName = "sparkles" // Will be custom in UI
    
    var isAvailable: Bool = false
    var currentSession: TokenSession?
    var usagePercentage: Double?
    var setupInstructions: String?
    var setupURL: URL? = URL(string: "https://aistudio.google.com/usage?timeRange=last-28-days")
    
    // MARK: - Private State
    
    private var fileSource: DispatchSourceFileSystemObject?
    private let agDir: URL
    private let brainDir: URL
    
    // MARK: - Initialization
    
    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.agDir = homeDir.appendingPathComponent(".gemini/antigravity")
        self.brainDir = agDir.appendingPathComponent("brain")
        
        checkAvailability()
        if isAvailable {
            Task {
                await refresh()
            }
            // In a real implementation we would watch the specific active conversation dir
            // setupFileWatcher()
        }
    }
    
    // MARK: - Internal Methods
    
    private func checkAvailability() {
        isAvailable = FileManager.default.fileExists(atPath: brainDir.path)
        if !isAvailable {
            setupInstructions = "Antigravity data not found in ~/.gemini/antigravity/"
        }
    }
    
    func refresh() async {
        guard isAvailable else { return }
        
        guard let dirs = try? FileManager.default.contentsOfDirectory(at: brainDir, includingPropertiesForKeys: [.isDirectoryKey]) else { return }
        
        let convDirs = dirs.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
        
        var totalInputTokens = 0
        var totalOutputTokens = 0
        var foundData = false
        
        for dir in convDirs {
            let logDir = dir.appendingPathComponent(".system_generated/logs")
            let transcriptFile = logDir.appendingPathComponent("transcript.jsonl")
            
            if FileManager.default.fileExists(atPath: transcriptFile.path) {
                let (inTokens, outTokens) = parseTranscriptTokens(transcriptFile)
                if inTokens > 0 || outTokens > 0 {
                    totalInputTokens += inTokens
                    totalOutputTokens += outTokens
                    foundData = true
                }
            }
        }
        
        if foundData {
            self.currentSession = TokenSession(
                inputTokens: totalInputTokens,
                outputTokens: totalOutputTokens,
                cacheReadTokens: 0,
                cacheWriteTokens: 0,
                model: "Antigravity Active Model",
                timestamp: .now,
                costEstimate: nil
            )
        } else {
            self.currentSession = nil
        }
    }
    
    private func parseTranscriptTokens(_ url: URL) -> (Int, Int) {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return (0, 0) }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var inputTokens = 0
        var outputTokens = 0
        
        for line in lines {
            if line.contains("\"type\":\"USER_INPUT\"") {
                inputTokens += line.count / 4
            } else if line.contains("\"type\":\"PLANNER_RESPONSE\"") {
                outputTokens += line.count / 4
            }
        }
        
        return (inputTokens, outputTokens)
}
}
