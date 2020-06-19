
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
    
    private func configure() {
        switch cellType {
        case .fileType:
            textLabel?.text = AMLocalizedString("File Type", "file type title, used in changing the export format of scaned doc")
            detailTextLabel?.text = UserDefaults.standard.string(forKey: DocScannerSaveSettingTableViewController.keys.docScanExportFileTypeKey)
        case .Quality:
            textLabel?.text = AMLocalizedString("Quality", "Quality title, used in changing the export quality of scaned doc")
            if let quality = DocScanQuality(rawValue:
                UserDefaults.standard.float(forKey: DocScannerSaveSettingTableViewController.keys.docScanQualityKey)
                ) {
                detailTextLabel?.text = quality.description
            }
        }
    }
}
