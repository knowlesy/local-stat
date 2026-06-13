import SwiftUI

/// Antigravity brand theme: Deep space dark with electric accents
struct AntigravityColors: Sendable {
    // Backgrounds
    static let base = Color(hex: "#0D0D1A")
    static let mantle = Color(hex: "#141428")
    static let crust = Color(hex: "#0A0A14")
    
    // Surfaces
    static let surface0 = Color(hex: "#1A1A2E")
    static let surface1 = Color(hex: "#252540")
    static let surface2 = Color(hex: "#2F2F4A")
    
    // Overlays
    static let overlay0 = Color(hex: "#3D3D5C")
    static let overlay1 = Color(hex: "#4D4D6E")
    static let overlay2 = Color(hex: "#5E5E80")
    
    // Text
    static let text = Color(hex: "#E2E8F0")
    static let subtext1 = Color(hex: "#CBD5E1")
    static let subtext0 = Color(hex: "#94A3B8")
    
    // Semantic Accents
    static let primary = Color(hex: "#7C3AED") // Electric violet
    static let secondary = Color(hex: "#06B6D4") // Cyan
    static let success = Color(hex: "#10B981") // Emerald
    static let warning = Color(hex: "#F59E0B") // Amber
    static let error = Color(hex: "#EF4444") // Red
    
    // Equivalent colors for compatibility with Catppuccin structure
    static let mauve = primary
    static let blue = Color(hex: "#3B82F6")
    static let green = success
    static let yellow = warning
    static let red = error
    static let peach = Color(hex: "#F97316")
    static let pink = Color(hex: "#EC4899")
    static let teal = Color(hex: "#14B8A6")
    static let sky = Color(hex: "#0EA5E9")
    static let sapphire = secondary
    static let lavender = Color(hex: "#8B5CF6")
    static let flamingo = Color(hex: "#F472B6")
    static let rosewater = Color(hex: "#FDA4AF")
    static let maroon = Color(hex: "#F87171")
}
