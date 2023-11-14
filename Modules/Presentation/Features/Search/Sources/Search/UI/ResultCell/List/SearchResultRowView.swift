import MEGASwiftUI
import SwiftUI

// MAKE SCREEN WIDE TO SEE DOCUMENTATION
// ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
// │╔═════════════╗╔══════════════════════╗┌────────────┐                                                          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// │║             ║║       [TITLE]        ║│ .prominent │                                                                             ││
// │║             ║╚══════════════════════╝└────────────┘                                                          │                   │
// │║             ║┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                                                                       Menu       ││
// │║Icon/Preview ║      [AuxTITLE] (optional)                                                                     │(optional, hidden  │
// │║(.preview    ║└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘                                                                in selection mode)││
// │║  Overlay)   ║┌──────────────────────┐╔═══════════════╗┌────────────────────────┐┌───────────────────────────┐│                   │
// │║             ║│ .secondary(.leading) │║  [SUBTITLE]   ║│ .secondary(.trailing)  ││ .secondary(.trailingEdge) │                   ││
// │╚═════════════╝└──────────────────────┘╚═══════════════╝└────────────────────────┘└───────────────────────────┘└ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

struct SearchResultRowView: View {
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionMode: Bool
    
    private let layout = ResultCellLayout.list
    
    var body: some View {
        content
            .listRowInsets(
                EdgeInsets(
                    top: -2,
                    leading: 12,
                    bottom: -2,
                    trailing: 16
                )
            )
            .onTapGesture {
                viewModel.actions.selectionAction()
            }
            .contextMenuWithPreview(
                actions: viewModel.previewContent.actions.toUIActions,
                sourcePreview: {
                    content
                },
                contentPreviewProvider: {
                    switch viewModel.previewContent.previewMode {
                    case let .preview(contentPreviewProvider):
                        return contentPreviewProvider()
                    case .noPreview:
                        return nil
                    }
                },
                didTapPreview: viewModel.actions.previewTapAction,
                didSelect: viewModel.actions.selectionAction
            )
    }
    
    private var content: some View {
        HStack {
            HStack {
                selectionIcon
                thumbnail
                Spacer()
                    .frame(width: 8)
                lines
                Spacer()
            }
            moreButton
        }
        .task {
            await viewModel.loadThumbnail()
        }
        .contentShape(Rectangle())
        .frame(minHeight: 60)
    }
    
    var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    @ViewBuilder var selectionIcon: some View {
        if selectionMode {
            Image(
                uiImage: isSelected ?
                viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
            )
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
        }
    }
    
    // optional overlay property in placement .previewOverlay
    private var thumbnail: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(propertyViewsFor(placement: .previewOverlay))
    }
    
    private var lines: some View {
        VStack(alignment: .leading, spacing: .zero) {
            titleLine
            auxTitleLine
            subtitleLine
        }
    }
    
    private var titleLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .titleTextColor(
                    colorAssets: viewModel.colorAssets,
                    hasVibrantTitle: viewModel.hasVibrantTitle
                )
            
            propertyViewsFor(placement: .prominent)
        }
    }
    
    // optional, middle line of content
    @ViewBuilder var auxTitleLine: some View {
        HStack(spacing: 4) {
            propertyViewsFor(placement: .auxLine)
        }
        .font(.subheadline)
        .lineLimit(1)
        .foregroundColor(.primary)
    }
    
    @ViewBuilder func propertyViewsFor(placement: PropertyPlacement) -> some View {
        viewModel.result.properties.propertyViewsFor(mode: layout, placement: placement)
    }
    
    private var subtitleLine: some View {
        HStack(spacing: 4) {
            propertyViewsFor(placement: .secondary(.leading))
            Text(viewModel.result.description(layout))
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
            propertyViewsFor(placement: .secondary(.trailing))
            Spacer()
            propertyViewsFor(placement: .secondary(.trailingEdge))
        }
    }
    
    @ViewBuilder
    private var moreButton: some View {
        if !selectionMode {
            UIButtonWrapper(
                image: viewModel.contextButtonImage
            ) { button in
                viewModel.actions.contextAction(button)
            }
            .frame(width: 40, height: 60)
        }
    }
}

struct SearchResultRowView_Previews: PreviewProvider {
    
    static var items: [SearchResultRowViewModel] {
        Array(0...9).map {
            .init(
                result: .previewResult(
                    idx: $0,
                    backgroundDisplayMode: .icon,
                    properties: [
                        .previewSamples[Int($0) % 3 + 1],
                        .previewSamples[Int($0)]
                    ]
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
        }
    }
    static var previews: some View {
        
        List {
            ForEach(items) {
                SearchResultRowView(
                    viewModel: $0,
                    selected: .constant([]),
                    selectionMode: .constant(false)
                )
            }
        }
        .listStyle(.plain)
    }
}

extension SearchResult {
    static func previewResult(
        idx: UInt64,
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode = .vertical,
        backgroundDisplayMode: VerticalBackgroundViewMode = .icon,
        properties: [ResultProperty] = []
    ) -> Self {
        .init(
            id: idx,
            thumbnailDisplayMode: thumbnailDisplayMode,
            backgroundDisplayMode: backgroundDisplayMode,
            title: "title\(idx)",
            description: { _ in "desc\(idx)" },
            type: .node,
            properties: properties,
            thumbnailImageData: { UIImage(systemName: "rectangle")!.pngData()! }
        )
    }
}
