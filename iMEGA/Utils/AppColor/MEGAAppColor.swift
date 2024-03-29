import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

enum MEGAAppColor {
    enum White {
        case _FFFFFF
        case _FFFFFF_navigationBarTitle
        case _FFFFFF_text
        case _FFFFFF_pageBackground
        case _FFFFFF_toolbarShadow
        case _EEEEEE
        case _EFEFEF
        case _F2F2F2
        case _F7F7F7
        case _F7F7F7_pageBackground
        case _FAFAFA
        case _FCFCFC
        case _FFD60008
        case _FFFFFF00
        case _FFFFFF30
        case _FFFFFF32
        case _FFFFFF80
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._FFFFFF: TokenColors.Background.blur
            case ._FFFFFF_navigationBarTitle, ._FFFFFF_text: TokenColors.Text.primary
            case ._FFFFFF_pageBackground: TokenColors.Background.page
            case ._FFFFFF_toolbarShadow: TokenColors.Border.strong
            case ._EEEEEE: TokenColors.Background.blur
            case ._EFEFEF: TokenColors.Background.blur
            case ._F2F2F2: TokenColors.Background.blur
            case ._F7F7F7: TokenColors.Background.surface1
            case ._F7F7F7_pageBackground: TokenColors.Background.page
            case ._FAFAFA: TokenColors.Background.blur
            case ._FCFCFC: TokenColors.Background.blur
            case ._FFD60008: TokenColors.Background.blur
            case ._FFFFFF00: TokenColors.Background.blur
            case ._FFFFFF30: TokenColors.Background.blur
            case ._FFFFFF32: TokenColors.Background.blur
            case ._FFFFFF80: TokenColors.Text.secondary
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._FFFFFF, ._FFFFFF_pageBackground, ._FFFFFF_navigationBarTitle, ._FFFFFF_text: UIColor.whiteFFFFFF
            case ._FFFFFF_toolbarShadow: UIColor.whiteFFFFFF // Toolbar shadow is only applied when .designToken feature flag is on so this legacy color will never be used.
            case ._EEEEEE: UIColor.whiteEEEEEE
            case ._EFEFEF: UIColor.whiteEFEFEF
            case ._F2F2F2: UIColor.whiteF2F2F2
            case ._F7F7F7, ._F7F7F7_pageBackground: UIColor.whiteF7F7F7
            case ._FAFAFA: UIColor.whiteFAFAFA
            case ._FCFCFC: UIColor.whiteFCFCFC
            case ._FFD60008: UIColor.whiteFFD60008
            case ._FFFFFF00: UIColor.whiteFFFFFF00
            case ._FFFFFF30: UIColor.whiteFFFFFF30
            case ._FFFFFF32: UIColor.whiteFFFFFF32
            case ._FFFFFF80: UIColor.whiteFFFFFF80
            }
        }
    }
    
    enum Black {
        case _00000015
        case _00000025
        case _00000032
        case _00000060
        case _00000075
        case _00000080
        case _000000
        case _000000_text
        case _000000_pageBackground
        case _000000_toolbarShadow
        case _1C1C1E
        case _1C1C1E_pageBackground
        case _2C2C2E
        case _2C2C2E_pageBackground
        case _222222
        case _29292C
        case _161616
        case _252525
        case _363638
        case _404040
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._00000015: TokenColors.Background.blur
            case ._00000025: TokenColors.Background.blur
            case ._00000032: TokenColors.Background.blur
            case ._00000060: TokenColors.Background.blur
            case ._00000075: TokenColors.Background.blur
            case ._00000080: TokenColors.Text.secondary
            case ._000000: TokenColors.Text.primary
            case ._000000_text: TokenColors.Text.primary
            case ._000000_pageBackground: TokenColors.Background.page
            case ._000000_toolbarShadow: TokenColors.Border.strong
            case ._1C1C1E: TokenColors.Background.blur
            case ._1C1C1E_pageBackground: TokenColors.Background.page
            case ._222222: TokenColors.Background.blur
            case ._2C2C2E: TokenColors.Background.blur
            case ._2C2C2E_pageBackground: TokenColors.Background.page
            case ._29292C: TokenColors.Background.blur
            case ._161616: TokenColors.Background.surface1
            case ._252525: TokenColors.Background.blur
            case ._363638: TokenColors.Background.blur
            case ._404040: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._00000015: UIColor.black00000015
            case ._00000025: UIColor.black00000025
            case ._00000032: UIColor.black00000032
            case ._00000060: UIColor.black00000060
            case ._00000075: UIColor.black00000075
            case ._00000080: UIColor.black00000080
            case ._000000, ._000000_pageBackground, ._000000_text: UIColor.black000000
            case ._000000_toolbarShadow: UIColor.black000000 // Toolbar shadow is only applied when .designToken feature flag is on so this legacy color will never be used.
            case ._1C1C1E, ._1C1C1E_pageBackground: UIColor.black1C1C1E
            case ._222222: UIColor.black222222
            case ._2C2C2E, ._2C2C2E_pageBackground: UIColor.black2C2C2E
            case ._29292C: UIColor.black29292C
            case ._161616: UIColor.black161616
            case ._252525: UIColor.black252525
            case ._363638: UIColor.black363638
            case ._404040: UIColor.black404040
            }
        }
    }
    
    enum Gray {
        case _1D1D1D
        case _3A3A3C
        case _3A3A3C_pageBackground
        case _3C3C43
        case _3C3C4330
        case _3D3D3D
        case _3F3F42
        case _8E8E93
        case _9B9B9B
        case _545A68
        case _04040F
        case _332F2F
        case _333333
        case _363638
        case _474747
        case _515151
        case _515151_disabledBarButtonTitle
        case _515151_navigationBarTint
        case _515151_barButtonTitle
        case _535356
        case _545457
        case _545458
        case _54545865
        case _555555
        case _676767
        case _808080
        case _848484
        case _949494
        case _999999
        case _B5B5B5
        case _BABABC
        case _BBBBBB
        case _C4C4C4
        case _C4CCCC
        case _C9C9C9
        case _D1D1D1
        case _D1D1D1_disabledBarButtonTitle
        case _D1D1D1_navigationBarTint
        case _D1D1D1_barButtonTitle
        case _DBDBDB
        case _E2E2E2
        case _E4EBEA
        case _E5E5E5
        case _E6E6E6
        case _E6E6E6_pageBackground
        case _E8E8E8
        case _EBEBEB
        case _EBEBF5
        case _F4F4F4
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._1D1D1D: TokenColors.Background.surface1
            case ._3A3A3C: TokenColors.Background.blur
            case ._3A3A3C_pageBackground: TokenColors.Background.page
            case ._3C3C43, ._3C3C4330: TokenColors.Border.strong
            case ._3D3D3D: TokenColors.Background.blur
            case ._3F3F42: TokenColors.Background.blur
            case ._8E8E93: TokenColors.Background.blur
            case ._9B9B9B: TokenColors.Background.blur
            case ._545A68: TokenColors.Background.blur
            case ._04040F: TokenColors.Background.blur
            case ._332F2F: TokenColors.Background.blur
            case ._333333: TokenColors.Background.blur
            case ._363638: TokenColors.Background.blur
            case ._474747: TokenColors.Background.blur
            case ._515151: TokenColors.Icon.secondary
            case ._515151_disabledBarButtonTitle: TokenColors.Text.disabled
            case ._515151_navigationBarTint: TokenColors.Icon.primary
            case ._515151_barButtonTitle: TokenColors.Text.primary
            case ._535356: TokenColors.Background.blur
            case ._545457: TokenColors.Background.blur
            case ._545458, ._54545865: TokenColors.Border.strong
            case ._555555: TokenColors.Background.blur
            case ._676767: TokenColors.Background.blur
            case ._808080: TokenColors.Background.blur
            case ._848484: TokenColors.Icon.secondary
            case ._949494: TokenColors.Background.blur
            case ._999999: TokenColors.Background.blur
            case ._B5B5B5: TokenColors.Icon.secondary
            case ._BABABC: TokenColors.Background.blur
            case ._BBBBBB: TokenColors.Background.blur
            case ._C4C4C4: TokenColors.Background.blur
            case ._C4CCCC: TokenColors.Background.blur
            case ._C9C9C9: TokenColors.Background.blur
            case ._D1D1D1: TokenColors.Icon.secondary
            case ._D1D1D1_disabledBarButtonTitle: TokenColors.Text.disabled
            case ._D1D1D1_navigationBarTint: TokenColors.Icon.primary
            case ._D1D1D1_barButtonTitle: TokenColors.Text.primary
            case ._DBDBDB: TokenColors.Background.blur
            case ._E2E2E2: TokenColors.Background.blur
            case ._E4EBEA: TokenColors.Background.blur
            case ._E5E5E5: TokenColors.Background.blur
            case ._E6E6E6: TokenColors.Background.blur
            case ._E6E6E6_pageBackground: TokenColors.Background.page
            case ._E8E8E8: TokenColors.Background.blur
            case ._EBEBEB: TokenColors.Background.blur
            case ._EBEBF5: TokenColors.Background.blur
            case ._F4F4F4: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._1D1D1D: UIColor.gray1D1D1D
            case ._3A3A3C, ._3A3A3C_pageBackground: UIColor.gray3A3A3C
            case ._3C3C43: UIColor.gray3C3C43
            case ._3C3C4330: UIColor.gray3C3C4330
            case ._3D3D3D: UIColor.gray3D3D3D
            case ._3F3F42: UIColor.gray3F3F42
            case ._8E8E93: UIColor.gray8E8E93
            case ._9B9B9B: UIColor.gray9B9B9B
            case ._545A68: UIColor.gray545A68
            case ._04040F: UIColor.gray04040F
            case ._332F2F: UIColor.gray332F2F
            case ._333333: UIColor.gray333333
            case ._363638: UIColor.gray363638
            case ._474747: UIColor.gray474747
            case ._515151: UIColor.gray515151
            case ._515151_disabledBarButtonTitle: UIColor.gray51515130
            case ._515151_navigationBarTint: UIColor.gray515151
            case ._515151_barButtonTitle: UIColor.gray515151
            case ._535356: UIColor.gray535356
            case ._545457: UIColor.gray545457
            case ._545458: UIColor.gray545458
            case ._54545865: UIColor.gray54545865
            case ._555555: UIColor.gray555555
            case ._676767: UIColor.gray676767
            case ._808080: UIColor.gray808080
            case ._848484: UIColor.gray848484
            case ._949494: UIColor.gray949494
            case ._999999: UIColor.gray999999
            case ._B5B5B5: UIColor.grayB5B5B5
            case ._BABABC: UIColor.grayBABABC
            case ._BBBBBB: UIColor.grayBBBBBB
            case ._C4C4C4: UIColor.grayC4C4C4
            case ._C4CCCC: UIColor.grayC4CCCC
            case ._C9C9C9: UIColor.grayC9C9C9
            case ._D1D1D1: UIColor.grayD1D1D1
            case ._D1D1D1_disabledBarButtonTitle: UIColor.grayD1D1D130
            case ._D1D1D1_navigationBarTint: UIColor.grayD1D1D1
            case ._D1D1D1_barButtonTitle: UIColor.grayD1D1D1
            case ._DBDBDB: UIColor.grayDBDBDB
            case ._E2E2E2: UIColor.grayE2E2E2
            case ._E4EBEA: UIColor.grayE4EBEA
            case ._E5E5E5: UIColor.grayE5E5E5
            case ._E6E6E6, ._E6E6E6_pageBackground: UIColor.grayE6E6E6
            case ._E8E8E8: UIColor.grayE8E8E8
            case ._EBEBEB: UIColor.grayEBEBEB
            case ._EBEBF5: UIColor.grayEBEBF5
            case ._F4F4F4: UIColor.grayF4F4F4
            }
        }
    }
    
    enum Blue {
        case _00ACBF
        case _02A2FF
        case _007AFF
        case _009AE0
        case _38C1FF
        case _059DE2
        case _0089C7
        case _0095A6
        case _0274CC
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._00ACBF: TokenColors.Background.blur
            case ._02A2FF: TokenColors.Background.blur
            case ._007AFF: TokenColors.Background.blur
            case ._009AE0: TokenColors.Background.blur
            case ._38C1FF: TokenColors.Background.blur
            case ._059DE2: TokenColors.Background.blur
            case ._0089C7: TokenColors.Background.blur
            case ._0095A6: TokenColors.Background.blur
            case ._0274CC: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._00ACBF: UIColor.blue00ACBF
            case ._02A2FF: UIColor.blue02A2FF
            case ._007AFF: UIColor.blue007AFF
            case ._009AE0: UIColor.blue009AE0
            case ._38C1FF: UIColor.blue38C1FF
            case ._059DE2: UIColor.blue059DE2
            case ._0089C7: UIColor.blue0089C7
            case ._0095A6: UIColor.blue0095A6
            case ._0274CC: UIColor.blue0274CC
            }
        }
    }
    
    enum Brown {
        case _544B27
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._544B27: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._544B27: UIColor.brown544B27
            }
        }
    }
    
    enum Green {
        case _00A382
        case _00A886
        case _00A88680
        case _00C29A
        case _00C29A4D
        case _007B62
        case _00FF00
        case _34C759
        case _009476
        case _4AA588
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._00A382: TokenColors.Background.blur
            case ._00A886: TokenColors.Support.success
            case ._00A88680: TokenColors.Background.blur
            case ._00C29A: TokenColors.Support.success
            case ._00C29A4D: TokenColors.Background.blur
            case ._007B62: TokenColors.Background.blur
            case ._00FF00: TokenColors.Background.blur
            case ._34C759: TokenColors.Background.blur
            case ._009476: TokenColors.Background.blur
            case ._4AA588: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._00A382: UIColor.green00A382
            case ._00A886: UIColor.green00A886
            case ._00A88680: UIColor.green00A88680
            case ._00C29A: UIColor.green00C29A
            case ._00C29A4D: UIColor.green00C29A4D
            case ._007B62: UIColor.green007B62
            case ._00FF00: UIColor.green0CFF00
            case ._34C759: UIColor.green34C759
            case ._009476: UIColor.green009476
            case ._4AA588: UIColor.green4AA588
            }
        }
    }
    
    enum Orange {
        case _E68F4D
        case _F9B35F
        case _FF9500
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._E68F4D: TokenColors.Background.blur
            case ._F9B35F: TokenColors.Background.blur
            case ._FF9500: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._E68F4D: UIColor.orangeE68F4D
            case ._F9B35F: UIColor.orangeF9B35F
            case ._FF9500: UIColor.orangeFF9500
            }
        }
    }
    
    enum Red {
        case _CA75D1
        case _CE0A11
        case _F30C14
        case _F30C14_error
        case _F30C14_badge
        case _F95C61
        case _F288C2
        case _F7363D
        case _F7363D_error
        case _F7363D_badge
        case _FF0000
        case _FF3B30
        case _FF453A
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._CA75D1: TokenColors.Background.blur
            case ._CE0A11: TokenColors.Background.blur
            case ._F30C14: TokenColors.Button.brand
            case ._F30C14_error: TokenColors.Support.error
            case ._F30C14_badge: TokenColors.Components.interactive
            case ._F95C61: TokenColors.Background.blur
            case ._F288C2: TokenColors.Background.blur
            case ._F7363D: TokenColors.Button.brand
            case ._F7363D_error: TokenColors.Support.error
            case ._F7363D_badge: TokenColors.Components.interactive
            case ._FF0000: TokenColors.Background.blur
            case ._FF3B30: TokenColors.Background.blur
            case ._FF453A: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._CA75D1: UIColor.redCA75D1
            case ._CE0A11: UIColor.redCE0A11
            case ._F30C14, ._F30C14_error, ._F30C14_badge: UIColor.redF30C14
            case ._F95C61: UIColor.redF95C61
            case ._F288C2: UIColor.redF288C2
            case ._F7363D, ._F7363D_error, ._F7363D_badge: UIColor.redF7363D
            case ._FF0000: UIColor.redFF3B30
            case ._FF3B30: UIColor.redFF3B30
            case ._FF453A: UIColor.redFF453A
            }
        }
    }
    
    enum Yellow {
        case _9D8319
        case _F8D552
        case _FED42926
        case _FED429
        case _FFCC0003
        case _FFCC00
        case _FFD60A
        case _FFD600
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._9D8319: UIColor.yellow9D8319
            case ._F8D552: UIColor.yellowF8D552
            case ._FED42926: UIColor.yellowFED42926
            case ._FED429: UIColor.yellowFED429
            case ._FFCC0003: UIColor.yellowFFCC0003
            case ._FFCC00: UIColor.yellowFFCC00
            case ._FFD60A: UIColor.yellowFFD60A
            case ._FFD600: UIColor.yellowFFD600
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._9D8319: UIColor.yellow9D8319
            case ._F8D552: UIColor.yellowF8D552
            case ._FED42926: UIColor.yellowFED42926
            case ._FED429: UIColor.yellowFED429
            case ._FFCC0003: UIColor.yellowFFCC0003
            case ._FFCC00: UIColor.yellowFFCC00
            case ._FFD60A: UIColor.yellowFFD60A
            case ._FFD600: UIColor.yellowFFD600
            }
        }
    }
}
