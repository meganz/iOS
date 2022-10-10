import UIKit

extension MyAccountHallTableViewCell {
    func setup(data: MyAccountHallCellData) {
        if let sectionText = data.sectionText, sectionLabel != nil {
            sectionLabel.text = sectionText
        }
        
        if let icon = data.icon, iconImageView != nil {
            iconImageView.image = icon
        }
        
        if data.isPendingViewVisible, let pendingText = data.pendingText, pendingLabel != nil, pendingView != nil {
            pendingLabel.text = pendingText
            pendingView.clipsToBounds = true
            pendingView.isHidden = false
        }
        
        if let detailText = data.detailText, detailLabel != nil {
            detailLabel.text = detailText
        }
        
        if let storageText = data.storageText, storageLabel != nil {
            storageLabel.text = storageText
            storageLabel.textColor = UIColor.mnz_blue(for: traitCollection)
        }
        
        if let storageUsedText = data.storageUsedText, storageUsedLabel != nil {
            storageUsedLabel.text = storageUsedText
            storageUsedLabel.textColor = UIColor.mnz_blue(for: traitCollection)
        }
        
        if let transferText = data.transferText, transferLabel != nil {
            transferLabel.text = transferText
            transferLabel.textColor = .systemGreen
        }
        
        if let transferUsedText = data.transferUsedText, transferUsedLabel != nil {
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
