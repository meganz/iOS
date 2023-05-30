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
                     image: Asset.Images.ActionSheetIcons.upload.image)
        case .sendToChats:
            cell.set(name: Strings.Localizable.General.sendToChat,
                     image: Asset.Images.NodeActions.sendToChat.image,
                     isEnabled: isChatReady,
                     showActivityIndicator: !isChatReady)
        default: return cell
        }
        
        return cell
    }
    
    // MARK: - UITableView data source
    open override func numberOfSections(in tableView: UITableView) -> Int {
        2
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
    }
}
