import UIKit

@IBDesignable
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

    func updateTimeLeftForTitle(withText text: String) {
        let warningTitleMessage = AMLocalizedString("<body>You have <warn>%@</warn> left to upgrade.</body>",
                                                    "Warning message to tell user time left to upgrade subscription.")
        let formattedTitleMessage = String(format: warningTitleMessage, text)
        let styleMarks: StyleMarks = ["warn": .warning,
                                      "body": .emphasized]
        titleLabel.attributedText = formattedTitleMessage.attributedString(with: styleMarks)
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
