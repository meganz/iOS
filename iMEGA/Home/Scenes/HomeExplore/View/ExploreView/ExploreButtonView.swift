import UIKit

struct GradientConfiguration: Equatable {
    struct GradientStep: Equatable {
        let color: CGColor
        let startPoint: CGPoint
    }
    
    let steps: [GradientStep]
}

struct GradientBackground {
    
    let backgroundLayer: CAGradientLayer
    
    func configure(with config: GradientConfiguration) {
        guard let start = config.steps.first, let end = config.steps.last, start != end else {
            fatalError("A configuration should have at least 2 points.")
        }
        
        backgroundLayer.colors = config.steps.map(\.color)
        backgroundLayer.startPoint = start.startPoint
        backgroundLayer.endPoint = end.startPoint
    }
}

final class ExploreView: UIButton {
    
    private lazy var gradientBackground = GradientBackground(backgroundLayer: layer as! CAGradientLayer)
    
    var gradientBackgroundConfiguration: GradientConfiguration? {
        didSet {
            setupView(with: traitCollection)
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView(with: traitCollection)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(with: traitCollection)
    }
    
    // MARK: - Privates
    
    private func setupView(with trait: UITraitCollection) {
        if let gradientBackgroundConfig = gradientBackgroundConfiguration {
            gradientBackground.configure(with: gradientBackgroundConfig)
        }
        self.imageView?.contentMode = .scaleAspectFit
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageEdgeInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    // MARK: - UIView overrides
    
    override class var layerClass: AnyClass { CAGradientLayer.self }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8
    }
}
