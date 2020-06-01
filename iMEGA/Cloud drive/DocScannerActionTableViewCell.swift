
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
        switch cellType {
        case .upload:
            actionImageView.image = UIImage(named: "upload")
            actionLabel.text = NSLocalizedString("uploadToMega", comment: "")
        case .sendMessage:
            actionImageView.tintColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            actionImageView.image = UIImage(named: "sendMessage")
            actionLabel.text = NSLocalizedString("sendToContact", comment: "")
        }
    }
}
