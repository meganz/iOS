import Foundation
import SwiftUI
import Combine
import UIKit
import MEGADomain

@available(iOS 16.0, *)
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var subscriptions = Set<AnyCancellable>()
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

// MARK: - Collection View Data Source
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
            item: photoSections[indexPath.section].contentList[indexPath.item]
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
    }
}
