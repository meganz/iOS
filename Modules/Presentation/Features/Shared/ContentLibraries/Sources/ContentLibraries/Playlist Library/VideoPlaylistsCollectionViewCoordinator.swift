import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI
import UIKit

@MainActor
public final class VideoPlaylistsCollectionViewCoordinator<ViewModel: VideoPlaylistsContentViewModelProtocol> {
    
    private enum Section {
        case videoPlaylists
    }
    
    /// Row Item type to support diffable data source diffing while protecting `VideoPlaylistEntity` agasint the `DiffableDataSource` API.
    private struct RowItem: Hashable, Sendable {
        let videoPlaylist: VideoPlaylistEntity
        
        init(videoPlaylist: VideoPlaylistEntity) {
            self.videoPlaylist = videoPlaylist
        }
        
        static func == (lhs: RowItem, rhs: RowItem) -> Bool {
            lhs.videoPlaylist.id == rhs.videoPlaylist.id &&
            lhs.videoPlaylist.name == rhs.videoPlaylist.name &&
            lhs.videoPlaylist.sharedLinkStatus == rhs.videoPlaylist.sharedLinkStatus
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(videoPlaylist.id)
            hasher.combine(videoPlaylist.name)
            hasher.combine(videoPlaylist.sharedLinkStatus)
        }
    }
    
    private let representer: VideoPlaylistsCollectionViewRepresenter<ViewModel>
    
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
    
    public init(_ representer: VideoPlaylistsCollectionViewRepresenter<ViewModel>) {
        self.representer = representer
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
        collectionView.dataSource = dataSource
    }
    
    private func makeDataSource(for collectionView: UICollectionView) -> DiffableDataSource {
        let cellRegistration = CellRegistration { [weak self] cell, _, rowItem in
            guard let self else { return }
            let cellViewModel = cellViewModel(for: rowItem)
            configureCell(cell, cellViewModel: cellViewModel, rowItem: rowItem)
        }
        
        return DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    func reloadData(with videoPlaylists: [VideoPlaylistEntity]) {
        reloadSnapshotTask = Task { await reloadData(with: videoPlaylists) }
    }
    
    private func reloadData(with videoPlaylists: [VideoPlaylistEntity]) async {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections([.videoPlaylists])
        let items = videoPlaylists.map { RowItem(videoPlaylist: $0) }
        snapshot.appendItems(items, toSection: .videoPlaylists)
        guard !Task.isCancelled else { return }
        await dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Cell setup
    
    private func configureCell(_ cell: UICollectionViewCell, cellViewModel: VideoPlaylistCellViewModel, rowItem: RowItem) {
        prepareCellForReuse(cell)
        
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration {
                cellView(for: rowItem)
            }
            .margins(.all, 0)
            cell.clipsToBounds = true
        } else {
            configureCellBelowiOS16(cellViewModel: cellViewModel, cell: cell, rowItem: rowItem)
        }
    }
    
    private func configureCellBelowiOS16(cellViewModel: VideoPlaylistCellViewModel, cell: UICollectionViewCell, rowItem: RowItem) {
        let cellView = cellView(for: rowItem)
        
        let cellHostingController = UIHostingController(rootView: cellView)
        cellHostingController.view.backgroundColor = .clear
        cellHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellHostingController.view)
        cell.contentView.backgroundColor = TokenColors.Background.page
        
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
    
    @ViewBuilder
    private func cellView(for rowItem: RowItem) -> some View {
        if rowItem.videoPlaylist.isSystemVideoPlaylist {
            FavoritePlaylistCell(
                viewModel: self.cellViewModel(for: rowItem),
                router: representer.router
            )
        } else {
            UserPlaylistCell(
                viewModel: self.cellViewModel(for: rowItem),
                router: representer.router
            )
            .background(TokenColors.Background.page.swiftUI)
        }
    }
    
    private func cellViewModel(for rowItem: RowItem) -> VideoPlaylistCellViewModel {
        VideoPlaylistCellViewModel(
            videoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoader(
                thumbnailLoader: representer.viewModel.thumbnailLoader,
                fallbackImageContainer: ImageContainer(
                    image: MEGAAssets.Image.videoPlaylistThumbnailFallback,
                    type: .thumbnail
                )
            ),
            videoPlaylistContentUseCase: representer.viewModel.videoPlaylistContentUseCase,
            sortOrderPreferenceUseCase: representer.viewModel.sortOrderPreferenceUseCase,
            videoPlaylistEntity: rowItem.videoPlaylist,
            setSelection: representer.viewModel.setSelection,
            onTapMoreOptions: { [weak self] in
                self?.representer.didSelectMoreOptionForItem?($0)
            }
        )
    }
}
