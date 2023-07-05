import UIKit

extension AdvancedTableViewController {
    
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
        cell.backgroundColor = .mnz_secondaryBackgroundGrouped(self.traitCollection)
    }
}
