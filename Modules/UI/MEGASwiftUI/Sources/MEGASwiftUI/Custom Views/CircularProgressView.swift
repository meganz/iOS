import SwiftUI

public struct CircularProgressView: View {
    @State private var animatedProgress: Double = 0
    let progress: Double
    let progressColor: Color
    let backgroundColor: Color
    let progressWidth: CGFloat = 5

    public init(progress: Double, progressColor: Color, backgroundColor: Color) {
        self.progress = progress
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: progressWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(progressColor, lineWidth: progressWidth)
                .rotationEffect(.degrees(-90))

            Text("\(progress * 100, specifier: "%.0f")%")
                .font(Font.system(.title3))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(10)
        }
        .onAppear {
            withAnimation(.easeOut.delay(0.3)) {
                self.animatedProgress = progress
            }
        }
    }
}
