
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
        
        title = Strings.Localizable.Settings.Section.userInterface
        
        defaultTabLabel.text = Strings.Localizable.defaultTab
        
        sortingAndViewModeLabel.text = Strings.Localizable.sortingAndViewMode
        
        hideRecentActivityLabel.text = Strings.Localizable.Settings.UserInterface.hideRecentActivity
        
        hideRecentActivitySwitch.isOn = !RecentsPreferenceManager.showRecents()
        
        defaultIconLabel.text = Strings.Localizable.default

        dayIconLabel.text = Strings.Localizable.day.localizedCapitalized

        nightIconLabel.text = Strings.Localizable.night

        minimalIconLabel.text = Strings.Localizable.minimal
        
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
            return Strings.Localizable.launch
            
        case .layout:
            return Strings.Localizable.layout
            
        case .recents:
            return Strings.Localizable.recents
            
        case .appIcon:
            return Strings.Localizable.appIcon
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch AppearanceSection(rawValue: section) {
        case .launch:
            return Strings.Localizable.configureDefaultLaunchSection
        
        case .layout:
            return Strings.Localizable.configureSortingOrderAndTheDefaultViewListOrThumbnail
            
        case .recents:
            return Strings.Localizable.Settings.UserInterface.HideRecentActivity.footer
            
        case .appIcon:
            return nil
            
        default:
            return nil
        }
    }
}
