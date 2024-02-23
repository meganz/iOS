import MEGADesignToken
import MEGADomain
import MEGASDKRepo

extension TransferTableViewCell {
    @objc func transferStateOverQuotaTextColor() -> UIColor {
        TokenColors.Text.warning
    }
    
    @objc func transferStateOverQuotaIconColor() -> UIColor {
        TokenColors.Support.warning
    }

    @objc func transferStateErrorTextColor() -> UIColor {
        TokenColors.Text.error
    }
    
    @objc func transferStateErrorIconColor() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc func transferTypeColor(for type: MEGATransferType) -> UIColor {
        guard let transferType = TransferTypeEntity(transferType: type) else { return TokenColors.Icon.onColor }

        switch transferType {
        case .download: return TokenColors.Indicator.green
        case .upload: return TokenColors.Indicator.blue
        default: return TokenColors.Icon.onColor
        }
    }
    
    @objc func transferInfoColor(for type: MEGATransferType) -> UIColor {
        guard UIColor.isDesignTokenEnabled() else {
            return type == .download ? UIColor.systemGreen : UIColor.mnz_blue(for: traitCollection)
        }
        return TokenColors.Text.secondary
    }
    
    @objc func setTransferStateIcon(_ image: UIImage, color: UIColor) {
        guard UIColor.isDesignTokenEnabled() else {
            arrowImageView.image = image
            return
        }
        
        arrowImageView.image = image.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = color
    }
}
