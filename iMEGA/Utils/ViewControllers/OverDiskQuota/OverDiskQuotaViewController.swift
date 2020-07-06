import UIKit

final class OverDiskQuotaViewController: UIViewController {

    final class OverDiskQuotaAdviceGenerator {

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

        // MARK: - Properties

        private let overDiskQuotaData: OverDiskQuotaInternal

        // MARK: - Lifecycles

        fileprivate init(_ overDiskQuotaData: OverDiskQuotaInternal) {
            self.overDiskQuotaData = overDiskQuotaData
        }

        // MARK: - Exposed Methods

        var titleMessage: String {
            AMLocalizedString("Your Data is at Risk!", "Warning title message tells user data in danger.")
        }

        func overDiskQuotaMessage(with traitCollection: UITraitCollection) -> NSAttributedString {
            let message = AMLocalizedString("<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to %@.</paragraph>",
                                                  "A paragraph of warning message tells user upgrade to selected [minimum subscription plan] before [deadline] due to [cloud space used] and [warning dates]")

            let formattedMessage = String(format: message,
                                        overDiskQuotaData.email,
                                        overDiskQuotaData.formattedWarningDates(with: dateFormatter),
                                        overDiskQuotaData.numberOfFiles(with: numberFormatter),
                                        overDiskQuotaData.takingUpStorage(with: byteCountFormatter),
                                        suggestedPlan)

            let styleMarks: StyleMarks = ["paragraph": .paragraph, "b": .emphasized]
            return formattedMessage.attributedString(
                with: styleMarks,
                attributedTextStyleFactory: createAttributedTextStyleFactory(from: traitCollection.theme))
        }

        func warningActionTitle(with traitCollection: UITraitCollection) -> NSAttributedString {
            let daysLeft = daysDistance(from: Date(), endDate: overDiskQuotaData.deadline)
            let daysLeftLocalized = String(format: AMLocalizedString("%d days", "Count of days"), daysLeft)
            let warningTitleMessage = AMLocalizedString("<body>You have <warn>%@</warn> left to upgrade.</body>",
                                                        "Warning message to tell user time left to upgrade subscription.")
            var formattedTitleMessage = String(format: warningTitleMessage, daysLeftLocalized)

            if daysLeft < 1 {
                formattedTitleMessage = AMLocalizedString("<body><warn>You must act immediately to save your data.</warn><body>",
                                                          "<body><warn>You must act immediately to save your data.</warn><body>")
            }
            let styleMarks: StyleMarks = ["warn": .warning, "body": .emphasized]
            return formattedTitleMessage.attributedString(
                with: styleMarks,
                attributedTextStyleFactory: createAttributedTextStyleFactory(from: traitCollection.theme))
        }

        // MARK: - Privates

        private func daysDistance(from startDate: Date, endDate: Date) -> Int {
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: startDate, to: endDate).day!
        }

        private var suggestedPlan: String {
            if let plan = overDiskQuotaData.plan {
                return String(format: AMLocalizedString("upgrade to <b>%@</b>", "Asks user to upgrade to plan"), plan)
            }

            return AMLocalizedString("contact support for a custom plan",
                                     "Asks the user to request a custom Pro plan from customer support because their storage usage is more than the regular plans.")
        }
    }

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

    private var overDiskQuotaAdvicer: OverDiskQuotaAdviceGenerator!

    // MARK: - ViewController Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTraitCollectionAwareView(with: traitCollection)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
    }

    // MARK: - Support Trait

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *) {
            if previousTraitCollection != traitCollection {
                setupTraitCollectionAwareView(with: traitCollection)
            }
        }
    }

    private func setupTraitCollectionAwareView(with traitCollection: UITraitCollection) {
        setupTitleLabel(titleLabel, with: traitCollection)
        setupMessageLabel(warningParagaphLabel,
                          withMessage: overDiskQuotaAdvicer.overDiskQuotaMessage(with: traitCollection))
        setupWarningView(warningView,
                         with: overDiskQuotaAdvicer.warningActionTitle(with: traitCollection))
        setupUpgradeButton(upgradeButton, with: traitCollection)
        setupDismissButton(dismissButton, with: traitCollection)
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
        overDiskQuotaAdvicer = OverDiskQuotaAdviceGenerator(overDiskQuota)
    }

    // MARK: - UI Customize

    private func setupNavigationController(_ navigationController: UINavigationController?) {
        title = AMLocalizedString("Storage Full", "Screen title")
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .headline, color: Color.Text.darkPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(for: contentScrollView)
    }

    private func setupWarningView(_ warningView: OverDisckQuotaWarningView, with text: NSAttributedString) {
        warningView.updateTitle(with: text)
    }

    private func setupTitleLabel(_ titleLabel: UILabel, with trait: UITraitCollection) {
        titleLabel.text = AMLocalizedString("Your Data is at Risk!", "Warning title message tells user data in danger.")
        let style = traitCollection.styler(of: .headline)
        style(titleLabel)
    }

    private func setupMessageLabel(_ descriptionLabel: UILabel, withMessage message: NSAttributedString) {
        descriptionLabel.attributedText = message
    }

    private func setupUpgradeButton(_ button: UIButton, with trait: UITraitCollection) {
        let style = trait.styler(of: .primary)
        style(button)
        button.setTitle(AMLocalizedString("upgrade", "Upgrade"), for: .normal)
        button.addTarget(self, action: .didTapUpgradeButton, for: .touchUpInside)
    }

    private func setupDismissButton(_ button: UIButton, with trait: UITraitCollection) {
        let style = trait.styler(of: .secondary)
        style(button)
        button.setTitle(AMLocalizedString("dismiss", "Dismiss"), for: .normal)
        button.addTarget(self, action: .didTapDismissButton, for: .touchUpInside)
    }

    // MARK: - Button Actions

    @objc fileprivate func didTapUpgradeButton(button: UIButton) {
        let upgradeViewController = UIStoryboard(name: "UpgradeAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "UpgradeTableViewControllerID")
        navigationController?.pushViewController(upgradeViewController, animated: true)
    }

    @objc fileprivate func didTapDismissButton(button: UIButton) {
        dismissAction?()
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
        warningDates.reduce("") { (result, date) in
            result + (formatter.string(from: date) + ", ")
        }
    }

    func numberOfFiles(with formatter: NumberFormatter) -> String {
        formatter.string(from: NSNumber(value: numberOfFilesOnCloud)) ?? "\(numberOfFilesOnCloud)"
    }

    func takingUpStorage(with formatter: ByteCountFormatter) -> String {
        let cloudSpaceUsedInBytes = cloudStorage.converted(to: .bytes).valueNumber
        return formatter.string(fromByteCount: cloudSpaceUsedInBytes.int64Value)
    }
}

// MARK: - Binding Button Action's

private extension Selector {
    static let didTapUpgradeButton = #selector(OverDiskQuotaViewController.didTapUpgradeButton(button:))
    static let didTapDismissButton = #selector(OverDiskQuotaViewController.didTapDismissButton(button:))
}
