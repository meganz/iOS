import Foundation
import MEGADomain
import SwiftUI

final class AllVideosCollectionViewCoordinator: NSObject {
    
    private enum Section {
        case allVideos
    }
    
    /// Row Item type to support diffable data source diffing while protecting `NodeEntity` agasint the `DiffableDataSource` API.
    private struct RowItem: Hashable {
        let node: NodeEntity
        
        init(node: NodeEntity) {
            self.node = node
        }
        
        static func == (lhs: RowItem, rhs: RowItem) -> Bool {
            lhs.node.id == rhs.node.id
            && lhs.node.isFavourite == rhs.node.isFavourite
            && lhs.node.name == rhs.node.name
            && lhs.node.label == rhs.node.label
            && lhs.node.isExported == rhs.node.isExported
            && lhs.node.isMarkedSensitive == rhs.node.isMarkedSensitive
        }
    }
    
    private let videoConfig: VideoConfig
    private let representer: AllVideosCollectionViewRepresenter
    
    private var dataSource: DiffableDataSource?
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item>
    private typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private typealias Item = RowItem
    
    init(_ representer: AllVideosCollectionViewRepresenter) {
        self.representer = representer
        self.videoConfig = representer.videoConfig
    }
    
    func configureDataSource(for collectionView: UICollectionView) {        
        dataSource = makeDataSource(for: collectionView)
        collectionView.dataSource = dataSource
    }
    
    private func makeDataSource(for collectionView: UICollectionView) -> DiffableDataSource {
        let cellRegistration = CellRegistration { [weak self] cell, _, rowItem in
            guard let self else { return }
            
            let viewModel = representer.viewModel
            
            let cellViewModel = VideoCellViewModel(
                nodeEntity: rowItem.node,
                thumbnailLoader: viewModel.thumbnailLoader,
                sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
                onTapMoreOptions: { [weak self] in self?.onTapMoreOptions($0, sender: cell) },
                onTapped: { [weak self] in self?.onTapCell(video: $0) }
            )
            let adapter = VideoSelectionCheckmarkUIUpdateAdapter(
                selection: representer.selection,
                viewModel: cellViewModel
            )
            configureCell(cell, cellViewModel: cellViewModel, adapter: adapter)
        }
        
        return DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    private func onTapCell(video: NodeEntity) {
        guard representer.selection.editMode != .active else {
            return
        }
        let videos = (dataSource?.snapshot().itemIdentifiers ?? []).map(\.node)
        representer.router.openMediaBrowser(for: video, allVideos: videos)
    }
    
    func reloadData(with videos: [NodeEntity]) {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections([.allVideos])
        snapshot.appendItems(videos.map(RowItem.init(node:)), toSection: .allVideos)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Cell setup
    
    private func configureCell(_ cell: UICollectionViewCell, cellViewModel: VideoCellViewModel, adapter: VideoSelectionCheckmarkUIUpdateAdapter) {
        prepareCellForReuse(cell)
        
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration {
                VideoCellView(
                    viewModel: cellViewModel,
                    selection: self.representer.selection,
                    onTappedCheckMark: adapter.onTappedCheckMark,
                    videoConfig: videoConfig
                )
                .background(videoConfig.colorAssets.pageBackgroundColor)
            }
            .margins(.all, 0)
            cell.clipsToBounds = true
        } else {
            configureCellBelowiOS16(cellViewModel: cellViewModel, cell: cell, adapter: adapter)
        }
    }
    
    private func configureCellBelowiOS16(cellViewModel: VideoCellViewModel, cell: UICollectionViewCell, adapter: VideoSelectionCheckmarkUIUpdateAdapter) {
        let cellView = VideoCellView(
            viewModel: cellViewModel,
            selection: self.representer.selection,
            onTappedCheckMark: adapter.onTappedCheckMark,
            videoConfig: videoConfig
        )
        
        let cellHostingController = UIHostingController(rootView: cellView)
        cellHostingController.view.backgroundColor = .clear
        cellHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellHostingController.view)
        cell.contentView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        
        NSLayoutConstraint.activate([
            cellHostingController.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            cellHostingController.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            cellHostingController.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            cellHostingController.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
    }
    
    private func prepareCellForReuse(_ cell: UICollectionViewCell) {
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = nil
        } else {
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        }
    }
    
    private func onTapMoreOptions(_ video: NodeEntity, sender: Any) {
        representer.router.openMoreOptions(for: video, sender: sender)
    }
}
