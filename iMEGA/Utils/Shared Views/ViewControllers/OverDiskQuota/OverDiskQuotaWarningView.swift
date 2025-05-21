import MEGAAssets
import UIKit

final class OverDiskQuotaWarningView: UIView, NibOwnerLoadable {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var warningImageView: UIImageView!

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView(with: traitCollection)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(with: traitCollection)
    }
    
    // MARK: - Dark Mode

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection != traitCollection {
            setupTraitCollectionAwareView(with: traitCollection)
        }
    }

    // MARK: - Method

    func updateTitle(with text: NSAttributedString) {
        titleLabel.attributedText = text
    }

    // MARK: - Setup View
    
    private func setupView(with trait: UITraitCollection) {
        translatesAutoresizingMaskIntoConstraints = false
        loadNibContent()
        setupTraitCollectionAwareView(with: trait)
        warningImageView.image = MEGAAssets.UIImage.image(named: "warning")
    }

    private func setupTraitCollectionAwareView(with trait: UITraitCollection) {
        trait.backgroundStyler(of: .primary)(self)
        setupContainerView(containerView, with: traitCollection)
        setupTitleLabel(titleLabel, with: traitCollection)
    }

    private func setupContainerView(_ containerView: UIView, with trait: UITraitCollection) {
        let customeViewStyle = trait.styler(of: MEGACustomViewStyle.warning)
        customeViewStyle(containerView)
    }

    private func setupTitleLabel(_ titleLabel: UILabel, with trait: UITraitCollection) {
        let style = trait.styler(of: .multiline)
        style(titleLabel)
    }
}
