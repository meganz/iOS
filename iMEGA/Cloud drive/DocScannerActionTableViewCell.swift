import MEGAL10n
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
        backgroundColor = .mnz_backgroundElevated()
        
        switch cellType {
        case .upload:
            actionImageView.image = UIImage.upload
            actionLabel.text = Strings.Localizable.uploadToMega
        case .sendMessage:
            actionImageView.tintColor = .mnz_primaryGray(for: self.traitCollection)
            actionImageView.image = UIImage.sendToChat
            actionLabel.text = Strings.Localizable.General.sendToChat
        }
    }
}
