import SwiftUI

struct DailyHeatmapView: View {
    let dailyTotals: [Decimal]
    let firstWeekdayOffset: Int
    let todayIndex: Int?
    var weekdayHeaders: [String] = ["S", "M", "T", "W", "T", "F", "S"]

    private var maxValue: Double {
        let max = dailyTotals.map { NSDecimalNumber(decimal: $0).doubleValue }.max() ?? 0
        return max > 0 ? max : 1
    }

    private var cells: [Cell] {
        let padded: [Decimal?] =
            Array(repeating: nil, count: firstWeekdayOffset) +
            dailyTotals.map(Optional.some)
        let totalCells = max(35, ((padded.count + 6) / 7) * 7)
        let padding = totalCells - padded.count
        let final = padded + Array(repeating: nil as Decimal?, count: padding)
        return final.enumerated().map { Cell(id: $0.offset, value: $0.element) }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7),
                spacing: 5
            ) {
                ForEach(cells) { cell in
                    cellView(for: cell)
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for cell: Cell) -> some View {
        let dayIndex = cell.id - firstWeekdayOffset
        let isToday = todayIndex.map { $0 == dayIndex } ?? false
        Rectangle()
            .fill(fillColor(for: cell.value))
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(isToday ? Color.primary : Color.clear, lineWidth: 1.5)
            )
    }

    private func fillColor(for value: Decimal?) -> Color {
        guard let value, value > 0 else {
            return Color.secondary.opacity(0.12)
        }
        let v = NSDecimalNumber(decimal: value).doubleValue
        let intensity = v / maxValue
        return Color.accentColor.opacity(0.12 + intensity * 0.78)
    }

    private struct Cell: Identifiable {
        let id: Int
        let value: Decimal?
    }
}

#Preview {
    DailyHeatmapView(
        dailyTotals: (1...30).map { Decimal($0 * 12) },
        firstWeekdayOffset: 4,
        todayIndex: 15
    )
    .padding()
}
