
import UIKit

class PhotoSelectedMarkerView: UIView {
    
    private let outerCircleInsetValue: CGFloat = 4
    private let innerCircleInsetValue: CGFloat = 5
    private let labelInsetFactor: CGFloat = 0.28

    // Outer circle ring
    private lazy var outerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: outerCircleInsetValue)
        
        layer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        layer.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        layer.lineWidth = 2
        
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.3
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        layer.shadowOffset = CGSize(width: -2, height: 2)
        
        return layer
    }()
    
    // Inner filled circle
    private lazy var innerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: innerCircleInsetValue)
        
        layer.fillColor = #colorLiteral(red: 0.2901960784, green: 0.6470588235, blue: 0.5333333333, alpha: 1)

        return layer
    }()
    
    // Center label
    private lazy var label: UILabel = {
       let label = UILabel(frame: bounds)
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    var text: String? {
        didSet {
            label.text = text
            label.sizeToFit()
        }
    }
    
    var selected: Bool = false {
        didSet {
            innerCircle.isHidden = !selected
            label.isHidden = !selected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
    }
    
    private func configureLayers() {
        layer.addSublayer(outerCircle)
        layer.addSublayer(innerCircle)
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        createPath(circleLayer: outerCircle, insetValue: outerCircleInsetValue)
        createPath(circleLayer: innerCircle, insetValue: innerCircleInsetValue)
        label.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    
    private func createPath(circleLayer: CAShapeLayer, insetValue: CGFloat) {
        circleLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: insetValue,
                                                               dy: insetValue)).cgPath

    }
}
