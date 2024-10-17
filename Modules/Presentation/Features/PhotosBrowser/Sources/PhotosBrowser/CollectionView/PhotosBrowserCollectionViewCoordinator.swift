import Combine
import MEGADomain
import SwiftUI
import UIKit

@MainActor
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
    private var layoutChangesMonitor: PhotosBrowserCollectionViewLayoutChangesMonitor
    private var reloadSnapshotTask: Task<Void, Never>?
    private var isInitiaLoad: Bool = true
    private var pageIndexSubscription: AnyCancellable?
    
    weak var layout: PhotosBrowserCollectionViewLayout?
    
    init(_ representer: PhotosBrowserCollectionViewRepresenter) {
        self.representer = representer
        self.layoutChangesMonitor = PhotosBrowserCollectionViewLayoutChangesMonitor(representer)
        
        super.init()
    }
    
    deinit {
        reloadSnapshotTask?.cancel()
    }
    
    // MARK: - Layout
    
    func updateLayout(_ newLayout: PhotosBrowserCollectionViewLayout, scrollToCurrentIndex: Bool = false) {
        self.layout = newLayout
        
        pageIndexSubscription?.cancel()
        pageIndexSubscription = newLayout.pageIndexPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIndex in
                self?.updateCurrentIndex(to: newIndex)
            }
        
        scrollToCurrentPage(shouldScroll: scrollToCurrentIndex)
    }
    
    // MARK: - DataSouce & Snapshots
    
    func configureDataSource(for collectionView: UICollectionView) {
        self.collectionView = collectionView
        
        let cellRegistration = CellRegistration { [weak self] cell, _, entity in
            guard let self else { return }
            
            configureCell(cell, with: entity)
        }
        
        dataSource = DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, entity in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entity)
        }
        
        layoutChangesMonitor.configure(collectionView: collectionView, coordinator: self)
        
        collectionView.dataSource = dataSource
    }
    
    func updateUI(with assets: [PhotosBrowserLibraryEntity]) {
        reloadSnapshotTask = Task {
            await reloadData(with: assets)
            
            guard isInitiaLoad else { return }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                
                scrollToCurrentPage(shouldScroll: true)
            }
        }
    }
    
    // MARK: - Private
    
    private func reloadData(with assets: [PhotosBrowserLibraryEntity]) async {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(assets, toSection: .main)
        
        guard !Task.isCancelled else { return }
        
        await dataSource?.apply(snapshot, animatingDifferences: false)
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
    
    private func updateCurrentIndex(to newIndex: Int) {
        guard representer.viewModel.currentIndex != newIndex else { return }
        
        representer.viewModel.library.currentIndex = newIndex
    }
    
    private func scrollToCurrentPage(shouldScroll: Bool) {
        guard shouldScroll, let collectionView = self.collectionView  else { return }
        
        let indexPath = IndexPath(item: representer.viewModel.library.currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}
