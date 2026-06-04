import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentBucketCarouselSheetView: View {
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let actionHandler: @MainActor (RecentBucketCarouselSheetViewModel.Action) -> Void
    }

    private static let carouselTileHeight: CGFloat = 100
    private static let estimatedHeight: CGFloat = 288

    @StateObject private var viewModel: RecentBucketCarouselSheetViewModel
    @State private var contentHeight: CGFloat = 0

    init(dependency: Dependency) {
        _viewModel = StateObject(
            wrappedValue: RecentBucketCarouselSheetViewModel(
                bucket: dependency.bucket,
                actionHandler: dependency.actionHandler
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            sheetContent
                // Detent wraps tightly around the content (which adapts to Dynamic Type), accounting for the
                // bottom safe area so the last row isn't clipped by the home indicator.
                .presentationDetents([.height(resolvedHeight + proxy.safeAreaInsets.bottom)])
        }
        .presentationDragIndicator(.visible)
    }

    private var resolvedHeight: CGFloat {
        contentHeight > 0 ? contentHeight : Self.estimatedHeight
    }

    @ViewBuilder
    private var sheetContent: some View {
        let base = content
            .onPreferenceChange(ContentHeightPreferenceKey.self) { contentHeight = $0 }

        if #available(iOS 16.4, *) {
            base.presentationBackground(TokenColors.Background.page.swiftUI)
        } else {
            base
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            carousel
            if viewModel.showsShowInLocation {
                showInLocationRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }

    private var headerView: some View {
        HStack(spacing: TokenSpacing._3) {
            viewModel.header.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(viewModel.header.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                if !viewModel.header.subtitle.isEmpty {
                    Text(viewModel.header.subtitle)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .padding(.top, TokenSpacing._5)
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._2) {
                ForEach(viewModel.displayedNodes, id: \.handle) { node in
                    RecentBucketCarouselFileTileView(node: node) {
                        viewModel.onTileTap(handle: node.handle)
                    }
                }

                RecentBucketCarouselTileView(variant: .seeAll) {
                    viewModel.onSeeAllTap()
                }
            }
        }
        .frame(height: Self.carouselTileHeight)
        .padding(.top, TokenSpacing._5)
    }

    private var showInLocationRow: some View {
        HStack(spacing: TokenSpacing._3) {
            MEGAAssets.Image.monoFileSearchMediumRegularOutline
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 24, height: 24)

            Text(Strings.Localizable.Home.Recent.Bucket.Carousel.showInLocation)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.top, TokenSpacing._5)
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
