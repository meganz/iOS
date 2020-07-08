
import UIKit

class DocScannerActionTableViewCell: UITableViewCell {
    @IBOutlet weak var actionImageView: UIImageView!
    @IBOutlet weak var actionLabel: UILabel!

    enum CellType: Int {
        case upload
        case sendMessage
    }
    
    var cellType: CellType = .upload {
        didSet {
            configure()
        }
    }
    
    private func configure() {
        backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
        
        switch cellType {
        case .upload:
            actionImageView.image = UIImage(named: "upload")
            actionLabel.text = AMLocalizedString("uploadToMega")
        case .sendMessage:
            actionImageView.tintColor = .mnz_primaryGray(for: self.traitCollection)
            actionImageView.image = UIImage(named: "sendMessage")
            actionLabel.text = AMLocalizedString("sendToContact")
        }
    }
}
