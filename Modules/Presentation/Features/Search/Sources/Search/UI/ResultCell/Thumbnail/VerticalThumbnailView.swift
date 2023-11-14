import SwiftUI

// ┌────────────────────────────────────────────────────┐
// │┌─────────────────────────────────────────────────┐ │
// ││                       .secondary(.trailingEdge) │ │
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

struct VerticalThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    
    private let layout: ResultCellLayout = .thumbnail(.vertical)
    
    var body: some View {
        VStack(spacing: .zero) {
            topInfoView
            bottomInfoView
        }
        .frame(height: 214)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipped()
    }
    
    private var topInfoView: some View {
        BackgroundView(
            image: $viewModel.thumbnailImage,
            mode: viewModel.result.backgroundDisplayMode,
            backgroundColor: thumbnailBackgroundColor,
            header: backgroundHeader,
            footer: backgroundFooter
        )
    }
    
    // hosts secondary(.trailingEdge) properties
    private var backgroundHeader: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                viewModel
                    .result
                    .properties
                    .propertyViewsFor(
                        mode: layout,
                        placement: .secondary(.trailingEdge)
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
                placement: .secondary(.trailingEdge)
            ).isNotEmpty
    }
    
    // hosts .secondary(.leading) properties
    // in practice currently play icon and duration
    private var backgroundFooter: some View {
        HStack(spacing: 1) {
            
            ForEach(viewModel.result.properties.propertiesFor(mode: layout, placement: .secondary(.leading))) { property in
                switch property.content {
                case .icon(image: let image, scalable: let scalable):
                    resultPropertyImage(image: image, scalable: scalable)
                        .frame(width: 16, height: 16)
                        .padding(2)
                case .text(let text):
                    Text(text)
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.9))
                        .background(viewModel.colorAssets._161616.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
            }
            
            Spacer()
            moreButton
        }
        .padding(.horizontal, 8)
    }
    
    // hosts title and .prominent properties
    private var topLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.title)
                .titleTextColor(
                    colorAssets: viewModel.colorAssets,
                    hasVibrantTitle: viewModel.hasVibrantTitle
                )
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    mode: layout,
                    placement: .prominent
                )
        }
    }
    
    // hosts subtitle and .secondary(.trailing) properties
    private var bottomLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.description(layout))
                .foregroundColor(.primary)
                .font(.caption)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    mode: layout,
                    placement: .secondary(.trailing)
                )
        }
    }
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreGrid
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 40, height: 40)
    }
    
    private var borderColor: Color {
        colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._545458
    }
    
    private var topNodeIconsBackgroundColor: Color {
        colorScheme == .light ? Color(white: 1, opacity: 0.3)
        : Color(white: 0, opacity: 0.4)
    }
    
    private var thumbnailBackgroundColor: Color {
        colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._1C1C1E
    }
}

struct VerticalThumbnailView_Previews: PreviewProvider {
    static func testView(
        mode: VerticalBackgroundViewMode,
        properties: [ResultProperty] = []
    ) -> some View {
        VerticalThumbnailView(
            viewModel: .init(
                result: .previewResult(
                    idx: 1,
                    thumbnailDisplayMode: .vertical,
                    backgroundDisplayMode: mode,
                    properties: properties
                ),
                rowAssets: .example,
                colorAssets: .example,
                previewContent: .example,
                actions: .init(
                    contextAction: { _ in },
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        )
        .frame(width: 173, height: 214)
    }
    static var previews: some View {
        testView(mode: .preview, properties: [.play, .duration, .someProminentIcon, .someTopIcon])
            .previewDisplayName("Video")
        testView(mode: .preview)
            .previewDisplayName("Preview")
        testView(mode: .icon)
            .previewDisplayName("Icon")
    }
}
