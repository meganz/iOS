import Foundation

extension CHTCollectionViewWaterfallLayout {
    @objc func configThumbnailListColumnCount() {
        let columns = Int(containerWidth) / Int(ThumbnailSize.width.rawValue)
        columnCount = max(2, columns)
    }
    
    private var containerWidth: CGFloat {
        var windowWidth = UIScreen.main.bounds.width
        if let keyWindow = UIApplication.shared.keyWindow {
            windowWidth = keyWindow.bounds.width - keyWindow.safeAreaInsets.left - keyWindow.safeAreaInsets.right
        }
        
        return windowWidth - sectionInset.left - sectionInset.right
    }
}
