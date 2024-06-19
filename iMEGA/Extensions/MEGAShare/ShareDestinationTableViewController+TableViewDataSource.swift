import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

enum ShareDestinationSection: Int, CaseIterable {
    case destination = 0, attachments
}

enum ShareDestinationRow: Int, CaseIterable {
    case uploadToMega = 0, sendToChats
}

extension ShareDestinationTableViewController {
    // MARK: - Register cells
    @objc func registerCustomCells() {
        tableView.register(HostingTableViewCell<ShareAttachmentCellView>.self,
                           forCellReuseIdentifier: "ShareAttachmentCellView")
    }
    
    // MARK: - Cells
    private func attachmentFieldCell(_ indexPath: IndexPath) -> HostingTableViewCell<ShareAttachmentCellView> {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareAttachmentCellView", for: indexPath) as? HostingTableViewCell<ShareAttachmentCellView>,
              let attachment = ShareAttachment.attachmentsArray().object(at: indexPath.row) as? ShareAttachment else {
            return HostingTableViewCell<ShareAttachmentCellView>()
        }
        
        let viewModel = ShareAttachmentCellViewModel(attachment: attachment, index: indexPath.row)
        let cellView = ShareAttachmentCellView(viewModel: viewModel)
        cell.host(cellView, parent: self)
        cell.selectionStyle = .none
        return cell
    }
    
    private func destinationCell(_ indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "destinationCell", for: indexPath) as? ShareDestinationTableViewCell else {
            return UITableViewCell()
        }
        
        switch ShareDestinationRow(rawValue: indexPath.row) {
        case .uploadToMega:
            cell.set(name: Strings.Localizable.uploadToMega,
                     image: UIImage.upload)
        case .sendToChats:
            cell.set(name: Strings.Localizable.General.sendToChat,
                     image: UIImage.sendToChat,
                     isEnabled: isChatReady,
                     showActivityIndicator: !isChatReady)
        default: return cell
        }
        
        return cell
    }
    
    // MARK: - UITableView data source
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        ShareDestinationSection.allCases.count
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ShareDestinationSection(rawValue: section) {
        case .destination: return 2
        case .attachments: return ShareAttachment.attachmentsArray().count
        default: return 0
        }
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch ShareDestinationSection(rawValue: indexPath.section) {
        case .destination: return destinationCell(indexPath)
        case .attachments: return attachmentFieldCell(indexPath)
        default: return UITableViewCell()
        }
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
        tableViewHeaderFooterView.textLabel?.textColor = secondaryTextColor
    }
    
    private func titleForHeader(in section: Int) -> String? {
        switch ShareDestinationSection(rawValue: section) {
        case .destination:
            return Strings.Localizable.selectDestination
        case .attachments:
            let attachmentCount = ShareAttachment.attachmentsArray().count
            return Strings.Localizable.Extensions.Share.Destination.Section.files(attachmentCount)
        default:
            return ""
        }
    }
    
    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard ShareDestinationSection(rawValue: section) == .attachments else { return "" }
        return Strings.Localizable.tapFileToRename
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard ShareDestinationSection(rawValue: section) == .attachments,
              let footer = view as? UITableViewHeaderFooterView else { return }
        footer.textLabel?.textAlignment = .center
        footer.textLabel?.textColor = secondaryTextColor
    }
    
    private var designTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
    
    private var secondaryTextColor: UIColor {
        if designTokenEnabled {
            TokenColors.Text.secondary
        } else {
            UIColor.secondaryLabel
        }
    }
    
    private func separatorColor(for traitCollection: UITraitCollection) -> UIColor {
        if designTokenEnabled {
            return TokenColors.Border.strong
        } else {
            switch traitCollection.userInterfaceStyle {
            case .unspecified, .light:
                return UIColor.gray3C3C4330
            case .dark:
                return UIColor.gray54545865
            @unknown default:
                return UIColor.gray3C3C4330
            }
        }
    }
    
    private func secondaryBackground(for traitCollection: UITraitCollection) -> UIColor {
        if designTokenEnabled {
            return TokenColors.Background.page
        } else {
            switch traitCollection.userInterfaceStyle {
            case .unspecified, .light:
                return UIColor.whiteF7F7F7
            case .dark:
                return UIColor.black1C1C1E
            @unknown default:
                return UIColor.black1C1C1E
            }
        }
    }
    
    @objc func updateAppearance() {
        tableView.separatorColor = separatorColor(for: traitCollection)
        tableView.backgroundColor = secondaryBackground(for: traitCollection)
    }
}
