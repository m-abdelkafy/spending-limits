import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var height: Height = .regular
    var tint: Color? = nil
    var marker: Double? = nil
    var showStripesWhenOver: Bool = false

    enum Height {
        case thin, regular, thick

        var value: CGFloat {
            switch self {
            case .thin: return 3
            case .regular: return 6
            case .thick: return 10
            }
        }
    }

    private var clampedProgress: Double {
        max(0, min(progress, 1))
    }

    private var color: Color {
        if let tint { return tint }
        if progress > 1 { return .red }
        if progress > 0.8 { return .orange }
        return .accentColor
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * clampedProgress)

                if showStripesWhenOver && progress > 1 {
                    Capsule()
                        .fill(stripePattern)
                        .frame(width: geo.size.width)
                        .clipShape(Capsule())
                }

                if let marker {
                    let x = geo.size.width * max(0, min(marker, 1))
                    Rectangle()
                        .fill(Color.primary.opacity(0.55))
                        .frame(width: 2, height: height.value + 4)
                        .offset(x: x - 1, y: -2)
                }
            }
        }
        .frame(height: height.value)
    }

    private var stripePattern: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.35), location: 0.0),
                .init(color: .white.opacity(0.35), location: 0.25),
                .init(color: .clear, location: 0.25),
                .init(color: .clear, location: 0.5),
                .init(color: .white.opacity(0.35), location: 0.5),
                .init(color: .white.opacity(0.35), location: 0.75),
                .init(color: .clear, location: 0.75),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressBarView(progress: 0.45, height: .thick, marker: 0.55)
        ProgressBarView(progress: 0.92, height: .regular)
        ProgressBarView(progress: 1.2, height: .regular, showStripesWhenOver: true)
        ProgressBarView(progress: 0.3, height: .thin, tint: .purple)
    }
    .padding()
}
