import SwiftUI

extension Color {
    static let text = Color(hex: "#F2F4F6")
    static let background = Color(hex: "#232628")
    static let background2 = Color(hex: "#1E1E1E")
    static let secondaryBackground = Color(hex: "#2B2D2F")
    static let tintColorDark = Color(hex: "#FF603B") // Using primary as tint
    static let tint = tintColorDark
    static let icon = Color(hex: "#A3ABB1")
    static let tabIconDefault = Color(hex: "#A3ABB1")
    static let tabIconSelected = tintColorDark
    static let primary = Color(hex: "#FF603B")
    static let secondary = Color(hex: "#FD6800")
    static let aqua = Color(hex: "#A0C9CB")
    static let amazon = Color(hex:"#ECECDC")
    static let morningSnow = Color(hex:"#F5F4ED")
    static let gold = Color(hex:"#F9FE00")
    static let blackKite = Color(hex:"#351E1C")
    
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
