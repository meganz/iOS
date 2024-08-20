import MEGADomain
import SwiftUI
import UIKit

final class PhotosBrowserCollectionViewCoordinator: NSObject {
    enum Section {
        case main
    }
    
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, Int>
    typealias CellRegistration = UICollectionView.CellRegistration<PhotosBrowserImageCell, Int>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Int>
    
    private(set) var dataSource: UICollectionViewDiffableDataSource<Section, Int>?
    private var collectionView: UICollectionView?
    private let representer: PhotosBrowserCollectionViewRepresenter
    
    init(_ representer: PhotosBrowserCollectionViewRepresenter) {
        self.representer = representer
        
        super.init()
    }
    
    // MARK: - DataSouce & Snapshots
    
    func configureDataSource(for collectionView: UICollectionView) {
        let cellRegistration = CellRegistration { [weak self] cell, _, item in
            guard let self else { return }
            
            configureCell(cell, with: item)
        }
        
        dataSource = DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        collectionView.dataSource = dataSource
    }
    
    func snapshot() -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(representer.viewModel.sampleData, toSection: .main) // placeholder
        
        return snapshot
    }
    
    // MARK: - Private
    
    private func configureCell(_ cell: UICollectionViewCell, with item: Int) {
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration(content: {
                PhotosBrowserImageCellContent(value: item)
            })
            .margins(.all, 0)
        } else {
            configureCellBelowiOS16(cell: cell, with: item)
        }
    }
    
    private func configureCellBelowiOS16(cell: UICollectionViewCell, with value: Int) {
        let cellHostingController = UIHostingController(rootView: PhotosBrowserImageCellContent(value: value))
        cellHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellHostingController.view)
        cell.contentView.wrap(cellHostingController.view)
    }
}
