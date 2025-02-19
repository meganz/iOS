import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

public extension ChatStatusEntity {
    var localizedIdentifier: String? {
        switch self {
        case .offline: Strings.Localizable.offline
        case .away: Strings.Localizable.away
        case .online: Strings.Localizable.online
        case .busy: Strings.Localizable.busy
        default: nil
        }
    }
    
    var color: Color {
        switch self {
        case .online: TokenColors.Support.success.swiftUI
        case .offline: TokenColors.Background.surface3.swiftUI
        case .away: TokenColors.Support.warning.swiftUI
        case .busy: TokenColors.Support.error.swiftUI
        default: .clear
        }
    }
}
