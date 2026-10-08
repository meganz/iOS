import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct LeftOffItemWidgetCardView: View {
    enum Layout {
        static let cardWidth: CGFloat = 180
        static let cardHeight: CGFloat = 180
        static let previewHeight: CGFloat = 144
        static let nameRowHeight: CGFloat = 32
        static let fileTypeIconSize: CGFloat = 72
        static let moreTileWidth: CGFloat = 90
    }

    @State private var viewModel: LeftOffItemCardViewModel
    private let card: LeftOffItemWidgetCardModel
    private let onTap: @MainActor () -> Void

    init(
        card: LeftOffItemWidgetCardModel,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        onTap: @escaping @MainActor () -> Void
    ) {
        self.card = card
        self.onTap = onTap
        _viewModel = State(
            wrappedValue: LeftOffItemCardViewModel(thumbnailLoader: thumbnailLoader)
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: TokenSpacing._2) {
                preview
                    .sensitive(card.isSensitive ? .blur : .none)
                nameRow
                    .sensitive(card.isSensitive ? .opacity : .none)
            }
            .frame(width: Layout.cardWidth, height: Layout.cardHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel([card.name, card.durationText].compactMap { $0 }.joined(separator: ", "))
        .task(id: card.node.hasThumbnail) {
            await viewModel.loadThumbnail(for: card.node)
        }
    }

    private var preview: some View {
        ZStack(alignment: .bottomTrailing) {
            TokenColors.Background.surface1.swiftUI

            if let thumbnail = viewModel.thumbnail {
                thumbnail.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Layout.cardWidth, height: Layout.previewHeight)
                    .clipped()
            } else {
                viewModel.fileTypeIcon(for: card.name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.fileTypeIconSize, height: Layout.fileTypeIconSize)
                    .frame(width: Layout.cardWidth, height: Layout.previewHeight)
            }

            if let durationText = card.durationText {
                Text(durationText)
                    .font(.caption2)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, TokenSpacing._2)
                    .padding(.vertical, TokenSpacing._1)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: TokenRadius.extraSmall))
                    .padding(TokenSpacing._2)
            }
        }
        .frame(width: Layout.cardWidth, height: Layout.previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
    }

    private var nameRow: some View {
        Text(card.name)
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(TokenSpacing._2)
            .frame(width: Layout.cardWidth, height: Layout.nameRowHeight, alignment: .leading)
    }
}
