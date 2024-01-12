import MEGADomain
import MEGASwiftUI
import Search
import SwiftUI

struct NodeBrowserView: View {
    @StateObject var viewModel: NodeBrowserViewModel

    var body: some View {
        if viewModel.isBackButtonShown {
            content
                .toolbar { toolbarContentWithBackButton }
        } else {
            content
               .toolbar { toolbarContentWithoutBackButton }
        }
    }

    private var content: some View {
        VStack {
            if let warningViewModel = viewModel.warningViewModel {
                WarningView(viewModel: warningViewModel)
                    .frame(height: 80)
            }
            if viewModel.isMediaDiscoveryShown, let mediaDiscoveryViewModel = viewModel.mediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.viewTask() }
    }

    @ToolbarContentBuilder
    private var toolbarContentWithBackButton: some ToolbarContent {
        toolbarLeadingBackButton
        toolbarNavigationTitle
        toolbarTrailingActions
    }

    @ToolbarContentBuilder
    private var toolbarContentWithoutBackButton: some ToolbarContent {
        toolbarLeadingAvatarImage
        toolbarNavigationTitle
        toolbarTrailingActions
    }

    @ToolbarContentBuilder
    private var toolbarLeadingBackButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.back() },
                label: { Image(.backArrow) }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarLeadingAvatarImage: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            MyAvatarIconView(
                viewModel: .init(
                    avatarObserver: viewModel.avatarViewModel,
                    onAvatarTapped: { viewModel.openUserProfile() }
                )
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarNavigationTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.title ?? "").font(.headline)
        }
    }

    @ToolbarContentBuilder
    private var toolbarTrailingActions: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(
                action: {
                    // Connect add node action
                },
                label: { Image(.navigationbarAdd) }
            )

            Menu {
                Picker(selection: $viewModel.viewMode, label: Text("ViewMode")) {
                    Text("Media Discovery").tag(ViewModePreferenceEntity.mediaDiscovery)
                    Text("List").tag(ViewModePreferenceEntity.list)
                    Text("Thumbnails").tag(ViewModePreferenceEntity.thumbnail)
                }
            } label: { Label("Sort", systemImage: "ellipsis") }
        }
    }
}
