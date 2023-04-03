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
        } else {
            pendingView?.isHidden = true
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
    
    @objc func layoutPendingView() {
        let pendingViewHeight = calculatePendingViewHeight()
        
        NSLayoutConstraint.activate([
            pendingView.heightAnchor.constraint(equalToConstant: calculatePendingViewHeight()),
            pendingView.widthAnchor.constraint(greaterThanOrEqualToConstant: pendingViewHeight)
        ])
        
        pendingView.layer.cornerRadius = pendingViewHeight / 2
    }
    
    private func calculatePendingViewHeight() -> CGFloat {
        let verticalPadding: CGFloat = 4
        let calculateNotLabel = MEGALabel()
        calculateNotLabel.apply(style: .caption2, weight: .medium)
        calculateNotLabel.text = "1"
        
        let fitSize = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        return CGSize(width: fitSize.width, height: calculateNotLabel.sizeThatFits(fitSize).height).height + verticalPadding
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
