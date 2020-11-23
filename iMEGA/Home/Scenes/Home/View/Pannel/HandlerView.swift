import UIKit

final class HandlerView: UIView {

    private var roundCornerShadowConfig: RoundCornerShadowConfiguration?

    private var styler: Reader<UIView, CALayer>?

    private var shadowCornerLayer: CALayer?

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

        let config = RoundCornerShadowConfiguration(
            backgroundColor: backgroundColor,
            corner: .init(
                corners: [.topLeft, .topRight],
                radius: 10
            ),
            shadow: .init(
                radius: 2,
                opacity: 0.2,
                offset: .init(width: 0, height: 0),
                color: shadowColor
            )
        )
        styler = config.dropTopCornerShadowStyler()
    }

    private func themeColor(of trait: UITraitCollection) -> (UIColor, UIColor) {
        if #available(iOS 12.0, *) {
            switch trait.userInterfaceStyle {
            case .dark: return (.mnz_black1C1C1E(), .white)
            case .light: return (.white, .mnz_black1C1C1E())
            default: return (.white, .mnz_black1C1C1E())
            }
        } else {
            return (.white, .mnz_black1C1C1E())
        }
    }
        // MARK: - UIView overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowCornerLayer?.removeFromSuperlayer()
        shadowCornerLayer = styler?.runReader(self)
    }
}

// MARK: - TraitEnviromentAware

extension HandlerView: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupView(with: currentTrait)
    }
}
