import Foundation

extension CHTCollectionViewWaterfallLayout {
    @objc func configThumbnailListColumnCount() {
        var windowWidth = UIScreen.main.bounds.width
        if let keyWindow = UIApplication.shared.keyWindow {
            windowWidth = keyWindow.bounds.width - keyWindow.safeAreaInsets.left - keyWindow.safeAreaInsets.right
        }
        let containerWidth = windowWidth - sectionInset.left - sectionInset.right
        let columns = Int(containerWidth / CGFloat(ThumbnailSize.width.rawValue))
        columnCount = max(2, columns)
    }
}
