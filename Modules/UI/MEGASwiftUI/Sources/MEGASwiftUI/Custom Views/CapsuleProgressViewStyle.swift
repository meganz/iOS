import SwiftUI

public struct CapsuleProgressViewStyle: ProgressViewStyle {
    private let tint: Color
    private let height: CGFloat

    public init(tint: Color, height: CGFloat) {
        self.tint = tint
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.3))
                Capsule()
                    .fill(tint)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: height)
    }
}
