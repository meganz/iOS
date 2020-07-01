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
        if #available(iOS 13, *) {
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
        setupTitleLabel(titleLabel)
        setupTraitCollectionAwareView(with: traitCollection)
    }

    private func setupTraitCollectionAwareView(with trait: UITraitCollection) {
        setupContainerView(containerView)
        setupDetailLabel(detailLabel)
    }

    private func setupContainerView(_ containerView: UIView) {
        let customeViewStyle = createCustomViewStyleFactory(from: createColorFactory(from: traitCollection.theme))
            .viewStyle(of: .warning)
        customeViewStyle(containerView)
    }

    private func setupDetailLabel(_ detailLabel: UILabel) {
        let style = createLabelStyleFactory(from: traitCollection.theme).createStyler(of: .noteSub)
        style(detailLabel)
        detailLabel.text = AMLocalizedString("After that, your data is subject to deletion.",
                                             "Warning message to tell user your data is about to be deleted.")
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        let style = createLabelStyleFactory(from: traitCollection.theme).createStyler(of: .noteMain)
        style(titleLabel)
    }
}
