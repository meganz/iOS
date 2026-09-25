import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ViewedLinksWidgetLoadingView: View {
    private static let rowCount = 4

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            ForEach(0..<Self.rowCount, id: \.self) { _ in
                HStack(spacing: TokenSpacing._4) {
                    SkeletonIcon()

                    SkeletonLine()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .shimmering()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Localizable.loading)
    }
}

private enum Skeleton {
    static let color = TokenColors.Text.primary.swiftUI
    static let iconSize = TokenSpacing._9
}

private struct SkeletonIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium)
            .fill(Skeleton.color)
            .frame(width: Skeleton.iconSize, height: Skeleton.iconSize)
    }
}

private struct SkeletonLine: View {
    @ScaledMetric(relativeTo: .callout) private var height: CGFloat = TokenSpacing._5

    var body: some View {
        RoundedRectangle(cornerRadius: TokenRadius.small)
            .fill(Skeleton.color)
            .frame(height: height)
    }
}

#Preview {
    ViewedLinksWidgetLoadingView()
}
