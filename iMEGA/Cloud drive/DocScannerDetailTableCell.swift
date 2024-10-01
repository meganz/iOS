import MEGADesignToken
import MEGAL10n
import UIKit

class DocScannerDetailTableCell: UITableViewCell {

    enum CellType: Int {
        case fileType
        case Quality
    }
    
    var cellType: CellType = .fileType {
        didSet {
            configure()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = TokenColors.Background.page
        textLabel?.textColor = TokenColors.Text.primary
        detailTextLabel?.textColor = TokenColors.Text.secondary
    }
    
    private func configure() {
        
        switch cellType {
        case .fileType:
            textLabel?.text = Strings.Localizable.fileType
            detailTextLabel?.text = UserDefaults.standard.string(forKey: DocScannerSaveSettingTableViewController.keys.docScanExportFileTypeKey)
        case .Quality:
            textLabel?.text = Strings.Localizable.quality
            let quality = DocScanQuality(
                rawValue: UserDefaults.standard.float(forKey: DocScannerSaveSettingTableViewController.keys.docScanQualityKey)
            ) ?? .best
            detailTextLabel?.text = quality.description
        }
    }
}
