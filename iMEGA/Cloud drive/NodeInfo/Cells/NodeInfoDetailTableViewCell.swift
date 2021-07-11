import UIKit

class NodeInfoDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var keyLabel: MEGALabel!
    @IBOutlet weak var valueLabel: MEGALabel!
    
    func configure(forNode node: MEGANode, rowType: DetailsSectionRow, folderInfo: MEGAFolderInfo?) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
    
        valueLabel.textColor = UIColor.mnz_label()

        switch rowType {
        case .location:
            keyLabel.text = NSLocalizedString("location", comment: "Title label of a node property.")
            guard let paretnNode = MEGASdkManager.sharedMEGASdk().parentNode(for: node) else {
                return
            }
            if paretnNode.type == .root {
            valueLabel.text = NSLocalizedString("cloudDrive", comment: "Title of the Cloud Drive section")
            } else {
                valueLabel.text = paretnNode.name
            }
            valueLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
        case .fileSize:
            keyLabel.text = NSLocalizedString("totalSize", comment: "Size of the file or folder you are sharing")
            valueLabel.text = node.mnz_numberOfVersions() == 0 ? Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk()) : Helper.memoryStyleString(fromByteCount: node.mnz_versionsSize())
        case .currentFileVersionSize:
            keyLabel.text = NSLocalizedString("currentVersion", comment: "Title of section to display information of the current version of a file")
            valueLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
        case .fileType:
            keyLabel.text = NSLocalizedString("type", comment: "Refers to the type of a file or folder.")
            valueLabel.text = node.mnz_fileType()
        case .folderSize:
            keyLabel.text = NSLocalizedString("totalSize", comment: "Size of the file or folder you are sharing")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: (folderInfo?.currentSize ?? 0) + (folderInfo?.versionsSize ?? 0))
        case .currentFolderVersionsSize:
            keyLabel.text = NSLocalizedString("currentVersions", comment: "Title of section to display information of all current versions of files.")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.currentSize ?? 0)
        case .previousFolderVersionsSize:
            keyLabel.text = NSLocalizedString("previousVersions", comment: "A button label which opens a dialog to display the full version history of the selected file.")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.versionsSize ?? 0)
        case .countVersions:
            keyLabel.text = NSLocalizedString("versions", comment: "Title of section to display number of all historical versions of files")
            guard let versions = folderInfo?.versions else {
                fatalError("Could not get versions from folder info")
            }
            valueLabel.text = String(versions)
        case .contains:
            keyLabel.text = NSLocalizedString("contains", comment: "Label for what a selection contains.")
            valueLabel.text = NSString.mnz_string(byFiles: folderInfo?.files ?? 0, andFolders: folderInfo?.folders ?? 0)
        case .addedDate:
            keyLabel.text = NSLocalizedString("Added", comment: "A label for any ‘Added’ text or title. For example to show the upload date of a file/folder.")
            valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.creationTime)
        case .modificationDate:
            keyLabel.text = NSLocalizedString("modified", comment: "A label for any 'Modified' text or title.")
            valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.modificationTime)
        case .linkCreationDate:
            keyLabel.text = NSLocalizedString("Link Creation", comment: "Text referencing the date of creation of a link")
            valueLabel.text = DateFormatter.dateMediumTimeShort().localisedString(from: node.publicLinkCreationTime ?? Date())
        }
    }
    
    
}
