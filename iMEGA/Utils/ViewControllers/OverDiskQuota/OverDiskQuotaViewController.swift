import UIKit

final class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet private var contentScrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagaphLabel: UILabel!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!

    @objc var dismissAction: (() -> Void)?

    private var warning: OverDiskQuotaWarning?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
        setupTitleLabel(titleLabel)
        setupWarningDescriptionLabel(warningParagaphLabel, withAttributedString: attributedWarningText(from: warning))
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
    }

    private func attributedWarningText(from warning: OverDiskQuotaWarning?) -> NSAttributedString? {
        guard let warning = warning else { return nil }
        return warning.attibutedWarningText
    }

    // MARK: - Setup MEGA UserData

    @objc func setup(with overDiskQuota: OverDiskQuotaInfomationType) {
        warning = OverDiskQuotaWarning(email: overDiskQuota.email,
                                       deadline: overDiskQuota.deadline,
                                       warningDates: overDiskQuota.warningDates,
                                       numberOfFilesOnCloud: overDiskQuota.numberOfFilesOnCloud,
                                       cloudStorage: overDiskQuota.cloudStorage,
                                       plan: overDiskQuota.availablePlan)
    }

    struct OverDiskQuotaWarning {
        typealias Email = String
        typealias Deadline = Date
        typealias WarningDates = [Date]
        typealias FileCount = UInt
        typealias Storage = NSNumber
        typealias SuggestedMEGAPlan = String

        let email: Email
        let deadline: Deadline
        let warningDates: WarningDates
        let numberOfFilesOnCloud: FileCount
        let cloudStorage: Storage
        let plan: SuggestedMEGAPlan
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
        LabelStyle.headline.style(titleLabel)
    }

    private func setupWarningDescriptionLabel(_ descriptionLabel: UILabel,
                                              withAttributedString attributedString: NSAttributedString?) {
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

// MARK: - Attributed Warning Text

fileprivate extension OverDiskQuotaViewController.OverDiskQuotaWarning {

    private var emailText: SematicText {
        return .leaf([.paragraph, .emphasized], " \(email)")
    }

    private var warningDatesText: SematicText {
        return .leaf([.paragraph, .emphasized], " on ") +
            .leaf([.paragraph, .emphasized], warningDates.reduce("") { (result, date) in
                result + (date.description + ", ")
            })
    }

    private var filesText: SematicText {
        return .leaf([.paragraph], "\(numberOfFilesOnCloud) files ")
    }

    private var takingUpSpaceText: SematicText {
        return .leaf([.paragraph, .emphasized], "taking up \(cloudStorage)")
    }

    private var suggestPlanText: SematicText {
        return .leaf([.paragraph, .emphasized], " " + plan)
    }

    private func text(_ text: String, withStyles styles: [AttributedTextStyle]) -> SematicText {
        return .leaf(styles, text)
    }

    var attibutedWarningText: NSAttributedString {
        let composedText: SematicText = text("We have contacted you by email to", withStyles: [.paragraph])
            + emailText
            + warningDatesText
            + text("but you still have ", withStyles: [.paragraph])
            + filesText
            + takingUpSpaceText
            + text("in your MEGA account, which requires you to upgrade to", withStyles: [.paragraph])
            + suggestPlanText
        return composedText.attributedString
    }
}
