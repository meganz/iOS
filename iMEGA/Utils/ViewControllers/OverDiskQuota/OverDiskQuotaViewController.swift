import UIKit

final class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet private var contentScrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagaphLabel: UILabel!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!
    @IBOutlet weak var warningView: OverDisckQuotaWarningView!

    @objc var dismissAction: (() -> Void)?

    private var warning: OverDiskQuotaWarning?

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    private lazy var byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useGB
        return byteCountFormatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
        setupTitleLabel(titleLabel)
        setupMessageLabel(warningParagaphLabel, overDiskInformation: warning)
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
        warningView.updateTimeLeftForTitle(withText: "33 days")
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
        title = AMLocalizedString("Over Disk Quota Screen Title", "Storage Full")
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .headline, color: Color.Text.lightPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(for: contentScrollView)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        titleLabel.text = AMLocalizedString("Over Disk Quota Title", "Your Data is at Risk!")
        LabelStyle.headline.style(titleLabel)
    }

    private func setupMessageLabel(_ descriptionLabel: UILabel, overDiskInformation: OverDiskQuotaWarning?) {
        guard let infor = overDiskInformation else {
            descriptionLabel.text = nil
            return
        }

        let message = AMLocalizedString("Over Disk Quota Message", "We have contacted you by email to bk@mega.nz on March 1 2020,  March 30 2020, April 30 2020 and May 15 2020, but you still have 45302 files taking up 234.54 GB in your MEGA account, which requires you to upgrade to PRO Lite. ")
        let formattedMessage = String(format: message,
                                      infor.email,
                                      infor.formattedWarningDates(with: dateFormatter),
                                      infor.numberOfFiles(with: numberFormatter),
                                      infor.takingUpStorage(with: byteCountFormatter),
                                      infor.plan)
        descriptionLabel.text = formattedMessage
    }

    private func setupUpgradeButton(_ button: UIButton) {
        ButtonStyle.active.style(button)
        button.setTitle(AMLocalizedString("Over Disk Quota Upgrade Button Text", "Upgrade"), for: .normal)
    }

    private func setupDismissButton(_ button: UIButton) {
        ButtonStyle.inactive.style(button)
        button.setTitle(AMLocalizedString("Over Disk Quota Dismiss Button Text", "Dismiss"), for: .normal)
    }

}

// MARK: - Attributed Warning Text

fileprivate extension OverDiskQuotaViewController.OverDiskQuotaWarning {

    func formattedWarningDates(with formatter: DateFormatter) -> String {
        return warningDates.reduce("") { (result, date) in
            result + (formatter.string(from: date) + ", ")
        }
    }

    func numberOfFiles(with formatter: NumberFormatter) -> String {
        return formatter.string(from: NSNumber(value: numberOfFilesOnCloud)) ?? "\(numberOfFilesOnCloud)"
    }

    func takingUpStorage(with formatter: ByteCountFormatter) -> String {
        return formatter.string(fromByteCount: cloudStorage.int64Value)
    }

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
