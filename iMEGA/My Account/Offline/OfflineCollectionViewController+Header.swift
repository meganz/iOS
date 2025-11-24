import Foundation

extension OfflineCollectionViewController {
    @objc func registerSupplementaryViewCell(in collectionView: UICollectionView) {
        collectionView.register(
            OfflineCollectionHeaderView.self,
            forSupplementaryViewOfKind: CHTCollectionElementKindSectionHeader,
            withReuseIdentifier: OfflineCollectionHeaderView.reusableIdentifier
        )
    }

    @objc func headerViewHeight(for section: Int) -> CGFloat {
        guard offline?.shouldShowHeaderView == true, section == 0 else { return 0 }
        return 40
    }

    @objc func headerSupplementaryView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let offlineViewController = self.offline, offlineViewController.shouldShowHeaderView else {
            assertionFailure("Case not handled: \(kind) - at \(indexPath)")
            return UICollectionReusableView()
        }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: CHTCollectionElementKindSectionHeader,
            withReuseIdentifier: OfflineCollectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as? OfflineCollectionHeaderView else {
            assertionFailure("Unable to dequeue the correct type of supplementary view")
            return UICollectionReusableView()
        }

        headerView.frame.size.height = 40
        headerView.addContentView(offlineViewController.headerView(for: self))
        return headerView
    }
}
