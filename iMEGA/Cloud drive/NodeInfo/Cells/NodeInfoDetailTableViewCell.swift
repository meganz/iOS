import MEGADesignToken
import MEGAL10n
import UIKit

class NodeInfoDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var keyLabel: MEGALabel!
    @IBOutlet weak var valueLabel: MEGALabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
        registerForTraitChanges()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #unavailable(iOS 17.0), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateAppearance()
        }
    }
    
    private func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        keyLabel.textColor = TokenColors.Text.secondary
    }
    
    func configure(forNode node: MEGANode, rowType: DetailsSectionRow, folderInfo: MEGAFolderInfo?) {
        valueLabel.textColor = TokenColors.Text.primary
        
        switch rowType {
        case .location:
            configureAsLocation(withNode: node)
        case .fileSize:
            configureAsFileSize(withNode: node)
        case .currentFileVersionSize:
            configureAsFileVersionSize(withNode: node)
        case .fileType:
            configureAsFileType(withNode: node)
        case .folderSize:
            configureAsFolderSize(withFolderInfo: folderInfo)
        case .currentFolderVersionsSize:
            configureAsCurrentFolderVersionsSize(withFolderInfo: folderInfo)
        case .previousFolderVersionsSize:
            configureAsPreviousFolderVersionsSize(withFolderInfo: folderInfo)
        case .countVersions:
            configureAsCountVersions(withFolderInfo: folderInfo)
        case .contains:
            configureAsContains(withFolderInfo: folderInfo)
        case .addedDate:
            configureAsAddedDate(withNode: node)
        case .modificationDate:
            configureAsModificationDate(withNode: node)
        case .linkCreationDate:
            configureAsLinkCreationDate(withNode: node)
        }
    }
    
    // MARK: - Private methods
    
    private func configureAsLocation(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.CloudDrive.Info.Node.location
        guard let parentNode = MEGASdk.shared.parentNode(for: node) else {
            return
        }
        if parentNode.type == .root {
            valueLabel.text = Strings.Localizable.cloudDrive
        } else {
            valueLabel.text = parentNode.name
        }
        valueLabel.textColor = TokenColors.Link.primary
    }
    
    private func configureAsCountVersions(withFolderInfo folderInfo: MEGAFolderInfo?) {
        keyLabel.text = Strings.Localizable.versions
        guard let versions = folderInfo?.versions else {
            fatalError("Could not get versions from folder info")
        }
        valueLabel.text = String(versions)
    }
    
    private func configureAsFileSize(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.totalSize
        valueLabel.text = node.mnz_numberOfVersions() == 0 ? Helper.size(for: node, api: MEGASdk.shared) : String.memoryStyleString(fromByteCount: node.mnz_versionsSize())
    }
    
    private func configureAsFileVersionSize(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.currentVersion
        valueLabel.text = Helper.size(for: node, api: MEGASdk.shared)
    }
    
    private func configureAsFileType(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.type
        valueLabel.text = node.mnz_fileType()
    }
    
    private func configureAsFolderSize(withFolderInfo folderInfo: MEGAFolderInfo?) {
        keyLabel.text = Strings.Localizable.totalSize
        let currentSize = folderInfo?.currentSize ?? 0
        let versionsSize = folderInfo?.versionsSize ?? 0
        let byteCount = currentSize + versionsSize
        valueLabel.text = String.memoryStyleString(fromByteCount: byteCount)
    }
    
    private func configureAsCurrentFolderVersionsSize(withFolderInfo folderInfo: MEGAFolderInfo?) {
        keyLabel.text = Strings.Localizable.currentVersion
        valueLabel.text = String.memoryStyleString(fromByteCount: folderInfo?.currentSize ?? 0)
    }
    
    private func configureAsPreviousFolderVersionsSize(withFolderInfo folderInfo: MEGAFolderInfo?) {
        keyLabel.text = Strings.Localizable.previousVersions
        valueLabel.text = String.memoryStyleString(fromByteCount: folderInfo?.versionsSize ?? 0)
    }
    
    private func configureAsContains(withFolderInfo folderInfo: MEGAFolderInfo?) {
        keyLabel.text = Strings.Localizable.contains
        valueLabel.text = NSString.mnz_string(byFiles: folderInfo?.files ?? 0, andFolders: folderInfo?.folders ?? 0)
    }
    
    private func configureAsAddedDate(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.added
        valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.creationTime ?? Date())
    }
    
    private func configureAsModificationDate(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.modified
        valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.modificationTime ?? Date())
    }
    
    private func configureAsLinkCreationDate(withNode node: MEGANode) {
        keyLabel.text = Strings.Localizable.linkCreation
        valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.publicLinkCreationTime ?? Date())
    }
    
}
