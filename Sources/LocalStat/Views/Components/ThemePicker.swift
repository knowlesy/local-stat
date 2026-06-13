import SwiftUI

/// Component for picking the app theme
struct ThemePicker: View {
    @Environment(ThemeManager.self) private var themeManager
    
    // 2 columns for the grid
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Theme")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(themeManager.text)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AppTheme.allCases) { themeOption in
                    Button(action: {
                        themeManager.selectedTheme = themeOption
                    }) {
                        HStack(spacing: 8) {
                            // Theme Preview Circle
                            ZStack {
                                Circle()
                                    .fill(previewColor(for: themeOption))
                                    .frame(width: 20, height: 20)
                                
                                if themeManager.selectedTheme == themeOption {
                                    Circle()
                                        .stroke(themeManager.text, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                }
                            }
                            
                            // Label & Emoji
                            Text("\(themeOption.emoji) \(themeOption.displayName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.selectedTheme == themeOption ? themeManager.text : themeManager.subtextPrimary)
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.selectedTheme == themeOption ? themeManager.surfaceAlt : themeManager.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.selectedTheme == themeOption ? themeManager.accent : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(themeManager.surfaceAlt.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func previewColor(for theme: AppTheme) -> Color {
        // Return the 'mantle' or base color for the preview circle
        switch theme {
        case .latte: return CatppuccinFlavor.latte.mantle
        case .frappe: return CatppuccinFlavor.frappe.mantle
        case .macchiato: return CatppuccinFlavor.macchiato.mantle
        case .mocha: return CatppuccinFlavor.mocha.mantle
        case .antigravity: return AntigravityColors.mantle
        }
    }
}
