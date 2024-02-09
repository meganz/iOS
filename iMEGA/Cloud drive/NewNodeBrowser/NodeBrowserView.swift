import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct NodeBrowserView: View {
    
    @StateObject var viewModel: NodeBrowserViewModel

    var body: some View {
        switch viewModel.viewState {
        case .editing:
            content
                .toolbar { toolbarContentEditing }
        case .regular(let isBackButtonShown):
            if isBackButtonShown {
                content
                    .toolbar { toolbarContent }
            } else {
                content
                   .toolbar { toolbarContentWithLeadingAvatar }
            }
        }
    }

    private var content: some View {
        VStack {
            if let warningViewModel = viewModel.warningViewModel {
                WarningView(viewModel: warningViewModel)
            }
            if viewModel.isMediaDiscoveryShown, let mediaDiscoveryViewModel = viewModel.mediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.viewTask() }
    }

    @ToolbarContentBuilder
    private var toolbarContentEditing: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.selectAll() },
                label: { Image(.selectAllItems) }
            )
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.title).font(.headline)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        toolbarNavigationTitle
    }

    @ToolbarContentBuilder
    private var toolbarContentWithLeadingAvatar: some ToolbarContent {
        toolbarLeadingAvatarImage
        toolbarNavigationTitle
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
            Text(viewModel.title)
                .font(.headline)
                .lineLimit(1)
        }
    }
}
