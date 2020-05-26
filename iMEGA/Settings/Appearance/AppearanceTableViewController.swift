
import UIKit

enum AppearanceSection: Int {
    case layout = 0
    case appIcon = 1
}

enum IconName: String {
    case day = "altIconDay"
    case night = "altIconNight"
    case minimal = "altIconMinimal"
}

class AppearanceTableViewController: UITableViewController {
    
    @IBOutlet weak var sortingAndViewModeLabel: UILabel!
    
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
        
        title = AMLocalizedString("Appearance", "Title of one of the Settings sections where you can customise the 'Appearance' of the app.")
        
        sortingAndViewModeLabel.text = AMLocalizedString("Sorting And View Mode", "Inside of Settings - Appearance, there is a view on which you can change the sorting preferences or the view mode preference for the app.")
        
        defaultIconLabel.text = AMLocalizedString("Default", "Label for any ‘Default’ button, link, text, title, etc. - (String as short as possible).")
        dayIconLabel.text = AMLocalizedString("Day", "Label for any ‘Day’ button, link, text, title, etc. - (String as short as possible).")
        nightIconLabel.text = AMLocalizedString("Night", "Label for any ‘Night’ button, link, text, title, etc. - (String as short as possible).")
        minimalIconLabel.text = AMLocalizedString("Minimal", "Label for any ‘Minimal’ button, link, text, title, etc. - (String as short as possible).")
        
        defaultIconLabel.textColor = UIColor.white
        dayIconLabel.textColor = UIColor.white
        nightIconLabel.textColor = UIColor.white
        minimalIconLabel.textColor = UIColor.white
        
        if #available(iOS 10.3, *) {
            let alternateIconName = UIApplication.shared.alternateIconName
            selectIcon(with: alternateIconName)
        } else {
            selectIcon(with: nil)
        }
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    // MARK: - Private
    
    func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        
        tableView.reloadData()
    }
    
    func selectIcon(with name: String?) {
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
    
    func markIcon(in view: UIView) {
        view.layer.borderColor = UIColor.white.cgColor
    }
    
    func changeLabelWeight(to label: UILabel) {
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor.white
    }
    
    func resetPreviousIcon(with name: String?) {
        switch name {
        case IconName.day.rawValue:
            dayIconContainerView.layer.borderColor = UIColor.clear.cgColor
            dayIconLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            
        case IconName.night.rawValue:
            nightIconContainerView.layer.borderColor = UIColor.clear.cgColor
            nightIconLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            
        case IconName.minimal.rawValue:
            minimalIconContainerView.layer.borderColor = UIColor.clear.cgColor
            minimalIconLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            
        default:
            defaultIconContainerView.layer.borderColor = UIColor.clear.cgColor
            defaultIconLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        }
    }
    
    func changeAppIcon(to iconName: String?) {
        if #available(iOS 10.3, *) {
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
    }
    
    // MARK: - IBActions
    
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
        switch section {
        case AppearanceSection.layout.rawValue:
            return AMLocalizedString("Layout", "Section title inside of Settings - Appearance, where you can change the app's layout distribution.")
            
        case AppearanceSection.appIcon.rawValue:
            return AMLocalizedString("App Icon", "Section title inside of Settings - Appearance, where you can change the app's icon.")
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case AppearanceSection.layout.rawValue:
            return AMLocalizedString("Configure sorting order and the default view (List or Thumbnail).", "Footer text to explain what you could do in the Settings - Appearance - Sorting And View Mode section.")
            
        case AppearanceSection.appIcon.rawValue:
            return nil
            
        default:
            return nil
        }
    }
}
