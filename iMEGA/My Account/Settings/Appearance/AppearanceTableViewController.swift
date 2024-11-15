import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI
import UIKit

enum AppearanceSection: Int {
    case launch
    case layout
    case hiddenItems
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
    
    @IBOutlet weak var hiddenItemsViewLabel: UILabel!
    @IBOutlet weak var hiddenItemsViewSwitch: UISwitch!
    
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
        hiddenItemsViewLabel.text = Strings.Localizable.Settings.UserInterface.HiddenItems.label
        mediaDiscoveryViewLabel.text = Strings.Localizable.Settings.UserInterface.mediaDiscovery
        mediaDiscoverySubfolderLabel.text = Strings.Localizable.Settings.UserInterface.mediaDiscoverySubFolder
        hideRecentActivityLabel.text = Strings.Localizable.Settings.UserInterface.hideRecentActivity
        
        defaultIconLabel.text = Strings.Localizable.default
        dayIconLabel.text = Strings.Localizable.day.localizedCapitalized
        nightIconLabel.text = Strings.Localizable.night
        minimalIconLabel.text = Strings.Localizable.minimal
        
        defaultIconLabel.textColor = TokenColors.Text.onColor
        dayIconLabel.textColor = TokenColors.Text.onColor
        nightIconLabel.textColor = TokenColors.Text.onColor
        minimalIconLabel.textColor = TokenColors.Text.onColor
        
        Task { await loadSettings() }
        
        let alternateIconName = UIApplication.shared.alternateIconName
        selectIcon(with: alternateIconName)
        
        setupColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        defaultTabDetailLabel.text = TabManager.getPreferenceTab().title
    }
    
    // MARK: - Private
    private func loadSettings() async {
        mediaDiscoveryViewSwitch.isOn = await viewModel.fetchSettingValue(for: .autoMediaDiscoverySetting)
        mediaDiscoverySubfolderSwitch.isOn = await viewModel.fetchSettingValue(for: .mediaDiscoveryShouldIncludeSubfolderSetting)
        hideRecentActivitySwitch.isOn = await viewModel.fetchSettingValue(for: .hideRecentActivity)
        if viewModel.isAppearanceSectionVisible(section: .hiddenItems) {
            hiddenItemsViewSwitch.isOn = await viewModel.fetchSettingValue(for: .showHiddenItems)
        }
    }
    
    private func setupColors() {
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
        
        [defaultTabLabel, sortingAndViewModeLabel, sortingAndViewModeLabel, mediaDiscoveryViewLabel, mediaDiscoverySubfolderLabel, hideRecentActivityLabel, hiddenItemsViewLabel]
            .forEach { $0?.textColor = TokenColors.Text.primary }
        defaultTabDetailLabel.textColor = TokenColors.Text.secondary
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
        view.layer.borderColor = TokenColors.Border.strongSelected.cgColor
    }
    
    private func changeLabelWeight(to label: UILabel) {
        label.font = UIFont.preferredFont(style: .caption1, weight: .bold)
        label.textColor = TokenColors.Text.onColor
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
    @IBAction func hiddenItemsViewValueChanged(_ sender: UISwitch) {
        viewModel.saveSetting(for: .showHiddenItems(sender.isOn))
    }
    
    @IBAction func mediaDiscoveryViewValueChanged(_ sender: UISwitch) {
        viewModel.saveSetting(for: .autoMediaDiscoverySetting(sender.isOn))
    }
    
    @IBAction func mediaDiscoverySubfolderValueChanged(_ sender: UISwitch) {
        viewModel.saveSetting(for: .mediaDiscoveryShouldIncludeSubfolderSetting(sender.isOn))
    }
    
    @IBAction func hideRecentActivityValueChanged(_ sender: UISwitch) {
        viewModel.saveSetting(for: .hideRecentActivity(sender.isOn))
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.isAppearanceSectionVisible(section: AppearanceSection(rawValue: indexPath.section)) ? UITableView.automaticDimension : .leastNonzeroMagnitude
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }
    
    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else { return }
        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
        tableViewHeaderFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView
        else { return }
        
        tableViewHeaderFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader(in: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.isAppearanceSectionVisible(section: AppearanceSection(rawValue: section)) ? UITableView.automaticDimension : .leastNonzeroMagnitude
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.isAppearanceSectionVisible(section: AppearanceSection(rawValue: section)) ? 1 : 0
    }
    
    private func titleForHeader(in section: Int) -> String? {
        guard let appearanceSection = AppearanceSection(rawValue: section),
              viewModel.isAppearanceSectionVisible(section: appearanceSection) else {
            return nil
        }
        
        return switch appearanceSection {
        case .mediaDiscoverySubfolder:
            nil
        case .launch:
            Strings.Localizable.launch
        case .layout:
            Strings.Localizable.layout
        case .hiddenItems:
            Strings.Localizable.Settings.UserInterface.HiddenItems.header
        case .mediaDiscovery:
            Strings.Localizable.Settings.UserInterface.MediaDiscovery.header
        case .recents:
            Strings.Localizable.recents
        case .appIcon:
            Strings.Localizable.appIcon
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let appearanceSection = AppearanceSection(rawValue: section),
              viewModel.isAppearanceSectionVisible(section: appearanceSection) else {
            return nil
        }
        return switch appearanceSection {
        case .launch:
            Strings.Localizable.configureDefaultLaunchSection
        case .layout:
            Strings.Localizable.configureSortingOrderAndTheDefaultViewListOrThumbnail
        case .mediaDiscoverySubfolder:
            Strings.Localizable.Settings.UserInterface.MediaDiscoverySubFolder.footer
        case .recents:
            Strings.Localizable.Settings.UserInterface.HideRecentActivity.footer
        case .hiddenItems:
            Strings.Localizable.Settings.UserInterface.HiddenItems.footer
        case .appIcon, .mediaDiscovery:
            nil
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
                    linkUrl: linkUrl
                )
            }
        case .none, .launch, .layout, .hiddenItems, .mediaDiscoverySubfolder, .recents, .appIcon:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch AppearanceSection(rawValue: section) {
        case .launch, .layout, .recents, .appIcon, .mediaDiscovery, .none, .mediaDiscoverySubfolder, .hiddenItems:
            UITableView.automaticDimension
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
