import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeAllView: View {
    let viewModel: PhotoLibraryContentViewModel
    let router: PhotoLibraryContentViewRouting
    
    var body: some View {
        if #available(iOS 16.0, *), FeatureFlagProvider().isFeatureFlagEnabled(for: .photoLibraryCollectionView) {
            PhotoLibraryModeAllCollectionView(
                viewModel: PhotoLibraryModeAllCollectionViewModel(libraryViewModel: viewModel)
            )
        } else {
            PhotoLibraryModeAllGridView(
                viewModel: PhotoLibraryModeAllGridViewModel(libraryViewModel: viewModel),
                router: router
            )
        }
    }
}
