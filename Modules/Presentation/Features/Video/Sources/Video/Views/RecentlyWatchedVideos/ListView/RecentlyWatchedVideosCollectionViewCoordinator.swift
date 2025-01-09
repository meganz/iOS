import ContentLibraries
import Foundation
import MEGADomain
import SwiftUI
import UIKit

@MainActor
final class RecentlyWatchedVideosCollectionViewCoordinator: NSObject {
    
    typealias SectionTitle = String
    
    /// Row Item type to support diffable data source diffing while protecting `NodeEntity` agasint the `DiffableDataSource` API.
    private struct RowItem: Hashable, Sendable {
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
    private let representer: RecentlyWatchedVideosCollectionViewRepresenter
    
    private var dataSource: DiffableDataSource?
    private typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item>
    private typealias DiffableDataSource = UICollectionViewDiffableDataSource<SectionTitle, Item>
    private typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<SectionTitle, Item>
    private typealias Item = RowItem
    private var reloadSnapshotTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    deinit {
        reloadSnapshotTask?.cancel()
    }
    
    init(_ representer: RecentlyWatchedVideosCollectionViewRepresenter) {
        self.representer = representer
        self.videoConfig = representer.videoConfig
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
        collectionView.dataSource = dataSource
    }
    
    private func makeDataSource(for collectionView: UICollectionView) -> DiffableDataSource {
        
        let headerRegistration = HeaderRegistration(elementKind: RecentlyWatchedVideosSupplementaryElementKind.recentlyWatchedVideosDateSectionHeader.elementKind) { [unowned self] headerCell, _, indexPath in
            configureHeader(
                headerCell,
                text: self.dataSource?.sectionIdentifier(for: indexPath.section) ?? ""
            )
        }
        
        let cellRegistration = CellRegistration { [weak self] cell, _, rowItem in
            guard let self else { return }
            
            let viewModel = representer.viewModel
            
            let cellViewModel = VideoCellViewModel(
                mode: .plain,
                viewContext: .recentlyWatchedVideos,
                nodeEntity: rowItem.node,
                thumbnailLoader: viewModel.thumbnailLoader,
                sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
                nodeUseCase: viewModel.nodeUseCase,
                featureFlagProvider: representer.viewModel.featureFlagProvier,
                onTapMoreOptions: { [weak self] in self?.onTapMoreOptions($0, sender: cell) },
                onTapped: { [weak self] in self?.onTapCell(video: $0) }
            )
            configureCell(cell, cellViewModel: cellViewModel)
        }
        
        let dataSource = DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == RecentlyWatchedVideosSupplementaryElementKind.recentlyWatchedVideosDateSectionHeader.elementKind else {
                return nil
            }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        return dataSource
    }
    
    private func onTapCell(video: NodeEntity) {
        let videos = (dataSource?.snapshot().itemIdentifiers ?? []).map(\.node)
        representer.router.openMediaBrowser(for: video, allVideos: videos)
    }
    
    func reloadData(with sections: [RecentlyWatchedVideoSection]) {
        reloadSnapshotTask = Task { await reloadData(with: sections) }
    }
    
    private func reloadData(with sections: [RecentlyWatchedVideoSection]) async {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections(sections.map(\.title))
        
        for section in sections {
            let videosAtSection = section.videos.map(\.node)
            snapshot.appendItems(videosAtSection.map(RowItem.init(node:)), toSection: section.title)
        }
        
        guard !Task.isCancelled else { return }
        await dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Header Cell setup
    
    private func configureHeader(_ cell: UICollectionViewCell, text: String) {
        prepareCellForReuse(cell)
        
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration {
                RecentlyWatchedVideosHeaderView(text: text)
            }
            .margins(.all, 0)
        } else {
            configureHeaderCellBelowiOS16(text: text, cell: cell)
        }
    }
    
    private func configureHeaderCellBelowiOS16(text: String, cell: UICollectionViewCell) {
        let cellView = RecentlyWatchedVideosHeaderView(text: text)
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
    
    // MARK: - Cell setup
    
    private func configureCell(_ cell: UICollectionViewCell, cellViewModel: VideoCellViewModel) {
        prepareCellForReuse(cell)
        
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration {
                VideoCellView(
                    viewModel: cellViewModel,
                    selection: self.videoSelection(),
                    onTappedCheckMark: {},
                    videoConfig: videoConfig
                )
                .background(videoConfig.colorAssets.pageBackgroundColor)
            }
            .margins(.all, 0)
            cell.clipsToBounds = true
        } else {
            configureCellBelowiOS16(cellViewModel: cellViewModel, cell: cell)
        }
    }
    
    private func configureCellBelowiOS16(cellViewModel: VideoCellViewModel, cell: UICollectionViewCell) {
        let cellView = VideoCellView(
            viewModel: cellViewModel,
            selection: self.videoSelection(),
            onTappedCheckMark: {},
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
    
    // Unfortunately, SwiftUI could not have optional @StateObject so we still need to pass this down.
    private func videoSelection() -> VideoSelection {
        VideoSelection()
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
