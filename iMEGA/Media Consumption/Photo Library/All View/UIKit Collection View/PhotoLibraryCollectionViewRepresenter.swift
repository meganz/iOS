import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct PhotoLibraryCollectionViewRepresenter: UIViewRepresentable {
    let viewModel: PhotoLibraryModeAllCollectionViewModel
    
    func makeCoordinator() -> PhotoLibraryCollectionViewCoordinator {
        PhotoLibraryCollectionViewCoordinator(self)
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = PhotoLibraryCollectionLayoutBuilder(zoomState: viewModel.zoomState).buildLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        MEGALogDebug("[Photos] update collection view")
        context.coordinator.reloadPhotoSections(viewModel.photoCategoryList)
    }
}
