import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPreference
import UIKit

extension AdvancedTableViewController {
    @PreferenceWrapper(key: PreferenceKeyEntity.isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var isSaveMediaCapturedToGalleryEnabled: Bool
    
    // MARK: - UITableViewDataSource

    open override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader(in: section)
    }

    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }

    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else { return }
        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        titleForFooter(in: section)
    }

    private enum Section: CaseIterable {
        case transfers
        case downloadOptions
        case camera
    }

    private func titleForHeader(in section: Int) -> String? {
        switch Section.allCases[section] {
        case .transfers:
            return Strings.Localizable.transfers
        case .downloadOptions:
            return Strings.Localizable.downloadOptions
        case .camera:
            return Strings.Localizable.camera
        }
    }

    private func titleForFooter(in section: Int) -> String? {
        switch Section.allCases[section] {
        case .transfers:
            return Strings.Localizable.transfersSectionFooter
        case .downloadOptions:
            return Strings.Localizable.imagesAndOrVideosDownloadedWillBeStoredInTheDeviceSMediaLibraryInsteadOfTheOfflineSection
        case .camera:
            return Strings.Localizable.saveACopyOfTheImagesAndVideosTakenFromTheMEGAAppInYourDeviceSMediaLibrary
        }
    }

    // MARK: - UITableViewDelegate

    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }

        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }

    @objc func configureLabelAppearance() {
        savePhotosLabel.textColor = TokenColors.Text.primary
        saveVideosLabel.textColor = TokenColors.Text.primary
        saveMediaInGalleryLabel.textColor = TokenColors.Text.primary
        dontUseHttpLabel.textColor = TokenColors.Text.primary
    }
    
    @objc func hasSetIsSaveMediaCapturedToGalleryEnabled() -> Bool {
        return Self.$isSaveMediaCapturedToGalleryEnabled.existed
    }
    
    @objc func setIsSaveMediaCapturedToGalleryEnabled(_ enabled: Bool) {
        Self.isSaveMediaCapturedToGalleryEnabled = enabled
    }
    
    @objc func getIsSaveMediaCapturedToGalleryEnabled() -> Bool {
        Self.isSaveMediaCapturedToGalleryEnabled
    }
}

extension AdvancedTableViewController {
    @objc static let savePhotoToGalleryKey: String = PreferenceKeyEntity.savePhotoToGallery.rawValue
    @objc static let saveVideoToGalleryKey: String = PreferenceKeyEntity.saveVideoToGallery.rawValue
    
    @objc func setupForLiquidGlass() {
        guard #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() else {
            return
        }
        saveImagesButton.isHidden = true
        saveVideosButton.isHidden = true
        saveMediaInGalleryButton.isHidden = true
        saveImagesSwitch.isUserInteractionEnabled = true
        saveVideosSwitch.isUserInteractionEnabled = true
        saveMediaInGallerySwitch.isUserInteractionEnabled = true
    }
    
    func checkPhotosPermission(on switchControl: UISwitch, with persistenceCallback: @escaping (Bool) -> Void) {
        let isOn = switchControl.isOn
        guard isOn else {
            persistenceCallback(false)
            return
        }
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        permissionHandler.photosPermissionWithCompletionHandler {[weak switchControl] granted in
            persistenceCallback(granted)
            
            guard !granted else { return }
            PermissionAlertRouter
                .makeRouter(deviceHandler: permissionHandler)
                .alertPhotosPermission()
            
            guard let switchControl else { return }
            switchControl.setOn(false, animated: true)
        }
    }
    
    @IBAction func saveImagesSwitchValueChanged(_ sender: UISwitch) {
        checkPhotosPermission(on: sender) { enabled in
            UserDefaults.standard.set(enabled, forKey: AdvancedTableViewController.savePhotoToGalleryKey)
        }
    }

    @IBAction func saveVideosSwitchValueChanged(_ sender: UISwitch) {
        checkPhotosPermission(on: sender) { enabled in
            UserDefaults.standard.set(enabled, forKey: AdvancedTableViewController.saveVideoToGalleryKey)
        }
    }
    
    @IBAction func saveInLibrarySwitchValueChanged(_ sender: UISwitch) {
        checkPhotosPermission(on: sender) { [weak self] enabled in
            guard let self else { return }
            setIsSaveMediaCapturedToGalleryEnabled(enabled)
        }
    }
}
