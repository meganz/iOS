
import Foundation

enum CookieSettingsSection: Int {
    case acceptCookies
    case essentialCookies
    case preferenceCookies
    case performanceAndAnalyticsCookies
    case advertisingCookies
    case thirdPartyCookies
}

class CookieSettingsTableViewController: UITableViewController {
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var acceptCookiesLabel: UILabel!
    @IBOutlet weak var acceptCookiesSwitch: UISwitch!
    
    @IBOutlet weak var essentialCookiesLabel: UILabel!
    @IBOutlet weak var essentialCookiesDetailLabel: UILabel!
    
    @IBOutlet weak var preferenceCookiesLabel: UILabel!
    @IBOutlet weak var preferenceCookiesSwitch: UISwitch!
    
    @IBOutlet weak var performanceAndAnalyticsCookiesLabel: UILabel!
    @IBOutlet weak var performanceAndAnalyticsSwitch: UISwitch!
    
    @IBOutlet weak var advertisingCookiesLabel: UILabel!
    @IBOutlet weak var advertisingCookiesSwitch: UISwitch!
    
    @IBOutlet weak var thirdPartyCookiesLabel: UILabel!
    @IBOutlet weak var thirdPartyCookiesSwitch: UISwitch!
    
    @IBOutlet weak var thirdPartyCookiesMoreInformationButton: UIButton!
    
    @IBOutlet var cookiePolicyBarButtonItem: UIBarButtonItem!
    @IBOutlet var privacyPolicyBarButtonItem: UIBarButtonItem!
    
    var router: CookieSettingsRouter!
    var viewModel: CookieSettingsViewModel!
    
    private var footersArray: Array<String> = ["", "", "", "", "", ""]
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        configView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                AppearanceManager.forceNavigationBarUpdate(self.navigationController?.navigationBar ?? UINavigationBar(), traitCollection: traitCollection)
                AppearanceManager.forceToolbarUpdate(self.navigationController?.toolbar ?? UIToolbar(), traitCollection: traitCollection)
                
                updateAppearance()
            }
        }
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: CookieSettingsViewModel.Command) {
        switch command {
        case .configCookieSettings(let cookiesBitmap):
            preferenceCookiesSwitch.setOn(cookiesBitmap.contains(.preference), animated: false)
            performanceAndAnalyticsSwitch.setOn(cookiesBitmap.contains(.analytics), animated: false)
            advertisingCookiesSwitch.setOn(cookiesBitmap.contains(.ads), animated: false)
            thirdPartyCookiesSwitch.setOn(cookiesBitmap.contains(.thirdparty), animated: false)
            
            acceptCookiesSwitch.isOn = preferenceCookiesSwitch.isOn && performanceAndAnalyticsSwitch.isOn && advertisingCookiesSwitch.isOn && thirdPartyCookiesSwitch.isOn
        
        case .updateFooters(let array):
            footersArray = array
            tableView.reloadData()
            
        case .cookieSettingsSaved:
            router.dismiss()
            
        case .showResult(let resultCommand):
            executeCommand(resultCommand)
        }
    }
    
    func executeCommand(_ command: CookieSettingsViewModel.Command.ResultCommand) {
        switch command {
        case .success(_):
            router.dismiss()
            
        case .error(let message):
            SVProgressHUD.showError(withStatus: message)
            break
        }
    }
    
    // MARK: - IBAActions
    
    @IBAction func saveTouchUpInside(_ sender: UIBarButtonItem) {
        viewModel.dispatch(.save)
    }
    
    @IBAction func acceptCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.acceptCookiesSwitchValueChanged(sender.isOn))
        
        preferenceCookiesSwitch.setOn(sender.isOn, animated: true)
        performanceAndAnalyticsSwitch.setOn(sender.isOn, animated: true)
        advertisingCookiesSwitch.setOn(sender.isOn, animated: true)
        thirdPartyCookiesSwitch.setOn(sender.isOn, animated: true)
    }
    
    @IBAction func preferenceCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.preferenceCookiesSwitchValueChanged(sender.isOn))
        
        switchManagement()
    }
    
    @IBAction func performanceAndAnalyticsSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.performanceAndAnalyticsSwitchValueChanged(sender.isOn))
        
        switchManagement()
    }
    
    @IBAction func advertisingCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.advertisingCookiesSwitchValueChanged(sender.isOn))
        
        switchManagement()
    }
    @IBAction func thirdPartyCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.thirdPartyCookiesSwitchValueChanged(sender.isOn))
        
        switchManagement()
    }
    
    @IBAction func thirdPartyCookiesMoreInfoTouchUpInside(_ sender: UIButton) {
        router.didTap(on: .showThirdPartyCookiesMoreInfo)
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UIBarButtonItem) {
        router.didTap(on: .showCookiePolicy)
    }
    
    @IBAction func privacyPolicyTouchUpInside(_ sender: UIBarButtonItem) {
        router.didTap(on: .showPrivacyPolicy)
    }
    
    // MARK: - Private
    
    private func configView() {
        navigationController?.presentationController?.delegate = self
        
        title = NSLocalizedString("Cookie Settings", comment: "Title of one of the Settings sections where you can see the MEGA's 'Cookie Settings'")
        
        saveBarButtonItem.title = NSLocalizedString("save", comment: "Button title to 'Save' the selected option")
        self.navigationItem.rightBarButtonItem = saveBarButtonItem
        
        acceptCookiesLabel.text = NSLocalizedString("Accept Cookies", comment: "")
        essentialCookiesLabel.text = NSLocalizedString("Essential Cookies", comment: "")
        essentialCookiesDetailLabel.text = NSLocalizedString("Always On", comment: "Text shown next to Essential Cookies in Cookie Settings. This setting can not be disabled, that is why is 'Always on'")
        preferenceCookiesLabel.text = NSLocalizedString("Preference Cookies", comment: "")
        performanceAndAnalyticsCookiesLabel.text = NSLocalizedString("Performance and Analytics Cookies", comment: "")
        advertisingCookiesLabel.text = NSLocalizedString("Advertising Cookies", comment: "")
        thirdPartyCookiesLabel.text = NSLocalizedString("Third Party Cookies", comment: "")
        
        thirdPartyCookiesMoreInformationButton.setTitle(NSLocalizedString("More Information", comment: "Cookie settings dialog link label. Should be same as in “24659” string."), for: .normal)
        thirdPartyCookiesMoreInformationButton.setTitleColor(.mnz_turquoise(for: traitCollection), for: .normal)
        thirdPartyCookiesMoreInformationButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        configToolbar()
        
        viewModel.dispatch(.configView)
        
        updateAppearance()
    }
    
    private func configToolbar() {
        cookiePolicyBarButtonItem.title = NSLocalizedString("Cookie Policy", comment: "Title of one of the Settings sections where you can see the MEGA's 'Cookie Policy'")
        privacyPolicyBarButtonItem.title = NSLocalizedString("privacyPolicyLabel", comment: "Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'")
        let flexibleBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([cookiePolicyBarButtonItem, flexibleBarButtonItem, privacyPolicyBarButtonItem], animated: false)
        navigationController?.toolbar.isHidden = false
        navigationController?.toolbar.isTranslucent = true
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundGroupedElevated(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        saveBarButtonItem.tintColor = .mnz_primaryGray(for: traitCollection)
        
        essentialCookiesDetailLabel.textColor = .mnz_secondaryLabel()
        
        tableView.reloadData()
    }
    
    private func switchManagement() {
        let areAllSwitchsEnabled: Bool = preferenceCookiesSwitch.isOn && performanceAndAnalyticsSwitch.isOn && advertisingCookiesSwitch.isOn && thirdPartyCookiesSwitch.isOn
        acceptCookiesSwitch.setOn(areAllSwitchsEnabled, animated: true)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .mnz_secondaryBackgroundGroupedElevated(traitCollection)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {        
        switch section {
        case CookieSettingsSection.acceptCookies.rawValue: return ""
            
        case CookieSettingsSection.essentialCookies.rawValue:
            return footersArray[CookieSettingsSection.essentialCookies.rawValue]
            
        case CookieSettingsSection.preferenceCookies.rawValue:
            return footersArray[CookieSettingsSection.preferenceCookies.rawValue]
            
        case CookieSettingsSection.performanceAndAnalyticsCookies.rawValue:
            return footersArray[CookieSettingsSection.performanceAndAnalyticsCookies.rawValue]
            
        case CookieSettingsSection.advertisingCookies.rawValue:
            return footersArray[CookieSettingsSection.advertisingCookies.rawValue]
            
        case CookieSettingsSection.thirdPartyCookies.rawValue:
            return footersArray[CookieSettingsSection.thirdPartyCookies.rawValue]
            
        default:
            return ""
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension CookieSettingsTableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
