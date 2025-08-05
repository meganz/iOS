import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct NodeBrowserView: View {
    
    @StateObject var viewModel: NodeBrowserViewModel

    var body: some View {
        content
            .legacyNoInternetViewModifier(viewModel: viewModel.noInternetViewModel)
            .ignoresSafeArea(.keyboard)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    leftToolbarContent
                }
                
                toolbarNavigationTitle
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    rightToolbarContent
                }
            }.navigationBarBackButtonHidden(viewModel.hidesBackButton)
    }
    
    private var content: some View {
        VStack {
            if let warningViewModel = viewModel.currentBannerViewModel {
                WarningBannerView(viewModel: warningViewModel)
            }
            if let mediaDiscoveryViewModel = viewModel.viewModeAwareMediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
                    .environment(\.editMode, $viewModel.editMode)
            }
        }
        .background()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onLoad { await viewModel.onLoadTask() }
    }

    @ToolbarContentBuilder
    private var toolbarContentEditing: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.selectAll() },
                label: { MEGAAssets.Image.selectAllItems }
            )
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(Strings.Localizable.cancel) { viewModel.stopEditing() }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.title).font(.headline)
        }
    }

    @ViewBuilder
    private var leftToolbarContent: some View {
        switch viewModel.viewState {
        case .editing:
            Button(
                action: { viewModel.selectAll() },
                label: { MEGAAssets.Image.selectAllItems }
            )
        case .regular(let leftBarButton):
            switch leftBarButton {
            case .avatar:
                MyAvatarIconView {
                    viewModel.openUserProfile()
                }
            case .back:
                EmptyView()
            case .close:
                Button(
                    action: { viewModel.closeNavBarButtonTapped() },
                    label: { Text(Strings.Localizable.close) }
                )
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
        }
    }
    
    @ViewBuilder
    private var rightToolbarContent: some View {
        switch viewModel.viewState {
        case .editing:
            Button(Strings.Localizable.cancel) { viewModel.stopEditing() }
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        case .regular:
            viewModel.contextMenuViewFactory?.makeAddMenuWithButtonView()
            viewModel.contextMenuViewFactory?.makeContextMenuWithButtonView()
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
