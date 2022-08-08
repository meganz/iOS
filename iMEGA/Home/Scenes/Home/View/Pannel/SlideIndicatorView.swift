import UIKit
import MEGAUIKit

final class SlideIndicatorView: UIView {

    private enum Constant {
        static let indicatorWidth: CGFloat = 40
        static let indicatorHeight: CGFloat = 5
    }

    private var indicatorView: UIView!

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
        addSlideIndicatorView(with: trait, to: self)
    }

    private func addSlideIndicatorView(with trait: UITraitCollection, to indicatorParentView: UIView) {
        let indicatorView = UIView(frame: .zero)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        self.indicatorView = indicatorView

        indicatorParentView.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.widthAnchor.constraint(equalToConstant: Constant.indicatorWidth),
            indicatorView.heightAnchor.constraint(equalToConstant: Constant.indicatorHeight),
            indicatorView.centerXAnchor.constraint(equalTo: indicatorParentView.centerXAnchor, constant: 0),
            indicatorView.centerYAnchor.constraint(equalTo: indicatorParentView.centerYAnchor, constant: 0),
        ])

        setupAppearance(with: trait)
    }

    private func setupAppearance(with trait: UITraitCollection) {
        trait.theme.customViewStyleFactory.styler(of: .slideIndicatorContainerView)(self)
        trait.theme.customViewStyleFactory.styler(of: .slideIndicator)(indicatorView)
    }
}

// MARK: - TraitEnviromentAware

extension SlideIndicatorView: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupAppearance(with: currentTrait)
    }

    func contentSizeCategoryDidChange(to contentSizeCategory: UIContentSizeCategory) {}
}
