import SwiftUI

struct PhotoLibraryModeAllView: View {
    let viewModel: PhotoLibraryContentViewModel
    let router: any PhotoLibraryContentViewRouting
    
    var body: some View {
        if #available(iOS 16.0, *) {
            PhotoLibraryModeAllCollectionView(
                viewModel: PhotoLibraryModeAllCollectionViewModel(libraryViewModel: viewModel),
                router: router
            )
        } else {
            PhotoLibraryModeAllGridView(
                viewModel: PhotoLibraryModeAllGridViewModel(libraryViewModel: viewModel),
                router: router
            )
        }
    }
}
