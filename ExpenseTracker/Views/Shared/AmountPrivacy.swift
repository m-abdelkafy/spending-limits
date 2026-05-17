import SwiftUI

struct PrivacyBlur: ViewModifier {
    @AppStorage("hideAmounts") private var hideAmounts: Bool = false

    func body(content: Content) -> some View {
        content
            .blur(radius: hideAmounts ? 6 : 0)
            .animation(.easeInOut(duration: 0.15), value: hideAmounts)
    }
}

extension View {
    func privacyBlur() -> some View {
        modifier(PrivacyBlur())
    }
}

struct ConditionalBlur: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active { content.privacyBlur() } else { content }
    }
}

struct PrivacyToggleButton: View {
    @AppStorage("hideAmounts") private var hideAmounts: Bool = false

    var body: some View {
        Button {
            hideAmounts.toggle()
        } label: {
            Image(systemName: hideAmounts ? "eye.slash.fill" : "eye.fill")
        }
        .accessibilityLabel(hideAmounts ? "Show amounts" : "Hide amounts")
    }
}
