import SwiftUI

struct DonutSlice: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
}

struct DonutChart: View {
    let slices: [DonutSlice]
    var size: CGFloat = 116
    var lineWidth: CGFloat = 10

    private var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: lineWidth)
                .padding(lineWidth / 2)

            if total > 0 {
                ForEach(Array(cumulativeSlices().enumerated()), id: \.offset) { _, item in
                    Circle()
                        .trim(from: item.start, to: item.end)
                        .stroke(item.slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .padding(lineWidth / 2)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func cumulativeSlices() -> [(slice: DonutSlice, start: CGFloat, end: CGFloat)] {
        var result: [(DonutSlice, CGFloat, CGFloat)] = []
        var running: Double = 0
        let gap = 0.005
        for slice in slices where slice.value > 0 {
            let start = running / total
            running += slice.value
            let end = running / total
            let adjustedEnd = max(start, end - gap)
            result.append((slice, CGFloat(start), CGFloat(adjustedEnd)))
        }
        return result
    }
}

#Preview {
    DonutChart(slices: [
        DonutSlice(value: 30, color: .red),
        DonutSlice(value: 20, color: .blue),
        DonutSlice(value: 15, color: .green),
        DonutSlice(value: 10, color: .orange),
        DonutSlice(value: 5, color: .purple),
    ])
    .padding()
}
