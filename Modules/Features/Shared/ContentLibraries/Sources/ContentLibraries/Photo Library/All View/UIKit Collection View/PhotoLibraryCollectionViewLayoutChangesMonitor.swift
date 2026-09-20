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

            // Decide reload vs. in-place reconfigure vs. no-op
            let refresh = refreshPlan(to: photoDateSections)

            // Update our local datasource before applying, so cell providers read fresh data
            photoLibraryDataSource = photoDateSections

            // Update Sections and Cells
            switch refresh {
            case .none:
                break
            case .reconfigure(let indexPaths):
                collectionView?.reconfigureItems(at: indexPaths)
            case .reload:
                collectionView?.reloadData()
            }
            
            // Update layout
            invalidateLayoutIfNeeded(
                zoomState: zoomState,
                bannerType: bannerType,
                previousLayoutBuilder: currentLayoutBuilder,
                didReloadData: refresh.didReloadData)
        }
        .store(in: &subscriptions)
    }
    
    private enum RefreshPlan {
        case none
        case reconfigure([IndexPath])
        case reload

        /// A reconfigure updates items only, not supplementary views, so — like the no-op case —
        /// it counts as "not reloaded" for the header-refresh decision in `invalidateLayoutIfNeeded`.
        var didReloadData: Bool {
            if case .reload = self { true } else { false }
        }
    }

    private func refreshPlan(to sections: [PhotoDateSection]) -> RefreshPlan {
        guard let collectionView else { return .none }
        // Index paths, not node-derived positions: the collection view answers in exactly the
        // coordinates the diff compares in, and they are unique by construction. Deriving keys from
        // nodes needed de-duplication, because a splice can leave one node in two slots at once and
        // a zoom-in makes both visible.
        //
        // Visible is not enough: with cell prefetching on, a cell just off screen is already built
        // and configured, and it is not rebuilt when it appears — only `willDisplay` fires. Left
        // out of the diff, it scrolls in still showing the placeholder it was prepared with. A
        // screen of margin each way covers the prefetch window. The layout answers for the whole
        // rect whether or not a cell was built in it, so this is a superset of what exists: a spare
        // index path is compared and then reconfigures nothing.
        let preparedRect = collectionView.bounds.insetBy(dx: 0, dy: -collectionView.bounds.height)
        let preparedIndexPaths = Set(collectionView.indexPathsForVisibleItems)
            .union(
                collectionView.collectionViewLayout.layoutAttributesForElements(in: preparedRect)?
                    .filter { $0.representedElementCategory == .cell }
                    .map(\.indexPath) ?? [])

        // A structural change (section add/remove, header/date change, or item-count change) needs
        // a full reload; a content-only change (placeholder → real node, thumbnail/favourite/
        // sensitive flips) reconfigures just the affected cells in place.
        guard let changed = photoLibraryDataSource.changedItemIndexPaths(
            to: sections, amongPrepared: preparedIndexPaths) else {
            return .reload
        }
        return changed.isEmpty ? .none : .reconfigure(changed)
    }
        
    private func invalidateLayoutIfNeeded(
        zoomState: PhotoLibraryZoomState,
        bannerType: PhotoLibraryBannerType?,
        previousLayoutBuilder: PhotoLibraryCollectionLayoutBuilder?,
        didReloadData: Bool
    ) {
        let newLayoutBuilder = PhotoLibraryCollectionLayoutBuilder(
            zoomState: zoomState,
            bannerType: bannerType,
            contentMode: representer.contentMode,
            photoGlobalHeaderType: representer.globalHeaderType,
            photoSectionHeaderType: representer.sectionHeaderType)
        
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
}
