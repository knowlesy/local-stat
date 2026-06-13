import Foundation

/// Tracker for Claude token usage
/// Reads from ~/.claude/projects/ JSONL files (Claude Code CLI)
@Observable
@MainActor
final class ClaudeTracker: AITokenTracker {
    
    // MARK: - Protocol Conformance
    
    let serviceName = "Claude Code"
    let shortLabel = "CLA"
    let iconName = "cpu" // Will be custom in UI
    
    var isAvailable: Bool = false
    var currentSession: TokenSession?
    var usagePercentage: Double? // Not available locally without auth
    var setupInstructions: String?
    var setupURL: URL? = URL(string: "https://console.anthropic.com/settings/usage")
    
    // MARK: - Private State
    
    private var fileSource: DispatchSourceFileSystemObject?
    private let claudeDir: URL
    private let projectsDir: URL
    
    // MARK: - Initialization
    
    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.claudeDir = homeDir.appendingPathComponent(".claude")
        self.projectsDir = claudeDir.appendingPathComponent("projects")
        
        checkAvailability()
        if isAvailable {
            Task {
                await refresh()
            }
            setupFileWatcher()
        }
    }
    // MARK: - Internal Methods
    
    private func checkAvailability() {
        isAvailable = FileManager.default.fileExists(atPath: claudeDir.path)
        if !isAvailable {
            setupInstructions = "Install Claude Code CLI via npm install -g @anthropic-ai/claude-code"
        }
    }
    
    func refresh() async {
        guard isAvailable else { return }
        
        guard let enumerator = FileManager.default.enumerator(at: projectsDir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]),
              let allURLs = enumerator.allObjects as? [URL] else { return }
        
        var latestFile: URL?
        var latestDate = Date.distantPast
        
        for url in allURLs {
            if url.pathExtension == "jsonl" {
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                if date > latestDate {
                    latestDate = date
                    latestFile = url
                }
            }
        }
        
        if let file = latestFile {
            parseLogFile(file)
        }
    }
    
    private func parseLogFile(_ url: URL) {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var inputTokens = 0
        var outputTokens = 0
        var cacheReadTokens = 0
        var cacheWriteTokens = 0
        var lastModel: String?
        
        // Parse from end to beginning to just get the current session/latest stats
        // In a real app we'd parse the whole file to accumulate session tokens
        for line in lines {
            guard let jsonData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { continue }
            
            // Look for token usage fields in the JSON (can be at root or inside message)
            var currentUsage: [String: Any]? = nil
            if let usage = json["usage"] as? [String: Any] {
                currentUsage = usage
            } else if let message = json["message"] as? [String: Any], let usage = message["usage"] as? [String: Any] {
                currentUsage = usage
            }
            
            if let usage = currentUsage {
                inputTokens += (usage["input_tokens"] as? Int) ?? 0
                outputTokens += (usage["output_tokens"] as? Int) ?? 0
                cacheReadTokens += (usage["cache_read_input_tokens"] as? Int) ?? (usage["cache_read_tokens"] as? Int) ?? 0
                cacheWriteTokens += (usage["cache_creation_input_tokens"] as? Int) ?? (usage["cache_creation_tokens"] as? Int) ?? 0
            }
            
            if let model = json["model"] as? String {
                lastModel = model
            } else if let message = json["message"] as? [String: Any], let model = message["model"] as? String {
                lastModel = model
            }
        }
        
        if inputTokens > 0 || outputTokens > 0 {
            // Rough cost estimate (Opus pricing as baseline: $15/M input, $75/M output)
            let cost = (Double(inputTokens) / 1_000_000.0 * 15.0) + (Double(outputTokens) / 1_000_000.0 * 75.0)
            
            self.currentSession = TokenSession(
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                model: lastModel ?? "claude-3-opus",
                timestamp: .now,
                costEstimate: cost
            )
        }
    }
    
    private func setupFileWatcher() {
        // Watch the projects directory for changes
        let fd = open(projectsDir.path, O_EVTONLY)
        guard fd != -1 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: DispatchQueue.global()
        )
        
        source.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        self.fileSource = source
    }
}
