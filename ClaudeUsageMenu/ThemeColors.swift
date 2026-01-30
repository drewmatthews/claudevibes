import SwiftUI

enum ThemePreset: String, CaseIterable {
    case claudePink
    case oceanBlue
    case forestGreen
    case sunsetOrange
    case lavender
    case monochrome

    var displayName: String {
        switch self {
        case .claudePink: return "Claude Pink"
        case .oceanBlue: return "Ocean Blue"
        case .forestGreen: return "Forest Green"
        case .sunsetOrange: return "Sunset Orange"
        case .lavender: return "Lavender"
        case .monochrome: return "Monochrome"
        }
    }

    var primary: Color {
        switch self {
        case .claudePink: return Color(red: 0.85, green: 0.55, blue: 0.55)
        case .oceanBlue: return Color(red: 0.35, green: 0.55, blue: 0.85)
        case .forestGreen: return Color(red: 0.35, green: 0.70, blue: 0.50)
        case .sunsetOrange: return Color(red: 0.90, green: 0.60, blue: 0.35)
        case .lavender: return Color(red: 0.65, green: 0.50, blue: 0.85)
        case .monochrome: return Color(red: 0.60, green: 0.60, blue: 0.60)
        }
    }

    var primaryLight: Color {
        switch self {
        case .claudePink: return Color(red: 0.92, green: 0.70, blue: 0.70)
        case .oceanBlue: return Color(red: 0.55, green: 0.72, blue: 0.95)
        case .forestGreen: return Color(red: 0.55, green: 0.82, blue: 0.65)
        case .sunsetOrange: return Color(red: 0.98, green: 0.78, blue: 0.55)
        case .lavender: return Color(red: 0.80, green: 0.70, blue: 0.95)
        case .monochrome: return Color(red: 0.78, green: 0.78, blue: 0.78)
        }
    }

    var primaryDark: Color {
        switch self {
        case .claudePink: return Color(red: 0.75, green: 0.45, blue: 0.45)
        case .oceanBlue: return Color(red: 0.25, green: 0.42, blue: 0.72)
        case .forestGreen: return Color(red: 0.25, green: 0.55, blue: 0.38)
        case .sunsetOrange: return Color(red: 0.78, green: 0.48, blue: 0.25)
        case .lavender: return Color(red: 0.50, green: 0.38, blue: 0.72)
        case .monochrome: return Color(red: 0.45, green: 0.45, blue: 0.45)
        }
    }
}
