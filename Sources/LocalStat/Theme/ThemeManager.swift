import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case latte, frappe, macchiato, mocha, antigravity
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .latte: return "Latte"
        case .frappe: return "Frappé"
        case .macchiato: return "Macchiato"
        case .mocha: return "Mocha"
        case .antigravity: return "Antigravity"
        }
    }
    
    var emoji: String {
        switch self {
        case .latte: return "🌻"
        case .frappe: return "🪴"
        case .macchiato: return "🌺"
        case .mocha: return "🌿"
        case .antigravity: return "✨"
        }
    }
}

/// Central theme manager that publishes semantic colors based on the selected theme
@Observable
@MainActor
final class ThemeManager: @unchecked Sendable {
    
    // Store in UserDefaults manually since @AppStorage doesn't work perfectly inside @Observable classes yet
    var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        if let savedThemeRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            self.selectedTheme = savedTheme
        } else {
            self.selectedTheme = .mocha
        }
    }
    
    // MARK: - Semantic Colors
    
    var background: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.base
        default: return catppuccinFlavor.base
        }
    }
    
    var surface: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.surface0
        default: return catppuccinFlavor.surface0
        }
    }
    
    var surfaceAlt: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.surface1
        default: return catppuccinFlavor.surface1
        }
    }
    
    var text: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.text
        default: return catppuccinFlavor.text
        }
    }
    
    var subtextPrimary: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.subtext1
        default: return catppuccinFlavor.subtext1
        }
    }
    
    var subtextSecondary: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.subtext0
        default: return catppuccinFlavor.subtext0
        }
    }
    
    var accent: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.primary
        default: return catppuccinFlavor.mauve
        }
    }
    
    var blue: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.blue
        default: return catppuccinFlavor.blue
        }
    }
    
    var success: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.success
        default: return catppuccinFlavor.green
        }
    }
    
    var warning: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.warning
        default: return catppuccinFlavor.yellow
        }
    }
    
    var error: Color {
        switch selectedTheme {
        case .antigravity: return AntigravityColors.error
        default: return catppuccinFlavor.red
        }
    }
    
    // MARK: - Dynamic Gauge Colors
    
    /// Returns a color based on the usage percentage (green -> yellow -> red)
    func gaugeColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5:
            return success
        case 0.5..<0.8:
            return warning
        default:
            return error
        }
    }
    
    // MARK: - Private Helper
    
    private var catppuccinFlavor: CatppuccinFlavor {
        switch selectedTheme {
        case .latte: return .latte
        case .frappe: return .frappe
        case .macchiato: return .macchiato
        case .mocha: return .mocha
        case .antigravity: return .mocha // Fallback, shouldn't be used
        }
    }
}
