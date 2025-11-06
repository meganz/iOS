import Foundation
import MEGAL10n

enum AccountMenuSectionType {
    case account
    case privacySuite

    var description: String? {
        switch self {
        case .privacySuite: Strings.Localizable.AccountMenu.OtherApps.sectionTitle
        default: nil
        }
    }
}
