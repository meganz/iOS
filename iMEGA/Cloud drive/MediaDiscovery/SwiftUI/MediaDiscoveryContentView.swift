import ContentLibraries
import MEGAAssets
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct MediaDiscoveryContentView: View {
    
    @StateObject var viewModel: MediaDiscoveryContentViewModel
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .normal:
                defaultView
            case .empty:
                emptyStateView
            }
        }
        .task { await viewModel.loadPhotos() }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        VStack(spacing: .zero) {
            if viewModel.showAutoMediaDiscoveryBanner {
                AutoMediaDiscoveryBannerView(showBanner: $viewModel.showAutoMediaDiscoveryBanner) {
                    viewModel.autoMediaDiscoveryBannerDismissed = true
                }
            }
            
            PhotoLibraryContentView(
                viewModel: viewModel.photoLibraryContentViewModel,
                router: viewModel.photoLibraryContentViewRouter,
                onFilterUpdate: nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        EmptyMediaDiscoveryContentView(
            image: MEGAAssets.UIImage.folderEmptyState,
            title: Strings.Localizable.emptyFolder) { viewModel.tapped(menuAction: $0) }
    }
}
