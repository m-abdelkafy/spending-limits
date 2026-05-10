import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: expense.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "Uncategorized")
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    if let account = expense.account {
                        Label(account.name, systemImage: account.type.icon)
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !expense.tags.isEmpty {
                        Text(expense.tags.map { "#\($0.name)" }.joined(separator: " "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.string(from: expense.amount))
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

struct CategoryIcon: View {
    let category: Category?

    var body: some View {
        let color = Color(hex: category?.colorHex ?? "#8E8E93")
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
            Image(systemName: category?.icon ?? "questionmark")
                .foregroundStyle(color)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }
}
