import Foundation
import Combine
import UIKit

@available(iOS 16.0, *)
final class PhotoLibraryCollectionViewCoordinator {
    private var subscriptions = Set<AnyCancellable>()
    private let collectionView: PhotoLibraryCollectionView
    
    var underlyingView: UICollectionView?
    var dataSource: UICollectionViewDiffableDataSource<PhotoDateSection, PhotoDateSection.Content>?
    
    init(_ collectionView: PhotoLibraryCollectionView) {
        self.collectionView = collectionView
        
        subscribeToPhotoCategoryList()
        subscribeToZoomState()
    }
}

// MARK: - Reload data
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToPhotoCategoryList() {
        collectionView.viewModel
            .$photoCategoryList
            .dropFirst()
            .sink { [weak self] in
                self?.reloadPhotoSections($0)
            }
            .store(in: &subscriptions)
    }
    
    func reloadPhotoSections(_ sections: [PhotoDateSection]) {
        dataSource?.applySnapshotUsingReloadData(sections.toDataSourceSnapshot())
    }
}

// MARK: - Reload layout
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToZoomState() {
        collectionView.viewModel
            .$zoomState
            .dropFirst()
            .map {
                PhotoLibraryCollectionLayoutBuilder(zoomState: $0).buildLayout()
            }
            .sink { [weak self] in
                self?.underlyingView?.setCollectionViewLayout($0, animated: true)
            }
            .store(in: &subscriptions)
    }
}
