import SwiftUI

struct PhotoLibraryModeAllView: View {
    let viewModel: PhotoLibraryContentViewModel
    let router: PhotoLibraryContentViewRouting
    
    var body: some View {
        if #available(iOS 16.0, *) {
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
