
final class PaddingLabel: UILabel {

    /// The amount of padding for each side in the label.
    @objc dynamic var edgeInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }

     override var bounds: CGRect {
        didSet {
            // This fixes an issue where the last line of the label would sometimes be cut off.
            if numberOfLines == 0 {
                let boundsWidth = bounds.width - edgeInsets.left - edgeInsets.right
                if preferredMaxLayoutWidth != boundsWidth {
                    preferredMaxLayoutWidth = boundsWidth
                    setNeedsUpdateConstraints()
                }
            }
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width  += edgeInsets.left + edgeInsets.right
        size.height += edgeInsets.top + edgeInsets.bottom

        // There's a UIKit bug where the content size is sometimes one point to short. This hacks that.
        if numberOfLines == 0 { size.height += 1 }

        return size
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var parentSize = super.sizeThatFits(size)
        parentSize.width  += edgeInsets.left + edgeInsets.right
        parentSize.height += edgeInsets.top + edgeInsets.bottom

        return parentSize
    }
}
