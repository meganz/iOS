import UIKit

class NodeInfoDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func configure(forNode node: MEGANode, rowType: DetailsSectionRow, folderInfo: MEGAFolderInfo?) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)

        valueLabel.textColor = UIColor.mnz_label()

        switch rowType {
        case .location:
            keyLabel.text = AMLocalizedString("location", "Title label of a node property.")
            valueLabel.text = MEGASdkManager.sharedMEGASdk().parentNode(for: node)?.name
            valueLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
        case .fileSize:
            keyLabel.text = AMLocalizedString("totalSize", "Size of the file or folder you are sharing")
            valueLabel.text = node.mnz_numberOfVersions() == 0 ? Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk()) : Helper.memoryStyleString(fromByteCount: node.mnz_versionsSize())
        case .currentFileVersionSize:
            keyLabel.text = AMLocalizedString("currentVersion", "Title of section to display information of the current version of a file")
            valueLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
        case .fileType:
            keyLabel.text = AMLocalizedString("type", "Refers to the type of a file or folder.")
            valueLabel.text = node.mnz_fileType()
        case .folderSize:
            keyLabel.text = AMLocalizedString("totalSize", "Size of the file or folder you are sharing")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: (folderInfo?.currentSize ?? 0) + (folderInfo?.versionsSize ?? 0))
        case .currentFolderVersionsSize:
            keyLabel.text = AMLocalizedString("currentVersions", "Title of section to display information of all current versions of files.")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.currentSize ?? 0)
        case .previousFolderVersionsSize:
            keyLabel.text = AMLocalizedString("previousVersions", "A button label which opens a dialog to display the full version history of the selected file.")
            valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.versionsSize ?? 0)
        case .countVersions:
            keyLabel.text = AMLocalizedString("versions", "Title of section to display number of all historical versions of files")
            guard let versions = folderInfo?.versions else {
                fatalError("Could not get versions from folder info")
            }
            valueLabel.text = String(versions)
        case .contains:
            keyLabel.text = AMLocalizedString("contains", "Label for what a selection contains.")
            valueLabel.text = NSString.mnz_string(byFiles: folderInfo?.files ?? 0, andFolders: folderInfo?.folders ?? 0)
        case .addedDate:
            keyLabel.text = AMLocalizedString("Added", "A label for any ‘Added’ text or title. For example to show the upload date of a file/folder.")
            valueLabel.text = (node.creationTime as NSDate).mnz_formattedDefaultDateForMedia()
        case .modificationDate:
            keyLabel.text = AMLocalizedString("modified", "A label for any 'Modified' text or title.")
            valueLabel.text = (node.modificationTime as NSDate).mnz_formattedDefaultDateForMedia()
        case .linkCreationDate:
            keyLabel.text = AMLocalizedString("Link Creation", "Text referencing the date of creation of a link")
            valueLabel.text = (node.modificationTime as NSDate).mnz_formattedDefaultDateForMedia()
        }
    }
}
