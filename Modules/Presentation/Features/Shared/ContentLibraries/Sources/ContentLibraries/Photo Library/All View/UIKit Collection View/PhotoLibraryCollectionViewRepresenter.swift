import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct PhotoLibraryCollectionViewRepresenter: UIViewRepresentable {
    let viewModel: PhotoLibraryModeAllCollectionViewModel
    let router: any PhotoLibraryContentViewRouting

    func makeCoordinator() -> PhotoLibraryCollectionViewCoordinator {
        PhotoLibraryCollectionViewCoordinator(self)
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewLayout())
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        MEGALogDebug("[Photos] update collection view")
        // View updates are handled by coordinator, because here we can not differentiate if we need to reload collection view or not, and we want to avoid reloading collection view if it is not needed.
        // For example, we do not need to reload data when zoom level changes.
        // So, we manage view updates and collection view reload in our coordinator.
    }
}

@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewRepresenter {
    var contentMode: PhotoLibraryContentMode {
        viewModel.libraryViewModel.contentMode
    }
}
