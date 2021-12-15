
import Foundation

enum CookieSettingsSection: Int {
    case acceptCookies
    case essentialCookies
    case performanceAndAnalyticsCookies
}

class CookieSettingsTableViewController: UITableViewController {
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var acceptCookiesLabel: UILabel!
    @IBOutlet weak var acceptCookiesSwitch: UISwitch!
    
    @IBOutlet weak var essentialCookiesLabel: UILabel!
    @IBOutlet weak var essentialCookiesDetailLabel: UILabel!
    
    @IBOutlet weak var performanceAndAnalyticsCookiesLabel: UILabel!
    @IBOutlet weak var performanceAndAnalyticsSwitch: UISwitch!
    
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
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            AppearanceManager.forceNavigationBarUpdate(self.navigationController?.navigationBar ?? UINavigationBar(), traitCollection: traitCollection)
            AppearanceManager.forceToolbarUpdate(self.navigationController?.toolbar ?? UIToolbar(), traitCollection: traitCollection)
            
            updateAppearance()
        }
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: CookieSettingsViewModel.Command) {
        switch command {
        case .configCookieSettings(let cookiesBitmap):
            performanceAndAnalyticsSwitch.setOn(cookiesBitmap.contains(.analytics), animated: false)
            
            acceptCookiesSwitch.isOn = performanceAndAnalyticsSwitch.isOn
        
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
        
        performanceAndAnalyticsSwitch.setOn(sender.isOn, animated: true)
    }
    
    @IBAction func performanceAndAnalyticsSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.performanceAndAnalyticsSwitchValueChanged(sender.isOn))
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
        
        title = Strings.Localizable.General.cookieSettings
        
        saveBarButtonItem.title = Strings.Localizable.save
        self.navigationItem.rightBarButtonItem = saveBarButtonItem
        
        acceptCookiesLabel.text = Strings.Localizable.Dialog.Cookies.accept
        essentialCookiesLabel.text = Strings.Localizable.Settings.Cookies.essential
        essentialCookiesDetailLabel.text = Strings.Localizable.Settings.Cookies.Essential.alwaysOn
        
        performanceAndAnalyticsCookiesLabel.text = Strings.Localizable.Settings.Cookies.performanceAndAnalytics
        
        configToolbar()
        
        viewModel.dispatch(.configView)
        
        updateAppearance()
    }
    
    private func configToolbar() {
        cookiePolicyBarButtonItem.title = Strings.Localizable.General.cookiePolicy
        privacyPolicyBarButtonItem.title = Strings.Localizable.privacyPolicyLabel
        let flexibleBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([cookiePolicyBarButtonItem, flexibleBarButtonItem, privacyPolicyBarButtonItem], animated: false)
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.isTranslucent = true
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundGroupedElevated(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        saveBarButtonItem.tintColor = .mnz_primaryGray(for: traitCollection)
        
        essentialCookiesDetailLabel.textColor = .mnz_secondaryLabel()
        
        tableView.reloadData()
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
            
        case CookieSettingsSection.performanceAndAnalyticsCookies.rawValue:
            return footersArray[CookieSettingsSection.performanceAndAnalyticsCookies.rawValue]
            
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
