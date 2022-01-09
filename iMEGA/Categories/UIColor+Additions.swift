
import Foundation

extension UIColor {
    
    // MARK: - Background
    
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
                return mnz_grayF7F7F7()
            }
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray3A3A3C()
            } else {
                return mnz_black2C2C2E()
            }
            
        @unknown default:
            return mnz_grayF7F7F7()
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
    
    @objc class func mnz_quaternaryBackgroundElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return UIColor.white.withAlphaComponent(0.78)
            
        case .dark:
            return mnz_black252525().withAlphaComponent(0.78)
            
        @unknown default:
            return UIColor.white
        }
    }
    
    // MARK: Background grouped
    
    @objc class func mnz_secondaryBackgroundGrouped(_ traitCollection: UITraitCollection) -> UIColor {
        return mnz_backgroundElevated(traitCollection)
    }
    
    @objc class func mnz_tertiaryBackgroundGrouped(_ traitCollection: UITraitCollection) -> UIColor {
        return mnz_secondaryBackgroundElevated(traitCollection)
    }
    
    // MARK: Background grouped elevated
    
    @objc class func mnz_backgroundGroupedElevated(_ traitCollection: UITraitCollection) -> UIColor {
        return mnz_secondaryBackground(for: traitCollection)
    }
    
    @objc class func mnz_secondaryBackgroundGroupedElevated(_ traitCollection: UITraitCollection) -> UIColor {
        return mnz_tertiaryBackground(traitCollection)
    }
    
    @objc class func mnz_tertiaryBackgroundGroupedElevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return mnz_grayE6E6E6()
            } else {
                return mnz_grayF7F7F7()
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
                let red: CGFloat = 0.0
                let green: CGFloat = 148.0/255.0
                let blue: CGFloat = 118.0/255.0
                let opacity: CGFloat = 0.1
                
                return UIColor(red: red, green: green, blue: blue, alpha: opacity)
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        case .dark:
            if selected {
                let red: CGFloat = 0
                let green: CGFloat = 163.0/255.0
                let blue: CGFloat = 130.0/255.0
                let opacity: CGFloat = 0.3
                
                return UIColor(red: red, green: green, blue: blue, alpha: opacity)
            } else {
                return  UIColor.mnz_secondaryBackground(for: traitCollection)
            }
            
        @unknown default:
            if selected {
                let red: CGFloat = 0
                let green: CGFloat = 148.0/255.0
                let blue: CGFloat = 118.0/255.0
                let opacity: CGFloat = 0.1
                
                return UIColor(red: red, green: green, blue: blue, alpha: opacity)
            } else {
                let red: CGFloat = 3.0/255
                let green: CGFloat = 3.0/255.0
                let blue: CGFloat = 3.0/255.0
                let opacity: CGFloat = 0.1
                
                return  UIColor(red:red, green: green, blue: blue, alpha: opacity)
            }
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
    
    @objc class func mnz_Elevated(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return UIColor.mnz_grayE6E6E6()
            } else {
                return UIColor.mnz_grayF7F7F7()
            }
            
        case .dark:
            return UIColor.mnz_black2C2C2E()
            
        @unknown default:
            return UIColor.mnz_grayF7F7F7()
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
    
    @objc class func mnz_secondaryLabel() -> UIColor {
        return UIColor.secondaryLabel
    }
    
    // MARK: - PRO account colors
    
    /**
     The color hex value is #FFA500
     
     - Returns: The color associated with the PRO LITE trademark.
     */
    @objc class func mnz_proLITE() -> UIColor {
        return UIColor.init(red: 1.0, green: 165.0/255.0, blue: 0.0, alpha: 1.0)
    }
    
    /**
     The color hex value is #E13339
     
     - Returns: The color associated with the PRO I trademark.
     */
    @objc class func mnz_redProI() -> UIColor {
        return UIColor.init(red: 225.0/255.0, green: 51.0/255.0, blue: 57.0/255.0, alpha: 1.0)
    }
    
    /**
     The color hex value is #DC191F
     
     - Returns: The color associated with the PRO II trademark.
     */
    @objc class func mnz_redProII() -> UIColor {
        return UIColor.init(red: 220.0/255.0, green: 25.0/255.0, blue: 31.0/255.0, alpha: 1.0)
    }
    
    /**
     The color hex value is #D90007
     
     - Returns: The color associated with the PRO III trademark.
     */
    @objc class func mnz_redProIII() -> UIColor {
        return UIColor.init(red: 217.0/255.0, green: 0, blue: 7.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_color(proLevel : MEGAAccountType) -> UIColor? {
        var proLevelColor: UIColor?
        switch (proLevel) {
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
    
    @objc class func mnz_colorForPriceLabel(proLevel : MEGAAccountType, traitCollection :UITraitCollection) -> UIColor? {
        var proLevelColor: UIColor?
        switch (proLevel) {
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
    
    class func mnz_toolbarButtonBackground(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return white
            
        case .dark:
            if traitCollection.accessibilityContrast == .high {
                return mnz_grayE5E5E5()
            } else {
                return mnz_black1C1C1E()
            }
            
        @unknown default:
            return white
        }
    }
    
    class func mnz_toolbarTextColor(_ traitCollection: UITraitCollection) -> UIColor {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            if traitCollection.accessibilityContrast == .high {
                return mnz_gray3D3D3D();
            } else {
                return mnz_gray515151();
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
    
    @objc class func mnz_black161616() -> UIColor {
        return UIColor.init(red: 22.0/255.0, green: 22.0/255.0, blue: 22.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_black1C1C1E() -> UIColor {
        return UIColor.init(red: 28.0/255.0, green: 28.0/255.0, blue: 30.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_black2C2C2E() -> UIColor {
        return UIColor.init(red: 44.0/255.0, green: 44.0/255.0, blue: 46.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_black252525() -> UIColor {
        return UIColor.init(red: 37.0/255.0, green: 37.0/255.0, blue: 37.0/255.0, alpha: 1.0)
    }
    
    // MARK: Gray
    
    @objc class func mnz_gray363638() -> UIColor {
        return UIColor.init(red: 54.0/255.0, green: 54.0/255.0, blue: 56.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray3A3A3C() -> UIColor {
        return UIColor.init(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray3C3C43() -> UIColor {
        return UIColor.init(red: 60.0/255.0, green: 60.0/255.0, blue: 67.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray3D3D3D() -> UIColor {
        return UIColor.init(red: 61.0/255.0, green: 61.0/255.0, blue: 61.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray3F3F42() -> UIColor {
        return UIColor.init(red: 63.0/255.0, green: 63.0/255.0, blue: 66.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray474747() -> UIColor {
        return UIColor(red: 71.0/255.0, green: 71.0/255.0, blue: 71.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray515151() -> UIColor {
        return UIColor.init(red: 81.0/255.0, green: 81.0/255.0, blue: 81.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray535356() -> UIColor {
        return UIColor.init(red: 83.0/255.0, green: 83.0/255.0, blue: 86.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray545458() -> UIColor {
        return UIColor.init(red: 84.0/255.0, green: 84.0/255.0, blue: 88.0/255.0, alpha: 1.0)
    }
    
    class func mnz_gray545457() -> UIColor {
        return UIColor.init(red: 84.0/255.0, green: 84.0/255.0, blue: 87.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray676767() -> UIColor {
        return UIColor.init(red: 103.0/255.0, green: 103.0/255.0, blue: 103.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray848484() -> UIColor {
        return UIColor.init(red: 132.0/255.0, green: 132.0/255.0, blue: 132.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray949494() -> UIColor {
        return UIColor.init(red: 148.0/255.0, green: 148.0/255.0, blue: 148.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayB5B5B5() -> UIColor {
        return UIColor.init(red: 181.0/255.0, green: 181.0/255.0, blue: 181.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayBBBBBB() -> UIColor {
        return UIColor.init(red: 187.0/255.0, green: 187.0/255.0, blue: 187.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayC9C9C9() -> UIColor {
        return UIColor.init(red: 201.0/255.0, green: 201.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayD1D1D1() -> UIColor {
        return UIColor.init(red: 209.0/255.0, green: 209.0/255.0, blue: 209.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayE2E2E2() -> UIColor {
        return UIColor.init(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayE5E5E5() -> UIColor {
        return UIColor.init(red: 229.0/255.0, green: 229.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayE6E6E6() -> UIColor {
        return UIColor.init(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_grayF4F4F4() -> UIColor {
        return UIColor.init(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_gray04040F() -> UIColor {
        return UIColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1.00)
    }
    
    @objc class func mnz_grayEBEBF5() -> UIColor {
        return UIColor(red: 0.92, green: 0.92, blue: 0.96, alpha: 1.00)
    }
    
    @objc class func mnz_gray333333() -> UIColor {
        return UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.00)
    }
    
    @objc class func mnz_grayBABABC() -> UIColor {
        return UIColor(red: 186.0/255.0, green: 186.0/255.0, blue: 186.0/255.0, alpha: 1.00)
    }
    
    // MARK: Blue
    
    @objc class func mnz_blue0089C7() -> UIColor {
        return UIColor.init(red: 0, green: 137.0/255.0, blue: 199.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_blue009AE0() -> UIColor {
        return UIColor.init(red: 0, green: 154.0/255.0, blue: 224.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_blue059DE2() -> UIColor {
        return UIColor.init(red: 5.0/255.0, green: 157.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_blue38C1FF() -> UIColor {
        return UIColor.init(red: 56.0/255.0, green: 193.0/255.0, blue: 1.0, alpha: 1.0)
    }
    
    // MARK: Green
    
    @objc class func mnz_green00A886() -> UIColor {
        return UIColor.init(red: 0, green: 168.0/255.0, blue: 134.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_green00C29A() -> UIColor {
        return UIColor.init(red: 0, green: 194.0/255.0, blue: 154.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_green00E9B9() -> UIColor {
        return UIColor.init(red: 0, green: 233.0/255.0, blue: 185.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_green347467() -> UIColor {
        return UIColor.init(red: 52.0/255.0, green: 116.0/255.0, blue: 103.0/255.0, alpha: 1.0)
    }
    
    class func mnz_green009476() -> UIColor {
        return UIColor.init(red: 0, green: 148.0/255.0, blue: 118.0/255.0, alpha: 1.0)
    }
    
    class func mnz_green007B62() -> UIColor {
        return UIColor.init(red: 0, green: 123.0/255.0, blue: 98.0/255.0, alpha: 1.0)
    }
    
    class func mnz_green00A382() -> UIColor {
        return UIColor.init(red: 0, green: 163.0/255.0, blue: 130.0/255.0, alpha: 1.0)
    }
    
    // MARK: Red
    
    @objc class func mnz_redF30C14() -> UIColor {
        return UIColor.init(red: 243.0/255.0, green: 12.0/255.0, blue: 20.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_redCE0A11() -> UIColor {
        return UIColor.init(red: 206.0/255.0, green: 10.0/255.0, blue: 17.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_redF7363D() -> UIColor {
        return UIColor.init(red: 247.0/255.0, green: 54.0/255.0, blue: 61.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_redF95C61() -> UIColor {
        return UIColor.init(red: 249.0/255.0, green: 92.0/255.0, blue: 97.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_redFF453A() -> UIColor {
        return UIColor.init(red: 1.0, green: 69.0/255.0, blue: 58.0/255.0, alpha: 1.0)
    }
    
    // MARK: White
    
    @objc class func mnz_whiteEEEEEE() -> UIColor {
        return UIColor.init(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_whiteF2F2F2() -> UIColor {
        return UIColor.init(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_whiteFCFCFC() -> UIColor {
        return UIColor.init(red: 252.0/255.0, green: 252.0/255.0, blue: 252.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_whiteF7F7F7() -> UIColor {
        return UIColor.init(red: 247.0/255.0, green:  247.0/255.0, blue:  247.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_whiteEFEFEF() -> UIColor {
        return UIColor.init(red: 239.0/255.0, green:  239.0/255.0, blue:  239.0/255.0, alpha: 1.0)
    }
    
    // MARK: Yellow
    
    @objc class func mnz_yellowFED429() -> UIColor {
        return UIColor.init(red: 254.0/255.0, green:  212.0/255.0, blue:  41.0/255.0, alpha: 0.22)
    }
    
    @objc class func mnz_yellow9D8319() -> UIColor {
        return UIColor.init(red: 157.0/255.0, green:  131.0/255.0, blue:  25.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_yellowF8D552() -> UIColor {
        return UIColor.init(red: 248.0/255.0, green:  213.0/255.0, blue:  82.0/255.0, alpha: 1.0)
    }
    
    // MARK: Brown
    
    @objc class func mnz_Brown544b27() -> UIColor {
        return UIColor.init(red: 84.0/255.0, green:  75.0/255.0, blue:  39.0/255.0, alpha: 1.0)
    }
}

