import Combine
import UIKit

@available(iOS 16.0, *)
@MainActor
final class PhotoLibraryCollectionViewLayoutChangesMonitor {
    
    private weak var collectionView: UICollectionView?
    private let representer: PhotoLibraryCollectionViewRepresenter
    private(set) var photoLibraryDataSource = [PhotoDateSection]()
    private var subscriptions = Set<AnyCancellable>()
    private var currentLayoutBuilder: PhotoLibraryCollectionLayoutBuilder?
    
    init(_ representer: PhotoLibraryCollectionViewRepresenter) {
        self.representer = representer
    }
    
    func configure(collectionView: UICollectionView) {
        self.collectionView = collectionView
        subscribeToDataAndLayoutChanges()
    }
    
    private func subscribeToDataAndLayoutChanges() {
                
        let sectionDataChangesPublisher = Publishers
            .CombineLatest(representer.viewModel.$photoCategoryList, representer.viewModel.$zoomState)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        
        Publishers.CombineLatest(
            sectionDataChangesPublisher,
            representer.viewModel.$showEnableCameraUpload
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] sectionDataChanges, showEnableCameraUpload in
            
            guard let self else {
                return
            }
            let (photoDateSections, zoomState) = sectionDataChanges
            
            // Build Sections
            let shouldRefresh = shouldRefresh(to: photoDateSections)
            
            // Update our local datasource
            photoLibraryDataSource = photoDateSections
                    
            // Update Sections and Cells
            if shouldRefresh {
                collectionView?.reloadData()
            }
            
            // Update layout
            invalidateLayoutIfNeeded(
                zoomState: zoomState,
                enableCameraUploadBannerVisible: showEnableCameraUpload,
                previousLayoutBuilder: currentLayoutBuilder)
        }
        .store(in: &subscriptions)
    }
        
    private func invalidateLayoutIfNeeded(zoomState: PhotoLibraryZoomState,
                                          enableCameraUploadBannerVisible: Bool,
                                          previousLayoutBuilder: PhotoLibraryCollectionLayoutBuilder?) {
                
        let newLayoutBuilder = PhotoLibraryCollectionLayoutBuilder(
            zoomState: zoomState,
            enableCameraUploadBannerVisible: enableCameraUploadBannerVisible)
        
        guard previousLayoutBuilder != newLayoutBuilder else {
            return
        }
        
        collectionView?.setCollectionViewLayout(newLayoutBuilder.buildLayout(), animated: true)
        collectionView?.collectionViewLayout.invalidateLayout()
        currentLayoutBuilder = newLayoutBuilder
    }
    
    private func shouldRefresh(to sections: [PhotoDateSection]) -> Bool {
        guard let collectionView else { return false }
        let visiblePositions = Dictionary(
            uniqueKeysWithValues:
                collectionView.indexPathsForVisibleItems.compactMap {
                    self.photoLibraryDataSource.position(at: $0)
                }.map {
                    ($0, true)
                }
        )
        
        return photoLibraryDataSource.shouldRefresh(to: sections, visiblePositions: visiblePositions)
    }
}
