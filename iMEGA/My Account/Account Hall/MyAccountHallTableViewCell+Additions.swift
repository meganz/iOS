import MEGADesignToken
import UIKit

extension MyAccountHallTableViewCell {
    func setup(data: MyAccountHallCellData) {
        if let sectionText = data.sectionText, sectionLabel != nil {
            sectionLabel.text = sectionText
        }
        
        if let icon = data.icon, iconImageView != nil {
            let image = UIColor.isDesignTokenEnabled() ? icon.withRenderingMode(.alwaysTemplate) : icon
            iconImageView.image = image
        }
        
        if data.isPendingViewVisible, let pendingText = data.pendingText, pendingLabel != nil, pendingView != nil {
            pendingLabel.text = pendingText
            pendingView.clipsToBounds = true
            pendingView.isHidden = false
        } else {
            pendingView?.isHidden = true
        }
        
        if let promoText = data.promoText, promoLabel != nil, promoView != nil {
            promoLabel.text = promoText
            promoView.clipsToBounds = true
            promoView.isHidden = false
        } else {
            promoView?.isHidden = true
        }
        
        if let detailText = data.detailText, detailLabel != nil {
            detailLabel.text = detailText
        }
        
        if let storageText = data.storageText, storageLabel != nil {
            storageLabel.text = storageText
            storageLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.info : UIColor.mnz_blue(for: traitCollection)
        }
        
        if let storageUsedText = data.storageUsedText, storageUsedLabel != nil {
            storageUsedLabel.text = storageUsedText
            storageUsedLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.info : UIColor.mnz_blue(for: traitCollection)
        }
        
        if let transferText = data.transferText, transferLabel != nil {
            transferLabel.text = transferText
            transferLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.success : .systemGreen
        }
        
        if let transferUsedText = data.transferUsedText, transferUsedLabel != nil {
            transferUsedLabel.text = transferUsedText
            transferUsedLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.success : .systemGreen
        }
    }
    
    private func layoutPendingView() {
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
    
    @objc func setupCell() {
        backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)

        if UIColor.isDesignTokenEnabled() && iconImageView != nil {
            iconImageView.tintColor = TokenColors.Icon.primary
        }
        
        if sectionLabel != nil {
            sectionLabel.textColor = UIColor.mnz_defaultLabelTextColor()
        }

        if detailLabel != nil {
            detailLabel.text = ""
            detailLabel.textColor = UIColor.mnz_secondaryLabelTextColor()
        }
        
        if pendingView != nil {
            pendingView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Components.interactive : UIColor.mnz_red(for: traitCollection)
            pendingLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : UIColor.mnz_badgeTextColor()
            layoutPendingView()
        }
        
        if promoView != nil {
            promoView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Support.success : UIColor.mnz_turquoise(for: traitCollection)
            promoLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : UIColor.mnz_whiteFFFFFF()
            promoView.layer.cornerRadius = 4.0
        }
    }
}

struct MyAccountHallCellData {
    var sectionText: String?
    var detailText: String?
    var icon: UIImage?
    var storageText: String?
    var transferText: String?
    var storageUsedText: String?
    var transferUsedText: String?
    var isPendingViewVisible: Bool = false
    var pendingText: String?
    var promoText: String?
}
