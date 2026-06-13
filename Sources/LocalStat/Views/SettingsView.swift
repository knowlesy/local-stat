import SwiftUI

/// Settings tab for app configuration
struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    
    @AppStorage("refreshInterval") private var refreshInterval: Double = 2.0
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon: Bool = true
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "cpu"
    
    @AppStorage("enableClipboardCommands") private var enableClipboardCommands: Bool = true
    @AppStorage("useBtopCommands") private var useBtopCommands: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Theme Picker
            ThemePicker()
            
            // App Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferences")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
                
                VStack(spacing: 16) {
                    // Update Interval
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("System Update Interval")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.text)
                            Spacer()
                            Text("\(Int(refreshInterval))s")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(theme.subtextPrimary)
                        }
                        
                        Slider(value: $refreshInterval, in: 1...10, step: 1)
                            .tint(theme.accent)
                    }
                    
                    Divider().background(theme.surfaceAlt)
                    
                    // Clipboard Commands
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Click-to-Copy Commands", isOn: $enableClipboardCommands)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.text)
                            .tint(theme.accent)
                        
                        if enableClipboardCommands {
                            Toggle("Use 'btop' instead of native commands", isOn: $useBtopCommands)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(theme.subtextSecondary)
                                .tint(theme.accent)
                                .padding(.leading, 24)
                        }
                    }
                    
                    Divider().background(theme.surfaceAlt)
                    
                    // Menu Bar Icon
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Menu Bar Icon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.text)
                        
                        HStack(spacing: 16) {
                            iconButton("cpu")
                            iconButton("memorychip")
                            iconButton("chart.bar.fill")
                            iconButton("sparkles")
                        }
                    }
                }
                .padding(16)
                .background(theme.surfaceAlt.opacity(0.3))
                .cornerRadius(12)
            }
            
            // About
            VStack(spacing: 4) {
                Text("LocalStat v1.0.0")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.subtextPrimary)
                Text("Created for Apple Silicon")
                    .font(.system(size: 10))
                    .foregroundColor(theme.subtextSecondary)
            }
            .padding(.top, 8)
        }
    }
    
    private func iconButton(_ icon: String) -> some View {
        Button(action: {
            menuBarIconName = icon
        }) {
            ZStack {
                if menuBarIconName == icon {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accent.opacity(0.2))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.accent, lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.surfaceAlt, lineWidth: 1))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(menuBarIconName == icon ? theme.accent : theme.text)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}
