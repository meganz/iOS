import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct LeftOffItemsWidgetLoadingView: View {
    private static let cardCount = 8

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: TokenSpacing._3) {
                ForEach(0..<Self.cardCount, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
        }
        .scrollDisabled(true)
        .shimmering()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Localizable.loading)
    }
}

private struct SkeletonCard: View {
    private typealias Layout = LeftOffItemWidgetCardView.Layout
    private static let color = TokenColors.Text.primary.swiftUI

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._2) {
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .fill(Self.color)
                .frame(width: Layout.cardWidth, height: Layout.previewHeight)

            RoundedRectangle(cornerRadius: TokenRadius.small)
                .fill(Self.color)
                .frame(width: 120, height: 12)
                .padding(TokenSpacing._2)
                .frame(width: Layout.cardWidth, height: Layout.nameRowHeight, alignment: .leading)
        }
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
    }
}

#Preview {
    LeftOffItemsWidgetLoadingView()
}
