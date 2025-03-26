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
            if isFinalWarning {
                let message = Strings.Localizable.Dialog.Storage.Paywall.Final.detail
                let styleMarks: StyleMarks = ["paragraph": .paragraph, "b": .emphasized(.subheadlineMedium)]
                return message.attributedString(with: styleMarks, attributedTextStyleFactory: traitCollection.theme.attributedTextStyleFactory)
            } else {
                let message = paywallNotFinalWarningMessage()
                let tappableString = message.subString(from: "[A]", to: "[/A]")
                let warningMessage = message
                    .replacingOccurrences(of: "[A]", with: "")
                    .replacingOccurrences(of: "[/A]", with: "")
                return NSAttributedString(
                    paywallAttributedString(
                        warningMessage,
                        tappableString: tappableString,
                        url: URL(string: "https://help.mega.io/plans-storage/space-storage/storage-exceeded")
                    )
                )
            }
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
        
        private func paywallNotFinalWarningMessage() -> String {
            let numberOfFiles = Int(overDiskQuotaData.numberOfFilesOnCloud)
            let warningDates = overDiskQuotaData.warningDates
            var message: String
            
            switch warningDates.count {
            case 0: // unknown times email was sent
                message = Strings.Localizable.OverDiskQuota.Paywall.NotFinalWarning.UnknownTimesEmailWasSent.message(numberOfFiles)
                
            case 1: // received one email
                let warningPeriod = warningDates.first.map {
                    dateFormatter.localisedString(from: $0)
                } ?? ""
                message = Strings.Localizable.OverDiskQuota.Paywall.NotFinalWarning.OneEmailSent.message(numberOfFiles)
                    .replacingOccurrences(of: "[date]", with: warningPeriod)
                
            default: // received more than one email
                message = Strings.Localizable.OverDiskQuota.Paywall.NotFinalWarning.MultipleEmailsSent.message(numberOfFiles)
            }
            
            message = message
                .replacingOccurrences(of: "[storageSpace]", with: overDiskQuotaData.takingUpStorage(with: byteCountFormatter))
                .replacingOccurrences(of: "[plan]", with: overDiskQuotaData.plan ?? "")
            
            return message
        }

        private func paywallAttributedString(
            _ message: String,
            tappableString: String? = nil,
            url: URL? = nil
        ) -> AttributedString {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            paragraphStyle.alignment = .center

            var attributedString = AttributedString(
                message,
                attributes: AttributeContainer([
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.preferredFont(forTextStyle: .subheadline),
                    .foregroundColor: TokenColors.Text.secondary
                ])
            )
            
            if let tappableString, let url, let range = attributedString.range(of: tappableString) {
                attributedString[range].link = url
            }
            
            return attributedString
        }
    }

    // MARK: - Views
    
    @IBOutlet private var contentScrollView: UIScrollView!
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var storageFullLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagraphTextView: UITextView!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!

    @IBOutlet weak var warningView: OverDiskQuotaWarningView!

    // MARK: - In / Out properties

    private var overDiskQuota: OverDiskQuotaInternal!

    private var overDiskQuotaAdvicer: OverDiskQuotaAdviceGenerator!

    private var viewModel: OverDiskQuotaViewModel?
    
    // MARK: - ViewController Lifecycles

    init(
        viewModel: OverDiskQuotaViewModel,
        overDiskQuotaData: any OverDiskQuotaInfomationProtocol
    ) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        setup(with: overDiskQuotaData)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTraitCollectionAwareView(with: traitCollection)
        
        viewModel?.dispatch(.onViewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController(navigationController)
    }

    private func setupTraitCollectionAwareView(with traitCollection: UITraitCollection) {
        setupScrollView(contentScrollView)
        setupContentView(contentView)
        setupStorageFullLabel(storageFullLabel)
        setupTitleLabel(titleLabel)
        setupMessageTextView(warningParagraphTextView,
                          withMessage: overDiskQuotaAdvicer.overDiskQuotaMessage(with: traitCollection))
        setupWarningView(warningView,
                         with: overDiskQuotaAdvicer.warningActionTitle(with: traitCollection))
        setupUpgradeButton()
        setupDismissButton()
    }

    // MARK: - Setup MEGA UserData

    private func setup(with overDiskQuotaData: any OverDiskQuotaInfomationProtocol) {
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
        navigationController?.navigationBar.setTranslucent()
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(for: contentScrollView)
        scrollView.backgroundColor = TokenColors.Background.page
    }
    
    private func setupContentView(_ contentView: UIView) {
        contentView.backgroundColor = TokenColors.Background.page
    }

    private func setupWarningView(_ warningView: OverDiskQuotaWarningView, with text: NSAttributedString) {
        warningView.updateTitle(with: text)
    }

    private func setupStorageFullLabel(_ label: UILabel) {
        storageFullLabel.text = Strings.Localizable.storageFull
        storageFullLabel.textColor = TokenColors.Text.onColor
        storageFullLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    }

    private func setupTitleLabel(_ titleLabel: UILabel) {
        titleLabel.text = overDiskQuotaAdvicer.titleMessage
        storageFullLabel.textColor = TokenColors.Text.primary
        storageFullLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    }

    private func setupMessageTextView(_ descriptionTextView: UITextView, withMessage message: NSAttributedString) {
        descriptionTextView.attributedText = message
        descriptionTextView.linkTextAttributes = [.foregroundColor: TokenColors.Link.primary]
    }

    private func setupUpgradeButton() {
        upgradeButton.setTitle(Strings.Localizable.OverDiskQuota.Paywall.Button.upgradeNow, for: .normal)
        upgradeButton.addTarget(self, action: .didTapUpgradeButton, for: .touchUpInside)
        upgradeButton.mnz_setupPrimary()
    }

    private func setupDismissButton() {
        dismissButton.setTitle(Strings.Localizable.dismiss, for: .normal)
        dismissButton.addTarget(self, action: .didTapDismissButton, for: .touchUpInside)
        dismissButton.mnz_setupSecondary()
    }

    // MARK: - Button Actions

    @objc fileprivate func didTapUpgradeButton() {
        viewModel?.dispatch(.didTapUpgradeButton)
    }

    @objc fileprivate func didTapDismissButton() {
        viewModel?.dispatch(.didTapDismissButton)
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
    static let didTapUpgradeButton = #selector(OverDiskQuotaViewController.didTapUpgradeButton)
    static let didTapDismissButton = #selector(OverDiskQuotaViewController.didTapDismissButton)
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
