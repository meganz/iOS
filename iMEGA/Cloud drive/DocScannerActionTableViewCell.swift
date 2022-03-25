
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
            actionImageView.image = Asset.Images.ActionSheetIcons.upload.image
            actionLabel.text = Strings.Localizable.uploadToMega
        case .sendMessage:
            actionImageView.tintColor = .mnz_primaryGray(for: self.traitCollection)
            actionImageView.image = Asset.Images.NodeActions.sendToChat.image
            actionLabel.text = Strings.Localizable.General.sendToChat
        }
    }
}
