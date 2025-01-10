import MEGADesignToken
import MEGASwiftUI
import SwiftUI

// MAKE SCREEN WIDE TO SEE DOCUMENTATION
// ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
// │╔══════════════════════╗┌────────────┐                                                          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// │║       [TITLE]        ║│ .prominent │                                                                             ││
// │╚══════════════════════╝└────────────┘                                                          │                   │
// │┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                                                                       Menu       ││
// │      [AuxTITLE] (optional)                                                                     │(optional, hidden  │
// │└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘                                                                in selection mode)││
// │┌──────────────────────┐╔═══════════════╗┌────────────────────────┐┌───────────────────────────┐│                   │
// │└──────────────────────┘╚═══════════════╝└────────────────────────┘└───────────────────────────┘└ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
// The Menu (More button or select button) is not affected by the sensitive property (.sensitive modifier)

struct SearchResultRowView: View {
    @ObservedObject var viewModel: SearchResultRowViewModel
    private let layout = ResultCellLayout.list
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        contentWithInsetsAndSwipeActions
            .replacedByContextMenuWithPreview(
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
            .task {
                await viewModel.loadThumbnail()
            }
    }
    
    private var contentWithInsetsAndSwipeActions: some View {
        content
            .swipeActions {
                ForEach(viewModel.swipeActions, id: \.self) { swipeAction in
                    Button(action: swipeAction.action) {
                        swipeAction
                            .image
                            .renderingMode(.template)
                            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    }
                    .tint(swipeAction.backgroundColor)
                }
            }
            .listRowInsets(
                EdgeInsets(
                    top: -2,
                    leading: 12,
                    bottom: -2,
                    trailing: 16
                )
            )
    }
    
    private var content: some View {
        HStack {
            HStack {
                thumbnail
                Spacer()
                    .frame(width: 8)
                lines
                Spacer()
            }
            .sensitive(viewModel.isSensitive ? .opacity : .none)
            moreButton
        }
        .contentShape(Rectangle())
        .frame(minHeight: 60)
    }
    
    // optional overlay property in placement .previewOverlay
    private var thumbnail: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .animatedAppearance(isContentLoaded: viewModel.isThumbnailLoadedOnce)
            .sensitive(viewModel.isSensitive && viewModel.hasThumbnail ? .blur : .none)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(propertyViewsFor(placement: .previewOverlay))
    }
    
    private var lines: some View {
        VStack(alignment: .leading, spacing: .zero) {
            titleLine
            auxTitleLine
            subtitleLine
            note
        }
    }
    
    private var titleLine: some View {
        HStack(spacing: 4) {
            Text(viewModel.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(viewModel.titleTextColor)
                .accessibilityLabel(viewModel.accessibilityIdentifier)
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
        .foregroundStyle(viewModel.colorAssets.subtitleTextColor)
    }
    
    @ViewBuilder func propertyViewsFor(placement: PropertyPlacement) -> some View {
        viewModel.result.properties.propertyViewsFor(layout: layout, placement: placement, colorAssets: viewModel.colorAssets)
    }
    
    private var subtitleLine: some View {
        HStack(spacing: 4) {
            propertyViewsFor(placement: .secondary(.leading))
            Text(viewModel.result.description(layout))
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(viewModel.colorAssets.subtitleTextColor)
            propertyViewsFor(placement: .secondary(.trailing))
            Spacer()
            propertyViewsFor(placement: .secondary(.trailingEdge))
        }
    }

    @ViewBuilder
    private var note: some View {
        if let note = viewModel.note {
            Text(note)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(viewModel.colorAssets.nodeDescriptionTextNormalColor)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var moreButton: some View {
        if editMode?.wrappedValue.isEditing != true {
            UIButtonWrapper(
                image: viewModel.contextButtonImage
            ) { button in
                viewModel.actions.contextAction(button)
            }
            .frame(width: 40, height: 60)
        }
    }
}

#Preview {
    var items: [SearchResultRowViewModel] {
        Array(0...9).map {
            .init(
                result: result(for: $0),
                query: { nil },
                rowAssets: .example,
                colorAssets: .example,
                previewContent: .example,
                actions: actions,
                swipeActions: []
            )
        }
    }
    
    var actions: SearchResultRowViewModel.UserActions {
        .init(
            contextAction: { _ in },
            selectionAction: {},
            previewTapAction: {}
        )
    }
    
    func result(for index: Int) -> SearchResult {
        .previewResult(
            idx: UInt64(index),
            backgroundDisplayMode: .icon,
            properties: [
                .previewSamples[index % 3 + 1],
                .previewSamples[index]
            ]
        )
    }
    
    return List {
        ForEach(items) {
            SearchResultRowView(
                viewModel: $0
            )
        }
    }
    .listStyle(.plain)
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
            note: nil,
            isSensitive: false,
            hasThumbnail: false,
            description: { _ in "desc\(idx)" },
            type: .node,
            properties: properties,
            thumbnailImageData: { UIImage(systemName: "rectangle")!.pngData()! },
            swipeActions: { _ in [] }
        )
    }
}
