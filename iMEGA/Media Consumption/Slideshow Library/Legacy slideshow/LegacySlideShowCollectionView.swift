import UIKit

final class LegacySlideShowCollectionView: UICollectionView {
    private var layout: SlideShowCollectionViewLayout?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isPagingEnabled = true

        layout = SlideShowCollectionViewLayout()
    }

    func updateLayout() {
        guard let layout = layout else { return }
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setCollectionViewLayout(layout, animated: false)
    }

    func fadeCell(for indexPath: IndexPath) {
        let screenHalf = self.bounds.height / 2 + self.bounds.height * CGFloat(indexPath.row)
        let topPosition = self.contentOffset.y
        guard let cell = self.cellForItem(at: indexPath) as? SlideShowCollectionViewCell,
              topPosition >= 0 else { return }
        let needOpacityToZeroChange = topPosition >= screenHalf
        let opacity = needOpacityToZeroChange ? 0 : 1 - ((topPosition.truncatingRemainder(dividingBy: screenHalf)) / screenHalf)
        cell.alpha = opacity
    }
}
