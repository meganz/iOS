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
    
    // MARK: - Setup View
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        loadNibContent()
        setupContainerView(containerView)
        setupDetailLabel(detailLabel)
        setupTitleLabel(titleLabel)
    }

    private func setupContainerView(_ containerView: UIView) {
        containerView.border(withColor: Color.Border.warning.uiColor)
            .border(withWidth: 1)
            .border(withCornerRadius: 8)
        containerView.backgroundColor = Color.Background.warning.uiColor

    }

    private func setupDetailLabel(_ detailLabel: UILabel) {
        LabelStyle.noteSub.style(detailLabel)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        LabelStyle.noteMain.style(titleLabel)
    }
}
