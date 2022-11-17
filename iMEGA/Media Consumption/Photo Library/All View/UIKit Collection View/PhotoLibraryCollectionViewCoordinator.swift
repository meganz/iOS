import Foundation
import SwiftUI
import Combine
import UIKit
import MEGADomain

@available(iOS 16.0, *)
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var subscriptions = Set<AnyCancellable>()
    private let router = PhotoLibraryContentViewRouter()
    
    private let collectionViewRepresenter: PhotoLibraryCollectionViewRepresenter
    private var photoSections = [PhotoDateSection]()
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var cellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    
    init(_ collectionViewRepresenter: PhotoLibraryCollectionViewRepresenter) {
        self.collectionViewRepresenter = collectionViewRepresenter
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
        ) { [unowned self] header, elementKind, indexPath in
            header.contentConfiguration = UIHostingConfiguration {
                PhotoSectionHeader(section: self.photoSections[indexPath.section])
            }
            .margins(.all, 0)
        }
        
        cellRegistration = UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity> {
            [unowned self] cell, indexPath, photo in
            let viewModel = PhotoCellViewModel(
                photo: photo,
                viewModel: collectionViewRepresenter.viewModel,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
            cell.viewModel = viewModel
            
            cell.contentConfiguration = UIHostingConfiguration {
                PhotoCellContent(viewModel: viewModel)
            }
            .margins(.all, 0)
            
            cell.clipsToBounds = true
        }
    }
}

// MARK: - Reload data
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToPhotoCategoryList() {
        collectionViewRepresenter.viewModel
            .$photoCategoryList
            .dropFirst()
            .sink { [weak self] in
                self?.reloadPhotoSections($0)
            }
            .store(in: &subscriptions)
    }
    
    func reloadPhotoSections(_ photoSections: [PhotoDateSection]) {
        self.photoSections = photoSections
        collectionView?.reloadData()
    }
}

// MARK: - Reload layout
@available(iOS 16.0, *)
extension PhotoLibraryCollectionViewCoordinator {
    private func subscribeToZoomState() {
        collectionViewRepresenter.viewModel
            .$zoomState
            .dropFirst()
            .map {
                PhotoLibraryCollectionLayoutBuilder(zoomState: $0).buildLayout()
            }
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
        router.openPhotoBrowser(for: photoSections.photo(at: indexPath), allPhotos: photoSections.allPhotos)
    }
}
