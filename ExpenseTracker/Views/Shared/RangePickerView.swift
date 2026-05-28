import SwiftUI

struct RangePickerView: View {
    @Binding var range: DateRange
    var allowFutureAnchors: Bool = false

    @State private var showSheet = false

    var body: some View {
        HStack(spacing: 10) {
            Picker("Scope", selection: scopeBinding) {
                ForEach(DateRangeScope.allCases, id: \.self) { scope in
                    Text(scope.label).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                stepButton(direction: -1, systemImage: "chevron.left")

                Button {
                    showSheet = true
                } label: {
                    Text(range.title())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .padding(.horizontal, 4)
                        .frame(minWidth: 80)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(range.scope.label.lowercased())")
                .accessibilityValue(range.title())

                stepButton(direction: 1, systemImage: "chevron.right")
                    .disabled(isAtUpperBound)
                    .opacity(isAtUpperBound ? 0.35 : 1)
            }
        }
        .sheet(isPresented: $showSheet) {
            RangePickerSheet(
                range: $range,
                isPresented: $showSheet,
                allowFutureAnchors: allowFutureAnchors
            )
            .presentationDetents([.medium])
        }
    }

    private var scopeBinding: Binding<DateRangeScope> {
        Binding(
            get: { range.scope },
            set: { newScope in
                if newScope != range.scope {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        range = DateRange(scope: newScope, anchor: range.anchor)
                    }
                }
            }
        )
    }

    private func stepButton(direction: Int, systemImage: String) -> some View {
        Button {
            step(by: direction)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction < 0 ? "Previous \(range.scope.label.lowercased())" : "Next \(range.scope.label.lowercased())")
    }

    private var isAtUpperBound: Bool {
        guard !allowFutureAnchors else { return false }
        return range.isCurrent()
    }

    private func step(by amount: Int) {
        let cal = Calendar.current
        let component: Calendar.Component = range.scope == .month ? .month : .year
        guard let next = cal.date(byAdding: component, value: amount, to: range.anchor) else { return }
        let granularity: Calendar.Component = range.scope == .month ? .month : .year
        if !allowFutureAnchors, amount > 0,
           cal.compare(next, to: .now, toGranularity: granularity) == .orderedDescending {
            return
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            range = DateRange(scope: range.scope, anchor: next)
        }
    }
}

private struct RangePickerSheet: View {
    @Binding var range: DateRange
    @Binding var isPresented: Bool
    var allowFutureAnchors: Bool

    @State private var draftAnchor: Date = .now

    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if allowFutureAnchors {
                        DatePicker(
                            "Date",
                            selection: $draftAnchor,
                            displayedComponents: .date
                        )
                    } else {
                        DatePicker(
                            "Date",
                            selection: $draftAnchor,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Select \(range.scope.label.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        range = DateRange(scope: range.scope, anchor: draftAnchor)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { draftAnchor = range.anchor }
        }
    }
}

#Preview {
    @Previewable @State var range: DateRange = .currentMonth()
    return VStack(spacing: 20) {
        RangePickerView(range: $range)
            .padding(.horizontal)
        Text("\(range.scope.label): \(range.title())")
            .font(.headline)
    }
    .padding(.vertical)
}
