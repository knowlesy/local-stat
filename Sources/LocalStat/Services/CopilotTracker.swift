import Foundation

/// Tracker for GitHub Copilot usage
/// Reads from VS Code extension logs
@Observable
@MainActor
final class CopilotTracker: AITokenTracker {
    
    // MARK: - Protocol Conformance
    
    let serviceName = "GitHub Copilot"
    let shortLabel = "COP"
    let iconName = "curlybraces" // Will be custom in UI
    
    var isAvailable: Bool = false
    var currentSession: TokenSession?
    var usagePercentage: Double?
    var setupInstructions: String?
    var setupURL: URL? = URL(string: "https://github.com/settings/copilot/features")
    
    // MARK: - Private State
    
    private let extensionsDir: URL
    private let logsDir: URL
    
    // MARK: - Initialization
    
    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.extensionsDir = homeDir.appendingPathComponent(".vscode/extensions")
        self.logsDir = homeDir.appendingPathComponent("Library/Application Support/Code/logs")
        
        checkAvailability()
        if isAvailable {
            Task {
                await refresh()
            }
        }
    }
    
    // MARK: - Internal Methods
    
    private func checkAvailability() {
        // Check if copilot or copilot-chat extension exists, or if ~/.copilot directory exists
        let hasCopilotDir = FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".copilot").path)
        
        var hasExtension = false
        if let dirs = try? FileManager.default.contentsOfDirectory(atPath: extensionsDir.path) {
            hasExtension = dirs.contains(where: { $0.lowercased().contains("copilot") })
        }
        
        isAvailable = hasCopilotDir || hasExtension
        
        if isAvailable {
            setupInstructions = "Enable 'Trace' log level in VS Code Developer options to see Copilot token usage."
        }
    }
    
    func refresh() async {
        guard isAvailable else { return }
        
        // Copilot does not store local token counts without explicitly
        // enabling Trace logging and having a complex parser.
        // We leave currentSession as nil to show 'Unused' in the UI.
        self.currentSession = nil
    }
}
