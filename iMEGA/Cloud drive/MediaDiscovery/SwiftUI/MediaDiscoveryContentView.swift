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
        .taskForiOS14 { await viewModel.loadPhotos() }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        PhotoLibraryContentView(
            viewModel: viewModel.photoLibraryContentViewModel,
            router: viewModel.photoLibraryContentViewRouter,
            onFilterUpdate: nil
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        EmptyMediaDiscoveryContentView(
            image: Asset.Images.EmptyStates.folderEmptyState.image,
            title: Strings.Localizable.emptyFolder) { viewModel.tapped(menuAction: $0) }
    }
}
