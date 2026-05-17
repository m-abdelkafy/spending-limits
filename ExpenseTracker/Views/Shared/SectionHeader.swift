import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: String
    var style: Style = .uppercase
    @ViewBuilder var trailing: () -> Trailing

    enum Style {
        case uppercase
        case flush
    }

    var body: some View {
        HStack {
            Text(style == .uppercase ? title.uppercased() : title)
                .font(.system(size: 13, weight: style == .flush ? .semibold : .regular))
                .foregroundStyle(.secondary)
            Spacer()
            trailing()
        }
        .padding(.top, 18)
        .padding(.bottom, 6)
        .padding(.horizontal, style == .uppercase ? 32 : 16)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, style: Style = .uppercase) {
        self.title = title
        self.style = style
        self.trailing = { EmptyView() }
    }
}
