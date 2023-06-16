import Foundation
import SwiftUI
import Combine
import UIKit
import MEGADomain

@available(iOS 16.0, *)
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var subscriptions = Set<AnyCancellable>()
    private let router: PhotoLibraryContentViewRouter
    
    private let representer: PhotoLibraryCollectionViewRepresenter
    private var photoSections = [PhotoDateSection]()
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var cellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    private var scrollTracker: PhotoLibraryCollectionViewScrollTracker!
    
    init(_ representer: PhotoLibraryCollectionViewRepresenter) {
        self.representer = representer
        router = PhotoLibraryContentViewRouter(contentMode: representer.contentMode)
        super.init()
        subscribeToPhotoCategoryList()
        subscribeToZoomState()
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        self.collectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        
        headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [unowned self] header, _, indexPath in
            header.contentConfiguration = UIHostingConfiguration {
                PhotoSectionHeader(section: self.photoSections[indexPath.section])
            }
            .margins(.all, 0)
        }
        
        cellRegistration = UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity> { [unowned self] cell, _, photo in
            let viewModel = PhotoCellViewModel(
                photo: photo,
                viewModel: representer.viewModel,
                thumbnailUseCase: ThumbnailUseCase.makeThumbnailUseCase(mode: representer.contentMode),
                mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo)
            )
            cell.viewModel = viewModel
            
            cell.contentConfiguration = UIHostingConfiguration {
                PhotoCellContent(viewModel: viewModel, isSelfSizing: false)
            }
            .margins(.all, 0)
            
            cell.clipsToBounds = true
        }
        
        configureScrollTracker(for: collectionView)
    }
    
    private func configureScrollTracker(for collectionView: UICollectionView) {
        scrollTracker = PhotoLibraryCollectionViewScrollTracker(
            libraryViewModel: representer.viewModel.libraryViewModel,
            collectionView: collectionView,
            delegate: self
        )
        scrollTracker.startTrackingScrolls()
    }
}

// MARK: - Reload data
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToPhotoCategoryList() {
        representer.viewModel
            .$photoCategoryList
            .sink { [weak self] in
                let shouldRefresh = self?.shouldRefresh(to: $0) == true
                self?.photoSections = $0
                if shouldRefresh {
                    self?.collectionView?.reloadData()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func shouldRefresh(to sections: [PhotoDateSection]) -> Bool {
        guard let collectionView else { return false }
        let visiblePositions = Dictionary(
            uniqueKeysWithValues:
                collectionView.indexPathsForVisibleItems.compactMap {
                    self.photoSections.position(at: $0)
                }.map {
                    ($0, true)
                }
        )
        
        return photoSections.shouldRefresh(to: sections, visiblePositions: visiblePositions)
    }
}

// MARK: - Reload layout
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToZoomState() {
        representer.viewModel
            .$zoomState
            .dropFirst()
            .map {
                PhotoLibraryCollectionLayoutBuilder(zoomState: $0).buildLayout()
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.collectionView?.setCollectionViewLayout($0, animated: true)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - UICollectionViewDataSource
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        photoSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoSections[section].contentList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration,
            for: indexPath,
            item: photoSections.photo(at: indexPath)
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
    }
}

// MARK: - UICollectionViewDelegate
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = photoSections.photo(at: indexPath) else { return }
        
        router.openPhotoBrowser(for: photo, allPhotos: photoSections.allPhotos)
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
        
        guard let indexPath = photoSections.indexPath(of: position) else { return }
        collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
    }
    
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        photoSections.position(at: indexPath)
    }
}
