import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI

struct LeftOffItemsCarouselView: View {
    let items: [LeftOffItemWidgetCardModel]
    let hasMore: Bool
    let isLoadingMore: Bool
    let thumbnailLoader: any ThumbnailLoaderProtocol
    let onOpenItem: @MainActor (LeftOffItemWidgetCardModel) -> Void
    let onLoadMore: @MainActor () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: TokenSpacing._3) {
                ForEach(items) { card in
                    LeftOffItemWidgetCardView(
                        card: card,
                        thumbnailLoader: thumbnailLoader,
                        onTap: { onOpenItem(card) }
                    )
                }

                if hasMore {
                    MoreTileView(action: onLoadMore)
                        .disabled(isLoadingMore)
                }
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
        }
    }
}
