import UIKit

class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var warningParagaphLabel: UILabel!

    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController(self.navigationController)
        setupScrollView(contentScrollView)
        setupTitleLabel(titleLabel)
        setupWarningDescriptionLabel(warningParagaphLabel)
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
    }

    // MARK: - UI Customize

    private func setupNavigationController(_ navigationController: UINavigationController?) {
        title = "Stoage Full"
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .headline, color: Color.Text.lightPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(ofScrollView: contentScrollView)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        let textStyle = TextStyle(font: .headline, color: .textDarkPrimary)
        textStyle.applied(on: titleLabel)
    }

    private func setupWarningDescriptionLabel(_ descriptionLabel: UILabel) {
        let textStyle = TextStyle(font: .subhead, color: .textDarkPrimary)
        var attributes = textStyle.applied(on: [:])

        let paragraphStyle = ParagraphStyle(lineSpacing: 8, alignment: .center)
        attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle.applied(on: NSMutableParagraphStyle())

        let attributedString = NSAttributedString(string: "We have contacted you by email to bk@mega.nz on March 1 2020,  March 30 2020, April 30 2020 and May 15 2020, but you still have 45302 files taking up 234.54 GB in your MEGA account, which requires you to upgrade to PRO Lite.",
                                                  attributes: attributes)
        descriptionLabel.attributedText = attributedString
    }

    private func setupUpgradeButton(_ button: UIButton) {
        let textStyle
            = ButtonStatedStyle<TextStyle>(stated: [
                .normal: TextStyle(font: .headline, color: .textLightPrimary),
                .disabled: TextStyle(font: .headline, color: .backgroundDisabledPrimary),
                .highlighted: TextStyle(font: .headline, color: .backgroundDisabledPrimary)])
        textStyle.applied(on: button)

        let backgroundStyle = ButtonStatedStyle<BackgroundStyle>(stated: [
            .normal: BackgroundStyle(backgroundColor: .backgroundEnabledPrimary),
            .highlighted: BackgroundStyle(backgroundColor: .backgroundEnabledPrimary),
        ])
        backgroundStyle.applied(on: button)


        let decorationStyle = DecorationStyle(corner: .init(radius: 8))
        decorationStyle.applied(on: button)

        button.setTitle("Upgrade", for: .normal)
    }

    private func setupDismissButton(_ button: UIButton) {
        let textStyle
            = ButtonStatedStyle<TextStyle>(stated: [
                .normal: TextStyle(font: .headline, color: .textGreenPrimary),
                .highlighted: TextStyle(font: .headline, color: .textGreenSecondary)])
        textStyle.applied(on: button)

        let backgroundStyle = ButtonStatedStyle<BackgroundStyle>(stated: [
            .normal: BackgroundStyle(backgroundColor: .backgroundDefaultLight),
            .highlighted: BackgroundStyle(backgroundColor: .backgroundDefaultLight),
        ])
        backgroundStyle.applied(on: button)


        let decorationStyle = DecorationStyle(shadow: ShadowStyle(shadowOffset: .init(width: 0, height: 3),
                                                                  shadowColor: .shadowPrimary),
                                              border: .init(width: 1, color: .shadowPrimary),
                                              corner: .init(radius: 8))
        decorationStyle.applied(on: button)
    }
}
