import Foundation

/// Protocol that all AI service trackers must conform to.
/// Enables uniform handling of Claude, Gemini, Copilot, and Antigravity tracking.
@MainActor
protocol AITokenTracker: Sendable {
    /// Display name of the service (e.g., "Claude Code")
    var serviceName: String { get }

    /// Short 2-3 letter label for compact display (e.g., "CLA")
    var shortLabel: String { get }

    /// SF Symbol name for the service icon
    var iconName: String { get }

    /// Whether the service is detected on this machine
    var isAvailable: Bool { get }

    /// Current or most recent token session data
    var currentSession: TokenSession? { get }

    /// Refresh token data by re-reading local files
    func refresh() async

    /// Human-readable setup instructions if the service needs configuration
    var setupInstructions: String? { get }
    
    /// Web URL to open for setting up the service
    var setupURL: URL? { get }
}

/// Represents a single token usage session/interaction
struct TokenSession: Sendable, Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheWriteTokens: Int
    let model: String?
    let timestamp: Date
    let costEstimate: Double?

    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens
    }

    init(
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        cacheReadTokens: Int = 0,
        cacheWriteTokens: Int = 0,
        model: String? = nil,
        timestamp: Date = .now,
        costEstimate: Double? = nil
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.model = model
        self.timestamp = timestamp
        self.costEstimate = costEstimate
    }
}

/// Status of an AI service's availability
enum AIServiceStatus: String, Sendable {
    case active       // Currently running / recent data
    case idle         // Installed but no recent activity
    case notInstalled // Not found on this machine
    case needsSetup   // Found but needs configuration
}

/// Formats a token count into a human-readable string
/// - Parameter count: The token count to format
/// - Returns: Formatted string (e.g., "12.5K", "1.2M")
func formatTokenCount(_ count: Int) -> String {
    if count < 1_000 {
        return "\(count)"
    } else if count < 1_000_000 {
        let value = Double(count) / 1_000.0
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))K"
            : String(format: "%.1fK", value)
    } else {
        let value = Double(count) / 1_000_000.0
        return String(format: "%.1fM", value)
    }
}
