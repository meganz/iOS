import UIKit

final class OverDiskQuotaViewController: UIViewController {

    final class OverDiskQuotaAdviceGenerator {

        // MARK: - Formatters

        private lazy var dateFormatter = DateFormatter.dateMedium()

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
            var message: String
            if let plan = overDiskQuotaData.plan {
                message = suggestingMEGAPlan(from: overDiskQuotaData, withPlanName: plan)
            } else {
                message = suggestingContactSupport(from: overDiskQuotaData)
            }

            let styleMarks: StyleMarks = ["paragraph": .paragraph, "b": .emphasized(.subheadline2)]
            return message.attributedString(with: styleMarks, attributedTextStyleFactory: traitCollection.theme.attributedTextStyleFactory)
        }

        func warningActionTitle(with traitCollection: UITraitCollection) -> NSAttributedString {
            let formattedTitleMessage = titleMessage(for: overDiskQuotaData.deadline)
            let styleMarks: StyleMarks = ["warn": .warning, "body": .emphasized(.caption1)]
            return formattedTitleMessage.attributedString(
                with: styleMarks,
                attributedTextStyleFactory: traitCollection.theme.attributedTextStyleFactory
            )
        }

        // MARK: - Privates

        private func daysLeftLocalized(from startDate: Date, to endDate: Date) -> String {
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = .day
            dateComponentsFormatter.unitsStyle = .short
            return dateComponentsFormatter.string(from: startDate, to: endDate)!
        }

        private func titleMessage(for deadline: Date) -> String {
            let daysLeft = daysDistance(from: Date(), endDate: deadline)
            switch daysLeft {
            case 0..<1: return
                AMLocalizedString(
                    "<body><warn>You must act immediately to save your data.</warn><body>",
                    "<body><warn>You must act immediately to save your data.</warn><body>"
                )
            default:
                let warningTitleMessage = AMLocalizedString(
                    "<body>You have <warn>%@</warn> left to upgrade.</body>",
                    "Warning message to tell user time left to upgrade subscription."
                )
                let formattedTitleMessage = String(format: warningTitleMessage,
                                                   daysLeftLocalized(from: Date(), to: deadline))
                return formattedTitleMessage
            }
        }

        private func daysDistance(from startDate: Date, endDate: Date) -> Int {
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: startDate, to: endDate).day!
        }

        private func suggestingMEGAPlan(from overDiskQuotaData: OverDiskQuotaInternal, withPlanName plan: String) -> String {
            let localisedWarning = AMLocalizedString("<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to upgrade to <b>%@</b>.</paragraph>")
            return String(format: localisedWarning,
                          overDiskQuotaData.email,
                          overDiskQuotaData.formattedWarningDates(with: dateFormatter),
                          overDiskQuotaData.numberOfFiles(with: numberFormatter),
                          overDiskQuotaData.takingUpStorage(with: byteCountFormatter),
                          plan)
        }

        private func suggestingContactSupport(from overDiskQuotaData: OverDiskQuotaInternal) -> String {
            let localisedWarning = AMLocalizedString("<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to contact support for a custom plan.</paragraph>")
            return String(format: localisedWarning,
                          overDiskQuotaData.email,
                          overDiskQuotaData.formattedWarningDates(with: dateFormatter),
                          overDiskQuotaData.numberOfFiles(with: numberFormatter),
                          overDiskQuotaData.takingUpStorage(with: byteCountFormatter))
        }
    }

    // MARK: - Views
    
    @IBOutlet private var contentScrollView: UIScrollView!
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var storageFullLabel: UILabel!
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
        setupNavigationController(navigationController, with: traitCollection)
    }

    private func setupTraitCollectionAwareView(with traitCollection: UITraitCollection) {
        setupScrollView(contentScrollView, with: traitCollection)
        setupContentView(contentView, with: traitCollection)
        setupStorageFullLabel(storageFullLabel, with: traitCollection)
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

    private func setupNavigationController(_ navigationController: UINavigationController?,
                                           with trait: UITraitCollection) {
        navigationController?.navigationBar.setTranslucent()
    }

    private func setupScrollView(_ scrollView: UIScrollView, with trait: UITraitCollection) {
        disableAdjustingContentInsets(for: contentScrollView)
        let backgroundStyler = trait.backgroundStyler(of: .primary)
        backgroundStyler(scrollView)
    }
    
    private func setupContentView(_ contentView: UIView, with trait: UITraitCollection) {
        let backgroundStyler = trait.backgroundStyler(of: .primary)
        backgroundStyler(contentView)
    }

    private func setupWarningView(_ warningView: OverDisckQuotaWarningView, with text: NSAttributedString) {
        warningView.updateTitle(with: text)
    }

    private func setupStorageFullLabel(_ label: UILabel, with trait: UITraitCollection) {
        storageFullLabel.text = AMLocalizedString("Storage Full", "Screen title")
        let style = TextStyle(font: Font.headline,
                              color: trait.theme.colorFactory.independent(.bright))
        style.applied(on: storageFullLabel)
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
        guard let navigationController = navigationController else { return }
        let upgradeViewController = UIStoryboard(name: "UpgradeAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "UpgradeTableViewControllerID")
        if #available(iOS 13.0, *) {
            AppearanceManager.forceNavigationBarUpdate(navigationController.navigationBar,
                                                       traitCollection: traitCollection)
        }
        navigationController.pushViewController(upgradeViewController, animated: true)
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

    func formattedWarningDates(with formatter: DateFormatting) -> String {
        warningDates.reduce("") { (result, date) in
            result + (formatter.localisedString(from: date) + ", ")
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

// MARK: - TraitEnviromentAware

extension OverDiskQuotaViewController: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupTraitCollectionAwareView(with: currentTrait)
    }
}
