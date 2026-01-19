import Combine
import UIKit

@MainActor
final class PhotoLibraryCollectionViewLayoutChangesMonitor {
    
    private weak var collectionView: UICollectionView?
    private let representer: PhotoLibraryCollectionViewRepresenter
    private(set) var photoLibraryDataSource = [PhotoDateSection]()
    private var subscriptions = Set<AnyCancellable>()
    private var currentLayoutBuilder: PhotoLibraryCollectionLayoutBuilder?
    
    /// Called when the layout changes due to zoom state changes (without data reload).
    var onLayoutChange: (() -> Void)?
    
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
            representer.viewModel.$bannerType
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] sectionDataChanges, bannerType in
            
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
                bannerType: bannerType,
                previousLayoutBuilder: currentLayoutBuilder,
                didReloadData: shouldRefresh)
        }
        .store(in: &subscriptions)
    }
        
    private func invalidateLayoutIfNeeded(
        zoomState: PhotoLibraryZoomState,
        bannerType: PhotoLibraryBannerType?,
        previousLayoutBuilder: PhotoLibraryCollectionLayoutBuilder?,
        didReloadData: Bool
    ) {
        let isMediaRevampEnabled = ContentLibraries.configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
        let newLayoutBuilder = PhotoLibraryCollectionLayoutBuilder(
            zoomState: zoomState,
            bannerType: bannerType,
            isMediaRevampEnabled: isMediaRevampEnabled,
            contentMode: representer.contentMode)
        
        guard previousLayoutBuilder != newLayoutBuilder else {
            return
        }
        
        collectionView?.setCollectionViewLayout(newLayoutBuilder.buildLayout(), animated: true)
        collectionView?.collectionViewLayout.invalidateLayout()
        currentLayoutBuilder = newLayoutBuilder
        
        // When layout changes without data reload (e.g., default ↔ compact zoom switch),
        // we need to manually refresh the global header since UIHostingConfiguration
        // won't automatically re-render when the Binding value changes.
        if !didReloadData {
            onLayoutChange?()
        }
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
