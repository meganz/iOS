import UIKit

final class SlideShowCollectionView: UICollectionView {
    private var layout: AnimatedCollectionViewLayout?
    
    override var bounds: CGRect {
        didSet {
            layout?.itemSize = bounds.size
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isPagingEnabled = true
    
        layout = AnimatedCollectionViewLayout()
    }
    
    func updateLayout() {
        guard let layout = layout else { return }
        layout.animator = CrossFadeAttributesAnimator()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setCollectionViewLayout(layout, animated: false)
    }
}
