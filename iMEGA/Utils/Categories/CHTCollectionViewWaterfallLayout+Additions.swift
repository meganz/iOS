import Foundation

extension CHTCollectionViewWaterfallLayout {
    @objc func configThumbnailListColumnCount() {
        let columns = Int(containerWidth) / Int(ThumbnailSize.width.rawValue)
        columnCount = max(2, columns)
    }
    
    private var containerWidth: CGFloat {
        // The collection view once it has been laid out, the window before that.
        let container: UIView? = (collectionView?.bounds.width ?? 0) > 0 ? collectionView : UIApplication.mnz_keyWindow()
        guard let container else { return 0 }
        let usableWidth = container.bounds.width - container.safeAreaInsets.left - container.safeAreaInsets.right
        return usableWidth - sectionInset.left - sectionInset.right
    }
}
