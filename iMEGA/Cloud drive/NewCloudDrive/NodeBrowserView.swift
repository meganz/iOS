import CloudDrive
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import Search
import SwiftUI
import UIKit

struct NodeBrowserView: View {

    var isCloudDriveRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp)
    }

    @StateObject var viewModel: NodeBrowserViewModel
    @StateObject var floatingAddButtonViewModel: FloatingAddButtonViewModel

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
                VStack(spacing: 0) {
                    if viewModel.shouldDisplayHeaderViewInMDView {
                        ResultsHeaderView(height: 44) {
                            SortHeaderView(
                                viewModel: viewModel.sortHeaderViewModelForMD,
                                horizontalPadding: TokenSpacing._5
                            )
                        } rightView: {
                            SearchResultsHeaderViewModeView(
                                viewModel: viewModel.viewModeHeaderViewModelForMD,
                                horizontalPadding: TokenSpacing._7
                            )
                        }
                    } else {
                        EmptyView()
                    }
                    MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
                }
            } else {
                SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
                    .environment(\.editMode, $viewModel.editMode)
            }
        }
        .background()
        .overlay(alignment: .bottomTrailing) {
            if floatingAddButtonViewModel.showsFloatingAddButton, viewModel.viewModeAwareMediaDiscoveryViewModel == nil {
                RoundedPrimaryImageButton(image: MEGAAssets.Image.plus, action: { floatingAddButtonViewModel.addButtonTapAction() })
                    .padding(TokenSpacing._5)
            }
        }
        .sheet(
            isPresented: $floatingAddButtonViewModel.showActions,
            content: {
                NodeUploadActionSheetView(viewModel: floatingAddButtonViewModel, isPresented: $floatingAddButtonViewModel.showActions)
            })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onLoad { await viewModel.onLoadTask() }
    }

    @ViewBuilder
    private var leftToolbarContent: some View {
        switch viewModel.viewState {
        case .editing:
            Button(
                action: { viewModel.selectAll() },
                label: {
                    if isCloudDriveRevampEnabled {
                        MEGAAssets.Image.checkStack.foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    } else {
                        MEGAAssets.Image.selectAllItems
                    }
                }
            )
        case .regular(let leftBarButton):
            switch leftBarButton {
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
            if !isCloudDriveRevampEnabled || viewModel.viewModeAwareMediaDiscoveryViewModel != nil {
                viewModel.contextMenuViewFactory?.makeAddMenuWithButtonView()
            }

            moreOptionsView
        }
    }

    @ViewBuilder
    private var moreOptionsView: some View {
        switch (isCloudDriveRevampEnabled, viewModel.hasParentNode, viewModel.shouldShowContextMenu) {
        case (true, true, _):
            ImageButtonWrapper(
                image: Image(uiImage: MEGAAssets.UIImage.moreNavigationBar),
                imageColor: TokenColors.Icon.primary.swiftUI,
                action: viewModel.moreOptionsButtonTapped
            )
            .frame(width: 38, height: 38)
        case (true, false, true), (false, _, _):
            viewModel.contextMenuViewFactory?.makeContextMenuWithButtonView()
        default:
            EmptyView()
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
