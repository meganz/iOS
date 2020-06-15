import UIKit

final class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet private var contentScrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var warningParagaphLabel: UILabel!

    @IBOutlet private var upgradeButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!
    @IBOutlet weak var warningView: OverDisckQuotaWarningView!

    @objc var dismissAction: (() -> Void)?

    private var warning: OverDiskQuota?

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
        setupTitleLabel(titleLabel)
        setupMessageLabel(warningParagaphLabel, overDiskInformation: warning)
        setupUpgradeButton(upgradeButton)
        setupDismissButton(dismissButton)
        warningView.updateTimeLeftForTitle(withText: "33 days")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController(navigationController)
        setupScrollView(contentScrollView)
    }

    // MARK: - Setup MEGA UserData

    @objc func setup(with overDiskQuota: OverDiskQuotaInfomationType) {
        warning = OverDiskQuota(email: overDiskQuota.email,
                                       deadline: overDiskQuota.deadline,
                                       warningDates: overDiskQuota.warningDates,
                                       numberOfFilesOnCloud: overDiskQuota.numberOfFilesOnCloud,
                                       cloudStorage: overDiskQuota.cloudStorage,
                                       plan: overDiskQuota.availablePlan)
    }

    struct OverDiskQuota {
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

    private func setupMessageLabel(_ descriptionLabel: UILabel, overDiskInformation: OverDiskQuota?) {
        guard let infor = overDiskInformation else { descriptionLabel.text = nil; return }
        let message = AMLocalizedString("Over Disk Quota Message", "We have contacted you by email to bk@mega.nz on March 1 2020,  March 30 2020, April 30 2020 and May 15 2020, but you still have 45302 files taking up 234.54 GB in your MEGA account, which requires you to upgrade to PRO Lite.")
        let formattedMessage = String(format: message,
                                      infor.email,
                                      infor.formattedWarningDates(with: dateFormatter),
                                      infor.numberOfFiles(with: numberFormatter),
                                      infor.takingUpStorage(with: byteCountFormatter),
                                      infor.plan)

        descriptionLabel.attributedText = MarkedStringParser.parseAttributedString(from: formattedMessage,
                                                                                   withStyleRegistration: ["paragraph": .paragraph,
                                                                                                           "b": .emphasized])
    }

    private func setupUpgradeButton(_ button: UIButton) {
        ButtonStyle.active.style(button)
        button.setTitle(AMLocalizedString("Over Disk Quota Upgrade Button Text", "Upgrade"), for: .normal)
        button.addTarget(self, action: #selector(didTapUpgradeButton(button:)), for: .touchUpInside)
    }

    private func setupDismissButton(_ button: UIButton) {
        ButtonStyle.inactive.style(button)
        button.setTitle(AMLocalizedString("Over Disk Quota Dismiss Button Text", "Dismiss"), for: .normal)
    }

    @objc private func didTapUpgradeButton(button: UIButton) {
        let upgradeViewController = UIStoryboard(name: "MyAccount", bundle: nil).instantiateViewController(withIdentifier: "UpgradeID")
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.pushViewController(upgradeViewController, animated: true)
    }
}

// MARK: - Attributed Warning Text

fileprivate extension OverDiskQuotaViewController.OverDiskQuota {

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
}
