
import UIKit

enum AppearanceSection: Int {
    case launch
    case layout
    case recents
    case appIcon
}

enum IconName: String {
    case day = "altIconDay"
    case night = "altIconNight"
    case minimal = "altIconMinimal"
}

class AppearanceTableViewController: UITableViewController {
    
    @IBOutlet weak var sortingAndViewModeLabel: UILabel!
    @IBOutlet weak var defaultTabLabel: UILabel!
    @IBOutlet weak var defaultTabDetailLabel: UILabel!
    
    @IBOutlet weak var hideRecentActivityLabel: UILabel!
    @IBOutlet weak var hideRecentActivitySwitch: UISwitch!
    
    @IBOutlet weak var defaultIconContainerView: UIView!
    @IBOutlet weak var defaultIconButton: UIButton!
    @IBOutlet weak var defaultIconLabel: UILabel!
    
    @IBOutlet weak var dayIconContainerView: UIView!
    @IBOutlet weak var dayIconButton: UIButton!
    @IBOutlet weak var dayIconLabel: UILabel!
    
    @IBOutlet weak var nightIconContainerView: UIView!
    @IBOutlet weak var nightIconButton: UIButton!
    @IBOutlet weak var nightIconLabel: UILabel!
    
    @IBOutlet weak var minimalIconContainerView: UIView!
    @IBOutlet weak var minimalIconButton: UIButton!
    @IBOutlet weak var minimalIconLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("settings.section.userInterface", comment: "Title of one of the Settings sections where you can customise the 'User Interface' of the app.")
        
        defaultTabLabel.text = NSLocalizedString("Default Tab", comment: "Inside of Settings - User Interface, there is a view on which you can change the default tab when launch the app.")
        
        sortingAndViewModeLabel.text = NSLocalizedString("Sorting And View Mode", comment: "Inside of Settings - Appearance, there is a view on which you can change the sorting preferences or the view mode preference for the app.")
        
        hideRecentActivityLabel.text = NSLocalizedString("settings.userInterface.hideRecentActivity", comment: "In Settings - User Interface, there is an option that you can enable to hide the contents of the Recents section")
        hideRecentActivitySwitch.isOn = !RecentsPreferenceManager.showRecents()
        
        defaultIconLabel.text = NSLocalizedString("Default", comment: "Label for any ‘Default’ button, link, text, title, etc. - (String as short as possible).")
        dayIconLabel.text = NSLocalizedString("Day", comment: "Label for any ‘Day’ button, link, text, title, etc. - (String as short as possible).")
        nightIconLabel.text = NSLocalizedString("Night", comment: "Label for any ‘Night’ button, link, text, title, etc. - (String as short as possible).")
        minimalIconLabel.text = NSLocalizedString("Minimal", comment: "Label for any ‘Minimal’ button, link, text, title, etc. - (String as short as possible).")
        
        defaultIconLabel.textColor = UIColor.white
        dayIconLabel.textColor = UIColor.white
        nightIconLabel.textColor = UIColor.white
        minimalIconLabel.textColor = UIColor.white
        
        let alternateIconName = UIApplication.shared.alternateIconName
        selectIcon(with: alternateIconName)
        
        updateAppearance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        defaultTabDetailLabel.text = TabManager.getPreferenceTab().title
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        
        tableView.reloadData()
    }
    
    private func selectIcon(with name: String?) {
        switch name {
        case IconName.day.rawValue:
            markIcon(in: dayIconContainerView)
            changeLabelWeight(to: dayIconLabel)
            
        case IconName.night.rawValue:
            markIcon(in: nightIconContainerView)
            changeLabelWeight(to: nightIconLabel)
            
        case IconName.minimal.rawValue:
            markIcon(in: minimalIconContainerView)
            changeLabelWeight(to: minimalIconLabel)
            
        default:
            markIcon(in: defaultIconContainerView)
            changeLabelWeight(to: defaultIconLabel)
        }
    }
    
    private func markIcon(in view: UIView) {
        view.layer.borderColor = UIColor.white.cgColor
    }
    
    private func changeLabelWeight(to label: UILabel) {
        label.font = UIFont.preferredFont(style: .caption1, weight: .bold)
        label.textColor = UIColor.white
    }
    
    private func resetPreviousIcon(with name: String?) {
        switch name {
        case IconName.day.rawValue:
            dayIconContainerView.layer.borderColor = UIColor.clear.cgColor
            dayIconLabel.font = UIFont.preferredFont(style: .caption1, weight: .medium)
            
        case IconName.night.rawValue:
            nightIconContainerView.layer.borderColor = UIColor.clear.cgColor
            nightIconLabel.font = UIFont.preferredFont(style: .caption1, weight: .medium)
            
        case IconName.minimal.rawValue:
            minimalIconContainerView.layer.borderColor = UIColor.clear.cgColor
            minimalIconLabel.font = UIFont.preferredFont(style: .caption1, weight: .medium)
            
        default:
            defaultIconContainerView.layer.borderColor = UIColor.clear.cgColor
            defaultIconLabel.font = UIFont.preferredFont(style: .caption1, weight: .medium)
        }
    }
    
    private func changeAppIcon(to iconName: String?) {
        if UIApplication.shared.supportsAlternateIcons {
            let alternateIconName = UIApplication.shared.alternateIconName
            UIApplication.shared.setAlternateIconName(iconName, completionHandler: { (error) in
                if let error = error {
                    MEGALogError("App icon failed to change due to \(error.localizedDescription)")
                } else {
                    self.selectIcon(with: iconName)
                    self.resetPreviousIcon(with: alternateIconName)
                }
            })
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func hideRecentActivityValueChanged(_ sender: UISwitch) {
        RecentsPreferenceManager.setShowRecents(!sender.isOn)
    }
    
    @IBAction func defaultIconTouchUpInside(_ sender: UIButton) {
        changeAppIcon(to: nil)
    }
    
    @IBAction func dayIconTouchUpInside(_ sender: UIButton) {
        changeAppIcon(to: IconName.day.rawValue)
    }
    
    @IBAction func nightIconTouchUpInside(_ sender: UIButton) {
        changeAppIcon(to: IconName.night.rawValue)
    }
    
    @IBAction func minimalIconTouchUpInside(_ sender: UIButton) {
        changeAppIcon(to: IconName.minimal.rawValue)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGrouped(traitCollection)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch AppearanceSection(rawValue: section) {
        case .launch:
            return NSLocalizedString("Launch", comment: "Section title inside of Settings - User Interface, where you can change the default tab when launch the app.")
            
        case .layout:
            return NSLocalizedString("Layout", comment: "Section title inside of Settings - Appearance, where you can change the app's layout distribution.")
            
        case .recents:
            return NSLocalizedString("Recents", comment: "Title for the recents section.")
            
        case .appIcon:
            return NSLocalizedString("App Icon", comment: "Section title inside of Settings - Appearance, where you can change the app's icon.")
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch AppearanceSection(rawValue: section) {
        case .launch:
            return NSLocalizedString("Configure default launch section.", comment: "Footer text to explain what you could do in the Settings - User Interface - Default Tab section.")
        
        case .layout:
            return NSLocalizedString("Configure sorting order and the default view (List or Thumbnail).", comment: "Footer text to explain what you could do in the Settings - Appearance - Sorting And View Mode section.")
            
        case .recents:
            return NSLocalizedString("settings.userInterface.hideRecentActivity.footer", comment: "In Settings - User Interface, there is an option that you can enable to hide the contents of the Recents section. This is the footer that appears under that option.")
            
        case .appIcon:
            return nil
            
        default:
            return nil
        }
    }
}
