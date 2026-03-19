import MEGAAssets
import MEGADesignToken
import SwiftUI

struct HomeTransferIndicatorView: View {
    let progress: CGFloat
    private let indicatorSize: CGFloat = 24
    private let ringSize: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    TokenColors.Icon.secondary.swiftUI.opacity(0.2),
                    style: StrokeStyle(lineWidth: 2)
                )
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    TokenColors.Support.success.swiftUI,
                    style: StrokeStyle(lineWidth: 2)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))

            MEGAAssets.Image.transferIndicator
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        }
        .frame(width: indicatorSize, height: indicatorSize)
    }
}

#Preview {
    HStack(spacing: 16) {
        HomeTransferIndicatorView(progress: 0)
        HomeTransferIndicatorView(progress: 0.35)
        HomeTransferIndicatorView(progress: 1)
    }
    .padding()
    .background(TokenColors.Background.page.swiftUI)
}
