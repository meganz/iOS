import Foundation
import UIKit

@objc protocol DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell?
}

@objc final class DynamicTypeCollectionManager: NSObject {
    
    final class CollectionItem {
        var section: Int
        var size: CGSize
        var sizingCell: UICollectionViewCell
        
        lazy var key: NSString = {
            "\(section)" as NSString
        }()
        
        init(section: Int, size: CGSize, sizingCell: UICollectionViewCell) {
            self.section = section
            self.size = size
            self.sizingCell = sizingCell
        }
    }
    
    @objc weak var delegate: DynamicTypeCollectionViewSizing?
    
    private let cache = NSCache<NSString, CollectionItem>()
    
    @objc init(delegate: DynamicTypeCollectionViewSizing) {
        self.delegate = delegate
    }
    
    @objc func resetCollectionItems() {
        cache.removeAllObjects()
    }
    
    @objc func currentItemSize(for indexPath: IndexPath) -> CGSize {
        guard let currentItem = cache.object(forKey: "\(indexPath.section)" as NSString) else {
            return calculateItemSize(for: indexPath)
        }

        return currentItem.size != .zero ? currentItem.size : calculateItemSize(for: indexPath)
    }
    
    private func calculateItemSize(for indexPath: IndexPath) -> CGSize {
        guard let sizingCell = delegate?.provideSizingCell(for: indexPath) else { return .zero }
        
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = CGFloat(ThumbnailSize.width.rawValue)

        let size = sizingCell.contentView.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        cacheItemSize(size, cell: sizingCell, section: indexPath.section)
        
        return size
    }
    
    private func cacheItemSize(_ size: CGSize, cell: UICollectionViewCell, section: Int) {
        let item = CollectionItem(section: section, size: size, sizingCell: cell)
        cache.setObject(item, forKey: item.key)
    }
}
