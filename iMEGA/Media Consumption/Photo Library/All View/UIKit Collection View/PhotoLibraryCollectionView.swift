import Foundation
import SwiftUI
import MEGADomain

@available(iOS 16.0, *)
struct PhotoLibraryCollectionView: UIViewRepresentable {
    let viewModel: PhotoLibraryModeAllCollectionViewModel
    
    func makeCoordinator() -> PhotoLibraryCollectionViewCoordinator {
        PhotoLibraryCollectionViewCoordinator(self)
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = PhotoLibraryCollectionLayoutBuilder(zoomState: viewModel.zoomState).buildLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        configureDataSource(for: collectionView, context: context)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        MEGALogDebug("[Photos] update collection view")
        context.coordinator.reloadPhotoSections(viewModel.photoCategoryList)
    }
    
    // MARK: Data Source
    private func configureDataSource(for collectionView: UICollectionView, context: Context) {
        registerCell(for: collectionView, context: context)
        registerHeader(context: context)
        context.coordinator.underlyingView = collectionView
    }
    
    private func registerCell(for collectionView: UICollectionView, context: Context) {
        let cellRegistration = UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity> {
            cell, indexPath, photo in
            let viewModel = PhotoCellViewModel(
                photo: photo,
                viewModel: self.viewModel,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
            cell.viewModel = viewModel
            
            cell.contentConfiguration = UIHostingConfiguration {
                PhotoCellContent(viewModel: viewModel)
            }
            .margins(.all, 0)
        }
        
        context.coordinator.dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    private func registerHeader(context: Context) {
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak dataSource = context.coordinator.dataSource]
            header, elementKind, indexPath in
            header.contentConfiguration = UIHostingConfiguration {
                if let section = dataSource?.sectionIdentifier(for: indexPath.section) {
                    PhotoSectionHeader(section: section)
                }
            }
            .margins(.all, 0)
        }
        
        context.coordinator.dataSource?.supplementaryViewProvider = {
            view, elementKind, indexPath in
            view.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
}
