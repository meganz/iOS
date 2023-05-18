
import UIKit

final class PhotoGridViewFlowLayout: UICollectionViewFlowLayout {
    
    private let cellInsetValue: CGFloat = 1
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()
        
        if let attributes = super.layoutAttributesForElements(in: rect) {
            for item in attributes where item.representedElementKind == nil {
                if let cellAttributes = item.copy() as? UICollectionViewLayoutAttributes {
                    cellAttributes.frame = cellAttributes.frame.insetBy(dx: cellInsetValue , dy: cellInsetValue)
                    result.append(cellAttributes)
                }
            }
        }
        
        return result
    }

}
