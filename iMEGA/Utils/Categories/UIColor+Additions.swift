import Foundation

extension UIColor {
    
    // MARK: - Background
    
    @objc class func mnz_tertiaryBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray3A3A3C
            } else {
                return UIColor.black2C2C2E
            }
            
        @unknown default:
            return UIColor.white
        }
    }
    
    // MARK: Background elevated
    
    @objc class func mnz_backgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.black2C2C2E
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
                return UIColor.grayE6E6E6
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray3A3A3C
            } else {
                return UIColor.black2C2C2E
            }
            
        @unknown default:
            return UIColor.whiteF7F7F7
        }
    }
    
    @objc class func mnz_tertiaryBackgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray545457()
            } else {
                return UIColor.gray3A3A3C
            }
            
        @unknown default:
            return UIColor.white
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
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return .black
            } else {
                return UIColor.black161616
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
                return UIColor.grayE6E6E6
            } else {
                return UIColor.whiteF7F7F7
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
                return UIColor.grayE6E6E6
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.black2C2C2E
            } else {
                return UIColor.black1C1C1E
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc class func mnz_tertiaryBackgroundGroupedElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayE6E6E6
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray545458
            } else {
                return UIColor.gray3A3A3C
            }
            
        @unknown default:
            return white
        }
    }
    
    // MARK: Background miscellany
    
    @objc class func mnz_qr(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.mnz_redProIII()
            
        case .dark:
            return UIColor.white
            
        @unknown default:
            return UIColor.mnz_redProIII()
        }
    }
    
    @objc class func mnz_chatLoadingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.black.withAlphaComponent(0.6)
            
        case .dark:
            return UIColor.white.withAlphaComponent(0.15)
            
        @unknown default:
            return UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    @objc class func mnz_chatRichLinkContentBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.white
        case .dark:
            return mnz_black1C1C1E()
        @unknown default:
            return UIColor.white
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
            return UIColor.white
            
        case .dark:
            return UIColor.black1C1C1E
            
        @unknown default:
            return UIColor.white
        }
    }
    
    @objc(mnz_notificationSeenBackgroundForTraitCollection:)
    class func mnz_notificationSeenBackground(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.whiteF7F7F7
            } else {
                return UIColor.whiteFAFAFA
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.black2C2C2E
            } else {
                return UIColor.black1C1C1E
            }
            
        @unknown default:
            return UIColor.white
        }
    }
    
    // MARK: - Objects
    @objc class func mnz_chatIncomingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.whiteF2F2F2
            } else {
                return UIColor.whiteEEEEEE
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray3F3F42
            } else {
                return UIColor.black2C2C2E
            }
            
        @unknown default:
            return UIColor.whiteEEEEEE
        }
    }
    
    @objc class func mnz_chatOutgoingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.green007B62
            } else {
                return UIColor.green009476
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green00C29A()
            } else {
                return UIColor.green00A382
            }
            
        @unknown default:
            return UIColor.green009476
        }
    }
    
    class func mnz_basicButton(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return .white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray535356
            } else {
                return UIColor.gray363638
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
                return UIColor.gray3C3C43.withAlphaComponent(0.5)
            } else {
                return UIColor.gray3C3C43.withAlphaComponent(0.3)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray545458
            } else {
                return UIColor.gray545458.withAlphaComponent(0.65)
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
                return UIColor.gray04040F.withAlphaComponent(0.4)
            } else {
                return UIColor.gray04040F.withAlphaComponent(0.15)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayEBEBF5.withAlphaComponent(0.6)
            } else {
                return UIColor.grayEBEBF5.withAlphaComponent(0.3)
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc class func mnz_Elevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayE6E6E6
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            return UIColor.black2C2C2E
            
        @unknown default:
            return UIColor.whiteF7F7F7
        }
    }
    
    // MARK: - Chat Reactions
    
    class func mnz_emojiLabelSelectedState(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.green007B62
            } else {
                return UIColor.mnz_green00A886()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green00C29A()
            } else {
                return UIColor.green00A382
            }
            
        @unknown default:
            return UIColor.mnz_green00A886()
        }
    }
    
    class func mnz_emoji(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.whiteF2F2F2
            } else {
                return UIColor.mnz_whiteF7F7F7()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray3F3F42
            } else {
                return UIColor.black2C2C2E
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
        return Colors.PROAccount.proLITE.color
    }
    
    /**
     The color hex value is #E13339
     
     - Returns: The color associated with the PRO I trademark.
     */
    @objc class func mnz_redProI() -> UIColor {
        return Colors.PROAccount.redProI.color
    }
    
    /**
     The color hex value is #DC191F
     
     - Returns: The color associated with the PRO II trademark.
     */
    @objc class func mnz_redProII() -> UIColor {
        return Colors.PROAccount.redProII.color
    }
    
    /**
     The color hex value is #D90007
     
     - Returns: The color associated with the PRO III trademark.
     */
    @objc class func mnz_redProIII() -> UIColor {
        return Colors.PROAccount.redProIII.color
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
                return UIColor.grayE5E5E5
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
                return UIColor.gray3D3D3D
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
            return UIColor.whiteFCFCFC
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayE5E5E5
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return UIColor.whiteFCFCFC
        }
    }
    
    class func mnz_voiceRecordingViewButtonBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return mnz_gray515151()
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayE5E5E5
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
            return UIColor.gray3C3C43.withAlphaComponent(0.6)
            
        case .dark:
            return white.withAlphaComponent(0.6)
            
        @unknown default:
            return UIColor.gray3C3C43.withAlphaComponent(0.6)
        }
    }
    
    // MARK: - Tints
    
    // MARK: Black
    
    class func mnz_black161616() -> UIColor {
        UIColor.black161616
    }
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        return UIColor.black1C1C1E
    }
    
    class func mnz_black2C2C2E() -> UIColor {
        UIColor.black2C2C2E
    }
    
    class func mnz_black252525() -> UIColor {
        UIColor.black252525
    }
    
    // MARK: Gray
    
    class func mnz_gray363638() -> UIColor {
        UIColor.gray363638
    }
    
    class func mnz_gray3A3A3C() -> UIColor {
        UIColor.gray3A3A3C
    }
    
    class func mnz_gray3C3C43() -> UIColor {
        UIColor.gray3C3C43
    }
    
    class func mnz_gray3D3D3D() -> UIColor {
        UIColor.gray3D3D3D
    }
    
    class func mnz_gray3F3F42() -> UIColor {
        UIColor.gray3F3F42
    }
    
    class func mnz_gray474747() -> UIColor {
        UIColor.gray474747
    }
    
    class func mnz_gray515151() -> UIColor {
        return UIColor.gray515151
    }
    
    class func mnz_gray535356() -> UIColor {
        UIColor.gray535356
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        UIColor.gray545458
    }
    
    class func mnz_gray545457() -> UIColor {
        UIColor.gray545457
    }
    
    class func mnz_gray676767() -> UIColor {
        UIColor.gray676767
    }
    
    class func mnz_gray848484() -> UIColor {
        return UIColor.gray848484
    }
    
    class func mnz_gray949494() -> UIColor {
        UIColor.gray949494
    }
    
    class func mnz_grayB5B5B5() -> UIColor {
        return UIColor.grayB5B5B5
    }
    
    class func mnz_grayBBBBBB() -> UIColor {
        UIColor.grayBBBBBB
    }
    
    class func mnz_grayC9C9C9() -> UIColor {
        UIColor.grayC9C9C9
    }
    
    class func mnz_grayD1D1D1() -> UIColor {
        return UIColor.grayD1D1D1
    }
    
    class func mnz_grayE2E2E2() -> UIColor {
        UIColor.grayE2E2E2
    }
    
    class func mnz_grayE5E5E5() -> UIColor {
        UIColor.grayE5E5E5
    }
    
    class func mnz_grayE6E6E6() -> UIColor {
        UIColor.grayE6E6E6
    }
    
    class func mnz_grayF4F4F4() -> UIColor {
        UIColor.grayF4F4F4
    }
    
    class func mnz_gray04040F() -> UIColor {
        UIColor.gray04040F
    }
    
    class func mnz_grayEBEBF5() -> UIColor {
        UIColor.grayEBEBF5
    }
    
    class func mnz_gray333333() -> UIColor {
        UIColor.gray333333
    }
    
    class func mnz_grayBABABC() -> UIColor {
        UIColor.grayBABABC
    }
    
    @objc class func mnz_grayDBDBDB() -> UIColor {
        UIColor.grayDBDBDB
    }
    
    @objc(mnz_primaryGrayForTraitCollection:)
    class func mnz_primaryGray(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.gray3D3D3D
            } else {
                return UIColor.gray515151
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayE5E5E5
            } else {
                return UIColor.grayD1D1D1
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
                return UIColor.gray676767
            } else {
                return UIColor.gray848484
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayC9C9C9
            } else {
                return UIColor.grayB5B5B5
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
                return UIColor.gray949494
            } else {
                return UIColor.grayBBBBBB
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.grayF4F4F4
            } else {
                return UIColor.grayE2E2E2
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Blue
    
    class func mnz_blue0089C7() -> UIColor {
        UIColor.blue0089C7
    }
    
    class func mnz_blue009AE0() -> UIColor {
        UIColor.blue009AE0
    }
    
    class func mnz_blue059DE2() -> UIColor {
        UIColor.blue059DE2
    }
    
    class func mnz_blue38C1FF() -> UIColor {
        UIColor.blue38C1FF
    }
    
    @objc(mnz_blueForTraitCollection:)
    class func mnz_blue(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.blue0089C7
            } else {
                return UIColor.blue009AE0
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.blue38C1FF
            } else {
                return UIColor.blue059DE2
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Green
    
    @objc class func mnz_green00A886() -> UIColor {
        return UIColor.green00A886
    }
    
    class func mnz_green00C29A() -> UIColor {
        return UIColor.green00C29A
    }
    
    class func mnz_green00E9B9() -> UIColor {
        UIColor.green00E9B9
    }
    
    class func mnz_green347467() -> UIColor {
        return UIColor.green347467
    }
    
    class func mnz_green009476() -> UIColor {
        UIColor.green009476
    }
    
    class func mnz_green007B62() -> UIColor {
        UIColor.green007B62
    }
    
    class func mnz_green00A382() -> UIColor {
        UIColor.green00A382
    }
    
    @objc(mnz_turquoiseForTraitCollection:)
    class func mnz_turquoise(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.green347467
            } else {
                return UIColor.green00A886
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.green00E9B9
            } else {
                return UIColor.green00C29A
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Red
    
    class func mnz_redF30C14() -> UIColor {
        UIColor.redF30C14
    }
    
    class func mnz_redCE0A11() -> UIColor {
        UIColor.redCE0A11
    }
    
    class func mnz_redF7363D() -> UIColor {
        UIColor.redF7363D
    }
    
    class func mnz_redF95C61() -> UIColor {
        UIColor.redF95C61
    }
    
    class func mnz_redFF453A() -> UIColor {
        return UIColor.redFF453A
    }
    
    @objc(mnz_redForTraitCollection:)
    class func mnz_red(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.redCE0A11
            } else {
                return UIColor.redF30C14
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.redF95C61
            } else {
                return UIColor.redF7363D
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: White
    
    class func mnz_whiteEEEEEE() -> UIColor {
        UIColor.whiteEEEEEE
    }
    
    class func mnz_whiteF2F2F2() -> UIColor {
        UIColor.whiteF2F2F2
    }
    
    class func mnz_whiteFCFCFC() -> UIColor {
        UIColor.whiteFCFCFC
    }
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        return UIColor.whiteF7F7F7
    }
    
    class func mnz_whiteEFEFEF() -> UIColor {
        UIColor.whiteEFEFEF
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
        return UIColor.yellowFFCC00
    }

    // MARK: Brown
    
    class func mnz_brown544b27() -> UIColor {
        UIColor.brown544B27
    }
}
