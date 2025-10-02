import Foundation

final class FolderLinkCollectionViewDiffableDataSource {
    private var dataSource: UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>?
    private weak var collectionView: UICollectionView?
    private weak var controller: FolderLinkCollectionViewController?
    
    init(collectionView: UICollectionView, controller: FolderLinkCollectionViewController?) {
        self.collectionView = collectionView
        self.controller = controller
    }

    func load(data: [ThumbnailSection: [MEGANode]], keys: [ThumbnailSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<ThumbnailSection, MEGANode>()
        keys.forEach { key in
            snapshot.appendSections([key])
            snapshot.appendItems(data[key] ?? [])
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
        collectionView?.reloadData()
    }

    func reload(nodes: [MEGANode]) {
        guard var newSnapshot = dataSource?.snapshot() else { return }
        let snapshotNodes = nodes.filter { newSnapshot.indexOfItem($0) != nil }
        if !snapshotNodes.isEmpty {
            newSnapshot.reloadItems(snapshotNodes)
            dataSource?.apply(newSnapshot)
        }
    }

    func configureDataSource() {
        guard let collectionView = collectionView else { return }

        dataSource = UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, node: MEGANode) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "NodeCollectionViewID",
                for: indexPath
            ) as? NodeCollectionViewCell else {
                fatalError("Could not instantiate NodeCollectionViewCell or Node at index")
            }
            
            cell.configureCell(forFolderLinkNode: node, allowedMultipleSelection: collectionView.allowsMultipleSelection, sdk: MEGASdk.sharedFolderLink, delegate: self?.controller)
            
            return cell
        }
    }
}
