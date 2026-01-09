import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI
import UIKit

enum PhotoLibrarySupplementaryElementKind: String {
    case photoDateSectionHeader = "photo-date-section-header-kind"
    case layoutHeader = "layout-header-element-kind"
    case globalZoomHeader = "global-zoom-header-kind"

    var elementKind: String { rawValue }
    static var globalHeaderHeight: CGFloat { 44 }
}

@MainActor
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var router: any PhotoLibraryContentViewRouting { representer.router }
    private let representer: PhotoLibraryCollectionViewRepresenter
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var bannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var globalZoomHeaderRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var photoCellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    private typealias PhotoLibraryEnableCameraUploadCollectionCell = UICollectionViewCell
    private let layoutChangesMonitor: PhotoLibraryCollectionViewLayoutChangesMonitor
    private var scrollTracker: PhotoLibraryCollectionViewScrollTracker!
    private var currentVisibleMonthTitle: String = ""
    private weak var globalHeaderView: UICollectionViewCell?
    private var visibleSectionHeaders: Set<Int> = []
    
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
        
        bannerRegistration =  UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.layoutHeader.elementKind) { [unowned self] header, _, _ in
            header.contentConfiguration = UIHostingConfiguration {
                EnableCameraUploadsBannerButtonView { [weak self] in
                    guard let self else { return }
                    router.openCameraUploadSettings(viewModel: viewModel)
                }
                .determineViewSize { [weak self] size in
                    Task { @MainActor in
                        self?.viewModel
                            .photoZoomControlPositionTracker
                            .update(viewSpace: size.height)
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
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel
            .photoZoomControlPositionTracker
            .trackContentOffset(scrollView.contentOffset.y)
    }

    private func createGlobalHeaderConfiguration(monthTitle: String) -> any UIContentConfiguration {
        UIHostingConfiguration {
            PhotoLibraryGlobalHeaderView(
                monthTitle: monthTitle,
                zoomState: Binding(
                    get: { self.viewModel.zoomState },
                    set: { self.viewModel.zoomState = $0 }
                )
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
        case .layoutHeader:
            return collectionView.dequeueConfiguredReusableSupplementary(using: bannerRegistration, for: indexPath)
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
        if elementKind == PhotoLibrarySupplementaryElementKind.globalZoomHeader.elementKind {
            view.layer.zPosition = 3
        }
        
        // Track visible section headers to update the global header with the topmost section
        if elementKind == PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind {
            view.layer.zPosition = 2
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
