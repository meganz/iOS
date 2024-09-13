import MEGADesignToken
import UIKit

final class PhotoSelectedMarkerView: SingleTapView {
    
    private let outerCircleInsetValue: CGFloat = 4
    private let innerCircleInsetValue: CGFloat = 5
    private let labelInset: CGFloat = 2

    // Outer circle ring
    private lazy var outerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: outerCircleInsetValue)
        layer.strokeColor = UIColor.whiteFFFFFF.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.65

        return layer
    }()
    
    // Inner filled circle
    private lazy var innerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        createPath(circleLayer: layer, insetValue: innerCircleInsetValue)

        layer.fillColor = TokenColors.Support.success.cgColor

        return layer
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.whiteFFFFFF
        label.baselineAdjustment = .alignCenters
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: .photoPickerCheckmark)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var selected: Bool = false {
        didSet {
            innerCircle.isHidden = !selected
            imageView.isHidden = !selected
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let hasDifferentColorAppearance = traitCollection.hasDifferentColorAppearance(
            comparedTo: previousTraitCollection
        )

        if hasDifferentColorAppearance {
            innerCircle.fillColor = TokenColors.Support.success.cgColor
        }
    }

    // MARK: - Private methods.
    
    private func configureLayers() {
        layer.addSublayer(outerCircle)
        layer.addSublayer(innerCircle)
        addSubview(imageView)
        
        setupImageViewConstraints()
    }
    
    private func createPath(circleLayer: CAShapeLayer, insetValue: CGFloat) {
        circleLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: insetValue,
                                                               dy: insetValue)).cgPath
    }

    private func setupImageViewConstraints() {
        NSLayoutConstraint.activate(
            [
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        )
    }
}
