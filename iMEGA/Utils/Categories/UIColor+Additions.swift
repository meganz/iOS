import Foundation

extension UIColor {
    
    // MARK: Chat
    @objc class func color(withChatStatus status: MEGAChatStatus) -> UIColor? {
        var color: UIColor?
        
        switch status {
        case .offline:
            color = mnz_primaryGray(for: UIScreen.main.traitCollection)
        case .away:
            color = .systemOrange
        case .online:
            color = systemGreen
        case .busy:
            color = mnz_red(for: UIScreen.main.traitCollection)
        default: break
        }
        
        return color
    }
    
    // MARK: - Background
    
    @objc class func mnz_tertiaryBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3A3A3C.uiColor
            } else {
                return MEGAAppColor.Black._2C2C2E.uiColor
            }
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    // MARK: Background elevated
    
    @objc class func mnz_backgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Black._2C2C2E.uiColor
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return white
        }
    }
    
    @objc class func mnz_secondaryBackgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    @objc class func mnz_tertiaryBackgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
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
    @objc(mnz_mainBarsForTraitCollection:)
    class func mnz_mainBars(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return .white
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return .black
            } else {
                return MEGAAppColor.Black._161616.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Background grouped
    
    @objc(mnz_backgroundGroupedForTraitCollection:)
    class func mnz_backgroundGrouped(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E6E6E6.uiColor
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            return .black
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Background grouped elevated
    
    @objc(mnz_secondaryBackgroundForTraitCollection:)
    class func mnz_secondaryBackground(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E6E6E6.uiColor
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Black._2C2C2E.uiColor
            } else {
                return MEGAAppColor.Black._1C1C1E.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc class func mnz_tertiaryBackgroundGroupedElevated(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    @objc class func mnz_qr(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.mnz_redProIII()
            
        case .dark:
            return MEGAAppColor.White._FFFFFF.uiColor
            
        @unknown default:
            return UIColor.mnz_redProIII()
        }
    }
    
    @objc class func mnz_chatLoadingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Black._00000060.uiColor
        case .dark:
            return MEGAAppColor.White._FFFFFF.uiColor.withAlphaComponent(0.15)
            
        @unknown default:
            return MEGAAppColor.Black._00000060.uiColor
        }
    }
    
    @objc class func mnz_chatRichLinkContentBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
        case .dark:
            return mnz_black1C1C1E()
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    @objc class func mnz_reactionBubbleBackgroundColor(_ traitCollection: UITraitCollection, selected: Bool) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if selected {
                return UIColor.chatReactionBubbleSelectedLight
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        case .dark:
            if selected {
                return UIColor.chatReactionBubbleSelectedDark
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        @unknown default:
            if selected {
                return UIColor.chatReactionBubbleSelectedLight
            } else {
                return UIColor.chatReactionBubbleUnselectedDefault
            }
        }
    }
    
    @objc(mnz_homeRecentsCellBackgroundForTraitCollection:)
    class func mnz_homeRecentsCellBackground(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.White._FFFFFF.uiColor
            
        case .dark:
            return MEGAAppColor.Black._1C1C1E.uiColor
            
        @unknown default:
            return MEGAAppColor.White._FFFFFF.uiColor
        }
    }
    
    @objc(mnz_notificationSeenBackgroundForTraitCollection:)
    class func mnz_notificationSeenBackground(for traitCollection: UITraitCollection) -> UIColor {
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
    @objc class func mnz_chatIncomingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.White._F2F2F2.uiColor
            } else {
                return MEGAAppColor.White._EEEEEE.uiColor
            }
            
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
    
    @objc class func mnz_chatOutgoingBubble(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    class func mnz_basicButton(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return .white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._535356.uiColor
            } else {
                return MEGAAppColor.Gray._363638.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc(mnz_separatorForTraitCollection:)
    class func mnz_separator(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(0.5)
            } else {
                return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(0.3)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._545458.uiColor
            } else {
                return MEGAAppColor.Gray._545458.uiColor.withAlphaComponent(0.65)
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc(mnz_handlebarForTraitCollection:)
    class func mnz_handlebar(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._04040F.uiColor.withAlphaComponent(0.4)
            } else {
                return MEGAAppColor.Gray._04040F.uiColor.withAlphaComponent(0.15)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._EBEBF5.uiColor.withAlphaComponent(0.6)
            } else {
                return MEGAAppColor.Gray._EBEBF5.uiColor.withAlphaComponent(0.3)
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc class func mnz_Elevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E6E6E6.uiColor
            } else {
                return MEGAAppColor.White._F7F7F7.uiColor
            }
            
        case .dark:
            return MEGAAppColor.Black._2C2C2E.uiColor
            
        @unknown default:
            return MEGAAppColor.White._F7F7F7.uiColor
        }
    }
    
    // MARK: - Chat Reactions
    
    class func mnz_emojiLabelSelectedState(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    class func mnz_emoji(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    @objc(mnz_subtitlesForTraitCollection:)
    class func mnz_subtitles(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: return UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        case .dark: return UIColor(white: 1, alpha: 0.8)
        @unknown default: return UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        }
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
    
    @objc class func mnz_color(proLevel: MEGAAccountType) -> UIColor? {
        var proLevelColor: UIColor?
        switch proLevel {
        case MEGAAccountType.free:
            proLevelColor = UIColor.systemGreen
            
        case MEGAAccountType.lite:
            proLevelColor = UIColor.mnz_proLITE()
            
        case MEGAAccountType.proI:
            proLevelColor = mnz_redProI()
            
        case MEGAAccountType.proII:
            proLevelColor = mnz_redProII()
            
        case MEGAAccountType.proIII:
            proLevelColor = mnz_redProIII()
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    @objc class func mnz_colorForPriceLabel(proLevel: MEGAAccountType, traitCollection: UITraitCollection) -> UIColor? {
        var proLevelColor: UIColor?
        switch proLevel {
        case MEGAAccountType.free:
            proLevelColor = UIColor.systemGreen
            
        case MEGAAccountType.lite:
            proLevelColor = UIColor.mnz_proLITE()
            
        case MEGAAccountType.proI, MEGAAccountType.proII, MEGAAccountType.proIII:
            proLevelColor = UIColor.mnz_red(for: traitCollection)
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    // MARK: - Input bar
    class func mnz_inputbarButtonBackground(_ traitCollection: UITraitCollection) -> UIColor? {
        let primaryGray = mnz_primaryGray(for: traitCollection)
        return (traitCollection.userInterfaceStyle == .dark)
        ? primaryGray.withAlphaComponent(0.2)
        : primaryGray.withAlphaComponent(0.04)
    }
    
    class func mnz_inputbarButtonImageTint(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    class func mnz_toolbarTextColor(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    // MARK: - Voice recording view
    
    class func mnz_voiceRecordingViewBackground(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    class func mnz_voiceRecordingViewButtonBackground(_ traitCollection: UITraitCollection) -> UIColor {
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
    
    class func emojiDescriptionTextColor(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(0.6)
            
        case .dark:
            return white.withAlphaComponent(0.6)
            
        @unknown default:
            return MEGAAppColor.Gray._3C3C43.uiColor.withAlphaComponent(0.6)
        }
    }
    
    // MARK: - Tints
    
    // MARK: Black
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        return MEGAAppColor.Black._1C1C1E.uiColor
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
    
    @objc(mnz_primaryGrayForTraitCollection:)
    class func mnz_primaryGray(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._3D3D3D.uiColor
            } else {
                return MEGAAppColor.Gray._515151.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Gray._E5E5E5.uiColor
            } else {
                return MEGAAppColor.Gray._D1D1D1.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc(mnz_secondaryGrayForTraitCollection:)
    class func mnz_secondaryGray(for traitCollection: UITraitCollection) -> UIColor {
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
            return .white
        }
    }
    
    @objc(mnz_tertiaryGrayForTraitCollection:)
    class func mnz_tertiaryGray(for traitCollection: UITraitCollection) -> UIColor {
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
            return .white
        }
    }
    
    // MARK: Blue
    
    @objc(mnz_blueForTraitCollection:)
    class func mnz_blue(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Blue._0089C7.uiColor
            } else {
                return MEGAAppColor.Blue._009AE0.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Blue._38C1FF.uiColor
            } else {
                return MEGAAppColor.Blue._059DE2.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Green
    
    @objc class func mnz_green00A886() -> UIColor {
        return MEGAAppColor.Green._00A886.uiColor
    }
    
    @objc(mnz_turquoiseForTraitCollection:)
    class func mnz_turquoise(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._347467.uiColor
            } else {
                return MEGAAppColor.Green._00A886.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Green._00E9B9.uiColor
            } else {
                return MEGAAppColor.Green._00C29A.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Red
    
    class func mnz_redFF453A() -> UIColor {
        MEGAAppColor.Red._FF453A.uiColor
    }
    
    @objc(mnz_redForTraitCollection:)
    class func mnz_red(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Red._CE0A11.uiColor
            } else {
                return MEGAAppColor.Red._F30C14.uiColor
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return MEGAAppColor.Red._F95C61.uiColor
            } else {
                return MEGAAppColor.Red._F7363D.uiColor
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: White
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        return MEGAAppColor.White._F7F7F7.uiColor
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
}
