import UIKit

@IBDesignable
final class OverDisckQuotaWarningView: UIView, NibOwnerLoadable {

    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var detailLabel: UILabel!
    
    @IBOutlet private var containerView: UIView!

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
        let warningTitleMessage = AMLocalizedString("Over Disk Quota Warning Title", "You have %@ left to upgrade.")
        let formattedTitleMessage = String(format: warningTitleMessage, text)
        titleLabel.text = formattedTitleMessage
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
        detailLabel.text = AMLocalizedString("Over Disk Quota Warning Message", "After that, your data is subject to deletion.")
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        LabelStyle.noteMain.style(titleLabel)
        titleLabel.text = nil
    }
}
