import Foundation

@MainActor
final class FolderLinkCollectionViewDiffableDataSource {
    private var dataSource: UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>?
    private weak var collectionView: UICollectionView?
    private weak var controller: FolderLinkCollectionViewController?
    
    init(collectionView: UICollectionView, controller: FolderLinkCollectionViewController?) {
        self.collectionView = collectionView
        self.controller = controller

        registerSupplementaryViewCell(in: collectionView)
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

    func configureDataSource(usesRevampedUI: Bool) {
        guard let collectionView = collectionView else { return }

        let reuseIdentifier = usesRevampedUI ? NodeCollectionViewCell.folderLinkReusableIdentifier : NodeCollectionViewCell.reusableIdentifier

        dataSource = UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, node: MEGANode) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier,
                for: indexPath
            ) as? NodeCollectionViewCell else {
                fatalError("Could not instantiate NodeCollectionViewCell or Node at index")
            }

            cell.configureCellForFolderLinkNode(
                node,
                allowedMultipleSelection: collectionView.allowsMultipleSelection,
                sdk: MEGASdk.sharedFolderLink,
                delegate: self?.controller,
                usesRevampedUI: usesRevampedUI
            )
            
            return cell
        }

        dataSource?.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            self?.headerSupplementaryView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
    }

    private func registerSupplementaryViewCell(in collectionView: UICollectionView) {
        collectionView.register(
            FolderLinkCollectionHeaderView.self,
            forSupplementaryViewOfKind: CHTCollectionElementKindSectionHeader,
            withReuseIdentifier: FolderLinkCollectionHeaderView.reusableIdentifier
        )
    }

    private func headerSupplementaryView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView? {
        guard kind == CHTCollectionElementKindSectionHeader,
              indexPath.section == 0,
              controller?.folderLink.shouldShowHeaderView == true,
              let controller,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: CHTCollectionElementKindSectionHeader,
                withReuseIdentifier: FolderLinkCollectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? FolderLinkCollectionHeaderView else {
            return UICollectionReusableView()
        }

        headerView.frame.size.height = 40
        headerView.addContentView(controller.folderLink.headerView(for: controller))
        return headerView
    }
}
