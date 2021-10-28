
import UIKit

enum FileVersioningSettingsSection: Int {
    case fileVersioning
    case fileVersions
    case deletePreviousVersions
}

final class FileVersioningTableViewController: UITableViewController, ViewType {
    
    @IBOutlet weak var fileVersionsLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var fileVersioningLabel: UILabel!
    @IBOutlet weak var fileVersioningSwitch: UISwitch!
    @IBOutlet weak var deleteOldVersionsLabel: UILabel!
    @IBOutlet weak var deleteOldVersionsCell: UITableViewCell!
    
    private var fileVersionSize = ""
    
    var viewModel: FileVersioningViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorAppearanceDidChange(to: traitCollection, from: nil)
        
        localizeText()
                
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        viewModel.dispatch(.onViewLoaded)
    }
    
    // MARK: - private
    
    func localizeText() {
        title = NSLocalizedString("File versioning", comment: "Title of the option to enable or disable file versioning on Settings section")
        fileVersioningLabel.text = NSLocalizedString("File versioning", comment:"Title of the option to enable or disable file versioning on Settings section")
        fileVersionsLabel.text = NSLocalizedString("File Versions", comment:"Settings preference title to show file versions info of the account")
        deleteOldVersionsLabel.text = NSLocalizedString("Delete Previous Versions", comment:"Text of a button which deletes all historical versions of files in the users entire account.")
    }
    
    @IBAction func fileVersioningSwitchValueChanged(_ sender: UISwitch) {
        if fileVersioningSwitch.isOn {
            viewModel.dispatch(.enableFileVersions)
        } else {
            viewModel.dispatch(.disableFileVersions)
        }
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: FileVersioningViewModel.Command) {
        switch command {
        case .updateSwitch(let enable):
            fileVersioningSwitch.setOn(enable, animated: false)
        case .updateFileVersions(let versions):
            detailLabel.text = "\(versions)"
            deleteOldVersionsCell.isUserInteractionEnabled = (versions > 0)
            deleteOldVersionsLabel.isEnabled =  (versions > 0)
        case .updateFileVersionsSize(let size):
            let byteCountFormatter = ByteCountFormatter()
            byteCountFormatter.countStyle = .memory
            let versionSizeString = byteCountFormatter.string(fromByteCount: size)
            fileVersionSize = versionSizeString
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == FileVersioningSettingsSection.deletePreviousVersions.rawValue {
            return NSLocalizedString("Delete all older versions of my files", comment: "The title of the section about deleting file versions in the settings.")
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var title: String?
        switch section {
        case FileVersioningSettingsSection.fileVersioning.rawValue:
            title = NSLocalizedString("Enable or disable file versioning for your entire account.[Br]You may still receive file versions from shared folders if your contacts have this enabled.", comment: "Subtitle of the option to enable or disable file versioning on Settings section")
            title = title?.replacingOccurrences(of: "\n", with: " ")
        case FileVersioningSettingsSection.fileVersions.rawValue:
            title = String(format: "%@ %@", NSLocalizedString("Total size taken up by file versions:", comment: ""), fileVersionSize)
        case FileVersioningSettingsSection.deletePreviousVersions.rawValue:
            title = NSLocalizedString("All current files will remain. Only historic versions of your files will be deleted.", comment: "A warning note about deleting all file versions in the settings section.")
        default:
            break;
        }
        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == FileVersioningSettingsSection.deletePreviousVersions.rawValue {
            viewModel.dispatch(.deletePreviousVersions)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension FileVersioningTableViewController: TraitEnviromentAware {
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: currentTrait)
        tableView.separatorColor = UIColor.mnz_separator(for: currentTrait)
        detailLabel.textColor = UIColor.mnz_secondaryLabel()
        deleteOldVersionsLabel.textColor = UIColor.mnz_red(for: currentTrait)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
}
