import MEGAL10n
import SwiftUI
import UIKit

enum AppearanceSection: Int {
    case launch
    case layout
    case mediaDiscovery
    case mediaDiscoverySubfolder
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
    
    @IBOutlet weak var mediaDiscoveryViewLabel: UILabel!
    @IBOutlet weak var mediaDiscoveryViewSwitch: UISwitch!
    
    @IBOutlet weak var mediaDiscoverySubfolderLabel: UILabel!
    @IBOutlet weak var mediaDiscoverySubfolderSwitch: UISwitch!
    
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
    
    private let viewModel: AppearanceViewModel
    
    init?(coder: NSCoder, viewModel: AppearanceViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must create AppearanceTableViewController with a viewModel.")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title = Strings.Localizable.Settings.Section.userInterface
        self.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
        
        defaultTabLabel.text = Strings.Localizable.defaultTab
        
        sortingAndViewModeLabel.text = Strings.Localizable.sortingAndViewMode
        
        mediaDiscoveryViewLabel.text = Strings.Localizable.Settings.UserInterface.mediaDiscovery
        
        mediaDiscoverySubfolderLabel.text = Strings.Localizable.Settings.UserInterface.mediaDiscoverySubFolder
        
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
        
        mediaDiscoveryViewSwitch.isOn = viewModel.autoMediaDiscoverySetting
        mediaDiscoverySubfolderSwitch.isOn = viewModel.mediaDiscoveryShouldIncludeSubfolderSetting
        
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
    @IBAction func mediaDiscoveryViewValueChanged(_ sender: UISwitch) {
        viewModel.autoMediaDiscoverySetting = sender.isOn
    }
    @IBAction func mediaDiscoverySubfolderValueChanged(_ sender: UISwitch) {
        viewModel.mediaDiscoveryShouldIncludeSubfolderSetting = sender.isOn
    }
    
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
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }
    
    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else { return }
        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       titleForHeader(in: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch AppearanceSection(rawValue: section) {
        case .none, .mediaDiscoverySubfolder:
            return .leastNonzeroMagnitude
        case .launch, .layout, .recents, .appIcon:
            return UITableView.automaticDimension
        case .mediaDiscovery:
            guard viewModel.showMediaDiscoverySetting else {
                return .leastNonzeroMagnitude
            }
            return UITableView.automaticDimension
        }
    }
    
    private func titleForHeader(in section: Int) -> String? {
        switch AppearanceSection(rawValue: section) {
        case .none, .mediaDiscoverySubfolder:
            return nil
        case .launch:
            return Strings.Localizable.launch
        case .layout:
            return Strings.Localizable.layout
        case .mediaDiscovery:
            guard viewModel.showMediaDiscoverySetting else {
                return nil
            }
            return Strings.Localizable.Settings.UserInterface.MediaDiscovery.header
        case .recents:
            return Strings.Localizable.recents
        case .appIcon:
            return Strings.Localizable.appIcon
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch AppearanceSection(rawValue: section) {
        case .none:
            return .leastNonzeroMagnitude
        case .launch, .layout, .recents, .appIcon:
            return UITableView.automaticDimension
        case .mediaDiscovery, .mediaDiscoverySubfolder:
            guard viewModel.showMediaDiscoverySetting else {
                return .leastNonzeroMagnitude
            }
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch AppearanceSection(rawValue: section) {
        case .launch:
            return Strings.Localizable.configureDefaultLaunchSection
        case .layout:
            return Strings.Localizable.configureSortingOrderAndTheDefaultViewListOrThumbnail
        case .mediaDiscoverySubfolder:
            guard viewModel.showMediaDiscoverySetting else {
                return nil
            }
            return Strings.Localizable.Settings.UserInterface.MediaDiscoverySubFolder.footer
        case .recents:
            return Strings.Localizable.Settings.UserInterface.HideRecentActivity.footer
        case .appIcon, .mediaDiscovery, .none:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch AppearanceSection(rawValue: section) {
        case .launch, .layout, .recents, .appIcon:
            return 1
        case .mediaDiscovery, .mediaDiscoverySubfolder:
            return viewModel.showMediaDiscoverySetting ? 1 : 0
        case .none:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch AppearanceSection(rawValue: indexPath.section) {
        case .launch, .layout, .recents, .appIcon:
            return UITableView.automaticDimension
        case .mediaDiscovery, .mediaDiscoverySubfolder:
            return viewModel.showMediaDiscoverySetting ? UITableView.automaticDimension : .leastNormalMagnitude
        case .none:
            return .leastNonzeroMagnitude
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch AppearanceSection(rawValue: section) {
        case .mediaDiscovery:
            guard let linkUrl = viewModel.mediaDiscoveryHelpLink else {
                return nil
            }
            return makeFooterView {
                AppearanceListFooterWithLinkView(
                    message: Strings.Localizable.Settings.UserInterface.MediaDiscovery.Footer.body,
                    linkMessage: Strings.Localizable.Settings.UserInterface.MediaDiscovery.Footer.link,
                    linkUrl: linkUrl)
            }
        case .none, .launch, .layout, .mediaDiscoverySubfolder, .recents, .appIcon:
            return nil
        }
    }
    
    private func makeFooterView(@ViewBuilder content: () -> some View) -> UIView? {
        let hostingController = UIHostingController(rootView: content())
        guard let hostView = hostingController.view else {
            return nil
        }
        
        hostView.translatesAutoresizingMaskIntoConstraints = false
        hostView.backgroundColor = .clear
    
        let footerView = UITableViewHeaderFooterView()
        let contentView = footerView.contentView
        contentView.backgroundColor = .clear
        contentView.addSubview(hostView)

        NSLayoutConstraint.activate([
            hostView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 18),
            contentView.rightAnchor.constraint(equalTo: hostView.rightAnchor, constant: 18),
            hostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor, constant: 16)
        ])
        
        return footerView
    }
}
