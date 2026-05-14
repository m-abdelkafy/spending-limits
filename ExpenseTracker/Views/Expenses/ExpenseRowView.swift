import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(primaryLabel)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    accountLabel
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
            Text(amountText)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch expense.kind {
        case .expense:
            CategoryIcon(category: expense.category)
        case .income:
            KindBadge(systemName: TransactionKind.income.icon, tint: .green)
        case .transfer:
            KindBadge(systemName: TransactionKind.transfer.icon, tint: .gray)
        }
    }

    private var primaryLabel: String {
        switch expense.kind {
        case .expense:
            return expense.category?.name ?? "Uncategorized"
        case .income:
            return expense.category?.name ?? "Income"
        case .transfer:
            return "Transfer"
        }
    }

    @ViewBuilder
    private var accountLabel: some View {
        switch expense.kind {
        case .expense, .income:
            if let account = expense.account {
                Label(account.name, systemImage: account.type.icon)
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .transfer:
            let from = expense.account?.name ?? "—"
            let to = expense.toAccount?.name ?? "—"
            Text("\(from) → \(to)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var amountText: String {
        let base = CurrencyFormatter.string(from: expense.amount)
        switch expense.kind {
        case .expense, .transfer:
            return base
        case .income:
            return "+\(base)"
        }
    }

    private var amountColor: Color {
        switch expense.kind {
        case .expense: return .primary
        case .income: return .green
        case .transfer: return .secondary
        }
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

private struct KindBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
            Image(systemName: systemName)
                .foregroundStyle(tint)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }
}
