import Foundation
import MEGADesignToken
import MEGAPresentation

extension UIColor {
    
    // MARK: Chat
    
    @objc class func color(
        withChatStatus status: MEGAChatStatus
    ) -> UIColor? {
        let color: UIColor? = switch status {
        case .offline:
            TokenColors.Icon.disabled
        case .away:
            TokenColors.Indicator.yellow
        case .online:
            TokenColors.Indicator.green
        case .busy:
            TokenColors.Indicator.pink
        default: nil
        }
        
        return color
    }
    
    // MARK: - Background
    
    @objc class func mnz_tertiaryBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFFFFFF
        case .dark:
            return UIColor.black2C2C2E
            
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    // MARK: - Background Colors
    
    @objc class func surface1Background() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func pageBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    // MARK: Background miscellany
    
    @objc class func mnz_qr(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.proAccountRedProIII
            
        case .dark:
            return UIColor.whiteFFFFFF
            
        @unknown default:
            return UIColor.proAccountRedProIII
        }
    }
    
    @objc class func mnz_chatRichLinkContentBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFFFFFF
        case .dark:
            return  UIColor.black1C1C1E
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    // MARK: - Objects
    
    @objc class func borderStrong() -> UIColor {
        TokenColors.Border.strong
    }
    
    @objc class func supportInfoColor() -> UIColor {
        TokenColors.Support.info
    }
    
    @objc class func supportSuccessColor() -> UIColor {
        TokenColors.Support.success
    }
    
    // MARK: - PRO account colors
    
    @objc class func mnz_color(
        proLevel: MEGAAccountType
    ) -> UIColor? {
        var proLevelColor: UIColor?
        switch proLevel {
        case MEGAAccountType.free:
            proLevelColor = UIColor.systemGreen
            
        case MEGAAccountType.lite:
            proLevelColor = .proAccountLITE
            
        case MEGAAccountType.proI:
            proLevelColor = .proAccountRedProI
            
        case MEGAAccountType.proII:
            proLevelColor = .proAccountRedProII
            
        case MEGAAccountType.proIII:
            proLevelColor = .proAccountRedProIII
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    @objc class func mnz_colorForPriceLabel(
        proLevel: MEGAAccountType
    ) -> UIColor? {
        var proLevelColor: UIColor?
        switch proLevel {
        case MEGAAccountType.free:
            proLevelColor = UIColor.systemGreen
            
        case MEGAAccountType.lite:
            proLevelColor = .proAccountLITE
            
        case MEGAAccountType.proI, MEGAAccountType.proII, MEGAAccountType.proIII:
            proLevelColor = UIColor.mnz_red()
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    // MARK: - Input bar
    class func mnz_inputbarButtonBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor? {
        return (
            traitCollection.userInterfaceStyle == .dark
        )
        ? mnz_secondaryTextColor().withAlphaComponent(
            0.2
        )
        : mnz_secondaryTextColor().withAlphaComponent(
            0.04
        )
    }
    
    // MARK: - Toolbar
    
    class func mnz_toolbarTextColor(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return iconSecondaryColor()
        case .dark:
            return white
            
        @unknown default:
            return iconSecondaryColor()
        }
    }
    
    @objc class func barTint() -> UIColor {
        TokenColors.Icon.primary
    }
    
    // MARK: Gray
    
    @objc class func mnz_grayDBDBDB() -> UIColor {
        UIColor.grayDBDBDB
    }
    
    @objc class func iconSecondaryColor() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    @objc(
        mnz_tertiaryGrayForTraitCollection:
    )
    class func mnz_tertiaryGray(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.grayBBBBBB
            
        case .dark:
            return UIColor.grayE2E2E2
            
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    // MARK: Red
    
    @objc class func mnz_red() -> UIColor {
        TokenColors.Button.brand
    }
    
    @objc class func mnz_errorRed() -> UIColor {
        TokenColors.Text.error
    }
    
    // MARK: White
    
    @objc class func mnz_whiteFFFFFF() -> UIColor {
        UIColor.whiteFFFFFF
    }
    
    // MARK: Text color
    
    @objc class func primaryTextColor() -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc class func textInfoColor() -> UIColor {
        TokenColors.Text.info
    }
    
    @objc class func mnz_secondaryTextColor() -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc class func mnz_takenDownNodeTextColor() -> UIColor {
        TokenColors.Text.error
    }
    
    @objc class func whiteTextColor() -> UIColor {
        TokenColors.Text.onColor
    }
    
    @objc class func succeedTextColor() -> UIColor {
        TokenColors.Text.success
    }
}
