import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import SwiftUI
import UIKit

enum PhotoLibrarySupplementaryElementKind: String {
    case photoDateSectionHeader = "photo-date-section-header-kind"
    case layoutHeader = "layout-header-element-kind"
    
    var elementKind: String { rawValue }
}

@available(iOS 16.0, *)
@MainActor
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var subscriptions = Set<AnyCancellable>()
    private var router: any PhotoLibraryContentViewRouting { representer.router }
    private let representer: PhotoLibraryCollectionViewRepresenter
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var bannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var photoCellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    private typealias PhotoLibraryEnableCameraUploadCollectionCell = UICollectionViewCell
    private let layoutChangesMonitor: PhotoLibraryCollectionViewLayoutChangesMonitor
    private var scrollTracker: PhotoLibraryCollectionViewScrollTracker!
    
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
            header.contentConfiguration = UIHostingConfiguration {
                PhotoSectionHeader(section: photoLibraryDataSource[indexPath.section])
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
                    self?.viewModel
                        .photoZoomControlPositionTracker
                        .update(viewSpace: size.height)
                }
            }
            .margins(.all, 0)
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
@available(iOS 16.0, *)
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
        case .none:
            fatalError("Unknown supported PhotoLibraryCollectionViewCoordinator.viewForSupplementaryElementOfKind: \(kind)")
        }
    }
}

// MARK: - UICollectionViewDelegate
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = photoLibraryDataSource.photo(at: indexPath) else { return }
        
        router.openPhotoBrowser(for: photo, allPhotos: photoLibraryDataSource.allPhotos)
    }
}

// MARK: - PhotoLibraryCollectionViewScrolling
@available(iOS 16.0, *)
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
