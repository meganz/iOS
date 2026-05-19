import SwiftUI

public struct CircularProgressView: View {
    let progress: Double
    let tint: Color
    let lineWidth: CGFloat

    public init(progress: Double, tint: Color, lineWidth: CGFloat = 2) {
        self.progress = progress
        self.tint = tint
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
    }
}
