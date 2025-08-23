import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    @AppStorage("appearance_theme") var selectedTheme = "system" {
        didSet {
            applyTheme()
        }
    }
    
    @AppStorage("accent_color") var accentColor = "blue" {
        didSet {
            applyAccentColor()
        }
    }
    
    init() {
        applyTheme()
        applyAccentColor()
    }
    
    private func applyTheme() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            switch self.selectedTheme {
            case "light":
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .light
                }
            case "dark":
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                }
            default: // system
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
    
    private func applyAccentColor() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            let color = self.uiColorFromString(self.accentColor)
            windowScene.windows.forEach { window in
                window.tintColor = color
            }
        }
    }
    
    func colorFromString(_ string: String) -> Color {
        switch string {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        default: return .blue
        }
    }
    
    private func uiColorFromString(_ string: String) -> UIColor {
        switch string {
        case "blue": return .systemBlue
        case "green": return .systemGreen
        case "orange": return .systemOrange
        case "purple": return .systemPurple
        case "red": return .systemRed
        case "yellow": return .systemYellow
        default: return .systemBlue
        }
    }
}