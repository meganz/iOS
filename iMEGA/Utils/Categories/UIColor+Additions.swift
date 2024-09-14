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
        MEGAAppColor.View.turquoise.uiColor
    }
    
    // MARK: - Background
    
    @objc class func mnz_tertiaryBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
        case .dark:
            return MEGAAppColor.Black._2C2C2E.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: Background elevated
    
    @objc class func mnz_backgroundElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF_pageBackground.uiColor
            
        case .dark:
            return MEGAAppColor.Black._1C1C1E_pageBackground.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF_pageBackground.uiColor
        }
    }
    
    @objc class func mnz_secondaryBackgroundElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E6E6E6.uiColor
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3A3A3C.uiColor
            } else {
                return MEGAAppColor.Black._2C2C2E.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._F7F7F7.uiColor
        }
    }
    
    @objc class func mnz_tertiaryBackgroundElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray545457()
            } else {
                return MEGAAppColor.Gray._3A3A3C.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: - Main Bar
    @objc(
        mnz_mainBarsForTraitCollection:
    )
    class func mnz_mainBars(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._F7F7F7.uiColor
            
        case .dark:
            return MEGAAppColor.Black._161616.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
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
    
    class func mnz_navigationBarButtonTitle(
        isEnabled: Bool,
        for traitCollection: UITraitCollection
    ) -> UIColor {
        barButtonTitle(
            isEnabled: isEnabled,
            for: traitCollection
        )
    }
    
    @objc class func mnz_cellBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF_pageBackground.uiColor
            
        case .dark:
            return MEGAAppColor.Black._2C2C2E_pageBackground.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF_pageBackground.uiColor
        }
    }
    
    @objc class func surfaceBackground() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func searchBarSurface1BackgroundColor() -> UIColor {
        TokenColors.Background.surface1
    }
    
    @objc class func searchBarPageBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    // MARK: Cell related colors
    
    @objc class func cellTitleColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Black._000000_text.uiColor
            
        case .dark:
            return MEGAAppColor.White._FFFFFF_text.uiColor
            
        @unknown default:
            return MEGAAppColor.Black._000000_text.uiColor
        }
    }
    
    class func cellAccessoryColor(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Gray._848484.uiColor
            
        case .dark:
            return MEGAAppColor.Gray._B5B5B5.uiColor
            
        @unknown default:
            return MEGAAppColor.Gray._848484.uiColor
        }
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
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._F7F7F7_pageBackground.uiColor
            
        case .dark:
            return MEGAAppColor.Black._000000_pageBackground.uiColor
            
        @unknown default:
            return MEGAAppColor.White._F7F7F7_pageBackground.uiColor
        }
    }
    
    // MARK: Background grouped elevated
    
    @objc(
        mnz_secondaryBackgroundForTraitCollection:
    )
    class func mnz_secondaryBackground(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._F7F7F7_pageBackground.uiColor
            
        case .dark:
            return MEGAAppColor.Black._1C1C1E_pageBackground.uiColor
            
        @unknown default:
            return MEGAAppColor.White._F7F7F7_pageBackground.uiColor
        }
    }
    
    @objc class func mnz_tertiaryBackgroundGroupedElevated(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E6E6E6.uiColor
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._545458.uiColor
            } else {
                return MEGAAppColor.Gray._3A3A3C.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: Background miscellany
    
    @objc class func mnz_qr(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.mnz_redProIII()
            
        case .dark:
            return MEGAAppColor.White._FFFFFF.uiColor
            
        @unknown default:
            return UIColor.mnz_redProIII()
        }
    }
    
    @objc class func mnz_chatLoadingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Black._00000060.uiColor
        case .dark:
            return MEGAAppColor.White._FFFFFF.uiColor.withAlphaComponent(
                0.15
            )
            
        @unknown default:
            return MEGAAppColor.Black._00000060.uiColor
        }
    }
    
    @objc class func mnz_chatRichLinkContentBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
        case .dark:
            return mnz_black1C1C1E()
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    @objc class func mnz_reactionBubbleBackgroundColor(
        _ traitCollection: UITraitCollection,
        selected: Bool
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if selected {
                return MEGAAppColor.Chat.chatReactionBubbleSelectedLight.uiColor
            } else {
                return  UIColor.mnz_secondaryBackground(
                    for: traitCollection
                )
            }
            
        case .dark:
            if selected {
                return MEGAAppColor.Chat.chatReactionBubbleSelectedDark.uiColor
            } else {
                return  UIColor.mnz_secondaryBackground(
                    for: traitCollection
                )
            }
            
        @unknown default:
            if selected {
                return MEGAAppColor.Chat.chatReactionBubbleSelectedLight.uiColor
            } else {
                return MEGAAppColor.Chat.chatReactionBubbleUnselectedDefault.uiColor
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
            return MEGAAppColor.White._FFFFFF.uiColor
            
        case .dark:
            return MEGAAppColor.Black._1C1C1E.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
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
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.White._F7F7F7.uiColor
            } else {
                return MEGAAppColor.White._FAFAFA.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Black._2C2C2E.uiColor
            } else {
                return MEGAAppColor.Black._1C1C1E.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: - Objects
    
    @objc class func mnz_chatIncomingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._EEEEEE.uiColor
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3F3F42.uiColor
            } else {
                return MEGAAppColor.Black._2C2C2E.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._EEEEEE.uiColor
        }
    }
    
    @objc class func mnz_chatOutgoingBubble(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._007B62.uiColor
            } else {
                return MEGAAppColor.Green._009476.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._00C29A.uiColor
            } else {
                return MEGAAppColor.Green._00A382.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.Green._009476.uiColor
        }
    }
    
    class func mnz_basicButton(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        TokenColors.Button.secondary
    }
    
    @objc(
        mnz_separatorForTraitCollection:
    )
    class func mnz_separator(
        for traitCollection: UITraitCollection
    ) -> UIColor {
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
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._04040F.uiColor.withAlphaComponent(
                    0.4
                )
            } else {
                return MEGAAppColor.Gray._04040F.uiColor.withAlphaComponent(
                    0.15
                )
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._EBEBF5.uiColor.withAlphaComponent(
                    0.6
                )
            } else {
                return MEGAAppColor.Gray._EBEBF5.uiColor.withAlphaComponent(
                    0.3
                )
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
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
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._007B62.uiColor
            } else {
                return UIColor.mnz_green00A886()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._00C29A.uiColor
            } else {
                return MEGAAppColor.Green._00A382.uiColor
            }
            
        @unknown default:
            return UIColor.mnz_green00A886()
        }
    }
    
    class func mnz_emoji(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.White._F2F2F2.uiColor
            } else {
                return UIColor.mnz_whiteF7F7F7()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3F3F42.uiColor
            } else {
                return MEGAAppColor.Black._2C2C2E.uiColor
            }
            
        @unknown default:
            return UIColor.mnz_whiteF7F7F7()
        }
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
        MEGAAppColor.Account.proAccountLite.uiColor
    }
    
    @objc class func mnz_background() -> UIColor {
        TokenColors.Background.page
    }
    
    /**
     The color hex value is #E13339
     
     - Returns: The color associated with the PRO I trademark.
     */
    @objc class func mnz_redProI() -> UIColor {
        MEGAAppColor.Account.proAccountRedProI.uiColor
    }
    
    /**
     The color hex value is #DC191F
     
     - Returns: The color associated with the PRO II trademark.
     */
    @objc class func mnz_redProII() -> UIColor {
        MEGAAppColor.Account.proAccountRedProII.uiColor
    }
    
    /**
     The color hex value is #D90007
     
     - Returns: The color associated with the PRO III trademark.
     */
    @objc class func mnz_redProIII() -> UIColor {
        MEGAAppColor.Account.proAccountRedProIII.uiColor
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
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E5E5E5.uiColor
            } else {
                return mnz_grayD1D1D1()
            }
            
        @unknown default:
            return white
        }
    }
    
    // MARK: - Toolbar
    
    class func mnz_toolbarTextColor(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3D3D3D.uiColor
            } else {
                return mnz_gray515151()
            }
            
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
    
    class func mnz_toolbarButtonTitle(
        isEnabled: Bool,
        for traitCollection: UITraitCollection
    ) -> UIColor {
        barButtonTitle(
            isEnabled: isEnabled,
            for: traitCollection
        )
    }
    
    class func mnz_toolbarShadow(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: MEGAAppColor.Black._000000_toolbarShadow.uiColor
        case .dark: MEGAAppColor.White._FFFFFF_toolbarShadow.uiColor
        @unknown default: MEGAAppColor.Black._000000_toolbarShadow.uiColor
        }
    }
    
    // MARK: - Voice recording view
    
    class func mnz_voiceRecordingViewBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FCFCFC.uiColor
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E5E5E5.uiColor
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return MEGAAppColor.White._FCFCFC.uiColor
        }
    }
    
    class func mnz_voiceRecordingViewButtonBackground(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return mnz_gray515151()
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E5E5E5.uiColor
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return mnz_gray515151()
        }
    }
    
    class func emojiDescriptionTextColor(
        _ traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(
                0.6
            )
            
        case .dark:
            return white.withAlphaComponent(
                0.6
            )
            
        @unknown default:
            return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(
                0.6
            )
        }
    }
    
    // MARK: - Tints
    
    // MARK: Black
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        return MEGAAppColor.Black._1C1C1E.uiColor
    }
    
    @objc class func mnz_black000000() -> UIColor {
        return MEGAAppColor.Black._000000.uiColor
    }
    
    // MARK: Gray
    
    class func mnz_gray3C3C43() -> UIColor {
        MEGAAppColor.Gray._3C3C43.uiColor
    }
    
    class func mnz_gray515151() -> UIColor {
        MEGAAppColor.Gray._515151.uiColor
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        MEGAAppColor.Gray._545458.uiColor
    }
    
    class func mnz_gray545457() -> UIColor {
        MEGAAppColor.Gray._545457.uiColor
    }
    
    class func mnz_gray848484() -> UIColor {
        MEGAAppColor.Gray._848484.uiColor
    }
    
    class func mnz_grayB5B5B5() -> UIColor {
        MEGAAppColor.Gray._B5B5B5.uiColor
    }
    
    class func mnz_grayD1D1D1() -> UIColor {
        MEGAAppColor.Gray._D1D1D1.uiColor
    }
    
    @objc class func mnz_grayDBDBDB() -> UIColor {
        MEGAAppColor.Gray._DBDBDB.uiColor
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
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._676767.uiColor
            } else {
                return MEGAAppColor.Gray._848484.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._C9C9C9.uiColor
            } else {
                return MEGAAppColor.Gray._B5B5B5.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    @objc(
        mnz_tertiaryGrayForTraitCollection:
    )
    class func mnz_tertiaryGray(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._949494.uiColor
            } else {
                return MEGAAppColor.Gray._BBBBBB.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._F4F4F4.uiColor
            } else {
                return MEGAAppColor.Gray._E2E2E2.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
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
        return MEGAAppColor.Green._00A886.uiColor
    }
    
    @objc class func mnz_green00FF00() -> UIColor {
        return MEGAAppColor.Green._00FF00.uiColor
    }
    
    @objc(
        mnz_turquoiseForTraitCollection:
    )
    class func mnz_turquoise(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Green._00A886.uiColor
            
        case .dark:
            return MEGAAppColor.Green._00C29A.uiColor
            
        @unknown default:
            return MEGAAppColor.Green._00A886.uiColor
        }
    }
    
    // MARK: Red
    
    class func mnz_redFF453A() -> UIColor {
        MEGAAppColor.Red._FF453A.uiColor
    }
    
    @objc class func mnz_redFF0000() -> UIColor {
        MEGAAppColor.Red._FF0000.uiColor
    }
    
    @objc(
        mnz_redForTraitCollection:
    )
    class func mnz_red(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Red._F30C14.uiColor
            
        case .dark:
            return MEGAAppColor.Red._F7363D.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
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
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Red._F30C14_badge.uiColor
            
        case .dark:
            return MEGAAppColor.Red._F7363D_badge.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: White
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        return MEGAAppColor.White._F7F7F7.uiColor
    }
    
    @objc class func mnz_whiteFFFFFF() -> UIColor {
        return MEGAAppColor.White._FFFFFF.uiColor
    }
    
    // MARK: Yellow
    
    class func mnz_yellowFED429() -> UIColor {
        MEGAAppColor.Yellow._FED429.uiColor
    }
    
    class func mnz_yellow9D8319() -> UIColor {
        MEGAAppColor.Yellow._9D8319.uiColor
    }
    
    class func mnz_yellowF8D552() -> UIColor {
        MEGAAppColor.Yellow._F8D552.uiColor
    }
    
    @objc class func mnz_yellowFFCC00() -> UIColor {
        MEGAAppColor.Yellow._FFCC00.uiColor
    }
    
    // MARK: Brown
    
    class func mnz_brown544b27() -> UIColor {
        MEGAAppColor.Brown._544B27.uiColor
    }
    
    // MARK: Private
    private class func barButtonTitle(
        isEnabled: Bool,
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: isEnabled ? MEGAAppColor.Gray._515151_barButtonTitle.uiColor : MEGAAppColor.Gray._515151_disabledBarButtonTitle.uiColor
        case .dark: isEnabled ? MEGAAppColor.Gray._D1D1D1_barButtonTitle.uiColor : MEGAAppColor.Gray._D1D1D1_disabledBarButtonTitle.uiColor
        @unknown default: MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    private class func barTint(
        for traitCollection: UITraitCollection
    ) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: MEGAAppColor.Gray._515151_navigationBarTint.uiColor
        case .dark: MEGAAppColor.Gray._D1D1D1_navigationBarTint.uiColor
        @unknown default: MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: Text color
    
    @objc class func mnz_primaryTextColor() -> UIColor {
        MEGAAppColor.Text.primary.uiColor
    }
    
    @objc class func mnz_secondaryTextColor() -> UIColor {
        MEGAAppColor.Text.secondary.uiColor
    }
    
    @objc class func mnz_takenDownNodeIconColor() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc class func mnz_takenDownNodeTextColor(for traitCollection: UITraitCollection) -> UIColor {
        TokenColors.Text.error
    }
    
    @objc class func whiteTextColor() -> UIColor {
        TokenColors.Text.onColor
    }
    
    @objc class func succeedTextColor() -> UIColor {
        TokenColors.Text.success
    }
}
