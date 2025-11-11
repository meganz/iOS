import MEGADesignToken
import MEGASwiftUI
import SwiftUI

// MAKE SCREEN WIDE TO SEE DOCUMENTATION
// ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
// │┌──────────────────────┐ ╔══════════════════════╗┌──────────────────────┐                       ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// ││ .prominent(.leading) │ ║       [TITLE]        ║│ .prominent(.trailing │                       │                  ││
// │└──────────────────────┘ ╚══════════════════════╝└──────────────────────┘                                           |
// │┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                                                               │       Menu       ││
// │      [AuxTITLE] (optional)                                                                     │(optional, hidden  │
// │└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘                                                                in selection mode)││
// │┌──────────────────────┐╔═══════════════╗┌────────────────────────┐┌───────────────────────────┐│                   │
// │└──────────────────────┘╚═══════════════╝└────────────────────────┘└───────────────────────────┘└ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
// The Menu (More button or select button) is not affected by the sensitive property (.sensitive modifier)
struct RevampedSearchResultRowView: View {
    private enum Constants {
        static let easeInOutDuration = 0.05
        static let longPressMininumDuration = 0.5
        static let tapHighlightDurationNs: UInt64 = 100_000_000
    }
    @ObservedObject var viewModel: SearchResultRowViewModel
    private let layout = ResultCellLayout.list
    @Environment(\.editMode) private var editMode
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var highlighted = false
    var body: some View {
        contentWithInsetsAndSwipeActions
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
                    .padding(.vertical, TokenSpacing._2)
                Spacer()
            }
            .sensitive(viewModel.isSensitive ? .opacity : .none)
            .contentShape(Rectangle())
            .onTapGesture {
                // Here we only highlight for tap selection in non-Edit mode
                // For long press and selection edit mode, we rely on List's built-in behavior for highlight cells
                if editMode?.wrappedValue.isEditing != true {
                    withAnimation(.easeInOut(duration: Constants.easeInOutDuration)) {
                        highlighted = true
                    }

                    Task {
                        try await Task.sleep(nanoseconds: Constants.tapHighlightDurationNs)
                        withAnimation(.easeInOut(duration: 0.05)) {
                            highlighted = false
                        }
                    }
                }
                viewModel.actions.selectionAction()
            }
            .onLongPressGesture(minimumDuration: Constants.longPressMininumDuration) {
                viewModel.actions.revampLongPress()
            }
            moreButton
        }
        .background(TokenColors.Background.surface1.swiftUI.opacity(highlighted ? 1 : 0))
        .contentShape(Rectangle())
        .frame(minHeight: 58)
    }

    // optional overlay property in placement .previewOverlay
    private var thumbnail: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .background(
                TokenColors.Background.surface1.swiftUI.cornerRadius(TokenRadius.small)
                    .opacity(viewModel.hasThumbnail ? 1 : 0)
            )
            .padding(.horizontal, TokenSpacing._2)
            .animatedAppearance(isContentLoaded: viewModel.isThumbnailLoadedOnce)
            .sensitive(viewModel.isSensitive && viewModel.hasThumbnail ? .blur : .none)
            .overlay(propertyViewsFor(placement: .previewOverlay))
    }

    @ViewBuilder
    private var lines: some View {
        VStack(alignment: .leading, spacing: .zero) {
            titleLine
            auxTitleLine
            subtitleLine
            noteView
            tagsView
        }
    }

    private var titleLine: some View {
        HStack(alignment: .center, spacing: 5) {
            propertyViewsFor(placement: .prominent(.leading))
            Text(viewModel.attributedTitle)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(1)
                .foregroundStyle(viewModel.titleTextColor)
                .accessibilityLabel(viewModel.accessibilityLabel)
            propertyViewsFor(placement: .prominent(.trailing))
        }
    }

    // optional, middle line of content
    @ViewBuilder var auxTitleLine: some View {
        HStack(spacing: TokenSpacing._2) {
            propertyViewsFor(placement: .auxLine)
        }
        .font(.footnote)
        .fontWeight(.regular)
        .lineLimit(1)
        .foregroundStyle(viewModel.colorAssets.subtitleTextColor)
    }

    @ViewBuilder func propertyViewsFor(placement: PropertyPlacement) -> some View {
        viewModel.result.properties.propertyViewsFor(layout: layout, placement: placement, colorAssets: viewModel.colorAssets)
    }

    private var subtitleLine: some View {
        HStack(spacing: TokenSpacing._2) {
            propertyViewsFor(placement: .secondary(.leading))
            Text(viewModel.result.description(layout))
                .font(.footnote)
                .fontWeight(.regular)
                .lineLimit(1)
                .foregroundStyle(viewModel.colorAssets.subtitleTextColor)
            propertyViewsFor(placement: .secondary(.trailing))
            Spacer()
            propertyViewsFor(placement: .secondary(.trailingEdge))
        }
    }

    @ViewBuilder
    private var noteView: some View {
        if let note = viewModel.note {
            Text(note)
                .lineLimit(1)
                .dynamicTypeSize(.xSmall ... .accessibility5)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var tagsView: some View {
        if let tagListViewModel = viewModel.tagListViewModel {
            HorizontalTagListView(viewModel: tagListViewModel)
                .padding(
                    EdgeInsets(
                        top: TokenSpacing._1,
                        leading: 0,
                        bottom: TokenSpacing._2,
                        trailing: 0
                    )
                )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var moreButton: some View {
        if editMode?.wrappedValue.isEditing != true {
            ImageButtonWrapper(
                image: Image(uiImage: viewModel.contextButtonImage),
                imageColor: TokenColors.Icon.secondary.swiftUI
            ) { button in
                viewModel.actions.contextAction(button)
            }
            .frame(width: 40)
        }
    }
}
