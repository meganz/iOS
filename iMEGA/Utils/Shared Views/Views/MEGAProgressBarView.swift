import Foundation
import MEGADesignToken
import SwiftUI

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
        registerForTraitChanges()
        configureSublayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForTraitChanges()
        configureSublayers()
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { [weak self] (progressBarView: MEGAProgressBarView, previousTraitCollection: UITraitCollection) in
            if progressBarView.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
                self?.configureSublayers()
            }
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            configureSublayers()
        }
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
    
    func makeUIView(context: Context) -> MEGAProgressBarView {
        let progressBarView = MEGAProgressBarView()
        progressBarView.setProgress(progress: progress, animated: animated)
        return progressBarView
    }
    
    func updateUIView(_ uiView: MEGAProgressBarView, context: Context) {
        uiView.setProgress(progress: progress, animated: animated)
    }
}

#Preview {
    MEGAProgressBarViewRepresenter(progress: 0.5, animated: true)
}
