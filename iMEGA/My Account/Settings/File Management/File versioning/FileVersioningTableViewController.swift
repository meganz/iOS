import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGAUIKit
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
        
        localizeText()
                
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        viewModel.dispatch(.onViewLoaded)
        setupColors()
    }
    
    // MARK: - private
    
    func localizeText() {
        title = Strings.Localizable.fileVersioning
        fileVersioningLabel.text = Strings.Localizable.fileVersioning
        fileVersionsLabel.text = Strings.Localizable.fileVersions
        deleteOldVersionsLabel.text = Strings.Localizable.deletePreviousVersions
    }
    
    @IBAction func fileVersioningSwitchValueChanged(_ sender: UISwitch) {
        if fileVersioningSwitch.isOn {
            viewModel.dispatch(.enableFileVersions)
        } else {
            viewModel.dispatch(.disableFileVersions)
        }
    }
    
    private func setupColors() {
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = TokenColors.Border.strong

        fileVersionsLabel.textColor = TokenColors.Text.primary
        fileVersioningLabel.textColor = TokenColors.Text.primary
        detailLabel.textColor = TokenColors.Text.secondary
        deleteOldVersionsLabel.textColor = TokenColors.Text.error
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
            return Strings.Localizable.deleteAllOlderVersionsOfMyFiles
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var title: String?
        switch section {
        case FileVersioningSettingsSection.fileVersioning.rawValue:
            title = Strings.Localizable.EnableOrDisableFileVersioningForYourEntireAccount.brYouMayStillReceiveFileVersionsFromSharedFoldersIfYourContactsHaveThisEnabled
            title = title?.replacingOccurrences(of: "\n", with: " ")
        case FileVersioningSettingsSection.fileVersions.rawValue:
            title = String(format: "%@ %@", Strings.Localizable.totalSizeTakenUpByFileVersions, fileVersionSize)
        case FileVersioningSettingsSection.deletePreviousVersions.rawValue:
            title = Strings.Localizable.AllCurrentFilesWillRemain.onlyHistoricVersionsOfYourFilesWillBeDeleted
        default:
            break
        }
        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == FileVersioningSettingsSection.deletePreviousVersions.rawValue {
            viewModel.dispatch(.deletePreviousVersions)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }

        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }

        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
}
