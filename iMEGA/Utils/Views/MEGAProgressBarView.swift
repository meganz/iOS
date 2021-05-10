import Foundation

@IBDesignable
final class MEGAProgressBarView: UIView {
    private let progressLayer = CALayer()
    private let bgMaskLayer = CAShapeLayer()
    private var progress: CGFloat = 0.0 {
        didSet { setNeedsDisplay() }
    }
    private var animated: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSublayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSublayers()
    }
    
    func setProgress(progress: CGFloat, animated: Bool) {
        self.animated = animated
        self.progress = progress
    }

    private func configureSublayers() {
        progressLayer.backgroundColor = UIColor.mnz_green00A886().cgColor
        layer.addSublayer(progressLayer)
    }

    override func draw(_ rect: CGRect) {
        bgMaskLayer.path = UIBezierPath(rect: rect).cgPath
        layer.mask = bgMaskLayer
        
        if animated {
            progressLayer.frame = CGRect(origin: .zero, size: CGSize(width: frame.width * progress, height: frame.height))
        } else {
            CATransaction.disableAnimations {
                self.progressLayer.frame = CGRect(origin: .zero, size: CGSize(width: self.frame.width * progress, height: self.frame.height))
            }
        }
    }
}

extension CATransaction {
    static func disableAnimations(_ completion: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        completion()
        CATransaction.commit()
    }
}
