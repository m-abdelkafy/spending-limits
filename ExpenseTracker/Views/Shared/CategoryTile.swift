import SwiftUI

struct CategoryTile: View {
    let icon: String
    let colorHex: String
    var size: CGFloat = 36

    init(icon: String, colorHex: String, size: CGFloat = 36) {
        self.icon = icon
        self.colorHex = colorHex
        self.size = size
    }

    init(category: Category?, size: CGFloat = 36) {
        self.icon = category?.icon ?? "questionmark"
        self.colorHex = category?.colorHex ?? "#8E8E93"
        self.size = size
    }

    var body: some View {
        let color = Color(hex: colorHex)
        let corner: CGFloat = size <= 28 ? 6 : 8
        let glyph = size * 0.5
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(color.opacity(0.22))
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: glyph, weight: .semibold))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 12) {
        CategoryTile(icon: "fork.knife", colorHex: "#FF6B6B", size: 24)
        CategoryTile(icon: "car.fill", colorHex: "#4F8EF7", size: 32)
        CategoryTile(icon: "bag.fill", colorHex: "#1ABC9C", size: 36)
    }
    .padding()
}
