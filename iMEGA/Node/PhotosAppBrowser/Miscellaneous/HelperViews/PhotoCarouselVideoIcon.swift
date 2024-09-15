import UIKit

final class PhotoCarouselVideoIcon: SingleTapView {
    
    private let halfRatio: CGFloat = 0.5
    private let playIconRightOffsetPaddingRatio: CGFloat = 1.225
    
    private lazy var vibrancyView: UIView = {
        let vibrancyView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        vibrancyView.clipsToBounds = true
        return vibrancyView
    }()
    
    private lazy var playIconLayer: CALayer = {
        let playIconLayer = CAShapeLayer()
        playIconLayer.path = UIBezierPath.playIconPath.cgPath
        playIconLayer.fillColor = UIColor.gray555555.cgColor
        playIconLayer.zPosition = 1
        return playIconLayer
    }()
    
    // MARK: - Initializers.

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    // MARK: - Overriden method.
    
    override func layoutSubviews() {
        super.layoutSubviews()
        vibrancyView.frame = bounds
        vibrancyView.layer.cornerRadius = bounds.width * halfRatio
        
        let iconHeight = bounds.height * halfRatio
        let widthToHeightRatio = UIBezierPath.playIconDefaultSize.width / UIBezierPath.playIconDefaultSize.height
        let iconWidth = iconHeight * widthToHeightRatio

        playIconLayer.transform = CATransform3DMakeScale(iconWidth / UIBezierPath.playIconDefaultSize.width,
                                                         iconHeight / UIBezierPath.playIconDefaultSize.height,
                                                         1)
        let leftPaddingpadding = ((bounds.width - iconWidth) * halfRatio) * playIconRightOffsetPaddingRatio
        playIconLayer.frame = CGRect(origin: CGPoint(x: leftPaddingpadding,
                                                     y: (bounds.height * halfRatio) - (iconHeight * halfRatio)),
                                      size: CGSize(width: iconHeight * widthToHeightRatio, height: iconHeight))

    }
    
    // MARK: - Private method.
    
    private func configure() {
        addSubview(vibrancyView)
        layer.addSublayer(playIconLayer)
    }
}

// MARK: - UIBezierPath Extension for the play Icon path and default size.

fileprivate extension UIBezierPath {
    static var playIconDefaultSize: CGSize {
        return CGSize(width: 48, height: 68)
    }
    
    // size of the path is 48 x 68
    static var playIconPath: UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: 48, y: 34))
        bezierPath.addLine(to: CGPoint(x: 0, y: 68))
        bezierPath.close()
        return bezierPath
    }
}
