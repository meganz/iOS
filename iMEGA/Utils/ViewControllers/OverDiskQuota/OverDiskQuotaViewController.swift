import UIKit

final class OverDiskQuotaViewController: UIViewController {

    // MARK: - Views
    
    @IBOutlet private var contentScrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagaphLabel: UILabel!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!

    @IBOutlet weak var warningView: OverDisckQuotaWarningView!

    // MARK: - In / Out properties

    @objc var dismissAction: (() -> Void)?

    private var overDiskQuota: OverDiskQuotaInternal!

    // MARK: - Formatters

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d yyyy"
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
        byteCountFormatter.countStyle = .binary
        return byteCountFormatter
    }()

    // MARK: - ViewController Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleLabel(titleLabel)
        setupMessageLabel(warningParagaphLabel, overDiskInformation: overDiskQuota)
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
        setupWarningView(warningView, withDeadline: overDiskQuota.deadline)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
    }

    // MARK: - Setup MEGA UserData

    @objc func setup(with overDiskQuotaData: OverDiskQuotaInfomationProtocol) {
        overDiskQuota = OverDiskQuotaInternal(email: overDiskQuotaData.email,
                                              deadline: overDiskQuotaData.deadline,
                                              warningDates: overDiskQuotaData.warningDates,
                                              numberOfFilesOnCloud: overDiskQuotaData.numberOfFilesOnCloud,
                                              cloudStorage: Measurement(value: overDiskQuotaData.cloudStorage.doubleValue,
                                                                        unit: .bytes),
                                              plan: overDiskQuotaData.suggestedPlanName)
    }

    // MARK: - UI Customize

    private func setupNavigationController(_ navigationController: UINavigationController?) {
        title = AMLocalizedString("Storage Full", "Screen title")
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .headline, color: Color.Text.lightPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(for: contentScrollView)
    }

    private func setupWarningView(_ warningView: OverDisckQuotaWarningView, withDeadline deadline: Date) {
        let daysLeft = daysDistance(from: Date(), endDate: deadline)
        let daysLeftLocalized = AMLocalizedString("%d days", "Count of days")
        warningView.updateTimeLeftForTitle(withText: String(format: daysLeftLocalized, daysLeft))
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        titleLabel.text = AMLocalizedString("Your Data is at Risk!", "Warning title message tells user data in danger.")
        LabelStyle.headline.style(titleLabel)
    }

    private func setupMessageLabel(_ descriptionLabel: UILabel, overDiskInformation: OverDiskQuotaInternal?) {
        guard let infor = overDiskInformation else { descriptionLabel.text = nil; return }
        let message = AMLocalizedString("<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to %@.</paragraph>",
                                        "A paragraph of warning message tells user upgrade to selected [minimum subscription plan] before [deadline] due to [cloud space used] and [warning dates]")

        let formattedMessage = String(format: message,
                                      infor.email,
                                      infor.formattedWarningDates(with: dateFormatter),
                                      infor.numberOfFiles(with: numberFormatter),
                                      infor.takingUpStorage(with: byteCountFormatter),
                                      infor.suggestedPlan)

        let styleMarks: StyleMarks = ["paragraph": .paragraph, "b": .emphasized]
        descriptionLabel.attributedText = formattedMessage.attributedString(with: styleMarks)
    }

    private func setupUpgradeButton(_ button: UIButton) {
        ButtonStyle.active.style(button)
        button.setTitle(AMLocalizedString("upgrade", "Upgrade"), for: .normal)
        button.addTarget(self, action: .didTapUpgradeButton, for: .touchUpInside)
    }

    private func setupDismissButton(_ button: UIButton) {
        ButtonStyle.inactive.style(button)
        button.setTitle(AMLocalizedString("dismiss", "Dismiss"), for: .normal)
        button.addTarget(self, action: .didTapDismissButton, for: .touchUpInside)
    }

    // MARK: - Button Actions

    @objc fileprivate func didTapUpgradeButton(button: UIButton) {
        let upgradeViewController = UIStoryboard(name: "MyAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "UpgradeID")
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.pushViewController(upgradeViewController, animated: true)
    }

    @objc fileprivate func didTapDismissButton(button: UIButton) {
        dismissAction?()
    }

    // MARK: - Days left

    private func daysDistance(from startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: startDate, to: endDate).day!
    }

    // MARK: - Internal Data Structure

    fileprivate struct OverDiskQuotaInternal {
        typealias Email = String
        typealias Deadline = Date
        typealias WarningDates = [Date]
        typealias FileCount = UInt
        typealias Storage = Measurement<UnitDataStorage>
        typealias SuggestedMEGAPlan = String

        let email: Email
        let deadline: Deadline
        let warningDates: WarningDates
        let numberOfFilesOnCloud: FileCount
        let cloudStorage: Storage
        let plan: SuggestedMEGAPlan?
    }
}

// MARK: - Attributed Warning Text

fileprivate extension OverDiskQuotaViewController.OverDiskQuotaInternal {

    func formattedWarningDates(with formatter: DateFormatter) -> String {
        return warningDates.reduce("") { (result, date) in
            result + (formatter.string(from: date) + ", ")
        }
    }

    func numberOfFiles(with formatter: NumberFormatter) -> String {
        return formatter.string(from: NSNumber(value: numberOfFilesOnCloud)) ?? "\(numberOfFilesOnCloud)"
    }

    func takingUpStorage(with formatter: ByteCountFormatter) -> String {
        let cloudSpaceUsedInBytes = cloudStorage.converted(to: .bytes).valueNumber
        return formatter.string(fromByteCount: cloudSpaceUsedInBytes.int64Value)
    }

    var suggestedPlan: SuggestedMEGAPlan {
        if let plan = plan {
            return String(format: AMLocalizedString("upgrade to <b>%@</b>", "Asks user to upgrade to plan"), plan)
        }

        return AMLocalizedString("contact support for a custom plan",
                                 "Asks the user to request a custom Pro plan from customer support because their storage usage is more than the regular plans.")
    }
}

// MARK: - Binding Button Action's

private extension Selector {
    static let didTapUpgradeButton = #selector(OverDiskQuotaViewController.didTapUpgradeButton(button:))
    static let didTapDismissButton = #selector(OverDiskQuotaViewController.didTapDismissButton(button:))
}
