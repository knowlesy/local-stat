import SwiftUI

/// Definitions for all 4 Catppuccin flavors
/// Source: https://github.com/catppuccin/catppuccin
enum CatppuccinFlavor: String, CaseIterable, Identifiable, Sendable {
    case latte, frappe, macchiato, mocha
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .latte: return "Latte"
        case .frappe: return "Frappé"
        case .macchiato: return "Macchiato"
        case .mocha: return "Mocha"
        }
    }
    
    var emoji: String {
        switch self {
        case .latte: return "🌻"
        case .frappe: return "🪴"
        case .macchiato: return "🌺"
        case .mocha: return "🌿"
        }
    }
    
    var isDark: Bool {
        self != .latte
    }
    
    // MARK: - Color Palette
    
    var rosewater: Color {
        switch self {
        case .latte: return Color(hex: "#DC8A78")
        case .frappe: return Color(hex: "#F2D5CF")
        case .macchiato: return Color(hex: "#F4DBD6")
        case .mocha: return Color(hex: "#F5E0DC")
        }
    }
    
    var flamingo: Color {
        switch self {
        case .latte: return Color(hex: "#DD7878")
        case .frappe: return Color(hex: "#EEBEBE")
        case .macchiato: return Color(hex: "#F0C6C6")
        case .mocha: return Color(hex: "#F2CDCD")
        }
    }
    
    var pink: Color {
        switch self {
        case .latte: return Color(hex: "#EA76CB")
        case .frappe: return Color(hex: "#F4B8E4")
        case .macchiato: return Color(hex: "#F5BDE6")
        case .mocha: return Color(hex: "#F5C2E7")
        }
    }
    
    var mauve: Color {
        switch self {
        case .latte: return Color(hex: "#8839EF")
        case .frappe: return Color(hex: "#CA9EE6")
        case .macchiato: return Color(hex: "#C6A0F6")
        case .mocha: return Color(hex: "#CBA6F7")
        }
    }
    
    var red: Color {
        switch self {
        case .latte: return Color(hex: "#D20F39")
        case .frappe: return Color(hex: "#E78284")
        case .macchiato: return Color(hex: "#ED8796")
        case .mocha: return Color(hex: "#F38BA8")
        }
    }
    
    var maroon: Color {
        switch self {
        case .latte: return Color(hex: "#E64553")
        case .frappe: return Color(hex: "#EA999C")
        case .macchiato: return Color(hex: "#EE99A0")
        case .mocha: return Color(hex: "#EBA0AC")
        }
    }
    
    var peach: Color {
        switch self {
        case .latte: return Color(hex: "#FE640B")
        case .frappe: return Color(hex: "#EF9F76")
        case .macchiato: return Color(hex: "#F5A97F")
        case .mocha: return Color(hex: "#FAB387")
        }
    }
    
    var yellow: Color {
        switch self {
        case .latte: return Color(hex: "#DF8E1D")
        case .frappe: return Color(hex: "#E5C890")
        case .macchiato: return Color(hex: "#EED49F")
        case .mocha: return Color(hex: "#F9E2AF")
        }
    }
    
    var green: Color {
        switch self {
        case .latte: return Color(hex: "#40A02B")
        case .frappe: return Color(hex: "#A6D189")
        case .macchiato: return Color(hex: "#A6DA95")
        case .mocha: return Color(hex: "#A6E3A1")
        }
    }
    
    var teal: Color {
        switch self {
        case .latte: return Color(hex: "#179299")
        case .frappe: return Color(hex: "#81C8BE")
        case .macchiato: return Color(hex: "#8BD5CA")
        case .mocha: return Color(hex: "#94E2D5")
        }
    }
    
    var sky: Color {
        switch self {
        case .latte: return Color(hex: "#04A5E5")
        case .frappe: return Color(hex: "#99D1DB")
        case .macchiato: return Color(hex: "#91D7E3")
        case .mocha: return Color(hex: "#89DCEB")
        }
    }
    
    var sapphire: Color {
        switch self {
        case .latte: return Color(hex: "#209FB5")
        case .frappe: return Color(hex: "#85C1DC")
        case .macchiato: return Color(hex: "#7DC4E4")
        case .mocha: return Color(hex: "#74C7EC")
        }
    }
    
    var blue: Color {
        switch self {
        case .latte: return Color(hex: "#1E66F5")
        case .frappe: return Color(hex: "#8CAAEE")
        case .macchiato: return Color(hex: "#8AADF4")
        case .mocha: return Color(hex: "#89B4FA")
        }
    }
    
    var lavender: Color {
        switch self {
        case .latte: return Color(hex: "#7287FD")
        case .frappe: return Color(hex: "#BABBF1")
        case .macchiato: return Color(hex: "#B7BDF8")
        case .mocha: return Color(hex: "#B4BEFE")
        }
    }
    
    var text: Color {
        switch self {
        case .latte: return Color(hex: "#4C4F69")
        case .frappe: return Color(hex: "#C6D0F5")
        case .macchiato: return Color(hex: "#CAD3F5")
        case .mocha: return Color(hex: "#CDD6F4")
        }
    }
    
    var subtext1: Color {
        switch self {
        case .latte: return Color(hex: "#5C5F77")
        case .frappe: return Color(hex: "#B5BFE2")
        case .macchiato: return Color(hex: "#B8C0E0")
        case .mocha: return Color(hex: "#BAC2DE")
        }
    }
    
    var subtext0: Color {
        switch self {
        case .latte: return Color(hex: "#6C6F85")
        case .frappe: return Color(hex: "#A5ADCE")
        case .macchiato: return Color(hex: "#A5ADCB")
        case .mocha: return Color(hex: "#A6ADC8")
        }
    }
    
    var overlay2: Color {
        switch self {
        case .latte: return Color(hex: "#7C7F93")
        case .frappe: return Color(hex: "#949CBB")
        case .macchiato: return Color(hex: "#939AB7")
        case .mocha: return Color(hex: "#9399B2")
        }
    }
    
    var overlay1: Color {
        switch self {
        case .latte: return Color(hex: "#8C8FA1")
        case .frappe: return Color(hex: "#838BA7")
        case .macchiato: return Color(hex: "#8087A2")
        case .mocha: return Color(hex: "#7F849C")
        }
    }
    
    var overlay0: Color {
        switch self {
        case .latte: return Color(hex: "#9CA0B0")
        case .frappe: return Color(hex: "#737994")
        case .macchiato: return Color(hex: "#6E738D")
        case .mocha: return Color(hex: "#6C7086")
        }
    }
    
    var surface2: Color {
        switch self {
        case .latte: return Color(hex: "#ACB0BE")
        case .frappe: return Color(hex: "#626880")
        case .macchiato: return Color(hex: "#5B6078")
        case .mocha: return Color(hex: "#585B70")
        }
    }
    
    var surface1: Color {
        switch self {
        case .latte: return Color(hex: "#BCC0CC")
        case .frappe: return Color(hex: "#51576D")
        case .macchiato: return Color(hex: "#494D64")
        case .mocha: return Color(hex: "#45475A")
        }
    }
    
    var surface0: Color {
        switch self {
        case .latte: return Color(hex: "#CCD0DA")
        case .frappe: return Color(hex: "#414559")
        case .macchiato: return Color(hex: "#363A4F")
        case .mocha: return Color(hex: "#313244")
        }
    }
    
    var base: Color {
        switch self {
        case .latte: return Color(hex: "#EFF1F5")
        case .frappe: return Color(hex: "#303446")
        case .macchiato: return Color(hex: "#24273A")
        case .mocha: return Color(hex: "#1E1E2E")
        }
    }
    
    var mantle: Color {
        switch self {
        case .latte: return Color(hex: "#E6E9EF")
        case .frappe: return Color(hex: "#292C3C")
        case .macchiato: return Color(hex: "#1E2030")
        case .mocha: return Color(hex: "#181825")
        }
    }
    
    var crust: Color {
        switch self {
        case .latte: return Color(hex: "#DCE0E8")
        case .frappe: return Color(hex: "#232634")
        case .macchiato: return Color(hex: "#181926")
        case .mocha: return Color(hex: "#11111B")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
