import MEGADesignToken
import SwiftUI

// ┌────────────────────────────────────────────────────┐
// │┌─────────────────────────────────────────────────┐ │
// ││                                    .verticalTop │ │
// │╠─────────────────────────────────────────────────╣ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                  Icon/Preview                   ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║                                                 ║ │
// │║─────────────────────┐                           ║ │
// │║ .secondary(.leading)│                           ║ │
// │╚═════════════════════════════════════════════════╝ │
// │╔══════════════════════╗┌───────────┐ ┌ ─ ─ ─ ─ ─ ┐ │
// │║       [TITLE]        ║│.prominent │               │
// │╚══════════════════════╝└───────────┘ │   Menu    │ │
// │╔═══════════════╗ ┌─────────────────┐    Select     │
// │║  [SUBTITLE]   ║ │.secondary(.trail│ │           │ │
// │╚═══════════════╝ └─────────────────┘  ─ ─ ─ ─ ─ ─  │
// └────────────────────────────────────────────────────┘
// The Menu Select (More button or select button) is not affected by the sensitive property (.sensitive modifier)

struct VerticalThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionEnabled: Bool
    
    private let layout: ResultCellLayout = .thumbnail(.vertical)
    
    var body: some View {
        VStack(spacing: .zero) {
            topInfoView
            bottomInfoView
        }
        .frame(height: 214)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipped()
    }
    
    var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    private var topInfoView: some View {
        BackgroundView(
            image: viewModel.thumbnailImage,
            isThumbnailLoaded: viewModel.isThumbnailLoadedOnce,
            mode: viewModel.result.backgroundDisplayMode,
            backgroundColor: thumbnailBackgroundColor,
            header: backgroundHeader,
            footer: backgroundFooter,
            isSensitive: viewModel.isSensitive
        )
        .sensitive(viewModel.isSensitive ? .opacity : .none)
        .clipped()
    }
    
    // hosts .verticalTop properties
    private var backgroundHeader: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                viewModel
                    .result
                    .properties
                    .propertyViewsFor(
                        layout: layout,
                        placement: .verticalTop,
                        colorAssets: viewModel.colorAssets
                    )
            }
            .padding(.vertical, 4)
        }
        .frame(height: 24)
        .padding(.trailing, 5)
        .background(
            hasTopHeaderIcons ? topNodeIconsBackgroundColor : .clear
        )
    }
    
    var hasTopHeaderIcons: Bool {
        viewModel
            .result
            .properties
            .propertiesFor(
                mode: layout,
                placement: .verticalTop
            ).isNotEmpty
    }
    
    // hosts .secondary(.leading) properties
    // in practice currently play icon and duration
    private var backgroundFooter: some View {
        HStack(spacing: 1) {
            let placement = PropertyPlacement.secondary(.leading)
            ForEach(viewModel.result.properties.propertiesFor(mode: layout, placement: placement) ) { property in
                switch property.content {
                case .icon(image: let image, scalable: let scalable):
                    property.resultPropertyImage(image: image, scalable: scalable, colorAssets: viewModel.colorAssets, placement: placement)
                        .frame(width: 16, height: 16)
                        .padding(2)
                case .text(let text):
                    Text(text)
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(viewModel.colorAssets.verticalThumbnailFooterText)
                        .background(viewModel.colorAssets.verticalThumbnailFooterBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                case .spacer:
                    Spacer()
                }
            }
            Spacer()
        }
        .padding(.leading, 3)
        .padding(.trailing, 8)
        .padding(.bottom, 3)
    }
    
    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                topLine
                bottomLine
            }.sensitive(viewModel.isSensitive ? .opacity : .none)
            
            Spacer()
            trailingView
                .frame(
                    width: 40,
                    height: 40
                )
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder var trailingView: some View {
        if selectionEnabled {
            selectionIcon
        } else {
            moreButton
        }
    }
    
    @ViewBuilder var selectionIcon: some View {
        Image(
            uiImage: isSelected ?
            viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
        )
        .resizable()
        .scaledToFit()
        .frame(width: 22, height: 22)
    }
    
    // hosts title and .prominent properties
    private var topLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.title)
                .foregroundStyle(viewModel.titleTextColor)
                .font(.system(.caption).weight(.medium))
                .lineLimit(1)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .prominent,
                    colorAssets: viewModel.colorAssets
                )
        }
    }
    
    // hosts subtitle and .secondary(.trailing) properties
    private var bottomLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.description(layout))
                .foregroundColor(viewModel.colorAssets.subtitleTextColor)
                .font(.caption)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .secondary(.trailing),
                    colorAssets: viewModel.colorAssets
                )
        }
    }
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreGrid
        ) { button in
            viewModel.actions.contextAction(button)
        }
    }
    
    private var borderColor: Color {
        if selectionEnabled && isSelected {
            viewModel.colorAssets.selectedBorderColor
        } else {
            viewModel.colorAssets.unselectedBorderColor
        }
    }
    
    private var topNodeIconsBackgroundColor: Color {
        viewModel.colorAssets.verticalThumbnailTopIconsBackground
    }
    
    private var thumbnailBackgroundColor: Color {
        viewModel.colorAssets.verticalThumbnailPreviewBackground
    }
}

#Preview("Video") {
    VerticalThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                thumbnailDisplayMode: .vertical,
                backgroundDisplayMode: .preview,
                properties: [.play, .duration, .someProminentIcon, .someTopIcon]
            ),
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}

#Preview("Preview") {
    VerticalThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                thumbnailDisplayMode: .vertical,
                backgroundDisplayMode: .preview,
                properties: []
            ),
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}

#Preview("Icon") {
    VerticalThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                thumbnailDisplayMode: .vertical,
                backgroundDisplayMode: .icon,
                properties: []
            ),
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}
