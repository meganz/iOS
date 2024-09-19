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
    
    // MARK: - Switcher
    @objc class func switchOnTintColor() -> UIColor {
        TokenColors.Support.success
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
    
    @objc class func mnz_backgroundElevated() -> UIColor {
        TokenColors.Background.page
    }
    
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
    
    // MARK: - Main Bar
    
    @objc class func mnz_navigationBarTitle(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc class func mnz_navigationBarTint(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        barTint(
            for: traitCollection
        )
    }
    
    @objc class func mnz_cellBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Background.page
    }
    
    @objc class func surface1Background() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func searchBarPageBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    // MARK: Cell related colors
    
    @objc class func cellTitleColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Text.primary
    }
    
    class func cellAccessoryColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Icon.secondary
    }
    
    // MARK: Icon tint color
    
    @objc
    class func secondaryIconTintColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Icon.secondary
    }
    
    // MARK: Background grouped
    
    @objc(
        mnz_backgroundGroupedForTraitCollection:
    )
    class func mnz_backgroundGrouped(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        pageBackgroundColor(
            for: traitCollection
        )
    }
    
    @objc(
        pageBackgroundForTraitCollection:
    )
    class func pageBackgroundColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Background.page
    }
    
    // MARK: Background grouped elevated
    
    @objc(
        mnz_secondaryBackgroundForTraitCollection:
    )
    class func mnz_secondaryBackground(
        for traitCollection: UITraitCollection
    ) -> UIColor {
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
                return  UIColor.mnz_secondaryBackground(
                    for: traitCollection
                )
            }
            
        case .dark:
            if selected {
                return UIColor.chatReactionBubbleSelectedDark
            } else {
                return  UIColor.mnz_secondaryBackground(
                    for: traitCollection
                )
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
    
    @objc class func mnz_Elevated() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func mnz_badgeTextColor() -> UIColor {
        TokenColors.Text.onColor
    }
    
    @objc class func mnz_secondaryLabelTextColor() -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc class func mnz_defaultLabelTextColor() -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc class func supportInfoColor() -> UIColor {
        TokenColors.Support.info
    }
    
    @objc class func supportSuccessColor() -> UIColor {
        TokenColors.Support.success
    }
    
    // MARK: - Chat Reactions
    
    @objc class func primaryTextColor() -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc class func secondaryTextColor() -> UIColor {
        TokenColors.Text.secondary
    }
    
    class func mnz_emojiLabelSelectedState(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Support.success
    }
    
    class func mnz_emoji(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Background.surface1
    }
    
    // MARK: - Text
    
    @objc class func mnz_subtitles() -> UIColor {
        TokenColors.Text.secondary
    }
    
    // MARK: - PRO account colors
    
    /**
     The color hex value is #FFA500
     
     - Returns: The color associated with the PRO LITE trademark.
     */
    @objc class func mnz_proLITE() -> UIColor {
        UIColor.proAccountLITE
    }
    
    @objc class func mnz_background() -> UIColor {
        TokenColors.Background.page
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
            proLevelColor = UIColor.mnz_red(
                for: traitCollection
            )
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    // MARK: - Input bar
    class func mnz_inputbarButtonBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor? {
        let primaryGray = mnz_primaryGray(
            for: traitCollection
        )
        return (
            traitCollection.userInterfaceStyle == .dark
        )
        ? primaryGray.withAlphaComponent(
            0.2
        )
        : primaryGray.withAlphaComponent(
            0.04
        )
    }
    
    class func mnz_inputbarButtonImageTint(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Icon.secondary
    }
    
    // MARK: - Toolbar
    
    class func mnz_toolbarTextColor(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return mnz_gray515151()
        case .dark:
            return white
            
        @unknown default:
            return mnz_gray515151()
        }
    }
    
    @objc class func mnz_toolbarTint(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        barTint(
            for: traitCollection
        )
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
    
    class func mnz_voiceRecordingViewButtonBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Icon.secondary
    }
    
    class func emojiDescriptionTextColor(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Border.strong
    }
    
    // MARK: Black
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        UIColor.black1C1C1E
    }
    
    @objc class func mnz_black000000() -> UIColor {
        TokenColors.Text.primary
    }
    
    // MARK: Gray
    
    class func mnz_gray3C3C43() -> UIColor {
        TokenColors.Border.strong
    }
    
    class func mnz_gray515151() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        TokenColors.Border.strong
    }
    
    class func mnz_gray545457() -> UIColor {
        UIColor.gray545457
    }
    
    class func mnz_gray848484() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    class func mnz_grayB5B5B5() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    class func mnz_grayD1D1D1() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    @objc class func mnz_grayDBDBDB() -> UIColor {
        UIColor.grayDBDBDB
    }
    
    @objc(
        mnz_primaryGrayForTraitCollection:
    )
    class func mnz_primaryGray(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc(
        mnz_secondaryGrayForTraitCollection:
    )
    class func mnz_secondaryGray(
        for traitCollection: UITraitCollection
    ) -> UIColor {
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
    
    // MARK: Blue
    
    @objc(
        mnz_blueForTraitCollection:
    )
    class func mnz_blue(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Text.info
    }
    
    // MARK: Green
    
    @objc class func mnz_green00A886() -> UIColor {
        TokenColors.Support.success
    }
    
    @objc class func mnz_green00FF00() -> UIColor {
        UIColor.green0CFF00
    }
    
    @objc(
        mnz_turquoiseForTraitCollection:
    )
    class func mnz_turquoise(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Support.success
    }
    
    // MARK: Red
    
    class func mnz_redFF453A() -> UIColor {
        UIColor.redFF453A
    }
    
    @objc class func mnz_redFF0000() -> UIColor {
        UIColor.redFF0000
    }
    
    @objc(
        mnz_redForTraitCollection:
    )
    class func mnz_red(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Button.brand
    }
    
    @objc(
        mnz_errorRedForTraitCollection:
    )
    class func mnz_errorRed(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Text.error
    }
    
    @objc(
        mnz_badgeRedForTraitCollection:
    )
    class func mnz_badgeRed(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Components.interactive
    }
    
    // MARK: White
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func mnz_whiteFFFFFF() -> UIColor {
        UIColor.whiteFFFFFF
    }
    
    // MARK: Yellow
    
    class func mnz_yellowFED429() -> UIColor {
        UIColor.yellowFED429
    }
    
    class func mnz_yellow9D8319() -> UIColor {
        UIColor.yellow9D8319
    }
    
    class func mnz_yellowF8D552() -> UIColor {
        UIColor.yellowF8D552
    }
    
    @objc class func mnz_yellowFFCC00() -> UIColor {
        UIColor.yellowFFCC00
    }
    
    // MARK: Brown
    
    class func mnz_brown544b27() -> UIColor {
        UIColor.brown544B27
    }
    
    // MARK: Private
    
    private class func barTint(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Icon.primary
    }
    
    // MARK: Text color
    
    @objc class func mnz_primaryTextColor() -> UIColor {
        TokenColors.Text.primary
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
