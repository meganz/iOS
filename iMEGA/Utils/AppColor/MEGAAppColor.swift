import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

enum MEGAAppColor {
    enum White {
        case _FFFFFF
        case _EEEEEE
        case _EFEFEF
        case _F2F2F2
        case _F7F7F7
        case _FAFAFA
        case _FCFCFC
        case _FFD60008
        case _FFFFFF00
        case _FFFFFF30
        case _FFFFFF32
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._FFFFFF: TokenColors.Background.blur
            case ._EEEEEE: TokenColors.Background.blur
            case ._EFEFEF: TokenColors.Background.blur
            case ._F2F2F2: TokenColors.Background.blur
            case ._F7F7F7: TokenColors.Background.blur
            case ._FAFAFA: TokenColors.Background.blur
            case ._FCFCFC: TokenColors.Background.blur
            case ._FFD60008: TokenColors.Background.blur
            case ._FFFFFF00: TokenColors.Background.blur
            case ._FFFFFF30: TokenColors.Background.blur
            case ._FFFFFF32: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._FFFFFF: UIColor.whiteFFFFFF
            case ._EEEEEE: UIColor.whiteEEEEEE
            case ._EFEFEF: UIColor.whiteEFEFEF
            case ._F2F2F2: UIColor.whiteF2F2F2
            case ._F7F7F7: UIColor.whiteF7F7F7
            case ._FAFAFA: UIColor.whiteFAFAFA
            case ._FCFCFC: UIColor.whiteFCFCFC
            case ._FFD60008: UIColor.whiteFFD60008
            case ._FFFFFF00: UIColor.whiteFFFFFF00
            case ._FFFFFF30: UIColor.whiteFFFFFF30
            case ._FFFFFF32: UIColor.whiteFFFFFF32
            }
        }
    }
    
    enum Black {
        case _00000015
        case _00000025
        case _00000032
        case _00000060
        case _00000075
        case _000000
        case _1C1C1E
        case _2C2C2E
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
            case ._000000: TokenColors.Background.blur
            case ._1C1C1E: TokenColors.Background.blur
            case ._2C2C2E: TokenColors.Background.blur
            case ._29292C: TokenColors.Background.blur
            case ._161616: TokenColors.Background.blur
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
            case ._000000: UIColor.black000000
            case ._1C1C1E: UIColor.black1C1C1E
            case ._2C2C2E: UIColor.black2C2C2E
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
        case _3C3C43
        case _3D3D3D
        case _3F3F42
        case _8E8E93
        case _9B9B9B
        case _545A68
        case _04040F
        case _333333
        case _363638
        case _474747
        case _515151
        case _535356
        case _545457
        case _545458
        case _676767
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
        case _DBDBDB
        case _E2E2E2
        case _E5E5E5
        case _E6E6E6
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
            case ._1D1D1D: TokenColors.Background.blur
            case ._3A3A3C: TokenColors.Background.blur
            case ._3C3C43: TokenColors.Background.blur
            case ._3D3D3D: TokenColors.Background.blur
            case ._3F3F42: TokenColors.Background.blur
            case ._8E8E93: TokenColors.Background.blur
            case ._9B9B9B: TokenColors.Background.blur
            case ._545A68: TokenColors.Background.blur
            case ._04040F: TokenColors.Background.blur
            case ._333333: TokenColors.Background.blur
            case ._363638: TokenColors.Background.blur
            case ._474747: TokenColors.Background.blur
            case ._515151: TokenColors.Background.blur
            case ._535356: TokenColors.Background.blur
            case ._545457: TokenColors.Background.blur
            case ._545458: TokenColors.Background.blur
            case ._676767: TokenColors.Background.blur
            case ._848484: TokenColors.Background.blur
            case ._949494: TokenColors.Background.blur
            case ._999999: TokenColors.Background.blur
            case ._B5B5B5: TokenColors.Background.blur
            case ._BABABC: TokenColors.Background.blur
            case ._BBBBBB: TokenColors.Background.blur
            case ._C4C4C4: TokenColors.Background.blur
            case ._C4CCCC: TokenColors.Background.blur
            case ._C9C9C9: TokenColors.Background.blur
            case ._D1D1D1: TokenColors.Background.blur
            case ._DBDBDB: TokenColors.Background.blur
            case ._E2E2E2: TokenColors.Background.blur
            case ._E5E5E5: TokenColors.Background.blur
            case ._E6E6E6: TokenColors.Background.blur
            case ._E8E8E8: TokenColors.Background.blur
            case ._EBEBEB: TokenColors.Background.blur
            case ._EBEBF5: TokenColors.Background.blur
            case ._F4F4F4: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._1D1D1D: UIColor.gray1D1D1D
            case ._3A3A3C: UIColor.gray3A3A3C
            case ._3C3C43: UIColor.gray3C3C43
            case ._3D3D3D: UIColor.gray3D3D3D
            case ._3F3F42: UIColor.gray3F3F42
            case ._8E8E93: UIColor.gray8E8E93
            case ._9B9B9B: UIColor.gray9B9B9B
            case ._545A68: UIColor.gray545A68
            case ._04040F: UIColor.gray04040F
            case ._333333: UIColor.gray333333
            case ._363638: UIColor.gray363638
            case ._474747: UIColor.gray474747
            case ._515151: UIColor.gray515151
            case ._535356: UIColor.gray535356
            case ._545457: UIColor.gray545457
            case ._545458: UIColor.gray545458
            case ._676767: UIColor.gray676767
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
            case ._DBDBDB: UIColor.grayDBDBDB
            case ._E2E2E2: UIColor.grayE2E2E2
            case ._E5E5E5: UIColor.grayE5E5E5
            case ._E6E6E6: UIColor.grayE6E6E6
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
        case _544b27
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._544b27: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._544b27: UIColor.brown544B27
            }
        }
    }
    
    enum Green {
        case _00A382
        case _00A8868
        case _00A88680
        case _00C29A
        case _00C29A4D
        case _00E9B9
        case _007B62
        case _34C759
        case _009476
        case _347467
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._00A382: TokenColors.Background.blur
            case ._00A8868: TokenColors.Background.blur
            case ._00A88680: TokenColors.Background.blur
            case ._00C29A: TokenColors.Background.blur
            case ._00C29A4D: TokenColors.Background.blur
            case ._00E9B9: TokenColors.Background.blur
            case ._007B62: TokenColors.Background.blur
            case ._34C759: TokenColors.Background.blur
            case ._009476: TokenColors.Background.blur
            case ._347467: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._00A382: UIColor.green00A382
            case ._00A8868: UIColor.green00A886
            case ._00A88680: UIColor.green00A88680
            case ._00C29A: UIColor.green00C29A
            case ._00C29A4D: UIColor.green00C29A4D
            case ._00E9B9: UIColor.green00E9B9
            case ._007B62: UIColor.green007B62
            case ._34C759: UIColor.green34C759
            case ._009476: UIColor.green009476
            case ._347467: UIColor.green347467
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
        case _F95C61
        case _F288C2
        case _F7363D
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
            case ._F30C14: TokenColors.Background.blur
            case ._F95C61: TokenColors.Background.blur
            case ._F288C2: TokenColors.Background.blur
            case ._F7363D: TokenColors.Background.blur
            case ._FF3B30: TokenColors.Background.blur
            case ._FF453A: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._CA75D1: UIColor.redCA75D1
            case ._CE0A11: UIColor.redCE0A11
            case ._F30C14: UIColor.redF30C14
            case ._F95C61: UIColor.redF95C61
            case ._F288C2: UIColor.redF288C2
            case ._F7363D: UIColor.redF7363D
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
            case ._9D8319: TokenColors.Background.blur
            case ._F8D552: TokenColors.Background.blur
            case ._FED42926: TokenColors.Background.blur
            case ._FED429: TokenColors.Background.blur
            case ._FFCC0003: TokenColors.Background.blur
            case ._FFCC00: TokenColors.Background.blur
            case ._FFD60A: TokenColors.Background.blur
            case ._FFD600: TokenColors.Background.blur
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
    
    enum Shadow {
        case blackAlpha10
        case blackAlpha20
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .blackAlpha10: TokenColors.Background.blur
            case .blackAlpha20: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .blackAlpha10: UIColor.blackAlpha10
            case .blackAlpha20: UIColor.blackAlpha20
            }
        }
    }
    
    enum Background {
        case background_cell
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .background_cell: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .background_cell: UIColor.backgroundCell
            }
        }
    }
    
    enum View {
        case cellBackground
        case textForeground
        case turquoise
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .cellBackground: TokenColors.Background.blur
            case .textForeground: TokenColors.Background.blur
            case .turquoise: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .cellBackground: UIColor.cellBackground
            case .textForeground: UIColor.textForeground
            case .turquoise: UIColor.turquoise
            }
        }
    }
}
