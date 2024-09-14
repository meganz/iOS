import MEGADesignToken
import MEGAFoundation
import MEGAL10n
import MEGAUIKit
import UIKit

final class OverDiskQuotaViewController: UIViewController {

    final class OverDiskQuotaAdviceGenerator {

        // MARK: - Formatters

        private lazy var dateFormatter: some DateFormatting = DateFormatter.dateMedium()

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
        private let isFinalWarning: Bool

        // MARK: - Lifecycles

        fileprivate init(_ overDiskQuotaData: OverDiskQuotaInternal) {
            self.overDiskQuotaData = overDiskQuotaData
            isFinalWarning = Calendar.current.dateComponents([.day], from: Date(), to: overDiskQuotaData.deadline).day ?? 0 < 1
        }

        // MARK: - Exposed Methods

        var titleMessage: String {
            isFinalWarning
            ? Strings.Localizable.Dialog.Storage.Paywall.Final.title
            : Strings.Localizable.Dialog.Storage.Paywall.NotFinal.title
        }

        func overDiskQuotaMessage(with traitCollection: UITraitCollection) -> NSAttributedString {
            var message: String
            
            if isFinalWarning {
                message = Strings.Localizable.Dialog.Storage.Paywall.Final.detail
            } else {
                var warningPeriod = ""
                if let firstWarningDate = overDiskQuotaData.warningDates.first {
                    warningPeriod = daysBetweenLocalized(from: firstWarningDate, to: Date())
                }
                message = Strings.Localizable.Dialog.Storage.Paywall.NotFinal.detail(warningPeriod,
                                                                                     overDiskQuotaData.email,
                                                                                     overDiskQuotaData.formattedWarningDates(with: dateFormatter),
                                                                                     overDiskQuotaData.takingUpStorage(with: byteCountFormatter))
            }

            let styleMarks: StyleMarks = ["paragraph": .paragraph, "b": .emphasized(.subheadlineMedium)]
            return message.attributedString(with: styleMarks, attributedTextStyleFactory: traitCollection.theme.attributedTextStyleFactory)
        }

        func warningActionTitle(with traitCollection: UITraitCollection) -> NSAttributedString {
            let formattedTitleMessage = warningMessage(for: overDiskQuotaData.deadline)
            let styleMarks: StyleMarks = ["warn": .warning, "body": .emphasized(.subheadlineSemibold)]
            return formattedTitleMessage.attributedString(
                with: styleMarks,
                attributedTextStyleFactory: traitCollection.theme.attributedTextStyleFactory
            )
        }

        // MARK: - Privates

        private func daysBetweenLocalized(from startDate: Date, to endDate: Date) -> String {
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = .day
            dateComponentsFormatter.unitsStyle = .short
            return dateComponentsFormatter.string(from: startDate, to: endDate)!
        }

        private func warningMessage(for deadline: Date) -> String {
            if isFinalWarning {
                return Strings.Localizable.Dialog.Storage.Paywall.Final.warning
            } else {
                return Strings.Localizable.Dialog.Storage.Paywall.NotFinal.warning(daysBetweenLocalized(from: Date(), to: deadline))
            }
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

    @IBOutlet weak var warningView: OverDiskQuotaWarningView!

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

    @objc func setup(with overDiskQuotaData: any OverDiskQuotaInfomationProtocol) {
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
        scrollView.backgroundColor = TokenColors.Background.page
    }
    
    private func setupContentView(_ contentView: UIView, with trait: UITraitCollection) {
        contentView.backgroundColor = TokenColors.Background.page
    }

    private func setupWarningView(_ warningView: OverDiskQuotaWarningView, with text: NSAttributedString) {
        warningView.updateTitle(with: text)
    }

    private func setupStorageFullLabel(_ label: UILabel, with trait: UITraitCollection) {
        storageFullLabel.text = Strings.Localizable.storageFull
        storageFullLabel.textColor = TokenColors.Text.onColor
        storageFullLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    }

    private func setupTitleLabel(_ titleLabel: UILabel, with trait: UITraitCollection) {
        titleLabel.text = overDiskQuotaAdvicer.titleMessage
        storageFullLabel.textColor = TokenColors.Text.primary
        storageFullLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    }

    private func setupMessageLabel(_ descriptionLabel: UILabel, withMessage message: NSAttributedString) {
        descriptionLabel.attributedText = message
        descriptionLabel.textColor = TokenColors.Text.secondary
    }

    private func setupUpgradeButton(_ button: UIButton, with trait: UITraitCollection) {
        button.setTitle(Strings.Localizable.upgrade, for: .normal)
        button.addTarget(self, action: .didTapUpgradeButton, for: .touchUpInside)
        button.mnz_setupPrimary(trait)
    }

    private func setupDismissButton(_ button: UIButton, with trait: UITraitCollection) {
        button.setTitle(Strings.Localizable.dismiss, for: .normal)
        button.addTarget(self, action: .didTapDismissButton, for: .touchUpInside)
        button.mnz_setupSecondary(trait)
    }

    // MARK: - Button Actions

    @objc fileprivate func didTapUpgradeButton(button: UIButton) {
        guard let navigationController = navigationController else { return }
        let upgradeViewController = UIStoryboard(name: "UpgradeAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "UpgradeTableViewControllerID")
            AppearanceManager.forceNavigationBarUpdate(navigationController.navigationBar,
                                                       traitCollection: traitCollection)
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
        typealias FileCount = UInt64
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

    func formattedWarningDates(with formatter: some DateFormatting) -> String {
        let localizedDates = warningDates.map { date in
            formatter.localisedString(from: date)
        }
        return localizedDates.joined(separator: ", ")
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

// MARK: - TraitEnvironmentAware

extension OverDiskQuotaViewController: TraitEnvironmentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupTraitCollectionAwareView(with: currentTrait)
    }
}
