import UIKit

final class OverDisckQuotaWarningView: UIView, NibOwnerLoadable {

    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var detailLabel: UILabel!
    
    @IBOutlet private var containerView: UIView!

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Dark Mode

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), previousTraitCollection != traitCollection {
            setupTraitCollectionAwareView(with: traitCollection)
        }
    }

    // MARK: - Method

    func updateTitle(with text: NSAttributedString) {
        titleLabel.attributedText = text
    }

    // MARK: - Setup View
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        loadNibContent()
        setupTitleLabel(titleLabel, with: traitCollection)
        setupTraitCollectionAwareView(with: traitCollection)
    }

    private func setupTraitCollectionAwareView(with trait: UITraitCollection) {
        setupContainerView(containerView, with: traitCollection)
        setupDetailLabel(detailLabel, with: traitCollection)
    }

    private func setupContainerView(_ containerView: UIView, with trait: UITraitCollection) {
        let customeViewStyle = trait.styler(of: MEGACustomViewStyle.warning)
        customeViewStyle(containerView)
    }

    private func setupDetailLabel(_ detailLabel: UILabel, with trait: UITraitCollection) {
        let style = trait.styler(of: .note2)
        style(detailLabel)
        detailLabel.text = AMLocalizedString("After that, your data is subject to deletion.",
                                             "Warning message to tell user your data is about to be deleted.")
    }

    private func setupTitleLabel(_ titleLabel: UILabel, with trait: UITraitCollection) {
        let style = trait.styler(of: .note1)
        style(titleLabel)
    }
}
