import UIKit

@IBDesignable
final class OverDisckQuotaWarningView: UIView, NibOwnerLoadable {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet var containerView: UIView!

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
    }

    private func setupContainerView(_ containerView: UIView) {
        containerView.border(withColor: Color.Border.warning.uiColor)
            .border(withWidth: 1)
            .border(withCornerRadius: 8)

        containerView.backgroundColor = Color.Background.warning.uiColor
    }

    private func setupDetailLabel(_ detailLabel: UILabel) {
        let detailTextStyle = TextStyle(font: Font.caption, color: Color.Text.darkPrimary)
        detailTextStyle.applied(on: detailLabel)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        let titleTextStyle = TextStyle(font: Font.caption, color: Color.Text.darkPrimary)
        titleTextStyle.applied(on: titleLabel)
    }
}
