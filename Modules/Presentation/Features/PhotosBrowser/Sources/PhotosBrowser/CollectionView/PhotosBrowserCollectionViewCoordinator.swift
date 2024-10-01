import MEGADomain
import SwiftUI
import UIKit

final class PhotosBrowserCollectionViewCoordinator: NSObject {
    enum Section {
        case main
    }
    
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, PhotosBrowserLibraryEntity>
    typealias CellRegistration = UICollectionView.CellRegistration<PhotosBrowserImageCell, PhotosBrowserLibraryEntity>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PhotosBrowserLibraryEntity>
    
    private(set) var dataSource: UICollectionViewDiffableDataSource<Section, PhotosBrowserLibraryEntity>?
    private var collectionView: UICollectionView?
    private let representer: PhotosBrowserCollectionViewRepresenter
    private let layoutChangesMonitor: PhotosBrowserCollectionViewLayoutChangesMonitor
    private var reloadSnapshotTask: Task<Void, Never>?
    
    init(_ representer: PhotosBrowserCollectionViewRepresenter) {
        self.representer = representer
        self.layoutChangesMonitor = PhotosBrowserCollectionViewLayoutChangesMonitor(representer)
        
        super.init()
    }
    
    deinit {
        reloadSnapshotTask?.cancel()
    }
    
    // MARK: - DataSouce & Snapshots
    
    func configureDataSource(for collectionView: UICollectionView) {
        let cellRegistration = CellRegistration { [weak self] cell, _, entity in
            guard let self else { return }
            
            configureCell(cell, with: entity)
        }
        
        dataSource = DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, entity in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entity)
        }
        
        layoutChangesMonitor.configure(collectionView: collectionView)
        
        collectionView.dataSource = dataSource
    }
    
    func updateUI(with assets: [PhotosBrowserLibraryEntity]) {
        reloadSnapshotTask = Task {
            await reloadData(with: assets)
        }
    }
    
    // MARK: - Private
    
    private func reloadData(with assets: [PhotosBrowserLibraryEntity]) async {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(assets, toSection: .main)
        
        guard !Task.isCancelled else { return }
        await dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func configureCell(_ cell: UICollectionViewCell, with entity: PhotosBrowserLibraryEntity) {
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration(content: {
                PhotosBrowserImageCellContent(viewModel: PhotosBrowserImageCellContentViewModel(entity: entity))
            })
            .margins(.all, 0)
        } else {
            configureCellBelowiOS16(cell: cell, with: entity)
        }
    }
    
    private func configureCellBelowiOS16(cell: UICollectionViewCell, with entity: PhotosBrowserLibraryEntity) {
        let cellHostingController = UIHostingController(rootView: PhotosBrowserImageCellContent(viewModel: PhotosBrowserImageCellContentViewModel(entity: entity)))
        cellHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellHostingController.view)
        cell.contentView.wrap(cellHostingController.view)
    }
}
