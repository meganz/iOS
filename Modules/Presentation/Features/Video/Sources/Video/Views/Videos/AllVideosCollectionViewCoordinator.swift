import Foundation
import MEGADomain
import SwiftUI

final class AllVideosCollectionViewCoordinator: NSObject {
    
    private enum Section {
        case allVideos
    }
    
    private let videoConfig: VideoConfig
    private let representer: AllVideosCollectionViewRepresenter
    
    private var dataSource: DiffableDataSource?
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item>
    private typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private typealias Item = NodeEntity
    
    init(_ representer: AllVideosCollectionViewRepresenter) {
        self.representer = representer
        self.videoConfig = representer.videoConfig
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        collectionView.delegate = self
        
        dataSource = makeDataSource(for: collectionView)
        collectionView.dataSource = dataSource
    }
    
    private func makeDataSource(for collectionView: UICollectionView) -> DiffableDataSource {
        let cellRegistration = CellRegistration { [weak self] cell, _, video in
            guard let self else { return }
            
            let cellViewModel = VideoCellViewModel(
                thumbnailUseCase: representer.thumbnailUseCase,
                nodeEntity: video
            )
            configureCell(cell, cellViewModel: cellViewModel)
        }
        
        return DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    func reloadData(with videos: [NodeEntity]) {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections([.allVideos])
        snapshot.appendItems(videos, toSection: .allVideos)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: - Cell setup
    
    private func configureCell(_ cell: UICollectionViewCell, cellViewModel: VideoCellViewModel) {
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration {
                VideoCellView(viewModel: cellViewModel, videoConfig: videoConfig)
                    .background(videoConfig.colorAssets.pageBackgroundColor)
            }
            .margins(.all, 0)
            cell.clipsToBounds = true
        } else {
            configureCellBelowiOS16(cellViewModel: cellViewModel, cell: cell)
        }
    }
    
    private func configureCellBelowiOS16(cellViewModel: VideoCellViewModel, cell: UICollectionViewCell) {
        let cellView = VideoCellView(viewModel: cellViewModel, videoConfig: videoConfig)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
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
}

// MARK: - AllVideosCollectionViewCoordinator+UICollectionViewDelegate

extension AllVideosCollectionViewCoordinator: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videos = dataSource?.snapshot().itemIdentifiers ?? []
        guard let video = videos[safe: indexPath.item] else { return }
        representer.router.openMediaBrowser(for: video, allVideos: videos)
    }
}
