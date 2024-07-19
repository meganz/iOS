import UIKit

final class PhotoCollectionBottomView: UIView {
    private let padding: CGFloat = 10
    
    // The following UIColor values are not design token-dependent, as they're color-literal "black/white" values in both dark/light modes
    private lazy var label: UILabel = {
        let label = UILabel()
        label.layer.zPosition = 1
        label.textColor = UIColor.white
        label.font = .boldSystemFont(ofSize: 12)
        return label
    }()
    
    private lazy var videoIconLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath.videoIconPath.cgPath
        layer.fillColor = UIColor.white.cgColor
        return layer
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0), UIColor.black].map { $0.cgColor }
        gradientLayer.opacity = 0.5
        return gradientLayer
    }()
    
    var text: String? {
        didSet {
            label.text = text
            layoutLabel()
        }
    }
    
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
        
        gradientLayer.frame = bounds
        
        let ratio = CGFloat(3.0) / CGFloat(4.0)
        let iconHeight = bounds.height * ratio
        videoIconLayer.transform = CATransform3DMakeScale(iconHeight/CGFloat(20.0),
                                                          iconHeight/CGFloat(20.0), CGFloat(1))
        videoIconLayer.frame = CGRect(origin: CGPoint(x: padding,
                                                      y: (bounds.height/CGFloat(2.0)) - (iconHeight/CGFloat(2))),
                                      size: CGSize(width: iconHeight, height: iconHeight))
        
        layoutLabel()
    }
    
    // MARK: - Private methods
    
    private func configure() {
        layer.addSublayer(gradientLayer)
        layer.addSublayer(videoIconLayer)
        addSubview(label)
    }
    
    private func layoutLabel() {
        label.sizeToFit()
        label.frame = CGRect(origin: CGPoint(x: bounds.width - label.bounds.width - padding,
                                             y: (bounds.height/2.0) - (label.bounds.height/2)),
                             size: label.bounds.size)
    }
}

// MARK: - UIBezierPath extension for video icon drawing path.

fileprivate extension UIBezierPath {
    static var videoIconPath: UIBezierPath {
        // size of the path is 20 x 20
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 17.92, y: 4.63))
        bezierPath.addLine(to: CGPoint(x: 14.09, y: 7.11))
        bezierPath.addLine(to: CGPoint(x: 14.09, y: 6.37))
        bezierPath.addCurve(to: CGPoint(x: 12.27, y: 4.56), controlPoint1: CGPoint(x: 14.09, y: 5.37), controlPoint2: CGPoint(x: 13.27, y: 4.56))
        bezierPath.addLine(to: CGPoint(x: 3.19, y: 4.56))
        bezierPath.addCurve(to: CGPoint(x: 1.37, y: 6.37), controlPoint1: CGPoint(x: 2.19, y: 4.56), controlPoint2: CGPoint(x: 1.37, y: 5.37))
        bezierPath.addLine(to: CGPoint(x: 1.37, y: 13.63))
        bezierPath.addCurve(to: CGPoint(x: 3.19, y: 15.45), controlPoint1: CGPoint(x: 1.37, y: 14.63), controlPoint2: CGPoint(x: 2.19, y: 15.45))
        bezierPath.addLine(to: CGPoint(x: 12.27, y: 15.45))
        bezierPath.addCurve(to: CGPoint(x: 14.09, y: 13.63), controlPoint1: CGPoint(x: 13.27, y: 15.45), controlPoint2: CGPoint(x: 14.09, y: 14.63))
        bezierPath.addLine(to: CGPoint(x: 14.09, y: 12.89))
        bezierPath.addLine(to: CGPoint(x: 17.92, y: 15.37))
        bezierPath.addCurve(to: CGPoint(x: 18.62, y: 14.99), controlPoint1: CGPoint(x: 18.35, y: 15.6), controlPoint2: CGPoint(x: 18.62, y: 15.21))
        bezierPath.addLine(to: CGPoint(x: 18.62, y: 5.01))
        bezierPath.addCurve(to: CGPoint(x: 17.92, y: 4.63), controlPoint1: CGPoint(x: 18.62, y: 4.79), controlPoint2: CGPoint(x: 18.37, y: 4.38))
        bezierPath.close()
        return bezierPath
    }
}
