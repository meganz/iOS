import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI

class CookieSettingsTableViewController: UITableViewController {
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var adPersonalisationLabel: UILabel!
    
    @IBOutlet weak var acceptCookiesLabel: UILabel!
    @IBOutlet weak var acceptCookiesSwitch: UISwitch!
    
    @IBOutlet weak var essentialCookiesLabel: UILabel!
    @IBOutlet weak var essentialCookiesDetailLabel: UILabel!
    
    @IBOutlet weak var performanceAndAnalyticsCookiesLabel: UILabel!
    @IBOutlet weak var performanceAndAnalyticsSwitch: UISwitch!
    
    @IBOutlet weak var advertisingCookiesLabel: UILabel!
    @IBOutlet weak var advertisingCookiesSwitch: UISwitch!
    
    @IBOutlet var cookiePolicyBarButtonItem: UIBarButtonItem!
    @IBOutlet var privacyPolicyBarButtonItem: UIBarButtonItem!
    
    var router: CookieSettingsRouter!
    var viewModel: CookieSettingsViewModel!
    
    private var footersArray: [String] = ["", "", "", "", "", ""]
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        configView()
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: CookieSettingsViewModel.Command) {
        switch command {
        case .configCookieSettings(let cookiesBitmap):
            performanceAndAnalyticsSwitch.setOn(cookiesBitmap.contains(.analytics), animated: false)
            if visibleCookieTypeSwitches().contains(where: { $0 == advertisingCookiesSwitch }) {
                advertisingCookiesSwitch.setOn(cookiesBitmap.contains(.ads), animated: false)
            }
            acceptCookiesSwitch.isOn = visibleCookieTypeSwitches().allSatisfy { $0.isOn }
            
        case .updateFooters(let array):
            footersArray = array
            tableView.reloadData()
            
        case .cookieSettingsSaved:
            router.dismiss()
            router.showAdMobConsentIfNeeded()
            
        case .showSnackBar(let message):
            showSnackBar(snackBar: SnackBar(message: message))
            
        case .showResult(let resultCommand):
            executeCommand(resultCommand)
            
        case .updateAutomaticallyAllVisibleSwitch(let currentState):
            visibleCookieTypeSwitches().forEach { currentSwitch in
                if currentSwitch.isHidden == false {
                    currentSwitch.isOn = currentState
                }
            }
        }
    }
    
    func executeCommand(_ command: CookieSettingsViewModel.Command.ResultCommand) {
        switch command {
        case .success:
            router.dismiss()
            
        case .error(let message):
            SVProgressHUD.showError(withStatus: message)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func saveTouchUpInside(_ sender: UIBarButtonItem) {
        viewModel.dispatch(.save)
    }
    
    @IBAction func acceptCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.acceptCookiesSwitchValueChanged(sender.isOn))
    }
    
    @IBAction func performanceAndAnalyticsSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.performanceAndAnalyticsSwitchValueChanged(sender.isOn))
        updateAcceptCookiesSwitchIfNeeded(newState: sender.isOn)
    }
    
    @IBAction func advertisingSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.advertisingSwitchValueChanged(sender.isOn))
        updateAcceptCookiesSwitchIfNeeded(newState: sender.isOn)
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UIBarButtonItem) {
        viewModel.dispatch(.showCookiePolicy)
    }
    
    @IBAction func privacyPolicyTouchUpInside(_ sender: UIBarButtonItem) {
        router.didTap(on: .showPrivacyPolicy)
    }
    
    // MARK: - Private
    
    private func configView() {
        navigationController?.presentationController?.delegate = self
        
        title = viewModel.viewTitle
        
        saveBarButtonItem.title = Strings.Localizable.close
        self.navigationItem.rightBarButtonItem = saveBarButtonItem
        
        adPersonalisationLabel.text = Strings.Localizable.Settings.Ad.AdPersonalisation.title
        acceptCookiesLabel.text = Strings.Localizable.Dialog.Cookies.accept
        essentialCookiesLabel.text = Strings.Localizable.Settings.Cookies.essential
        essentialCookiesDetailLabel.text = Strings.Localizable.Settings.Cookies.Essential.alwaysOn
        performanceAndAnalyticsCookiesLabel.text = Strings.Localizable.Settings.Cookies.performanceAndAnalytics
                
        configToolbar()
        
        viewModel.dispatch(.configView)
        
        setupColors()
    }
    
    private func configToolbar() {
        cookiePolicyBarButtonItem.title = Strings.Localizable.General.cookiePolicy
        privacyPolicyBarButtonItem.title = Strings.Localizable.privacyPolicyLabel
        let flexibleBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([cookiePolicyBarButtonItem, flexibleBarButtonItem, privacyPolicyBarButtonItem], animated: false)
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.isTranslucent = true
    }
    
    private func setupColors() {
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = TokenColors.Border.strong
        
        saveBarButtonItem.tintColor = TokenColors.Text.secondary
        
        adPersonalisationLabel.textColor = TokenColors.Text.primary
        
        acceptCookiesLabel.textColor = TokenColors.Text.primary
        acceptCookiesSwitch.onTintColor = TokenColors.Support.success
        
        essentialCookiesLabel.textColor = TokenColors.Text.primary
        essentialCookiesDetailLabel.textColor = TokenColors.Text.secondary
        
        performanceAndAnalyticsCookiesLabel.textColor = TokenColors.Text.primary
        performanceAndAnalyticsSwitch.onTintColor = TokenColors.Support.success
        
        advertisingCookiesLabel.textColor = TokenColors.Text.primary
        advertisingCookiesSwitch.onTintColor = TokenColors.Support.success
    }
    
    private func configureAppearanceForTableViewHeaderFooterView(
        _ view: UITableViewHeaderFooterView,
        title: String? = nil
    ) {
        view.textLabel?.textColor = TokenColors.Text.secondary
        
        // Sets the title as how the text is. Not All caps by default.
        if let title {
            view.textLabel?.text = title
        }
    }
    
    private func visibleCookieTypeSwitches() -> [UISwitch] {
        viewModel.numberOfSection == 5 ? [performanceAndAnalyticsSwitch, advertisingCookiesSwitch] : [performanceAndAnalyticsSwitch]
    }
    
    private func updateAcceptCookiesSwitchIfNeeded(newState: Bool) {
        let shouldUpdateAcceptCookiesSwitch: Bool
        
        if newState {
            shouldUpdateAcceptCookiesSwitch = visibleCookieTypeSwitches().allSatisfy { $0.isOn == newState }
        } else {
            shouldUpdateAcceptCookiesSwitch = acceptCookiesSwitch.isOn
        }
        
        if shouldUpdateAcceptCookiesSwitch {
            acceptCookiesSwitch.isOn = newState
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footerView = view as? UITableViewHeaderFooterView else { return }
        configureAppearanceForTableViewHeaderFooterView(footerView)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard viewModel.showAdsSettings, let headerView = view as? UITableViewHeaderFooterView else { return }
        configureAppearanceForTableViewHeaderFooterView(
            headerView,
            title: CookieSettingsSection(rawValue: section)?.headerTitle
        )
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.shouldHideSection(section) ? 0.01 : UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        viewModel.shouldHideSection(section) ? 0.01 : UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == CookieSettingsSection.adPersonalisation.rawValue else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.dispatch(.showAdPrivacyOptionForm)
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.shouldHideSection(section) ? 0 : super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSection
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.showAdsSettings ? CookieSettingsSection(rawValue: section)?.headerTitle : nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case CookieSettingsSection.acceptCookies.rawValue:
            footersArray[CookieSettingsSection.acceptCookies.rawValue]
            
        case CookieSettingsSection.essentialCookies.rawValue:
            footersArray[CookieSettingsSection.essentialCookies.rawValue]
            
        case CookieSettingsSection.performanceAndAnalyticsCookies.rawValue:
            footersArray[CookieSettingsSection.performanceAndAnalyticsCookies.rawValue]
            
        default:
            ""
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension CookieSettingsTableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
