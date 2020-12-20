
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
        backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
        detailTextLabel?.textColor = .mnz_secondaryLabel()
        
        switch cellType {
        case .fileType:
            textLabel?.text = NSLocalizedString("File Type", comment: "file type title, used in changing the export format of scaned doc")
            detailTextLabel?.text = UserDefaults.standard.string(forKey: DocScannerSaveSettingTableViewController.keys.docScanExportFileTypeKey)
        case .Quality:
            textLabel?.text = NSLocalizedString("Quality", comment: "Quality title, used in changing the export quality of scaned doc")
            if let quality = DocScanQuality(rawValue:
                UserDefaults.standard.float(forKey: DocScannerSaveSettingTableViewController.keys.docScanQualityKey)
                ) {
                detailTextLabel?.text = quality.description
            }
        }
    }
}
