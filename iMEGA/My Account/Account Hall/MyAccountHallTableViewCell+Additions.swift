import Accounts
import MEGADesignToken
import MEGAUIKit

extension MyAccountHallTableViewCell {
    private var pendingViewWidthConstraint: String {
        "pendingViewWidthConstraint"
    }
    
    private var pendingViewHeightConstraint: String {
        "pendingViewHeightConstraint"
    }
    
    func setup(data: MyAccountHallCellData) {
        if let sectionText = data.sectionText, sectionLabel != nil {
            sectionLabel.text = sectionText
        }
        
        if let icon = data.icon, iconImageView != nil {
            iconImageView.image = icon.withRenderingMode(.alwaysTemplate)
        }
        
        if data.isPendingViewVisible, let pendingText = data.pendingText, pendingLabel != nil, pendingView != nil {
            pendingLabel.text = pendingText
            pendingView.clipsToBounds = true
            pendingView.isHidden = false
        } else {
            setPendingViewSizeToZero()
            pendingView?.isHidden = true
        }
        
        if let promoText = data.promoText, promoLabel != nil, promoView != nil {
            promoLabel.text = promoText
            promoView.clipsToBounds = true
            promoView.isHidden = false
        } else {
            promoView?.isHidden = true
        }
        
        detailLabel?.text = data.detailText ?? ""
        
        if let storageText = data.storageText, storageLabel != nil {
            storageLabel.text = storageText
            storageLabel.textColor = TokenColors.Text.info
        }
        
        if let storageUsedText = data.storageUsedText, storageUsedLabel != nil {
            storageUsedLabel.text = storageUsedText
            storageUsedLabel.textColor = TokenColors.Text.info
        }
        
        if let transferText = data.transferText, transferLabel != nil {
            transferLabel.text = transferText
            transferLabel.textColor = TokenColors.Text.success
        }
        
        if let transferUsedText = data.transferUsedText, transferUsedLabel != nil {
            transferUsedLabel.text = transferUsedText
            transferUsedLabel.textColor = TokenColors.Text.success
        }
    }
    
    @objc func setupCell() {
        backgroundColor = TokenColors.Background.page
        
        if iconImageView != nil {
            iconImageView.tintColor = TokenColors.Icon.primary
        }
        
        if sectionLabel != nil {
            sectionLabel.textColor = UIColor.primaryTextColor()
        }
        
        if detailLabel != nil {
            detailLabel.textColor =  TokenColors.Text.secondary
        }
        
        if pendingView != nil {
            pendingView.backgroundColor = TokenColors.Components.interactive
            pendingLabel.textColor = TokenColors.Text.onColor
            layoutPendingView()
        }
        
        if promoView != nil {
            promoView.backgroundColor = TokenColors.Notifications.notificationSuccess
            promoLabel.textColor = TokenColors.Text.success
            promoView.layer.cornerRadius = 4.0
        }
    }
    
    // MARK: - Private
    private func layoutPendingView() {
        let pendingViewHeight = calculatePendingViewHeight()
        
        let widthConstraint = pendingView.constraint(with: pendingViewWidthConstraint) ?? {
            let constraint = pendingView.widthAnchor.constraint(greaterThanOrEqualToConstant: pendingViewHeight)
            constraint.identifier = pendingViewWidthConstraint
            return constraint
        }()
        
        let heightConstraint = pendingView.constraint(with: pendingViewHeightConstraint) ?? {
            let constraint = pendingView.heightAnchor.constraint(equalToConstant: pendingViewHeight)
            constraint.identifier = pendingViewHeightConstraint
            return constraint
        }()
        
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        
        pendingView.layer.cornerRadius = pendingViewHeight / 2
        pendingViewSpacingConstraint.isActive = false
        pendingViewSpacingConstraint.priority = UILayoutPriority(800)
    }
    
    private func setPendingViewSizeToZero() {
        guard pendingView != nil else { return }
        
        pendingViewSpacingConstraint.isActive = true
        pendingViewSpacingConstraint.priority = UILayoutPriority(1000)
        pendingViewSpacingConstraint.constant = 10
        pendingView.isHidden = true
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
