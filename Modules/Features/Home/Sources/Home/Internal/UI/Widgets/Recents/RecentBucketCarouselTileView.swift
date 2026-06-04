import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

/// Owns a single tile's view model so that loading its thumbnail only
/// re-renders this tile, not the whole carousel sheet.
struct RecentBucketCarouselFileTileView: View {
    @StateObject private var viewModel: RecentBucketCarouselTileViewModel
    private let action: () -> Void

    init(node: NodeEntity, action: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: RecentBucketCarouselTileViewModel(node: node))
        self.action = action
    }

    var body: some View {
        RecentBucketCarouselTileView(
            variant: viewModel.hasThumbnail ? .fileThumbnail(image: viewModel.image) : .fileIcon(image: viewModel.image),
            action: action
        )
        .task {
            await viewModel.loadThumbnail()
        }
    }
}

struct RecentBucketCarouselTileView: View {
    enum Variant {
        case fileThumbnail(image: Image)
        case fileIcon(image: Image)
        case seeAll
    }

    let variant: Variant
    let action: () -> Void

    private static let tileHeight: CGFloat = 100
    private static let fileTileWidth: CGFloat = 126
    private static let seeAllTileWidth: CGFloat = 56
    private static let tileCornerRadius: CGFloat = TokenRadius.medium
    private static let iconSize: CGFloat = 32

    var body: some View {
        Button(action: action) {
            switch variant {
            case let .fileThumbnail(image):
                thumbnailTile(image: image)
            case let .fileIcon(image):
                iconTile(image: image)
            case .seeAll:
                seeAllTile
            }
        }
        .buttonStyle(.plain)
    }

    private func thumbnailTile(image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: Self.fileTileWidth, height: Self.tileHeight)
            .background(TokenColors.Background.surface2.swiftUI)
            .clipShape(RoundedRectangle(cornerRadius: Self.tileCornerRadius))
    }

    private func iconTile(image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Self.iconSize, height: Self.iconSize)
            .frame(width: Self.fileTileWidth, height: Self.tileHeight)
            .background(TokenColors.Background.surface2.swiftUI)
            .clipShape(RoundedRectangle(cornerRadius: Self.tileCornerRadius))
    }

    private var seeAllTile: some View {
        MEGAAssets.Image.chevronRight
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .frame(width: 7.5, height: 13.5)
            .frame(width: Self.seeAllTileWidth, height: Self.tileHeight)
    }
}
