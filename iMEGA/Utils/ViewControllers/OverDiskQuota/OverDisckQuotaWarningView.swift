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
    
    // MARK: - Method

    func updateTitle(with text: NSAttributedString) {
        titleLabel.attributedText = text
    }

    // MARK: - Setup View
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        loadNibContent()
        setupContainerView(containerView)
        setupDetailLabel(detailLabel)
        setupTitleLabel(titleLabel)
    }

    private func setupContainerView(_ containerView: UIView) {
        ViewStyle.warning.style(containerView)
    }

    private func setupDetailLabel(_ detailLabel: UILabel) {
        LabelStyle.noteSub.style(detailLabel)
        detailLabel.text = AMLocalizedString("After that, your data is subject to deletion.",
                                             "Warning message to tell user your data is about to be deleted.")
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        LabelStyle.noteMain.style(titleLabel)
        titleLabel.text = nil
    }
}
