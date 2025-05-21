import MEGAAssetsBundle
import SwiftUI
import UIKit

extension MEGAAssets {
    public struct UIColor {
        public static func color(named: String) -> UIKit.UIColor? {
            return UIKit.UIColor(named: named, in: Bundle.MEGAAssetsBundle, compatibleWith: nil)
        }
        
        public static var whiteFFFFFF: UIKit.UIColor { MEGAUIColorBundle.whiteFFFFFF }
        public static var black000000: UIKit.UIColor { MEGAUIColorBundle.black000000 }
        public static var black2C2C2E: UIKit.UIColor { MEGAUIColorBundle.black2C2C2E }
        public static var proAccountRedProIII: UIKit.UIColor { MEGAUIColorBundle.proAccountRedProIII }
        public static var black1C1C1E: UIKit.UIColor { MEGAUIColorBundle.black1C1C1E }
        public static var proAccountLITE: UIKit.UIColor { MEGAUIColorBundle.proAccountLITE }
        public static var proAccountRedProI: UIKit.UIColor { MEGAUIColorBundle.proAccountRedProI }
        public static var proAccountRedProII: UIKit.UIColor { MEGAUIColorBundle.proAccountRedProII }
        public static var grayDBDBDB: UIKit.UIColor { MEGAUIColorBundle.grayDBDBDB }
        public static var grayE2E2E2: UIKit.UIColor { MEGAUIColorBundle.grayE2E2E2 }
        public static var grayBBBBBB: UIKit.UIColor { MEGAUIColorBundle.grayBBBBBB }
        public static var gray999999: UIKit.UIColor { MEGAUIColorBundle.gray999999 }
        public static var green00C29A4D: UIKit.UIColor { MEGAUIColorBundle.green00C29A4D }
        public static var black363638: UIKit.UIColor { MEGAUIColorBundle.black363638 }
        public static var verifyEmailFirstGradient: UIKit.UIColor { MEGAUIColorBundle.verifyEmailFirstGradient }
        public static var verifyEmailSecondGradient: UIKit.UIColor { MEGAUIColorBundle.verifyEmailSecondGradient }
        public static var gray04040F: UIKit.UIColor { MEGAUIColorBundle.gray04040F }
        public static var whiteFFFFFF30: UIKit.UIColor { MEGAUIColorBundle.whiteFFFFFF30 }
        public static var pasteImageBorder: UIKit.UIColor { MEGAUIColorBundle.pasteImageBorder }
        public static var explorerForegroundDark: UIKit.UIColor { MEGAUIColorBundle.explorerForegroundDark }
        public static var gradientRed: UIKit.UIColor { MEGAUIColorBundle.gradientRed }
        public static var gradientPink: UIKit.UIColor { MEGAUIColorBundle.gradientPink }
        public static var explorerDocumentsFirstGradient: UIKit.UIColor { MEGAUIColorBundle.explorerDocumentsFirstGradient }
        public static var explorerDocumentsSecondGradient: UIKit.UIColor { MEGAUIColorBundle.explorerDocumentsSecondGradient }
        public static var explorerAudioFirstGradient: UIKit.UIColor { MEGAUIColorBundle.explorerAudioFirstGradient }
        public static var explorerAudioSecondGradient: UIKit.UIColor { MEGAUIColorBundle.explorerAudioSecondGradient }
        public static var explorerGradientLightBlue: UIKit.UIColor { MEGAUIColorBundle.explorerGradientLightBlue }
        public static var explorerGradientDarkBlue: UIKit.UIColor { MEGAUIColorBundle.explorerGradientDarkBlue }
        public static var whiteF7F7F7: UIKit.UIColor { MEGAUIColorBundle.whiteF7F7F7 }
        public static var pageBgColorDark: UIKit.UIColor { MEGAUIColorBundle.pageBgColorDark }
        public static var upgradeAccountPrimaryText: UIKit.UIColor { MEGAUIColorBundle.upgradeAccountPrimaryText }
        public static var gray8E8E93: UIKit.UIColor { MEGAUIColorBundle.gray8E8E93 }
        public static var green00A88680: UIKit.UIColor { MEGAUIColorBundle.green00A88680 }
        public static var black00000015: UIKit.UIColor { MEGAUIColorBundle.black00000015 }
        public static var yellowFED429: UIKit.UIColor { MEGAUIColorBundle.yellowFED429 }
        public static var whiteF2F2F2: UIKit.UIColor { MEGAUIColorBundle.whiteF2F2F2 }
        public static var chatAvatarBackground: UIKit.UIColor { MEGAUIColorBundle.chatAvatarBackground }
        public static var whiteFFFFFF00: UIKit.UIColor { MEGAUIColorBundle.whiteFFFFFF00 }
        public static var redFF3B30: UIKit.UIColor { MEGAUIColorBundle.redFF3B30 }
        public static var orangeF9B35F: UIKit.UIColor { MEGAUIColorBundle.orangeF9B35F }
        public static var orangeE68F4D: UIKit.UIColor { MEGAUIColorBundle.orangeE68F4D }
        public static var blue02A2FF: UIKit.UIColor { MEGAUIColorBundle.blue02A2FF }
        public static var blue0274CC: UIKit.UIColor { MEGAUIColorBundle.blue0274CC }
        public static var blue00ACBF: UIKit.UIColor { MEGAUIColorBundle.blue00ACBF }
        public static var blue0095A6: UIKit.UIColor { MEGAUIColorBundle.blue0095A6 }
        public static var redF288C2: UIKit.UIColor { MEGAUIColorBundle.redF288C2 }
        public static var redCA75D1: UIKit.UIColor { MEGAUIColorBundle.redCA75D1 }
        public static var whiteEFEFEF: UIKit.UIColor { MEGAUIColorBundle.whiteEFEFEF }
        public static var callAvatarBackground: UIKit.UIColor { MEGAUIColorBundle.callAvatarBackground }
        public static var callAvatarBackgroundGradient: UIKit.UIColor { MEGAUIColorBundle.callAvatarBackgroundGradient }
        public static var chatStatusOnline: UIKit.UIColor { MEGAUIColorBundle.chatStatusOnline }
        public static var chatStatusOffline: UIKit.UIColor { MEGAUIColorBundle.chatStatusOffline }
        public static var chatStatusAway: UIKit.UIColor { MEGAUIColorBundle.chatStatusAway }
        public static var chatStatusBusy: UIKit.UIColor { MEGAUIColorBundle.chatStatusBusy }
        public static var whiteFFD60008: UIKit.UIColor { MEGAUIColorBundle.whiteFFD60008 }
        public static var black29292C: UIKit.UIColor { MEGAUIColorBundle.black29292C }
        public static var mediaConsumptionDecryptTitleEnabled: UIKit.UIColor { MEGAUIColorBundle.mediaConsumptionDecryptTitleEnabled }
        public static var mediaConsumptionDecryptTitleDisabled: UIKit.UIColor { MEGAUIColorBundle.mediaConsumptionDecryptTitleDisabled }
        public static var green00C29A: UIKit.UIColor { MEGAUIColorBundle.green00C29A }
        public static var grayE4EBEA: UIKit.UIColor { MEGAUIColorBundle.grayE4EBEA }
    }
}

extension MEGAAssets {
    public struct Color {
        public static func color(named: String) -> SwiftUI.Color {
            return SwiftUI.Color(named, bundle: Bundle.MEGAAssetsBundle)
        }
        
        public static var black000000: SwiftUI.Color { MEGAColorBundle.black000000 }
        public static var whiteFFFFFF: SwiftUI.Color { MEGAColorBundle.whiteFFFFFF }
        public static var black2C2C2E: SwiftUI.Color { MEGAColorBundle.black2C2C2E }
        public static var gray363638: SwiftUI.Color { MEGAColorBundle.gray363638 }
        public static var grayD1D1D1: SwiftUI.Color { MEGAColorBundle.grayD1D1D1 }
        public static var navigationBg: SwiftUI.Color { MEGAColorBundle.navigationBg }
        public static var backgroundRegularPrimaryElevated: SwiftUI.Color { MEGAColorBundle.backgroundRegularPrimaryElevated }
    }
}
