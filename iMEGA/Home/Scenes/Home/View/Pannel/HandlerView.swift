import MEGADesignToken
import MEGAUIKit
import UIKit

final class HandlerView: UIView {
    
    private var roundCornerShadowConfig: RoundCornerShadowConfiguration?
    
    private var styler: Reader<UIView, CALayer>?
    
    private var shadowCornerLayer: CALayer?
    
    private var indicatorView: SlideIndicatorView!
    
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
        let (backgroundColor, shadowColor) = themeColor(of: trait)
        
        let slideIndicatorView = SlideIndicatorView()
        slideIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slideIndicatorView)
        self.indicatorView = slideIndicatorView
        
        NSLayoutConstraint.activate([
            slideIndicatorView.heightAnchor.constraint(equalToConstant: 10),
            centerYAnchor.constraint(equalTo: slideIndicatorView.centerYAnchor),
            leadingAnchor.constraint(equalTo: slideIndicatorView.leadingAnchor),
            trailingAnchor.constraint(equalTo: slideIndicatorView.trailingAnchor)
        ])
        
        let config = RoundCornerShadowConfiguration(
            backgroundColor: backgroundColor,
            corner: .init(
                corners: [.topLeft, .topRight],
                radius: 20
            ),
            shadow: .init(
                radius: 20,
                opacity: 0.2,
                offset: .init(width: 0, height: 0.2),
                color: shadowColor
            )
        )
        styler = config.dropTopCornerShadowStyler()
    }
    
    private func themeColor(of trait: UITraitCollection) -> (UIColor, UIColor) {
        switch trait.userInterfaceStyle {
        case .dark: return (TokenColors.Background.page, UIColor.whiteFFFFFF)
        case .light: return (TokenColors.Background.page, .mnz_black1C1C1E())
        default: return (TokenColors.Background.page, .mnz_black1C1C1E())
        }
    }
    
    // MARK: - UIView overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowCornerLayer?.removeFromSuperlayer()
        shadowCornerLayer = styler?.runReader(self)
        bringSubviewToFront(indicatorView)
    }
}

// MARK: - TraitEnvironmentAware

extension HandlerView: TraitEnvironmentAware {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupView(with: currentTrait)
    }
}
