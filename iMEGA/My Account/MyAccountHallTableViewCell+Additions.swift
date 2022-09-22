import UIKit

extension MyAccountHallTableViewCell {
    func setup(data: MyAccountHallCellData) {
        sectionLabel.text = data.sectionText
        iconImageView.image = data.icon
        pendingView.isHidden = !data.isPendingViewVisible
        if data.isPendingViewVisible {
            pendingLabel.text = data.pendingText
            pendingView.clipsToBounds = true
        }
        
        detailLabel.text = data.detailText
        
        if let storageText = data.storageText {
            storageLabel.text = storageText
            storageLabel.textColor = UIColor.mnz_blue(for: traitCollection)
        }
        
        if let storageUsedText = data.storageUsedText {
            storageUsedLabel.text = storageUsedText
            storageUsedLabel.textColor = UIColor.mnz_blue(for: traitCollection)
        }
        
        if let transferText = data.transferText {
            transferLabel.text = transferText
            transferLabel.textColor = .systemGreen
        }
        
        if let transferUsedText = data.transferUsedText {
            transferUsedLabel.text = transferUsedText
            transferUsedLabel.textColor = .systemGreen
        }
    }
}

struct MyAccountHallCellData {
    var sectionText: String? = nil
    var detailText: String? = nil
    var icon: UIImage? = nil
    var storageText: String? = nil
    var transferText: String? = nil
    var storageUsedText: String? = nil
    var transferUsedText: String? = nil
    var isPendingViewVisible: Bool = false
    var pendingText: String? = nil
}
