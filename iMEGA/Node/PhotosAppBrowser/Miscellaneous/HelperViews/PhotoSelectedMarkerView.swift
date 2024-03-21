import MEGADesignToken
import UIKit

final class PhotoSelectedMarkerView: SingleTapView {
    
    private let outerCircleInsetValue: CGFloat = 4
    private let innerCircleInsetValue: CGFloat = 5
    private let labelInset: CGFloat = 2
    private let labelInsetFactor: CGFloat = 0.28

    // Outer circle ring
    private lazy var outerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: outerCircleInsetValue)

        if UIColor.isDesignTokenEnabled() {
            layer.strokeColor = designTokenStrokeColor
            layer.fillColor = designTokenFillColor
        } else {
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = UIColor.whiteFFFFFF.cgColor
            // The design token version of the checkmark does not contain a shadow
            layer.shadowColor = UIColor.black000000.cgColor
            layer.lineWidth = 1.65
            layer.shadowRadius = 1
            layer.shadowOpacity = 0.3
            layer.shadowOffset = CGSize(width: -2, height: 2)
        }

        return layer
    }()
    
    // Inner filled circle
    private lazy var innerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: innerCircleInsetValue)

        if UIColor.isDesignTokenEnabled() {
            layer.fillColor = TokenColors.Components.selectionControl.cgColor
        } else {
            layer.fillColor = UIColor.green4AA588.cgColor
        }

        return layer
    }()
    
    // Center label
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center

        if UIColor.isDesignTokenEnabled() {
            label.textColor = TokenColors.Icon.inverseAccent
        } else {
            label.textColor = UIColor.whiteFFFFFF
        }

        label.baselineAdjustment = .alignCenters
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    private var designTokenStrokeColor: CGColor? {
        selected ? nil : TokenColors.Border.strong.cgColor
    }

    private var designTokenFillColor: CGColor {
        selected ? TokenColors.Components.selectionControl.cgColor : UIColor.clear.cgColor
    }

    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var selected: Bool = false {
        didSet {
            innerCircle.isHidden = !selected
            label.isHidden = !selected
            if UIColor.isDesignTokenEnabled() {
                outerCircle.fillColor = designTokenFillColor
                outerCircle.strokeColor = designTokenStrokeColor
            }
        }
    }
    
    // MARK: - Initializers.
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
    }
    
    // MARK: - Overriden method.
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        createPath(circleLayer: outerCircle, insetValue: outerCircleInsetValue)
        createPath(circleLayer: innerCircle, insetValue: innerCircleInsetValue)
        label.frame = bounds.insetBy(dx: labelInset + innerCircleInsetValue,
                                     dy: labelInset + innerCircleInsetValue)
    }
    
    // MARK: - Private methods.
    
    private func configureLayers() {
        layer.addSublayer(outerCircle)
        layer.addSublayer(innerCircle)
        addSubview(label)
    }
    
    private func createPath(circleLayer: CAShapeLayer, insetValue: CGFloat) {
        circleLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: insetValue,
                                                               dy: insetValue)).cgPath
    }
}
