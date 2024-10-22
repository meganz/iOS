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
    
    // MARK: Background elevated
    
    @objc class func mnz_secondaryBackgroundElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteF7F7F7
            
        case .dark:
            return UIColor.black2C2C2E
            
        @unknown default:
            return UIColor.whiteF7F7F7
        }
    }
    
    @objc class func mnz_tertiaryBackgroundElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFFFFFF
            
        case .dark:
            return UIColor.gray3A3A3C
            
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
    
    @objc class func mnz_chatLoadingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.black00000060
        case .dark:
            return UIColor.whiteFFFFFF.withAlphaComponent(
                0.15
            )
            
        @unknown default:
            return UIColor.black00000060
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
    
    @objc class func mnz_reactionBubbleBackgroundColor(
        _ traitCollection: UITraitCollection,
        selected: Bool
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if selected {
                return UIColor.chatReactionBubbleSelectedLight
            } else {
                return TokenColors.Background.page
            }
            
        case .dark:
            if selected {
                return UIColor.chatReactionBubbleSelectedDark
            } else {
                return TokenColors.Background.page
            }
            
        @unknown default:
            if selected {
                return UIColor.chatReactionBubbleSelectedLight
            } else {
                return UIColor.chatReactionBubbleSelectedDark
            }
        }
    }
    
    @objc(
        mnz_homeRecentsCellBackgroundForTraitCollection:
    )
    class func mnz_homeRecentsCellBackground(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFFFFFF
            
        case .dark:
            return UIColor.black1C1C1E
            
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    @objc(
        mnz_notificationSeenBackgroundForTraitCollection:
    )
    class func mnz_notificationSeenBackground(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFAFAFA
            
        case .dark:
            return UIColor.black1C1C1E
            
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    // MARK: - Objects
    
    @objc class func mnz_chatIncomingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteEEEEEE
        case .dark:
            return UIColor.black2C2C2E
            
        @unknown default:
            return UIColor.whiteEEEEEE
        }
    }
    
    @objc class func mnz_chatOutgoingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.green009476
            
        case .dark:
            return UIColor.green00A382
            
        @unknown default:
            return UIColor.green009476
        }
    }
    
    class func mnz_basicButton(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Button.secondary
    }
    
    @objc class func mnz_separator() -> UIColor {
        TokenColors.Border.strong
    }
    
    @objc(
        mnz_handlebarForTraitCollection:
    )
    class func mnz_handlebar(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.gray04040F.withAlphaComponent(0.15)
            
        case .dark:
            return UIColor.grayEBEBF5.withAlphaComponent(0.3)
            
        @unknown default:
            return UIColor.whiteFFFFFF
        }
    }
    
    @objc class func supportInfoColor() -> UIColor {
        TokenColors.Support.info
    }
    
    @objc class func supportSuccessColor() -> UIColor {
        TokenColors.Support.success
    }
    
    // MARK: - PRO account colors
    
    /**
     The color hex value is #FFA500
     
     - Returns: The color associated with the PRO LITE trademark.
     */
    @objc class func mnz_proLITE() -> UIColor {
        UIColor.proAccountLITE
    }
    
    /**
     The color hex value is #E13339
     
     - Returns: The color associated with the PRO I trademark.
     */
    @objc class func mnz_redProI() -> UIColor {
        UIColor.proAccountRedProI
    }
    
    /**
     The color hex value is #DC191F
     
     - Returns: The color associated with the PRO II trademark.
     */
    @objc class func mnz_redProII() -> UIColor {
        UIColor.proAccountRedProII
    }
    
    /**
     The color hex value is #D90007
     
     - Returns: The color associated with the PRO III trademark.
     */
    @objc class func mnz_redProIII() -> UIColor {
        UIColor.proAccountRedProIII
    }
    
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
        proLevel: MEGAAccountType,
        traitCollection: UITraitCollection
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
    
    class func barButtonTitleColor(isEnabled: Bool) -> UIColor {
        isEnabled ? TokenColors.Text.primary: TokenColors.Text.disabled
    }
    
    class func mnz_toolbarShadow(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Border.strong
    }
    
    // MARK: - Voice recording view
    
    class func mnz_voiceRecordingViewBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.whiteFCFCFC
            
        case .dark:
            return UIColor.black1C1C1E
            
        @unknown default:
            return UIColor.whiteFCFCFC
        }
    }
    
    // MARK: Gray
    
    class func mnz_gray3C3C43() -> UIColor {
        TokenColors.Border.strong
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        TokenColors.Border.strong
    }
    
    class func mnz_gray545457() -> UIColor {
        UIColor.gray545457
    }
    
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
    
    class func mnz_badgeRed() -> UIColor {
        TokenColors.Components.interactive
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
    
    @objc class func mnz_takenDownNodeIconColor() -> UIColor {
        TokenColors.Support.error
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
