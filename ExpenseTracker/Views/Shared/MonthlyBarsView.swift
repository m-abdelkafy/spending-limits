import SwiftUI

struct MonthlyBarsView: View {
    let monthlyTotals: [Decimal]
    var currentMonthIndex: Int? = nil
    var monthLabels: [String] = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    private var maxValue: Double {
        let max = monthlyTotals.map { NSDecimalNumber(decimal: $0).doubleValue }.max() ?? 0
        return max > 0 ? max : 1
    }

    var body: some View {
        GeometryReader { proxy in
            let barWidth = (proxy.size.width - CGFloat(monthlyTotals.count - 1) * 6) / CGFloat(monthlyTotals.count)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(monthlyTotals.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(width: barWidth, height: max(proxy.size.height - 18, 0))
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(fillColor(for: value, isCurrent: currentMonthIndex == index))
                                .frame(width: barWidth, height: barHeight(for: value, available: proxy.size.height - 18))
                        }
                        Text(monthLabels[index])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(currentMonthIndex == index ? .primary : .secondary)
                            .frame(height: 14)
                    }
                }
            }
        }
        .frame(height: 132)
    }

    private func barHeight(for value: Decimal, available: CGFloat) -> CGFloat {
        let v = NSDecimalNumber(decimal: value).doubleValue
        guard v > 0, available > 0 else { return 0 }
        let ratio = v / maxValue
        return max(2, CGFloat(ratio) * available)
    }

    private func fillColor(for value: Decimal, isCurrent: Bool) -> Color {
        if value <= 0 {
            return Color.secondary.opacity(0.18)
        }
        return Color.accentColor.opacity(isCurrent ? 1.0 : 0.78)
    }
}

#Preview {
    MonthlyBarsView(
        monthlyTotals: (1...12).map { Decimal($0 * 80) },
        currentMonthIndex: 4
    )
    .padding()
}
