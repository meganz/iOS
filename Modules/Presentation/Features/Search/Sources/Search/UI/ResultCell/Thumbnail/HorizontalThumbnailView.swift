import SwiftUI

// MAKE SCREEN WIDE TO SEE DOCUMENTATION
// ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
// │╔═════════════╗╔══════════════════════╗┌────────────┐                                                          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// │║             ║║       [TITLE]        ║│ .prominent │                                                                             ││
// │║             ║╚══════════════════════╝└────────────┘                                                          │                   │
// │║             ║                                                                                                        Menu       ││
// │║    Icon     ║                                                                                                │(optional, hidden  │
// │║             ║                                                                                                 in selection mode)││
// │║             ║╔═══════════════╗┌──────────────────────┐┌────────────────────────┐┌───────────────────────────┐│                   │
// │║             ║║  [SUBTITLE]   ║│ .secondary(.leading) ││ .secondary(.trailing)  ││ .secondary(.trailingEdge) │                   ││
// │╚═════════════╝╚═══════════════╝└──────────────────────┘└────────────────────────┘└───────────────────────────┘└ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
// The Menu (More button or select button) is not affected by the sensitive property (.sensitive modifier)

struct HorizontalThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionEnabled: Bool
    
    @ScaledMetric(relativeTo: .title) var height = 46
    
    private let layout: ResultCellLayout = .thumbnail(.horizontal)
    
    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: 8) {
                thumbnailImage
                
                VStack(alignment: .leading, spacing: .zero) {
                    titleAndLabel
                    infoAndIcons
                }
                .padding(.vertical, 8)
            }
            .sensitive(viewModel.isSensitive ? .opacity : .none)
            Spacer()
            trailingView
        }
        .padding(.leading, 9)
        .padding(.trailing, 8)
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var thumbnailImage: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .animatedAppearance(isContentLoaded: viewModel.isThumbnailLoadedOnce)
            .sensitive(viewModel.isSensitive && viewModel.hasThumbnail ? .blur : .none)
    }
    
    private var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    private var titleAndLabel: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.title)
                .font(.system(.caption).weight(.medium))
                .foregroundStyle(viewModel.titleTextColor)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .prominent, colorAssets: viewModel.colorAssets)
        }
        .frame(height: 12)
    }
    
    private var infoAndIcons: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.description(layout))
                .font(.caption)
                .foregroundStyle(viewModel.colorAssets.subtitleTextColor)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.leading), colorAssets: viewModel.colorAssets)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.trailing), colorAssets: viewModel.colorAssets)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.trailingEdge), colorAssets: viewModel.colorAssets)

        }
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
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreList
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 24, height: 24)
    }
    
    private var borderColor: Color {
        if selectionEnabled && isSelected {
            viewModel.colorAssets.selectedBorderColor
        } else {
            viewModel.colorAssets.unselectedBorderColor
        }
    }
}
