import Foundation

extension UIColor {
    
    // MARK: - Background
    
    @objc class func mnz_background() -> UIColor {
        .systemBackground
    }
    
    @objc class func mnz_tertiaryBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_gray3A3A3C()
            } else {
                return UIColor.mnz_black2C2C2E()
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
                return mnz_black2C2C2E()
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
                return mnz_grayE6E6E6()
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray3A3A3C()
            } else {
                return mnz_black2C2C2E()
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
                return UIColor.mnz_gray3A3A3C()
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
                return Colors.General.Black._161616.color
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
                return Colors.General.Gray.e6E6E6.color
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
                return Colors.General.Gray.e6E6E6.color
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Black._2c2c2e.color
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
                return mnz_grayE6E6E6()
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray545458()
            } else {
                return mnz_gray3A3A3C()
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
                return Colors.Chat.ReactionBubble.selectedLight.color
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        case .dark:
            if selected {
                return Colors.Chat.ReactionBubble.selectedDark.color
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        @unknown default:
            if selected {
                return Colors.Chat.ReactionBubble.selectedLight.color
            } else {
                return Colors.Chat.ReactionBubble.unselectedDefault.color
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
                return Colors.General.White.fafafa.color
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Black._2c2c2e.color
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
                return UIColor.mnz_whiteF2F2F2()
            } else {
                return UIColor.mnz_whiteEEEEEE()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_gray3F3F42()
            } else {
                return UIColor.mnz_black2C2C2E()
            }
            
        @unknown default:
            return UIColor.mnz_whiteEEEEEE()
        }
    }
    
    @objc class func mnz_chatOutgoingBubble(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green007B62()
            } else {
                return UIColor.mnz_green009476()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green00C29A()
            } else {
                return UIColor.mnz_green00A382()
            }
            
        @unknown default:
            return UIColor.mnz_green009476()
        }
    }
    
    class func mnz_basicButton(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return .white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray._535356.color
            } else {
                return Colors.General.Gray._363638.color
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
                return Colors.General.Gray._3C3C43.color.withAlphaComponent(0.5)
            } else {
                return Colors.General.Gray._3C3C43.color.withAlphaComponent(0.3)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray._545458.color
            } else {
                return Colors.General.Gray._545458.color.withAlphaComponent(0.65)
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
                return Colors.General.Gray._04040F.color.withAlphaComponent(0.4)
            } else {
                return Colors.General.Gray._04040F.color.withAlphaComponent(0.15)
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray.ebebf5.color.withAlphaComponent(0.6)
            } else {
                return Colors.General.Gray.ebebf5.color.withAlphaComponent(0.3)
            }
            
        @unknown default:
            return .white
        }
    }
    
    @objc class func mnz_Elevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_grayE6E6E6()
            } else {
                return UIColor.whiteF7F7F7
            }
            
        case .dark:
            return UIColor.mnz_black2C2C2E()
            
        @unknown default:
            return UIColor.whiteF7F7F7
        }
    }
    
    // MARK: - Chat Reactions
    
    class func mnz_emojiLabelSelectedState(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green007B62()
            } else {
                return UIColor.mnz_green00A886()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_green00C29A()
            } else {
                return UIColor.mnz_green00A382()
            }
            
        @unknown default:
            return UIColor.mnz_green00A886()
        }
    }
    
    class func mnz_emoji(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_whiteF2F2F2()
            } else {
                return UIColor.mnz_whiteF7F7F7()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_gray3F3F42()
            } else {
                return UIColor.mnz_black2C2C2E()
            }
            
        @unknown default:
            return UIColor.mnz_whiteF7F7F7()
        }
    }
    
    // MARK: - Text
    
    @objc class func mnz_label() -> UIColor {
        .label
    }
    
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
                return mnz_grayE5E5E5()
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
                return mnz_gray3D3D3D()
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
            return mnz_whiteFCFCFC()
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_grayE5E5E5()
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return mnz_whiteFCFCFC()
        }
    }
    
    class func mnz_voiceRecordingViewButtonBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return mnz_gray515151()
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_grayE5E5E5()
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
            return mnz_gray3C3C43().withAlphaComponent(0.6)
            
        case .dark:
            return white.withAlphaComponent(0.6)
            
        @unknown default:
            return mnz_gray3C3C43().withAlphaComponent(0.6)
        }
    }
    
    // MARK: - Tints
    
    // MARK: Black
    
    class func mnz_black161616() -> UIColor {
        return Colors.General.Black._161616.color
    }
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        return UIColor.black1C1C1E
    }
    
    class func mnz_black2C2C2E() -> UIColor {
        return Colors.General.Black._2c2c2e.color
    }
    
    class func mnz_black252525() -> UIColor {
        return Colors.General.Black._252525.color
    }
    
    // MARK: Gray
    
    class func mnz_gray363638() -> UIColor {
        return Colors.General.Gray._363638.color
    }
    
    class func mnz_gray3A3A3C() -> UIColor {
        return Colors.General.Gray._3A3A3C.color
    }
    
    class func mnz_gray3C3C43() -> UIColor {
        return Colors.General.Gray._3C3C43.color
    }
    
    class func mnz_gray3D3D3D() -> UIColor {
        return Colors.General.Gray._3D3D3D.color
    }
    
    class func mnz_gray3F3F42() -> UIColor {
        return Colors.General.Gray._3F3F42.color
    }
    
    class func mnz_gray474747() -> UIColor {
        return Colors.General.Gray._474747.color
    }
    
    class func mnz_gray515151() -> UIColor {
        return UIColor.gray515151
    }
    
    class func mnz_gray535356() -> UIColor {
        return Colors.General.Gray._535356.color
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        return Colors.General.Gray._545458.color
    }
    
    class func mnz_gray545457() -> UIColor {
        return Colors.General.Gray._545457.color
    }
    
    class func mnz_gray676767() -> UIColor {
        return Colors.General.Gray._676767.color
    }
    
    class func mnz_gray848484() -> UIColor {
        return UIColor.gray848484
    }
    
    class func mnz_gray949494() -> UIColor {
        return Colors.General.Gray._949494.color
    }
    
    class func mnz_grayB5B5B5() -> UIColor {
        return UIColor.grayB5B5B5
    }
    
    class func mnz_grayBBBBBB() -> UIColor {
        return Colors.General.Gray.bbbbbb.color
    }
    
    class func mnz_grayC9C9C9() -> UIColor {
        return Colors.General.Gray.c9C9C9.color
    }
    
    class func mnz_grayD1D1D1() -> UIColor {
        return UIColor.grayD1D1D1
    }
    
    class func mnz_grayE2E2E2() -> UIColor {
        return Colors.General.Gray.e2E2E2.color
    }
    
    class func mnz_grayE5E5E5() -> UIColor {
        return Colors.General.Gray.e5E5E5.color
    }
    
    class func mnz_grayE6E6E6() -> UIColor {
        return Colors.General.Gray.e6E6E6.color
    }
    
    class func mnz_grayF4F4F4() -> UIColor {
        return Colors.General.Gray.f4F4F4.color
    }
    
    class func mnz_gray04040F() -> UIColor {
        return Colors.General.Gray._04040F.color
    }
    
    class func mnz_grayEBEBF5() -> UIColor {
        return Colors.General.Gray.ebebf5.color
    }
    
    class func mnz_gray333333() -> UIColor {
        return Colors.General.Gray._333333.color
    }
    
    class func mnz_grayBABABC() -> UIColor {
        return Colors.General.Gray.bababc.color
    }
    
    @objc class func mnz_grayDBDBDB() -> UIColor {
        Colors.General.Gray.dbdbdb.color
    }
    
    @objc(mnz_primaryGrayForTraitCollection:)
    class func mnz_primaryGray(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray._3D3D3D.color
            } else {
                return UIColor.gray515151
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray.e5E5E5.color
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
                return Colors.General.Gray._676767.color
            } else {
                return UIColor.gray848484
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray.c9C9C9.color
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
                return Colors.General.Gray._949494.color
            } else {
                return Colors.General.Gray.bbbbbb.color
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Gray.f4F4F4.color
            } else {
                return Colors.General.Gray.e2E2E2.color
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Blue
    
    class func mnz_blue0089C7() -> UIColor {
        return Colors.General.Blue._0089C7.color
    }
    
    class func mnz_blue009AE0() -> UIColor {
        return Colors.General.Blue._009Ae0.color
    }
    
    class func mnz_blue059DE2() -> UIColor {
        return Colors.General.Blue._059De2.color
    }
    
    class func mnz_blue38C1FF() -> UIColor {
        return Colors.General.Blue._38C1Ff.color
    }
    
    @objc(mnz_blueForTraitCollection:)
    class func mnz_blue(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Blue._0089C7.color
            } else {
                return Colors.General.Blue._009Ae0.color
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Blue._38C1Ff.color
            } else {
                return Colors.General.Blue._059De2.color
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
        return Colors.General.Green._00E9B9.color
    }
    
    class func mnz_green347467() -> UIColor {
        return UIColor.green347467
    }
    
    class func mnz_green009476() -> UIColor {
        return Colors.General.Green._009476.color
    }
    
    class func mnz_green007B62() -> UIColor {
        return Colors.General.Green._007B62.color
    }
    
    class func mnz_green00A382() -> UIColor {
        return Colors.General.Green._00A382.color
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
                return Colors.General.Green._00E9B9.color
            } else {
                return UIColor.green00C29A
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: Red
    
    class func mnz_redF30C14() -> UIColor {
        return Colors.General.Red.f30C14.color
    }
    
    class func mnz_redCE0A11() -> UIColor {
        return Colors.General.Red.ce0A11.color
    }
    
    class func mnz_redF7363D() -> UIColor {
        return Colors.General.Red.f7363D.color
    }
    
    class func mnz_redF95C61() -> UIColor {
        return Colors.General.Red.f95C61.color
    }
    
    class func mnz_redFF453A() -> UIColor {
        return UIColor.redFF453A
    }
    
    @objc(mnz_redForTraitCollection:)
    class func mnz_red(for traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Red.ce0A11.color
            } else {
                return Colors.General.Red.f30C14.color
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return Colors.General.Red.f95C61.color
            } else {
                return Colors.General.Red.f7363D.color
            }
            
        @unknown default:
            return .white
        }
    }
    
    // MARK: White
    
    class func mnz_whiteEEEEEE() -> UIColor {
        return Colors.General.White.eeeeee.color
    }
    
    class func mnz_whiteF2F2F2() -> UIColor {
        return Colors.General.White.f2F2F2.color
    }
    
    class func mnz_whiteFCFCFC() -> UIColor {
        return Colors.General.White.fcfcfc.color
    }
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        return UIColor.whiteF7F7F7
    }
    
    class func mnz_whiteEFEFEF() -> UIColor {
        return Colors.General.White.efefef.color
    }
    
    // MARK: Yellow
    
    class func mnz_yellowFED429() -> UIColor {
        return Colors.General.Yellow.fed429.color
    }
    
    class func mnz_yellow9D8319() -> UIColor {
        return Colors.General.Yellow._9D8319.color
    }
    
    class func mnz_yellowF8D552() -> UIColor {
        return Colors.General.Yellow.f8D552.color
    }

    @objc class func mnz_yellowFFCC00() -> UIColor {
        return UIColor.yellowFFCC00
    }

    // MARK: Brown
    
    class func mnz_brown544b27() -> UIColor {
        return Colors.General.Brown._544b27.color
    }
}
