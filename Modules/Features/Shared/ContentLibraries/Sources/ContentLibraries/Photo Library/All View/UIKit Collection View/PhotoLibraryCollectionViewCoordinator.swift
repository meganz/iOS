import Combine
import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI
import UIKit

enum PhotoLibrarySupplementaryElementKind: String {
    case photoDateSectionHeader = "photo-date-section-header-kind"
    case layoutHeaderEnableCameraUploads = "layout-header-enable-camera-uploads-kind"
    case layoutHeaderLimitedPermissions = "layout-header-limited-permissions-kind"
    case globalZoomHeader = "global-zoom-header-kind"
    
    var elementKind: String { rawValue }
    static var globalHeaderHeight: CGFloat { 44 }
    
    var zPosition: CGFloat {
        switch self {
        case .layoutHeaderEnableCameraUploads, .layoutHeaderLimitedPermissions: 4
        case .globalZoomHeader: 3
        case .photoDateSectionHeader: 2
        }
    }
    
    static func layoutHeader(for bannerType: PhotoLibraryBannerType?) -> PhotoLibrarySupplementaryElementKind? {
        guard let bannerType else { return nil }
        switch bannerType {
        case .enableCameraUploads:
            return .layoutHeaderEnableCameraUploads
        case .limitedPermissions:
            return .layoutHeaderLimitedPermissions
        }
    }
}

@MainActor
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var router: any PhotoLibraryContentViewRouting { representer.router }
    private let representer: PhotoLibraryCollectionViewRepresenter
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var enableCameraUploadsBannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var limitedPermissionsBannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var globalZoomHeaderRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var photoCellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    private typealias PhotoLibraryEnableCameraUploadCollectionCell = UICollectionViewCell
    private let layoutChangesMonitor: PhotoLibraryCollectionViewLayoutChangesMonitor
    private var scrollTracker: PhotoLibraryCollectionViewScrollTracker!
    private var currentVisibleMonthTitle: String = ""
    private weak var globalHeaderView: UICollectionViewCell?
    private var visibleSectionHeaders: Set<Int> = []

    private var dragInitialIndexPath: IndexPath?
    private var dragLastIndexPath: IndexPath?
    private var dragSelectionMode: DragSelectionMode?
    private var initialSelectionHandles: Set<HandleEntity> = []

    private enum DragSelectionMode {
        case select
        case deselect
    }

    private var photoLibraryDataSource: [PhotoDateSection] {
        layoutChangesMonitor.photoLibraryDataSource
    }
    
    private var viewModel: PhotoLibraryModeAllCollectionViewModel {
        representer.viewModel
    }
    
    init(_ representer: PhotoLibraryCollectionViewRepresenter) {
        self.representer = representer
        layoutChangesMonitor = PhotoLibraryCollectionViewLayoutChangesMonitor(representer)
        super.init()
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        self.collectionView = collectionView
        
        headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind) { [unowned self] header, _, indexPath in
            let isMediaRevampEnabled = ContentLibraries.configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
            let isFirstSection = isMediaRevampEnabled && indexPath.section == 0
            
            header.contentConfiguration = UIHostingConfiguration {
                // First section uses a placeholder header (invisible) when media revamp is enabled
                if isFirstSection {
                    EmptyView()
                } else {
                    PhotoSectionHeader(section: photoLibraryDataSource[indexPath.section])
                }
            }
            .margins(.all, 0)
        }
        
        enableCameraUploadsBannerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.layoutHeaderEnableCameraUploads.elementKind) { [unowned self] header, _, _ in
            header.contentConfiguration = UIHostingConfiguration {
                EnableCameraUploadsBannerButtonView({ [weak self] in
                    guard let self else { return }
                    router.openCameraUploadSettings(viewModel: viewModel)
                }, closeButtonAction: viewModel.dismissEnableCameraUploadBanner)
                .determineViewSize { [weak self] size in
                    Task { @MainActor in
                        self?.viewModel.photoZoomControlPositionTracker.update(viewSpace: size.height)
                    }
                }
            }
            .margins(.all, 0)
        }
        
        limitedPermissionsBannerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.layoutHeaderLimitedPermissions.elementKind) { [unowned self] header, _, _ in
            header.contentConfiguration = UIHostingConfiguration {
                LimitedAccessBannerView { [weak self] in
                    self?.viewModel.dismissLimitedAccessBanner()
                }
                .determineViewSize { [weak self] size in
                    Task { @MainActor in
                        self?.viewModel.photoZoomControlPositionTracker.update(viewSpace: size.height)
                    }
                }
            }
            .margins(.all, 0)
        }
        
        globalZoomHeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.globalZoomHeader.elementKind) { [unowned self] header, _, _ in
            self.globalHeaderView = header
            let monthTitle = currentVisibleMonthTitle.isEmpty ? (photoLibraryDataSource.first?.title ?? "") : currentVisibleMonthTitle
            header.contentConfiguration = createGlobalHeaderConfiguration(monthTitle: monthTitle)
        }
        
        photoCellRegistration = UICollectionView.CellRegistration { [unowned self] cell, _, photo in
            let viewModel = PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(mode: representer.contentMode),
                nodeUseCase: NodeUseCaseFactory.makeNodeUseCase(for: representer.contentMode),
                sensitiveNodeUseCase: SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(for: representer.contentMode)
            )
            cell.viewModel = viewModel
            
            cell.contentConfiguration = UIHostingConfiguration {
                PhotoCellContent(viewModel: viewModel, isSelfSizing: false)
            }
            .margins(.all, 0)
            
            cell.clipsToBounds = true
        }
        
        configureScrollTracker(for: collectionView)
        
        layoutChangesMonitor.configure(collectionView: collectionView)
        
        if ContentLibraries.configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp) {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            panGesture.delegate = self
            collectionView.addGestureRecognizer(panGesture)
        }

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel
            .photoZoomControlPositionTracker
            .trackContentOffset(scrollView.contentOffset.y)
    }
    
    private func createGlobalHeaderConfiguration(monthTitle: String) -> any UIContentConfiguration {
        return UIHostingConfiguration {
            PhotoLibraryGlobalHeaderView(
                monthTitle: monthTitle,
                viewModel: self.viewModel
            )
        }
        .margins(.all, 0)
        .background(TokenColors.Background.page.swiftUI)
    }
    
    private func updateGlobalHeaderMonthTitle() {
        guard ContentLibraries.configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp),
              let globalHeaderView = globalHeaderView,
              let topSection = visibleSectionHeaders.min(),
              topSection < photoLibraryDataSource.count else {
            return
        }
        
        let newMonthTitle = photoLibraryDataSource[topSection].title
        
        if currentVisibleMonthTitle != newMonthTitle {
            currentVisibleMonthTitle = newMonthTitle
            globalHeaderView.contentConfiguration = createGlobalHeaderConfiguration(monthTitle: newMonthTitle)
        }
    }
    
    private func configureScrollTracker(for collectionView: UICollectionView) {
        scrollTracker = PhotoLibraryCollectionViewScrollTracker(
            libraryViewModel: viewModel.libraryViewModel,
            collectionView: collectionView,
            delegate: self
        )
        scrollTracker.startTrackingScrolls()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard viewModel.isEditing else { return }
        
        let location = gesture.location(in: collectionView)
        
        switch gesture.state {
        case .began:
            guard let indexPath = collectionView?.indexPathForItem(at: location),
                  let photo = photoLibraryDataSource.photo(at: indexPath) else {
                return
            }
            
            collectionView?.isScrollEnabled = false
            
            dragInitialIndexPath = indexPath
            dragLastIndexPath = indexPath
            dragSelectionMode = viewModel.libraryViewModel.selection.isPhotoSelected(photo) ? .deselect : .select
            initialSelectionHandles = Set(viewModel.libraryViewModel.selection.photos.keys)
            if let dragSelectionMode {
                applySelectionMode(dragSelectionMode, to: photo)
            }
            
        case .changed:
            guard let indexPath = collectionView?.indexPathForItem(at: location) else {
                break
            }
            if indexPath != dragLastIndexPath {
                updateSelection(at: indexPath)
                dragLastIndexPath = indexPath
            }
            
        case .ended, .cancelled, .failed:
            collectionView?.isScrollEnabled = true
            dragInitialIndexPath = nil
            dragLastIndexPath = nil
            dragSelectionMode = nil
            initialSelectionHandles.removeAll()
            
        default:
            break
        }
    }
    
    private func updateSelection(at currentIndexPath: IndexPath) {
        guard let initialIndexPath = dragInitialIndexPath,
              let lastIndexPath = dragLastIndexPath,
              let selectionMode = dragSelectionMode else { return }
        
        let currentRange = Set(photoLibraryDataSource.indexPaths(from: initialIndexPath, to: currentIndexPath))
        let previousRange = Set(photoLibraryDataSource.indexPaths(from: initialIndexPath, to: lastIndexPath))
        
        // Photos added to the range in this step
        let addedToRange = currentRange.subtracting(previousRange)
        for indexPath in addedToRange {
            guard let photo = photoLibraryDataSource.photo(at: indexPath) else { continue }
            applySelectionMode(selectionMode, to: photo)
        }
        
        // Photos removed from the range in this step
        let removedFromRange = previousRange.subtracting(currentRange)
        for indexPath in removedFromRange {
            guard let photo = photoLibraryDataSource.photo(at: indexPath) else { continue }
            let wasSelected = initialSelectionHandles.contains(photo.handle)
            if wasSelected {
                viewModel.libraryViewModel.selection.selectPhoto(photo)
            } else {
                viewModel.libraryViewModel.selection.deselectPhoto(photo)
            }
        }
    }
    
    private func applySelectionMode(_ mode: DragSelectionMode, to photo: NodeEntity) {
        switch mode {
        case .select:
            viewModel.libraryViewModel.selection.selectPhoto(photo)
        case .deselect:
            viewModel.libraryViewModel.selection.deselectPhoto(photo)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        photoLibraryDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoLibraryDataSource[section].contentList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        collectionView.dequeueConfiguredReusableCell(
            using: photoCellRegistration,
            for: indexPath,
            item: photoLibraryDataSource.photo(at: indexPath)
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch PhotoLibrarySupplementaryElementKind(rawValue: kind) {
        case .layoutHeaderEnableCameraUploads:
            return collectionView.dequeueConfiguredReusableSupplementary(using: enableCameraUploadsBannerRegistration, for: indexPath)
        case .layoutHeaderLimitedPermissions:
            return collectionView.dequeueConfiguredReusableSupplementary(using: limitedPermissionsBannerRegistration, for: indexPath)
        case .photoDateSectionHeader:
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        case .globalZoomHeader:
            return collectionView.dequeueConfiguredReusableSupplementary(using: globalZoomHeaderRegistration, for: indexPath)
        case .none:
            fatalError("Unknown supported PhotoLibraryCollectionViewCoordinator.viewForSupplementaryElementOfKind: \(kind)")
        }
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = photoLibraryDataSource.photo(at: indexPath) else { return }
        
        if photo.isTakenDown {
            router.showTakenDownNodeAlert()
        } else {
            router.openPhotoBrowser(for: photo, allPhotos: photoLibraryDataSource.allPhotos)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        guard let kind = PhotoLibrarySupplementaryElementKind(rawValue: elementKind) else { return }
        
        view.layer.zPosition = kind.zPosition
        
        // Track visible section headers to update the global header with the topmost section
        if kind == .photoDateSectionHeader {
            visibleSectionHeaders.insert(indexPath.section)
            updateGlobalHeaderMonthTitle()
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {
        // Remove section from tracking when it's no longer visible
        if elementKind == PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind {
            visibleSectionHeaders.remove(indexPath.section)
            updateGlobalHeaderMonthTitle()
        }
    }
}

// MARK: - PhotoLibraryCollectionViewScrolling

extension PhotoLibraryCollectionViewCoordinator: PhotoLibraryCollectionViewScrolling {
    func scrollTo(_ position: PhotoScrollPosition) {
        guard position != .top else {
            collectionView?.setContentOffset(.zero, animated: false)
            return
        }
        
        guard let indexPath = photoLibraryDataSource.indexPath(of: position) else { return }
        collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
    }
    
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        photoLibraryDataSource.position(at: indexPath)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoLibraryCollectionViewCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
              viewModel.isEditing else {
            return false
        }
        
        let velocity = panGesture.velocity(in: collectionView)
        
        guard abs(velocity.x) > abs(velocity.y) else {
            return false
        }
        
        let location = panGesture.location(in: collectionView)
        return collectionView?.indexPathForItem(at: location) != nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
