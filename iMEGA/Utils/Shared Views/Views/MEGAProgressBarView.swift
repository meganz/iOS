import Foundation
import MEGADesignToken
import SwiftUI

@IBDesignable
final class MEGAProgressBarView: UIView {
    public var progressColor: UIColor = TokenColors.Components.interactive {
        didSet {
            progressLayer.backgroundColor = progressColor.cgColor
        }
    }
    
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
        progressLayer.backgroundColor = TokenColors.Components.interactive.cgColor
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

struct MEGAProgressBarViewRepresenter: UIViewRepresentable {
    let progress: CGFloat
    let animated: Bool
    let progressColor: UIColor
    
    func makeUIView(context: Context) -> MEGAProgressBarView {
        let view = MEGAProgressBarView()
        view.progressColor = progressColor
        view.setProgress(progress: progress, animated: animated)
        return view
    }
    
    func updateUIView(_ uiView: MEGAProgressBarView, context: Context) {
        uiView.progressColor = progressColor
        uiView.setProgress(progress: progress, animated: animated)
    }
}

#Preview {
    MEGAProgressBarViewRepresenter(progress: 0.5, animated: true, progressColor: TokenColors.Components.interactive)
}
