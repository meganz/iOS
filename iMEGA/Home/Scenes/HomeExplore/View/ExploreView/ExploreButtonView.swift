import MEGADesignToken
import UIKit

final class ExplorerView: UIView {
    
    private let radius: CGFloat = 6.0
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var iconBackgroundImageView: UIImageView!
    @IBOutlet weak var iconForegroundImageView: UIImageView!
    
    var configuration: ExplorerCardConfiguration? {
        didSet {
            guard let configuration = configuration else { return }
            label.text = configuration.title
            label.isAccessibilityElement = false
            button.accessibilityLabel = configuration.title
            iconForegroundImageView.image = configuration.iconForegroundImage
            iconBackgroundImageView?.image = configuration.iconBackgroundImage
            borderGradientLayer.colors = configuration.borderGradientColors.map({$0.cgColor})
            backgroundColorGradientLayer.colors = configuration.backgroundGradientColors.map({$0.cgColor})
            foregroundGradientLayer.colors = configuration.foregroundGradientColors.map({$0.cgColor})
            foregroundGradientLayer.opacity = configuration.foregroundGradientOpacity
        }
    }

    lazy var borderGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: frame.size)
        gradientLayer.mask = borderShapeLayer
        return gradientLayer
    }()
    
    lazy var backgroundColorGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: frame.size)
        return gradientLayer
    }()
    
    lazy var foregroundGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: frame.size)
        gradientLayer.mask = borderShapeLayer
        return gradientLayer
    }()
    
    lazy var borderShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 4.0
        shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 6.0).cgPath
        shapeLayer.strokeColor = TokenColors.Background.page.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        return shapeLayer
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        guard let bottomSubview = subviews.first else {
            return
        }
        
        layer.insertSublayer(backgroundColorGradientLayer, below: bottomSubview.layer)
        layer.insertSublayer(foregroundGradientLayer, below: bottomSubview.layer)
        layer.insertSublayer(borderGradientLayer, below: bottomSubview.layer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = radius
        borderShapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        borderGradientLayer.frame =  CGRect(origin: .zero, size: frame.size)
        foregroundGradientLayer.frame = CGRect(origin: .zero, size: frame.size)
        backgroundColorGradientLayer.frame = CGRect(origin: .zero, size: frame.size)
    }
    
}
