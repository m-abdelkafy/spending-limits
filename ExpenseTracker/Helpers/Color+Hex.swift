import SwiftUI

extension Color {
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexValue.hasPrefix("#") { hexValue.removeFirst() }

        var int: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hexValue.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (79, 142, 247, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
        #else
        return "#4F8EF7"
        #endif
    }
}

enum CategoryPalette {
    static let colors: [String] = [
        "#FF6B6B", "#F39C12", "#F1C40F", "#1ABC9C",
        "#16A085", "#27AE60", "#4F8EF7", "#3498DB",
        "#9B59B6", "#8E44AD", "#E74C3C", "#34495E",
    ]
}

enum CategoryIconPalette {
    static let icons: [String] = [
        "fork.knife", "cart.fill", "bag.fill", "car.fill",
        "fuelpump.fill", "tram.fill", "airplane", "house.fill",
        "bolt.fill", "wifi", "phone.fill", "doc.text.fill",
        "popcorn.fill", "gamecontroller.fill", "music.note", "tv.fill",
        "book.fill", "graduationcap.fill", "heart.fill", "cross.case.fill",
        "pawprint.fill", "gift.fill", "tshirt.fill", "wrench.adjustable.fill",
    ]
}
