import Foundation
import MEGADomain
import MEGAPresentation
import SwiftUI

@MainActor
final class AllVideosCollectionViewCoordinator: NSObject {
    
    private enum Section {
        case allVideos
    }
    
    /// Row Item type to support diffable data source diffing while protecting `NodeEntity` agasint the `DiffableDataSource` API.
    private struct RowItem: Hashable, Sendable {
        let node: NodeEntity
        let searchText: String?

        init(node: NodeEntity, searchText: String?) {
            self.node = node
            self.searchText = searchText
        }
        
        static func == (lhs: RowItem, rhs: RowItem) -> Bool {
            lhs.node.id == rhs.node.id
            && lhs.node.isFavourite == rhs.node.isFavourite
            && lhs.node.name == rhs.node.name
            && lhs.node.description == rhs.node.description
            && lhs.node.label == rhs.node.label
            && lhs.node.isExported == rhs.node.isExported
            && lhs.node.isMarkedSensitive == rhs.node.isMarkedSensitive
            && lhs.searchText == rhs.searchText
        }
    }
    
    private let videoConfig: VideoConfig
    private let representer: AllVideosCollectionViewRepresenter
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var searchText: String?

    private var dataSource: DiffableDataSource?
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item>
    private typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private typealias Item = RowItem
    private var reloadSnapshotTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    deinit {
        reloadSnapshotTask?.cancel()
    }
    
    init(
        _ representer: AllVideosCollectionViewRepresenter,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.representer = representer
        self.videoConfig = representer.videoConfig
    }
    
    func configure(_ collectionView: UICollectionView, searchText: String?) {
        self.searchText = searchText
        configureDataSource(for: collectionView)

        switch viewContext() {
        case .playlistContent(let type) where type == .user && featureFlagProvider.isFeatureFlagEnabled(for: .reorderVideosInVideoPlaylistContent):
            configureDragDropInteraction(for: collectionView)
        default:
            break
        }
    }
    
    private func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
        collectionView.dataSource = dataSource
    }
    
    private func configureDragDropInteraction(for collectionView: UICollectionView) {
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
    }

    private func makeDataSource(for collectionView: UICollectionView) -> DiffableDataSource {
        let cellRegistration = CellRegistration { [weak self] cell, _, rowItem in
            guard let self else { return }
            
            let viewModel = representer.viewModel
            guard let viewContext = viewContext() else { return }
            
            let cellViewModel = VideoCellViewModel(
                mode: .plain,
                viewContext: viewContext,
                nodeEntity: rowItem.node,
                searchText: rowItem.searchText,
                thumbnailLoader: viewModel.thumbnailLoader,
                sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
                nodeUseCase: viewModel.nodeUseCase,
                featureFlagProvider: featureFlagProvider,
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
    
    private func viewContext() -> VideoCellViewModel.ViewContext? {
        switch representer.viewType {
        case .allVideos: .allVideos
        case .playlistContent(let type): .playlistContent(type: type)
        case .playlists: nil
        case .recentlyWatchedVideos: nil
        }
    }
    
    private func onTapCell(video: NodeEntity) {
        guard representer.selection.editMode != .active else {
            return
        }
        let videos = (dataSource?.snapshot().itemIdentifiers ?? []).map(\.node)
        representer.router.openMediaBrowser(for: video, allVideos: videos)
    }
    
    func reloadData(with videos: [NodeEntity], searchText: String?) {
        self.searchText = searchText
        reloadSnapshotTask = Task { await reloadData(with: videos) }
    }
    
    private func reloadData(with videos: [NodeEntity]) async {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections([.allVideos])
        snapshot.appendItems(videos.map(rowItem(for:)), toSection: .allVideos)
        guard !Task.isCancelled else { return }
        await dataSource?.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Cell setup

    private func rowItem(for node: NodeEntity) -> RowItem {
        RowItem(
            node: node,
            searchText: featureFlagProvider.isFeatureFlagEnabled(for: .searchUsingNodeDescription) ? searchText : nil
        )
    }

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

// MARK: - Drag & Drop Extension

extension AllVideosCollectionViewCoordinator: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let rowItem = dataSource?.itemIdentifier(for: indexPath) else { return [] }
        let itemProvider = NSItemProvider(object: rowItem.node.id.description as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = rowItem
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        self.collectionView(collectionView, itemsForBeginning: session, at: indexPath)
    }
    
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        if coordinator.proposal.operation == .move {
            reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        guard let sourceIndexPath = items.first?.sourceIndexPath else { return }
        
        collectionView.performBatchUpdates {
            guard let item = dataSource?.itemIdentifier(for: sourceIndexPath) else { return }
            guard var snapshot = dataSource?.snapshot() else { return }
            
            snapshot.deleteItems([item])
            
            switch itemDragDirectionType(destination: destinationIndexPath, source: sourceIndexPath) {
            case .none:
                guard let dragItem = items.first?.dragItem else { return }
                handleDrop(dragItem, toItemAt: destinationIndexPath, on: coordinator)
                return
            case .downward:
                guard let afterItem = dataSource?.itemIdentifier(for: destinationIndexPath) else { return }
                snapshot.insertItems([item], afterItem: afterItem)
            case .upward:
                guard let beforeItem = dataSource?.itemIdentifier(for: destinationIndexPath) else { return }
                snapshot.insertItems([item], beforeItem: beforeItem)
            }
            
            dataSource?.apply(snapshot, animatingDifferences: true)
        }
        
        guard let dragItem = items.first?.dragItem else { return }
        handleDrop(dragItem, toItemAt: destinationIndexPath, on: coordinator)
    }
    
    private func itemDragDirectionType(destination destinationIndexPath: IndexPath, source sourceIndexPath: IndexPath) -> ItemDragDirectionType {
        if destinationIndexPath == sourceIndexPath {
            .none
        } else if destinationIndexPath.row > sourceIndexPath.row {
            .downward
        } else {
            .upward
        }
    }
    
    private func handleDrop(_ dragItem: UIDragItem, toItemAt indexPath: IndexPath, on coordinator: UICollectionViewDropCoordinator) {
        coordinator.drop(dragItem, toItemAt: indexPath)
    }
}

private enum ItemDragDirectionType {
    case downward
    case upward
    case none
}
