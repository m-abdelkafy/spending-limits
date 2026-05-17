import SwiftUI

struct MonthPickerView: View {
    @Binding var month: Date
    var allowFutureMonths: Bool = false

    @State private var showSheet = false

    var body: some View {
        HStack(spacing: 2) {
            stepButton(direction: -1, systemImage: "chevron.left")

            Button {
                showSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(monthLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 130)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select month")
            .accessibilityValue(monthLabel)

            stepButton(direction: 1, systemImage: "chevron.right")
                .disabled(isAtBoundary(direction: 1))
                .opacity(isAtBoundary(direction: 1) ? 0.35 : 1)
        }
        .sheet(isPresented: $showSheet) {
            MonthPickerSheet(
                month: $month,
                isPresented: $showSheet,
                allowFutureMonths: allowFutureMonths
            )
            .presentationDetents([.medium])
        }
    }

    private func stepButton(direction: Int, systemImage: String) -> some View {
        Button {
            step(by: direction)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction < 0 ? "Previous month" : "Next month")
    }

    private var monthLabel: String {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: .now)
        let monthYear = cal.component(.year, from: month)
        if monthYear == currentYear {
            return month.formatted(.dateTime.month(.wide))
        }
        return month.formatted(.dateTime.month(.wide).year())
    }

    private func isAtBoundary(direction: Int) -> Bool {
        guard direction > 0, !allowFutureMonths else { return false }
        return Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func step(by months: Int) {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .month, value: months, to: month) else { return }
        if !allowFutureMonths, months > 0,
           cal.compare(next, to: .now, toGranularity: .month) == .orderedDescending {
            return
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            month = Budget.normalize(month: next)
        }
    }
}

private struct MonthPickerSheet: View {
    @Binding var month: Date
    @Binding var isPresented: Bool
    var allowFutureMonths: Bool

    @State private var draft: Date = .now

    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if allowFutureMonths {
                        DatePicker(
                            "Month",
                            selection: $draft,
                            displayedComponents: .date
                        )
                    } else {
                        DatePicker(
                            "Month",
                            selection: $draft,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Select month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        month = Budget.normalize(month: draft)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { draft = month }
        }
    }
}

#Preview {
    @Previewable @State var month: Date = .now
    return VStack(spacing: 24) {
        MonthPickerView(month: $month)
        Text(month.formatted(.dateTime.year().month()))
    }
    .padding()
}
