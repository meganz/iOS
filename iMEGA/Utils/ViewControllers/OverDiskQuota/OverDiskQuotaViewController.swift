import UIKit

final class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet private var contentScrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagaphLabel: UILabel!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
        setupTitleLabel(titleLabel)
        setupWarningDescriptionLabel(warningParagaphLabel)
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
    }

    // MARK: - UI Customize

    private func setupNavigationController(_ navigationController: UINavigationController?) {
        title = AMLocalizedString("Stoage Full")
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .headline, color: Color.Text.lightPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(for: contentScrollView)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        titleLabel.text = AMLocalizedString("Your Data is at Risk!")
        let textStyle = TextStyle(font: .headline, color: .textDarkPrimary)
        textStyle.applied(on: titleLabel)
    }

    private func setupWarningDescriptionLabel(_ descriptionLabel: UILabel) {
        let attributes = AttributedTextStyle.paragraph.style(TextAttributes())
        let warningText = AMLocalizedString("We have contacted you by email to bk@mega.nz on March 1 2020,  March 30 2020, April 30 2020 and May 15 2020, but you still have 45302 files taking up 234.54 GB in your MEGA account, which requires you to upgrade to PRO Lite.")
        let attributedString = NSAttributedString(string: warningText,
                                                  attributes: attributes)
        descriptionLabel.attributedText = attributedString
    }

    private func setupUpgradeButton(_ button: UIButton) {
        ButtonStyle.active.style(button)
        button.setTitle(AMLocalizedString("Upgrade"), for: .normal)

    }

    private func setupDismissButton(_ button: UIButton) {
        ButtonStyle.inactive.style(button)
        button.setTitle(AMLocalizedString("Dismiss"), for: .normal)
    }
}
