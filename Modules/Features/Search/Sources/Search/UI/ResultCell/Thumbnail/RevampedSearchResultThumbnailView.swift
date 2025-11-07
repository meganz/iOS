import MEGADesignToken
import MEGASwiftUI
import SwiftUI

// ┌─────────────────────────────────────────────────────────────────────────────────────┐
// │┌─────────────────────────────────────────────────┐                                  │
// ││                       .secondary(.trailingEdge) │                                  │
// │╠─────────────────────────────────────────────────╣                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                  Icon/Preview                   ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║─────────────────────┐                           ║                                  │
// │║ .secondary(.leading)│                           ║                                  │
// │╚═════════════════════════════════════════════════╝                                  │
// │┌─────────────────────┐╔══════════════════════╗┌─────────────────────┐ ┌ ─ ─ ─ ─ ─ ┐ │
// ││.prominent(.leading) │║       [TITLE]        ║│.prominent(.trailing │               │
// │└─────────────────────┘╚══════════════════════╝└─────────────────────┘ │   Menu    │ │
// │╔═══════════════╗ ┌─────────────────┐                                     Select     │
// │║  [SUBTITLE]   ║ │.secondary(.trail│                                  │           │ │
// │╚═══════════════╝ └─────────────────┘                                   ─ ─ ─ ─ ─ ─  │
// └─────────────────────────────────────────────────────────────────────────────────────┘
// The Menu Select (More button or select button) is not affected by the sensitive property (.sensitive modifier)

struct RevampedSearchResultThumbnailView: View {
    private enum Constants {
        static let cellHeight = 184.0
        static let topViewHeight = 148.0
        static let bottomViewHeight = 155.0
        static let standardIconSize = 24.0
        static let bottomTrailingPropertyImageSize = 16.0
    }

    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionEnabled: Bool

    private let layout: ResultCellLayout = .thumbnail

    var body: some View {
        VStack(spacing: .zero) {
            topInfoView
            bottomInfoView
        }
        .onTapGesture {
            // [IOS-10758]
        }
        .frame(height: Constants.cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        .clipped()
        .task {
            await viewModel.loadThumbnail()
        }
    }

    private var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }

    private var topInfoView: some View {
        RevampedThumbnailBackgroundView(
            image: viewModel.thumbnailImage,
            isThumbnailLoaded: viewModel.isThumbnailLoadedOnce,
            mode: viewModel.result.backgroundDisplayMode,
            backgroundColor: viewModel.colorAssets.verticalThumbnailPreviewBackground,
            isSensitive: viewModel.isSensitive
        )
        .frame(height: Constants.topViewHeight)
        .sensitive(viewModel.isSensitive ? .opacity : .none)
        .clipped()
        .overlay(alignment: .topTrailing) {
            backgroundHeader
        }
        .overlay(alignment: .bottomTrailing) {
            backgroundFooter
        }
    }

    // hosts .secondary(.trailingEdge) properties
    private var backgroundHeader: some View {
        HStack(spacing: TokenSpacing._2) {
            Spacer()
            ForEach(
                viewModel
                    .result
                    .properties
                    .propertiesFor(mode: .thumbnail, placement: .secondary(.trailingEdge))
            ) { property in
                ZStack {
                    TokenColors.Background.surfaceTransparent.swiftUI
                        .frame(width: Constants.standardIconSize, height: Constants.standardIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                    propertyView(for: property, colorAssets: viewModel.colorAssets, placement: .secondary(.trailingEdge))
                }
            }
        }
        .padding([.trailing, .top], TokenSpacing._2)
    }

    // hosts .secondary(.leading) properties
    // in practice currently play icon and duration
    private var backgroundFooter: some View {
        HStack(spacing: 1) {
            let placement = PropertyPlacement.secondary(.leading)
            ForEach(viewModel.result.properties.propertiesFor(mode: layout, placement: placement) ) { property in
                switch property.content {
                case .icon(image: let image, layoutConfig: let layoutConfig):
                    property.resultPropertyImage(image: image, layoutConfig: layoutConfig, colorAssets: viewModel.colorAssets, placement: placement)
                        .frame(width: Constants.bottomTrailingPropertyImageSize, height: Constants.bottomTrailingPropertyImageSize)
                        .padding(TokenSpacing._1)
                case .text(let text):
                    Text(text)
                        .padding(TokenSpacing._1)
                        .font(.caption2)
                        .foregroundColor(viewModel.colorAssets.verticalThumbnailFooterText)
                        .background(viewModel.colorAssets.verticalThumbnailFooterBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                case .spacer:
                    Spacer()
                }
            }
        }
        .padding([.trailing, .bottom], TokenSpacing._2)
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                topLine
            }.sensitive(viewModel.isSensitive ? .opacity : .none)

            Spacer()
            trailingView
                .frame(width: Constants.standardIconSize)
        }
        .padding(.horizontal, TokenSpacing._2)
    }

    @ViewBuilder private var trailingView: some View {
        if selectionEnabled {
            selectionIcon
        } else {
            moreButton
        }
    }

    private var selectionIcon: some View {
        Image(
            uiImage: isSelected ?
            viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
        )
        .resizable()
        .scaledToFit()
        .frame(width: Constants.standardIconSize, height: Constants.standardIconSize)
    }

    // hosts title and .prominent properties
    private var topLine: some View {
        HStack(spacing: TokenSpacing._2) {
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .prominent(.leading),
                    colorAssets: viewModel.colorAssets
                )

            Text(viewModel.plainTitle)
                .foregroundStyle(viewModel.titleTextColor)
                .font(.caption)
                .lineLimit(2)
                .accessibilityLabel(viewModel.accessibilityLabel)

            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .prominent(.trailing),
                    colorAssets: viewModel.colorAssets
                )
        }
    }

    private var moreButton: some View {
        ImageButtonWrapper(
            image: Image(uiImage: viewModel.moreGrid),
            imageColor: TokenColors.Icon.secondary.swiftUI
        ) { button in
            viewModel.actions.contextAction(button)
        }
    }

    @ViewBuilder private func propertyView(for property: ResultProperty, colorAssets: SearchConfig.ColorAssets, placement: PropertyPlacement) -> some View {
        switch property.content {
        case let .icon(image: image, layoutConfig: layoutConfig):
            property.resultPropertyImage(image: image, layoutConfig: layoutConfig, colorAssets: colorAssets, placement: placement)
                .frame(width: layoutConfig.size, height: layoutConfig.size)
        case .text(let text):
            Text(text)
        case .spacer:
            Spacer()
        }
    }
}
