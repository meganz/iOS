import UIKit

protocol MEGACarouselFlowLayoutDelegate: AnyObject {

    func collectionView(_ collectionView: UICollectionView,
                        collectionViewLayout: MEGACarouselFlowLayout,
                        didScrollToPage: Int)
}

final class MEGACarouselFlowLayout: UICollectionViewFlowLayout {

    fileprivate struct LayoutState {
        var size: CGSize
        func isEqual(_ otherState: LayoutState) -> Bool {
            return self.size.equalTo(otherState.size)
        }
    }

    enum SpacingMode {
        case fixed(spacing: CGFloat)
        case overlap(visibleOffset: CGFloat)
    }

    private let spacingMode: SpacingMode = .fixed(spacing: 10)

    private let itemScaleFactor: CGFloat = 0.6
    private let itemAlpha: CGFloat = 0.6
    private let itemShift: CGFloat = 0.6

    private(set) var page: Int = 0 {
        didSet {
            guard let collectionView = collectionView else { return }
            delegate?.collectionView(collectionView, collectionViewLayout: self, didScrollToPage: page)
        }
    }

    fileprivate var state = LayoutState(size: CGSize.zero)

    weak var delegate: MEGACarouselFlowLayoutDelegate?

    override func prepare() {
        super.prepare()

        let currentState = LayoutState(size: collectionView!.bounds.size)
        if !currentState.isEqual(state) {
            setupCollectionView()
            updateLayout()
            state = currentState
        }
    }

    private func setupCollectionView() {
        guard let collectionView = collectionView else { return }

        collectionView.decelerationRate = .fast
    }

     func updateLayout() {
        guard let collectionView = collectionView else { return }

        let collectionViewSize = collectionView.bounds.size
        let insetY = (collectionViewSize.height - itemSize.height) / 2
        let insetX = (collectionViewSize.width - itemSize.width) / 2
        self.sectionInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        let scaledItemOffset = (itemSize.width - itemSize.width * itemScaleFactor) / 2

        switch spacingMode {
        case .fixed(spacing: let spacing):
            self.minimumLineSpacing = spacing - scaledItemOffset
        case .overlap(visibleOffset: let visibleOffset):
            self.minimumLineSpacing = insetX - visibleOffset - scaledItemOffset
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributers = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributers.map {
            transformLayoutAttributes($0)
        }
    }

    fileprivate func transformLayoutAttributes(_ attribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = attribute.copy() as! UICollectionViewLayoutAttributes
        guard let collectionView = self.collectionView else { return attributes }

        let collectionCenter = collectionView.frame.size.width / 2
        let offset = collectionView.contentOffset.x
        let normalizedCenter = attributes.center.x - offset

        let maxDistance = self.itemSize.width + self.minimumLineSpacing
        let distance = min(abs(collectionCenter - normalizedCenter), maxDistance)
        let ratio = (maxDistance - distance) / maxDistance

        let alpha = ratio * (1 - itemAlpha) + itemAlpha
        let scale = ratio * (1 - itemScaleFactor) + itemScaleFactor
        let shift = (1 - ratio) * itemShift
        attributes.alpha = alpha
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
        attributes.zIndex = Int(alpha * 10)

        attributes.center.y += shift

        return attributes
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView,
              collectionView.isPagingEnabled,
              let layoutAttributes = self.layoutAttributesForElements(in: collectionView.bounds)
        else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

        let midSide = collectionView.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + midSide

        let sorted = layoutAttributes.sorted {
            let first = abs($0.center.x - proposedContentOffsetCenterOrigin)
            let second = abs($1.center.x - proposedContentOffsetCenterOrigin)
            return first < second
        }
        let closest = sorted.first ?? UICollectionViewLayoutAttributes()
        let targetContentOffset = CGPoint(x: floor(closest.center.x - midSide), y: proposedContentOffset.y)

        page = Int(round(targetContentOffset.x / (itemSize.width + minimumLineSpacing)))
        return targetContentOffset
    }

    private var delete: UICollectionViewLayoutAttributes?

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        if attributes?.alpha == 0 {
            delete = attributes
        } else {
            let copy = attributes?.copy() as? UICollectionViewLayoutAttributes
            copy?.frame = delete!.frame
            delete = nil
            return copy
        }

        return attributes
    }
}
